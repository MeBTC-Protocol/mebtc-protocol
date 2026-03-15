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
  BASIC_URI
  MEMINER_URI
  PROMINER_URI
  PRIMEMINER_URI
  APEXMINER_URI

USDC Decimals:
  In den Costs/Prices verwenden wir 6 decimals (1 USDC = 1_000_000)
*/

contract SetupModels is Script {
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
        address twapOracle = vm.envAddress("TWAP_ORACLE");

        MinerNFT miner = MinerNFT(minerAddr);

        string memory rigUri = _envStringOr(
            "RIG_URI",
            "ipfs://bafybeigsp6tfv3i3ue5efhcbejgjvuo34ditxb7o2fvqjxokb5fn5fmtjq/RigMiner.json"
        );
        string memory basicUri = _envStringOr(
            "BASIC_URI",
            "ipfs://bafybeigsp6tfv3i3ue5efhcbejgjvuo34ditxb7o2fvqjxokb5fn5fmtjq/BasicMiner.json"
        );
        string memory meUri = _envStringOr(
            "MEMINER_URI",
            "ipfs://bafybeigsp6tfv3i3ue5efhcbejgjvuo34ditxb7o2fvqjxokb5fn5fmtjq/MeMiner.json"
        );
        string memory proUri = _envStringOr(
            "PROMINER_URI",
            "ipfs://bafybeigsp6tfv3i3ue5efhcbejgjvuo34ditxb7o2fvqjxokb5fn5fmtjq/ProMiner.json"
        );
        string memory primeUri = _envStringOr(
            "PRIMEMINER_URI",
            "ipfs://bafybeigsp6tfv3i3ue5efhcbejgjvuo34ditxb7o2fvqjxokb5fn5fmtjq/PrimeMiner.json"
        );
        string memory apexUri = _envStringOr(
            "APEXMINER_URI",
            "ipfs://bafybeigsp6tfv3i3ue5efhcbejgjvuo34ditxb7o2fvqjxokb5fn5fmtjq/ApexMiner.json"
        );

        // -------------------------
        // RigMiner
        // -------------------------
        // baseHashrate: 500 (0.5 TH/s = 500 GH/s)
        // power: 200 W
        // maxSupply: 50,000
        // price: 24 USDC
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

        // -------------------------
        // BasicMiner
        // -------------------------
        // baseHashrate: 13,500 (13.5 TH/s)
        // power: 1350 W
        // maxSupply: 20,000
        // price: 49 USDC
        uint256[4] memory basicPowerCosts = [
            uint256(1_000_000),  // 1 USDC
            uint256(2_000_000),  // 2 USDC
            uint256(4_000_000),  // 4 USDC
            uint256(6_000_000)   // 6 USDC
        ];

        uint256[4] memory basicHashCosts = [
            uint256(2_000_000),   // 2 USDC
            uint256(4_000_000),   // 4 USDC
            uint256(6_000_000),   // 6 USDC
            uint256(10_000_000)   // 10 USDC
        ];

        // -------------------------
        // MeMiner
        // -------------------------
        // baseHashrate: 50,000 (50 TH/s)
        // power: 2250 W
        // maxSupply: 10,000
        // price: 124 USDC
        uint256[4] memory mePowerCosts = [
           uint256(2_000_000),   // 2 USDC
           uint256(5_000_000),   // 5 USDC
           uint256(9_000_000),   // 9 USDC
           uint256(14_000_000)   // 14 USDC
        ];

        uint256[4] memory meHashCosts = [
           uint256(4_000_000),   // 4 USDC
           uint256(7_000_000),   // 7 USDC
           uint256(12_000_000),  // 12 USDC
           uint256(20_000_000)   // 20 USDC
        ];

        // -------------------------
        // ProMiner
        // -------------------------
        // baseHashrate: 104,000 (104 TH/s)
        // power: 3068 W
        // maxSupply: 3,000
        // price: 349 USDC
        uint256[4] memory proPowerCosts = [
            uint256(6_000_000),   // 6 USDC
            uint256(12_000_000),  // 12 USDC
            uint256(19_000_000),  // 19 USDC
            uint256(31_000_000)   // 31 USDC
        ];

        uint256[4] memory proHashCosts = [
            uint256(10_000_000),  // 10 USDC
            uint256(19_000_000),  // 19 USDC
            uint256(31_000_000),  // 31 USDC
            uint256(50_000_000)   // 50 USDC
        ];

        // -------------------------
        // PrimeMiner
        // -------------------------
        // baseHashrate: 200,000 (200 TH/s)
        // power: 3500 W
        // maxSupply: 800
        // price: 749 USDC
        uint256[4] memory primePowerCosts = [
            uint256(10_000_000),  // 10 USDC
            uint256(20_000_000),  // 20 USDC
            uint256(35_000_000),  // 35 USDC
            uint256(55_000_000)   // 55 USDC
        ];

        uint256[4] memory primeHashCosts = [
            uint256(17_000_000),  // 17 USDC
            uint256(35_000_000),  // 35 USDC
            uint256(55_000_000),  // 55 USDC
            uint256(90_000_000)   // 90 USDC
        ];

        // -------------------------
        // ApexMiner
        // -------------------------
        // baseHashrate: 270,000 (270 TH/s)
        // power: 3645 W
        // maxSupply: 200
        // price: 1,499 USDC
        uint256[4] memory apexPowerCosts = [
            uint256(19_000_000),  // 19 USDC
            uint256(37_000_000),  // 37 USDC
            uint256(67_000_000),  // 67 USDC
            uint256(105_000_000)  // 105 USDC
        ];

        uint256[4] memory apexHashCosts = [
            uint256(34_000_000),  // 34 USDC
            uint256(67_000_000),  // 67 USDC
            uint256(105_000_000), // 105 USDC
            uint256(165_000_000)  // 165 USDC
        ];

        vm.startBroadcast(pk);

        // Add RigMiner
        uint16 rigId = miner.addModel(
            500,                // baseHashrate
            200,                // basePowerWatt
            50_000,             // maxSupply
            24_000_000,         // priceUSDC
            0,                  // minLiquidityUsdc: always open
            rigUri,
            rigPowerCosts,
            rigHashCosts
        );
        console2.log("RigMiner added modelId:", uint256(rigId));

        // Add BasicMiner
        uint16 basicId = miner.addModel(
            13_500,             // baseHashrate
            1_350,              // basePowerWatt
            20_000,             // maxSupply
            49_000_000,         // priceUSDC
            10_000_000_000,     // minLiquidityUsdc: 10,000 USDC
            basicUri,
            basicPowerCosts,
            basicHashCosts
        );
        console2.log("BasicMiner added modelId:", uint256(basicId));

        // Add MeMiner
        uint16 meId = miner.addModel(
            50_000,             // baseHashrate
            2_250,              // basePowerWatt
            10_000,             // maxSupply
            124_000_000,        // priceUSDC
            50_000_000_000,     // minLiquidityUsdc: 50,000 USDC
            meUri,
            mePowerCosts,
            meHashCosts
        );
        console2.log("MeMiner added modelId:", uint256(meId));

        // Add ProMiner
        uint16 proId = miner.addModel(
            104_000,            // baseHashrate
            3_068,              // basePowerWatt
            3_000,              // maxSupply
            349_000_000,        // priceUSDC
            200_000_000_000,    // minLiquidityUsdc: 200,000 USDC
            proUri,
            proPowerCosts,
            proHashCosts
        );
        console2.log("ProMiner added modelId:", uint256(proId));

        // Add PrimeMiner
        uint16 primeId = miner.addModel(
            200_000,            // baseHashrate
            3_500,              // basePowerWatt
            800,                // maxSupply
            749_000_000,        // priceUSDC
            750_000_000_000,    // minLiquidityUsdc: 750,000 USDC
            primeUri,
            primePowerCosts,
            primeHashCosts
        );
        console2.log("PrimeMiner added modelId:", uint256(primeId));

        // Add ApexMiner
        uint16 apexId = miner.addModel(
            270_000,            // baseHashrate
            3_645,              // basePowerWatt
            200,                // maxSupply
            1_499_000_000,      // priceUSDC
            2_000_000_000_000,  // minLiquidityUsdc: 2,000,000 USDC
            apexUri,
            apexPowerCosts,
            apexHashCosts
        );
        console2.log("ApexMiner added modelId:", uint256(apexId));

        // Finalize all models (makes them purchasable once liquidity gate passes)
        miner.finalizeModel(rigId);
        miner.finalizeModel(basicId);
        miner.finalizeModel(meId);
        miner.finalizeModel(proId);
        miner.finalizeModel(primeId);
        miner.finalizeModel(apexId);
        console2.log("All models finalized.");

        // Activate liquidity gate
        miner.setLiquidityOracle(twapOracle);
        console2.log("LiquidityOracle set:", twapOracle);

        vm.stopBroadcast();
    }
}
