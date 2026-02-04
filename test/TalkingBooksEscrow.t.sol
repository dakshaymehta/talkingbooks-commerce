// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {TalkingBooksEscrow} from "../src/TalkingBooksEscrow.sol";

contract MockUSDC {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract TalkingBooksEscrowTest is Test {
    TalkingBooksEscrow public escrow;
    MockUSDC public usdc;
    
    address platform = address(0x1);
    address author = address(0x2);
    address user = address(0x3);
    
    function setUp() public {
        usdc = new MockUSDC();
        escrow = new TalkingBooksEscrow(address(usdc), platform);
    }
    
    function test_RegisterAuthor() public {
        vm.prank(author);
        escrow.registerAuthor("shakespeare", 100000); // $0.10
        
        (address wallet, uint256 price, , , bool active) = escrow.getAuthor("shakespeare");
        assertEq(wallet, author);
        assertEq(price, 100000);
        assertTrue(active);
    }
    
    function test_StartSession() public {
        // Register author
        vm.prank(author);
        escrow.registerAuthor("feynman", 250000); // $0.25
        
        // Mint USDC to user and approve
        usdc.mint(user, 1000000); // $1.00
        vm.prank(user);
        usdc.approve(address(escrow), 250000);
        
        // Start session
        vm.prank(user);
        escrow.startSession("feynman");
        
        // Check balances (70% to author, 30% to platform)
        assertEq(usdc.balanceOf(author), 175000); // $0.175
        assertEq(usdc.balanceOf(platform), 75000); // $0.075
        
        // Check stats
        (, , uint256 sessions, uint256 earnings, ) = escrow.getAuthor("feynman");
        assertEq(sessions, 1);
        assertEq(earnings, 175000);
    }
    
    function test_RevertOnUnknownAuthor() public {
        vm.prank(user);
        vm.expectRevert(TalkingBooksEscrow.AuthorNotFound.selector);
        escrow.startSession("unknown");
    }
}
