// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TalkingBooksEscrow
 * @author PantheonAI (JarvisPantheon + @Dakshay)
 * @notice Pay USDC to have AI conversations with author personas
 * @dev Built for USDC Hackathon - Agentic Commerce Track
 * 
 * "I think one of the things that would be tremendously useful is 
 *  if we could ask Aristotle a question." — Steve Jobs, 1985
 * 
 * Knowledge is the ultimate commodity.
 */

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TalkingBooksEscrow {
    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice USDC token contract (6 decimals)
    IERC20 public immutable USDC;
    
    /// @notice Maximum platform fee (50% = 5000 bps)
    uint256 public constant MAX_PLATFORM_FEE_BPS = 5000;
    
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Platform wallet that receives fees
    address public platform;
    
    /// @notice Platform fee in basis points (default 30% = 3000 bps)
    uint256 public platformFeeBps = 3000;
    
    /// @notice Author persona data
    struct Author {
        address wallet;          // Wallet receiving royalties
        uint256 pricePerSession; // Price in USDC (6 decimals, e.g., 100000 = $0.10)
        uint256 totalSessions;   // Lifetime session count
        uint256 totalEarnings;   // Lifetime earnings (author share only)
        bool active;             // Whether author is active
    }
    
    /// @notice Mapping of author ID to Author struct
    mapping(string => Author) public authors;
    
    /// @notice List of all registered author IDs
    string[] public authorIds;
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emitted when a new author is registered
    event AuthorRegistered(
        string indexed authorId,
        address indexed wallet,
        uint256 pricePerSession
    );
    
    /// @notice Emitted when an author's details are updated
    event AuthorUpdated(
        string indexed authorId,
        uint256 newPrice
    );
    
    /// @notice Emitted when a session is started and payment is processed
    event SessionStarted(
        string indexed authorId,
        address indexed user,
        uint256 totalAmount,
        uint256 authorShare,
        uint256 platformShare,
        uint256 sessionNumber
    );
    
    /// @notice Emitted when platform fee is updated
    event PlatformFeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    
    /// @notice Emitted when platform address is updated
    event PlatformUpdated(address oldPlatform, address newPlatform);
    
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    
    error AuthorAlreadyExists();
    error AuthorNotFound();
    error InvalidPrice();
    error InvalidAuthorId();
    error TransferFailed();
    error OnlyPlatform();
    error FeeTooHigh();
    error ZeroAddress();
    
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Initialize the escrow contract
     * @param _usdc Address of the USDC token contract
     * @param _platform Address of the platform wallet
     */
    constructor(address _usdc, address _platform) {
        if (_usdc == address(0) || _platform == address(0)) revert ZeroAddress();
        USDC = IERC20(_usdc);
        platform = _platform;
    }
    
    /*//////////////////////////////////////////////////////////////
                            AUTHOR FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Register a new author persona
     * @param authorId Unique identifier (e.g., "shakespeare", "feynman")
     * @param pricePerSession Price per session in USDC (6 decimals)
     * @dev Anyone can register an author. The caller becomes the royalty recipient.
     */
    function registerAuthor(
        string calldata authorId,
        uint256 pricePerSession
    ) external {
        if (bytes(authorId).length == 0) revert InvalidAuthorId();
        if (authors[authorId].active) revert AuthorAlreadyExists();
        if (pricePerSession == 0) revert InvalidPrice();
        
        authors[authorId] = Author({
            wallet: msg.sender,
            pricePerSession: pricePerSession,
            totalSessions: 0,
            totalEarnings: 0,
            active: true
        });
        
        authorIds.push(authorId);
        
        emit AuthorRegistered(authorId, msg.sender, pricePerSession);
    }
    
    /**
     * @notice Update author price (only author wallet can call)
     * @param authorId The author to update
     * @param newPrice New price per session
     */
    function updateAuthorPrice(
        string calldata authorId,
        uint256 newPrice
    ) external {
        Author storage author = authors[authorId];
        if (!author.active) revert AuthorNotFound();
        if (msg.sender != author.wallet) revert OnlyPlatform();
        if (newPrice == 0) revert InvalidPrice();
        
        author.pricePerSession = newPrice;
        
        emit AuthorUpdated(authorId, newPrice);
    }
    
    /*//////////////////////////////////////////////////////////////
                            SESSION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Start a conversation session with an author
     * @param authorId The author to talk to
     * @dev User must have approved this contract to spend USDC first
     * 
     * Flow:
     * 1. User approves USDC spend: USDC.approve(escrow, amount)
     * 2. User calls startSession(authorId)
     * 3. Contract transfers USDC from user
     * 4. Contract splits payment: 70% to author, 30% to platform
     * 5. Events emitted for tracking
     * 6. Agent delivers AI conversation experience
     */
    function startSession(string calldata authorId) external {
        Author storage author = authors[authorId];
        if (!author.active) revert AuthorNotFound();
        
        uint256 amount = author.pricePerSession;
        
        // Transfer USDC from user to this contract
        if (!USDC.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        
        // Calculate splits
        uint256 platformShare = (amount * platformFeeBps) / 10000;
        uint256 authorShare = amount - platformShare;
        
        // Transfer to author
        if (!USDC.transfer(author.wallet, authorShare)) {
            revert TransferFailed();
        }
        
        // Transfer to platform
        if (!USDC.transfer(platform, platformShare)) {
            revert TransferFailed();
        }
        
        // Update stats
        author.totalSessions++;
        author.totalEarnings += authorShare;
        
        emit SessionStarted(
            authorId,
            msg.sender,
            amount,
            authorShare,
            platformShare,
            author.totalSessions
        );
    }
    
    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Get author details
     * @param authorId The author to query
     * @return wallet Author's wallet address
     * @return pricePerSession Price per session in USDC
     * @return totalSessions Lifetime session count
     * @return totalEarnings Lifetime earnings (author share)
     * @return active Whether author is active
     */
    function getAuthor(string calldata authorId) external view returns (
        address wallet,
        uint256 pricePerSession,
        uint256 totalSessions,
        uint256 totalEarnings,
        bool active
    ) {
        Author memory a = authors[authorId];
        return (a.wallet, a.pricePerSession, a.totalSessions, a.totalEarnings, a.active);
    }
    
    /**
     * @notice Get total number of registered authors
     * @return count Number of authors
     */
    function getAuthorCount() external view returns (uint256) {
        return authorIds.length;
    }
    
    /**
     * @notice Get author ID by index
     * @param index Index in the authorIds array
     * @return authorId The author ID at that index
     */
    function getAuthorIdByIndex(uint256 index) external view returns (string memory) {
        return authorIds[index];
    }
    
    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Update platform fee (only platform can call)
     * @param newFeeBps New fee in basis points (max 50%)
     */
    function setPlatformFee(uint256 newFeeBps) external {
        if (msg.sender != platform) revert OnlyPlatform();
        if (newFeeBps > MAX_PLATFORM_FEE_BPS) revert FeeTooHigh();
        
        emit PlatformFeeUpdated(platformFeeBps, newFeeBps);
        platformFeeBps = newFeeBps;
    }
    
    /**
     * @notice Update platform address (only platform can call)
     * @param newPlatform New platform wallet address
     */
    function setPlatform(address newPlatform) external {
        if (msg.sender != platform) revert OnlyPlatform();
        if (newPlatform == address(0)) revert ZeroAddress();
        
        emit PlatformUpdated(platform, newPlatform);
        platform = newPlatform;
    }
}
