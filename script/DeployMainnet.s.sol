// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MiningManager} from "../src/core/MiningManager.sol";
import {MeBTC} from "../src/token/MeBTC.sol";
import {MinerNFT} from "../src/nft/MinerNFT.sol";

/*
    Env Vars:
      PRIVATE_KEY
      PAY_TOKEN_ADDRESS
      POOL_ADDRESS        // poolTreasury (Wallet/Multisig/Treasury-Contract), NICHT Uniswap Pool
      PROJECT_WALLET      // 5% vom Primärverkauf
      ROYALTY_WALLET      // 100% der Royalties (Receiver)
      ROYALTY_BPS         // z.B. 250 = 2.5%
*/

contract DeployMainnet is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address PAY = vm.envAddress("PAY_TOKEN_ADDRESS");
        address POOL = vm.envAddress("POOL_ADDRESS");
        address PROJECT = vm.envAddress("PROJECT_WALLET");
        address ROYALTY = vm.envAddress("ROYALTY_WALLET");
        uint96 ROYALTY_BPS = uint96(vm.envUint("ROYALTY_BPS"));

        require(PAY != address(0) && POOL != address(0), "pay/pool=0");
        require(PROJECT != address(0) && ROYALTY != address(0), "project/royalty=0");

        vm.startBroadcast(pk);

        MiningManager manager = new MiningManager(PAY, POOL);
        MinerNFT miner = new MinerNFT(PAY, POOL, PROJECT, ROYALTY, ROYALTY_BPS);
        MeBTC mebtc = new MeBTC(address(manager));

        manager.init(address(mebtc), address(miner));
        miner.setManager(address(manager));

        vm.stopBroadcast();

        console2.log("PAY:     ", PAY);
        console2.log("POOL:    ", POOL);
        console2.log("PROJECT: ", PROJECT);
        console2.log("ROYALTY: ", ROYALTY);
        console2.log("Manager: ", address(manager));
        console2.log("MinerNFT:", address(miner));
        console2.log("MeBTC:   ", address(mebtc));
    }
}
