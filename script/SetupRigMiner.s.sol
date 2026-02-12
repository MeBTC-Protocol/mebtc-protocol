// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MinerNFT} from "../src/nft/MinerNFT.sol";

/*
Env:
  PRIVATE_KEY
  MINER_ADDRESS

Optional:
  RIG_URI
*/

contract SetupRigMiner is Script {
    function _envStringOr(string memory key, string memory fallbackValue) internal view returns (string memory) {
        try vm.envString(key) returns (string memory v) {
            return v;
        } catch {
            return fallbackValue;
        }
    }

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address minerAddr = vm.envAddress("MINER_ADDRESS");
        MinerNFT miner = MinerNFT(minerAddr);

        string memory rigUri = _envStringOr(
            "RIG_URI",
            "ipfs://bafybeigsp6tfv3i3ue5efhcbejgjvuo34ditxb7o2fvqjxokb5fn5fmtjq/RigMiner.json"
        );

        // RigMiner params (USDC 6 decimals)
        uint256[4] memory rigPowerCosts = [
            uint256(1_000_000),  // 1 USDC
            uint256(2_000_000),  // 2 USDC
            uint256(3_000_000),  // 3 USDC
            uint256(5_000_000)   // 5 USDC
        ];

        uint256[4] memory rigHashCosts = [
            uint256(2_000_000),  // 2 USDC
            uint256(4_000_000),  // 4 USDC
            uint256(6_000_000),  // 6 USDC
            uint256(9_000_000)   // 9 USDC
        ];

        vm.startBroadcast(pk);
        uint16 rigId = miner.addModel(
            500,            // baseHashrate (GH)
            200,            // basePowerWatt
            50_000,         // maxSupply
            24_000_000,     // priceUSDC
            rigUri,
            rigPowerCosts,
            rigHashCosts
        );
        vm.stopBroadcast();

        console2.log("RigMiner added modelId:", uint256(rigId));
    }
}
