// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {MinerNFT} from "../src/nft/MinerNFT.sol";

/*
Env:
  PRIVATE_KEY
  MINER_ADDRESS
  USDC_ADDRESS
  MODEL_ID
  QTY (optional, default 1)

Optional (onlyOwner):
  ADD_MODEL=true/false

  MODEL_BASE_HASH
  MODEL_BASE_POWER
  MODEL_MAX_SUPPLY
  MODEL_PRICE_USDC
  MODEL_URI

  POWER_COST_0..3
  HASH_COST_0..3
*/

contract MintMinerFuji is Script {
    function _envBool(string memory key, bool fallbackValue) internal view returns (bool) {
        try vm.envString(key) returns (string memory v) {
            bytes32 h = keccak256(bytes(v));
            if (h == keccak256(bytes("true")) || h == keccak256(bytes("1"))) return true;
            if (h == keccak256(bytes("false")) || h == keccak256(bytes("0"))) return false;
            return fallbackValue;
        } catch {
            return fallbackValue;
        }
    }

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);

        address minerAddr = vm.envAddress("MINER_ADDRESS");
        address usdcAddr = vm.envAddress("USDC_ADDRESS");

        MinerNFT miner = MinerNFT(minerAddr);
        IERC20 usdc = IERC20(usdcAddr);

        uint16 modelId = uint16(vm.envUint("MODEL_ID"));

        uint256 qty;
        try vm.envUint("QTY") returns (uint256 q) {
            qty = q;
        } catch {
            qty = 1;
        }

        bool addModel = _envBool("ADD_MODEL", false);

        vm.startBroadcast(pk);

        // Optional: Owner kann per Env neue Modelle hinzufügen + sofort finalisieren
        if (addModel) {
            uint32 baseHash = uint32(vm.envUint("MODEL_BASE_HASH"));
            uint32 basePower = uint32(vm.envUint("MODEL_BASE_POWER"));
            uint32 maxSupplyNew = uint32(vm.envUint("MODEL_MAX_SUPPLY")); // umbenannt (kein shadow)
            uint256 price = vm.envUint("MODEL_PRICE_USDC");
            string memory uri = vm.envString("MODEL_URI");

            uint256[4] memory p;
            uint256[4] memory h;

            p[0] = vm.envUint("POWER_COST_0");
            p[1] = vm.envUint("POWER_COST_1");
            p[2] = vm.envUint("POWER_COST_2");
            p[3] = vm.envUint("POWER_COST_3");

            h[0] = vm.envUint("HASH_COST_0");
            h[1] = vm.envUint("HASH_COST_1");
            h[2] = vm.envUint("HASH_COST_2");
            h[3] = vm.envUint("HASH_COST_3");

            uint256 minLiq = 0; // new models via script default to no liquidity gate; set via setLiquidityOracle if needed
            uint16 newId =
                miner.addModel(baseHash, basePower, maxSupplyNew, price, minLiq, uri, p, h);
            miner.finalizeModel(newId);

            console2.log("Added+finalized modelId:", uint256(newId));
        }

        // getModel gibt 10 Werte zurück -> Destructuring muss genau 10 sein
        (
            uint32 baseHashrate,
            uint32 basePowerWatt,
            uint32 maxSupply,
            uint32 minted,
            uint256 priceUSDC,
            bool finalized,
            ,
            uint256[4] memory powerStepCost,
            uint256[4] memory hashStepCost,
            string memory modelUri
        ) = miner.getModel(modelId);

        require(finalized, "model not live");
        require(uint256(minted) + qty <= uint256(maxSupply), "sold out");

        uint256 total = priceUSDC * qty;

        // approve + buy
        usdc.approve(minerAddr, total);
        uint256 firstId = miner.buyFromModel(modelId, qty);

        vm.stopBroadcast();

        console2.log("Buyer:", user);
        console2.log("MinerNFT:", minerAddr);
        console2.log("ModelId:", uint256(modelId));
        console2.log("Qty:", qty);

        console2.log("BaseHashrate:", uint256(baseHashrate));
        console2.log("BasePowerWatt:", uint256(basePowerWatt));
        console2.log("MaxSupply:", uint256(maxSupply));
        console2.log("MintedBefore:", uint256(minted));

        console2.log("PriceUSDC:", priceUSDC);
        console2.log("TotalUSDC:", total);

        // Arrays einzeln loggen (console2.log unterstützt nicht beliebig viele args)
        console2.log("PowerCost0:", powerStepCost[0]);
        console2.log("PowerCost1:", powerStepCost[1]);
        console2.log("PowerCost2:", powerStepCost[2]);
        console2.log("PowerCost3:", powerStepCost[3]);

        console2.log("HashCost0:", hashStepCost[0]);
        console2.log("HashCost1:", hashStepCost[1]);
        console2.log("HashCost2:", hashStepCost[2]);
        console2.log("HashCost3:", hashStepCost[3]);

        console2.log("URI:", modelUri);
        console2.log("First tokenId:", firstId);
    }
}
