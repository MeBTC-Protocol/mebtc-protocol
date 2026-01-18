// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MockUSDC} from "../src/mocks/MockUSDC.sol";

/*
Env:
  PRIVATE_KEY
*/
contract DeployMockUSDC is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);
        MockUSDC usdc = new MockUSDC();
        vm.stopBroadcast();

        console2.log("MockUSDC:", address(usdc));
    }
}
