// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MockUSDC} from "../src/mocks/MockUSDC.sol";

/*
Env:
  PRIVATE_KEY
  TOKEN_ADDRESS
  RECIPIENT
  AMOUNT_USDC (6 decimals)
*/
contract MintMockUSDC is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address token = vm.envAddress("TOKEN_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT");
        uint256 amount = vm.envUint("AMOUNT_USDC");

        require(token != address(0) && recipient != address(0), "arg=0");

        vm.startBroadcast(pk);
        MockUSDC(token).mint(recipient, amount);
        vm.stopBroadcast();

        console2.log("Minted:", amount);
        console2.log("To:", recipient);
    }
}
