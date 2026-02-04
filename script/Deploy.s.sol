// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {TalkingBooksEscrow} from "../src/TalkingBooksEscrow.sol";

contract DeployScript is Script {
    // Base Sepolia USDC
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address platform = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        TalkingBooksEscrow escrow = new TalkingBooksEscrow(USDC, platform);
        
        console.log("TalkingBooksEscrow deployed to:", address(escrow));
        console.log("Platform:", platform);
        console.log("USDC:", USDC);
        
        vm.stopBroadcast();
    }
}
