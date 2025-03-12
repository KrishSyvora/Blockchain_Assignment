// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract DeployNFT is Script{
    function run() external {
        vm.startBroadcast(); // required for deploying contracts or tx's to

        // Deploying the contract
        NFTMarketplace marketplace = new NFTMarketplace();
        console.log("NFT Marketplace deployed at:", address(marketplace));

        vm.stopBroadcast(); // esures no additional actions are taken after deployment 
    }
}
//forge script script/deployNFT.s.sol:DeployNFT --rpc-url https://sepolia-rpc.scroll.io --private-key <private-key> --broadcast