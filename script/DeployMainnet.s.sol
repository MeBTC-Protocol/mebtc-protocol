// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MiningManager} from "../src/core/MiningManager.sol";
import {MeBTC} from "../src/token/MeBTC.sol";
import {MinerNFT} from "../src/nft/MinerNFT.sol";
import {StakeVault} from "../src/core/StakeVault.sol";
import {TokenVault} from "../src/core/TokenVault.sol";
import {LiquidityEngine} from "../src/core/LiquidityEngine.sol";
import {TwapOracleJoeV2} from "../src/core/TwapOracleJoeV2.sol";

interface IJoeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

/*
    Env Vars:
      PRIVATE_KEY
      PAY_TOKEN_ADDRESS
      DEMAND_VAULT        // optional: USDC Vault (sonst neu deployen)
      FEE_VAULT_MEBTC     // optional: MeBTC Vault (sonst neu deployen)
      TWAP_ORACLE         // optional: Canonical TWAP-Oracle Adresse (sonst neu deployen)
      JOE_FACTORY         // Trader Joe V2 Factory
      MIN_USDC_LP         // Mindest USDC für Pool-Creation (z.B. 10000000 = 10k USDC)
      EPOCH_SECONDS       // Epoch-Takt (z.B. 3600)
      LP_BURN_BPS         // Auto-Compound Burn-BPS (z.B. 200 = 2%)
      TWAP_WINDOW_SECONDS // TWAP Fenster (z.B. 3600)
      PROJECT_WALLET      // 10% vom Primärverkauf
      ROYALTY_WALLET      // 100% der Royalties (Receiver)
      ROYALTY_BPS         // z.B. 250 = 2.5%
*/

contract DeployMainnet is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address PAY = vm.envAddress("PAY_TOKEN_ADDRESS");
        address DEMAND;
        address FEE_MEBTC;
        address FACTORY = vm.envAddress("JOE_FACTORY");
        uint256 MIN_USDC = vm.envUint("MIN_USDC_LP");
        uint256 EPOCH = vm.envUint("EPOCH_SECONDS");
        uint16 BURN_BPS = uint16(vm.envUint("LP_BURN_BPS"));
        uint32 TWAP_WINDOW = uint32(vm.envUint("TWAP_WINDOW_SECONDS"));
        address PROJECT = vm.envAddress("PROJECT_WALLET");
        address ROYALTY = vm.envAddress("ROYALTY_WALLET");
        uint96 ROYALTY_BPS = uint96(vm.envUint("ROYALTY_BPS"));

        require(PAY != address(0), "pay=0");
        require(FACTORY != address(0), "factory=0");
        require(MIN_USDC > 0 && EPOCH > 0 && TWAP_WINDOW > 0, "lp params");
        require(PROJECT != address(0) && ROYALTY != address(0), "project/royalty=0");

        vm.startBroadcast(pk);

        MiningManager manager = new MiningManager(PAY);
        MeBTC mebtc = new MeBTC(address(manager));
        StakeVault stakeVault = new StakeVault(address(mebtc), address(manager));

        try vm.envAddress("DEMAND_VAULT") returns (address v) {
            DEMAND = v;
        } catch {
            DEMAND = address(new TokenVault(PAY));
        }

        try vm.envAddress("FEE_VAULT_MEBTC") returns (address v) {
            FEE_MEBTC = v;
        } catch {
            FEE_MEBTC = address(new TokenVault(address(mebtc)));
        }

        address pair = IJoeFactory(FACTORY).getPair(PAY, address(mebtc));
        if (pair == address(0)) {
            pair = IJoeFactory(FACTORY).createPair(PAY, address(mebtc));
        }

        address TWAP;
        try vm.envAddress("TWAP_ORACLE") returns (address v) {
            TWAP = v;
        } catch {
            TWAP = address(new TwapOracleJoeV2(address(mebtc), PAY, pair, MIN_USDC, TWAP_WINDOW));
        }

        LiquidityEngine engine = new LiquidityEngine(
            PAY, address(mebtc), FACTORY, DEMAND, FEE_MEBTC, MIN_USDC, EPOCH, BURN_BPS
        );

        TokenVault(DEMAND).init(address(engine));
        TokenVault(FEE_MEBTC).init(address(engine));

        MinerNFT miner = new MinerNFT(
            PAY, DEMAND, FEE_MEBTC, PROJECT, ROYALTY, ROYALTY_BPS, address(mebtc), TWAP
        );

        manager.init(address(mebtc), address(miner), address(stakeVault), DEMAND, FEE_MEBTC, TWAP);
        miner.setManager(address(manager));

        vm.stopBroadcast();

        console2.log("PAY:     ", PAY);
        console2.log("DEMAND:  ", DEMAND);
        console2.log("FEE MBTC:", FEE_MEBTC);
        console2.log("TWAP:    ", TWAP);
        console2.log("Pair:    ", pair);
        console2.log("PROJECT: ", PROJECT);
        console2.log("ROYALTY: ", ROYALTY);
        console2.log("Manager: ", address(manager));
        console2.log("MinerNFT:", address(miner));
        console2.log("MeBTC:   ", address(mebtc));
        console2.log("Stake:   ", address(stakeVault));
        console2.log("Engine:  ", address(engine));
    }
}
