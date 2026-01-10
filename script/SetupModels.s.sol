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
  BASIC_URI
  MEMINER_URI

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

        MinerNFT miner = MinerNFT(minerAddr);

        string memory basicUri = _envStringOr("BASIC_URI", "ipfs://BASIC_MINER_METADATA");
        string memory meUri    = _envStringOr("MEMINER_URI", "ipfs://ME_MINER_METADATA");


        // -------------------------
        // BasicMiner (Nerdminer-like)
        // -------------------------
        // baseHashrate: 500 (interpretiere es als 500 Ghash in deinem UI, onchain ist es nur eine Einheit)
        // power: 20 W
        // maxSupply: 20,000
        // price: 1 USDC
        //
        // powerCosts / hashCosts = upgrade step costs (4 steps)
        // (Vorschlag: stark ansteigend, weil "letztes Tuning" teurer ist)
        uint256[4] memory basicPowerCosts = [
            uint256(50_000),   // 0.05 USDC
            uint256(150_000),  // 0.15 USDC
            uint256(400_000),  // 0.40 USDC
            uint256(1_000_000) // 1.00 USDC
        ];

        uint256[4] memory basicHashCosts = [
            uint256(100_000),  // 0.10 USDC
            uint256(250_000),  // 0.25 USDC
            uint256(600_000),  // 0.60 USDC
            uint256(1_500_000) // 1.50 USDC
        ];

        // -------------------------
        // MeMiner (S9 feeling: mehr Power, aber bessere Effizienz)
        // -------------------------
        // baseHashrate: 2000
        // power: 50 W
        // maxSupply: 10,000
        // price: 3 USDC
        //
        // Upgrade-Kosten "ausgeglichen" (gleichmäßiger ansteigend)
        uint256[4] memory mePowerCosts = [
           uint256(250_000),  // 0.25 USDC
           uint256(350_000),  // 0.35 USDC
           uint256(500_000),  // 0.50 USDC
           uint256(700_000)   // 0.70 USDC
        ];

        uint256[4] memory meHashCosts = [
           uint256(350_000),  // 0.35 USDC
           uint256(500_000),  // 0.50 USDC
           uint256(700_000),  // 0.70 USDC
           uint256(950_000)   // 0.95 USDC
        ];

        vm.startBroadcast(pk);

        // Add + finalize BasicMiner
        uint16 basicId = miner.addModel(
            500,                 // baseHashrate
            20,                  // basePowerWatt
            20_000,              // maxSupply
            1_000_000,            // priceUSDC
            basicUri,
            basicPowerCosts,
            basicHashCosts
        );
        miner.finalizeModel(basicId);
        console2.log("BasicMiner modelId:", uint256(basicId));

        // Add + finalize MeMiner
        uint16 meId = miner.addModel(
            2000,                // baseHashrate
            50,                  // basePowerWatt
            10_000,              // maxSupply
            3_000_000,            // priceUSDC
            meUri,
            mePowerCosts,
            meHashCosts
        );
        miner.finalizeModel(meId);
        console2.log("MeMiner modelId:", uint256(meId));

        vm.stopBroadcast();
    }
}
