// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IMiningManager {
    function resyncMiner(uint256 tokenId) external;
    function currentEffHash(uint256 tokenId) external view returns (uint256);
}

/*
Env:
  PRIVATE_KEY
  MANAGER_ADDRESS
  TOKEN_ID
*/
contract ResyncMiner is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address managerAddr = vm.envAddress("MANAGER_ADDRESS");
        uint256 tokenId = vm.envUint("TOKEN_ID");

        require(managerAddr != address(0), "manager=0");

        IMiningManager manager = IMiningManager(managerAddr);
        uint256 beforeHash = manager.currentEffHash(tokenId);

        vm.startBroadcast(pk);
        manager.resyncMiner(tokenId);
        vm.stopBroadcast();

        uint256 afterHash = manager.currentEffHash(tokenId);
        console2.log("Resynced tokenId:", tokenId);
        console2.log("currentEffHash (before->after):", beforeHash, "->", afterHash);
    }
}
