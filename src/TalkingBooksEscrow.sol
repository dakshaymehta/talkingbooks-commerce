// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title TalkingBooksEscrow
/// @notice Pay USDC to have AI conversations with authors. Revenue splits automatically.
/// @dev Built for PantheonAI - "Ask Aristotle a question"
contract TalkingBooksEscrow {
    IERC20 public immutable usdc;
    address public platform;
    uint256 public platformFeeBps = 3000; // 30% in basis points
    
    struct Author {
        address wallet;
        uint256 pricePerSession; // in USDC (6 decimals)
        uint256 totalSessions;
        uint256 totalEarnings;
        bool active;
    }
    
    mapping(string => Author) public authors;
    string[] public authorIds;
    
    event AuthorRegistered(string indexed authorId, address wallet, uint256 price);
    event SessionStarted(string indexed authorId, address indexed user, uint256 amount, uint256 sessionNumber);
    event PaymentSplit(string indexed authorId, uint256 authorShare, uint256 platformShare);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    
    constructor(address _usdc, address _platform) {
        usdc = IERC20(_usdc);
        platform = _platform;
    }
    
    /// @notice Register an author persona with a price per session
    /// @param authorId Unique identifier (e.g., "shakespeare", "einstein")
    /// @param pricePerSession Price in USDC (6 decimals, so 100000 = $0.10)
    function registerAuthor(string memory authorId, uint256 pricePerSession) external {
        require(bytes(authorId).length > 0, "Empty authorId");
        require(!authors[authorId].active, "Author already registered");
        require(pricePerSession > 0, "Price must be > 0");
        
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
    
    /// @notice Start a conversation session with an author
    /// @param authorId The author to talk to
    /// @dev User must have approved this contract to spend USDC first
    function startSession(string memory authorId) external {
        Author storage author = authors[authorId];
        require(author.active, "Author not found");
        
        uint256 amount = author.pricePerSession;
        
        // Transfer USDC from user to this contract
        require(usdc.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");
        
        // Calculate splits
        uint256 platformShare = (amount * platformFeeBps) / 10000;
        uint256 authorShare = amount - platformShare;
        
        // Distribute payments
        require(usdc.transfer(author.wallet, authorShare), "Author payment failed");
        require(usdc.transfer(platform, platformShare), "Platform payment failed");
        
        // Update stats
        author.totalSessions++;
        author.totalEarnings += authorShare;
        
        emit SessionStarted(authorId, msg.sender, amount, author.totalSessions);
        emit PaymentSplit(authorId, authorShare, platformShare);
    }
    
    /// @notice Get author info
    function getAuthor(string memory authorId) external view returns (
        address wallet,
        uint256 pricePerSession,
        uint256 totalSessions,
        uint256 totalEarnings,
        bool active
    ) {
        Author memory a = authors[authorId];
        return (a.wallet, a.pricePerSession, a.totalSessions, a.totalEarnings, a.active);
    }
    
    /// @notice Get total number of registered authors
    function getAuthorCount() external view returns (uint256) {
        return authorIds.length;
    }
    
    /// @notice Update platform fee (only platform can call)
    function setPlatformFee(uint256 newFeeBps) external {
        require(msg.sender == platform, "Only platform");
        require(newFeeBps <= 5000, "Fee too high"); // Max 50%
        emit PlatformFeeUpdated(platformFeeBps, newFeeBps);
        platformFeeBps = newFeeBps;
    }
}
