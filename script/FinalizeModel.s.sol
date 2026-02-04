// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MinerNFT} from "../src/nft/MinerNFT.sol";

/*
Env:
  PRIVATE_KEY
  MINER_ADDRESS
  MODEL_ID
*/

contract FinalizeModel is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address minerAddr = vm.envAddress("MINER_ADDRESS");
        uint16 modelId = uint16(vm.envUint("MODEL_ID"));

        MinerNFT miner = MinerNFT(minerAddr);

        vm.startBroadcast(pk);
        miner.finalizeModel(modelId);
        vm.stopBroadcast();

        console2.log("Finalized modelId:", uint256(modelId));
    }
}
