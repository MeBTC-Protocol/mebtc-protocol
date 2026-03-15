// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MinerNFT} from "../src/nft/MinerNFT.sol";

/*
Env:
  MINER_ADDRESS

Optional:
  FROM_ID (default: 1)
  TO_ID   (default: nextModelId - 1)
*/

contract ListModels is Script {
    function _envUintOr(string memory key, uint256 fallbackValue) internal view returns (uint256) {
        try vm.envUint(key) returns (uint256 v) {
            return v;
        } catch {
            return fallbackValue;
        }
    }

    function run() external view {
        address minerAddr = vm.envAddress("MINER_ADDRESS");
        MinerNFT miner = MinerNFT(minerAddr);

        uint256 nextId = uint256(miner.nextModelId());
        if (nextId <= 1) {
            console2.log("No models found.");
            return;
        }

        uint256 defaultFrom = 1;
        uint256 defaultTo = nextId - 1;

        uint256 fromId = _envUintOr("FROM_ID", defaultFrom);
        uint256 toId = _envUintOr("TO_ID", defaultTo);

        if (fromId < 1) fromId = 1;
        if (toId > defaultTo) toId = defaultTo;

        require(fromId <= toId, "invalid range");

        console2.log("MinerNFT:", minerAddr);
        console2.log("Model range:", fromId, "->", toId);

        for (uint256 i = fromId; i <= toId; i++) {
            (
                uint32 baseHashrate,
                uint32 basePowerWatt,
                uint32 maxSupply,
                uint32 minted,
                uint256 priceUSDC,
                bool finalized,
                ,
                ,
                ,
            ) = miner.getModel(uint16(i));

            console2.log("----");
            console2.log("ModelId:", i);
            console2.log("baseHashrate(GH):", uint256(baseHashrate));
            console2.log("basePowerWatt:", uint256(basePowerWatt));
            console2.log("maxSupply:", uint256(maxSupply));
            console2.log("minted:", uint256(minted));
            console2.log("priceUSDC(6d):", priceUSDC);
            console2.log("finalized:", finalized);
        }
    }
}
