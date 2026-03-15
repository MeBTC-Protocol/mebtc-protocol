// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MinerNFT} from "../src/nft/MinerNFT.sol";
import {MiningManager} from "../src/core/MiningManager.sol";
import {MeBTC} from "../src/token/MeBTC.sol";
import {StakeVault} from "../src/core/StakeVault.sol";
import {MockPayToken, MockTwapOracle} from "./helpers/MeBTCTestBase.sol";

contract LiquidityGateTest is Test {
    MockPayToken internal payToken;
    MockTwapOracle internal oracle;
    MiningManager internal manager;
    MinerNFT internal miner;
    MeBTC internal mebtc;
    StakeVault internal stakeVault;

    address internal demandVault = address(0xBEEF);
    address internal feeVaultMeBTC = address(0xFEE1);
    address internal project = address(0xCAFE);
    address internal royalty = address(0xD00D);
    address internal user = address(0xA11CE);
    address internal owner = address(this);

    uint256 internal constant THRESHOLD = 10_000_000_000; // 10,000 USDC (6 decimals)

    uint16 internal modelId;

    function setUp() public {
        payToken = new MockPayToken("MockUSD", "mUSD", 6);
        oracle = new MockTwapOracle(false, 0);
        manager = new MiningManager(address(payToken));
        mebtc = new MeBTC(address(manager));
        stakeVault = new StakeVault(address(mebtc), address(manager));

        miner = new MinerNFT(
            address(payToken),
            demandVault,
            feeVaultMeBTC,
            project,
            royalty,
            0,
            address(mebtc),
            address(oracle)
        );

        manager.init(address(mebtc), address(miner), address(stakeVault), demandVault, feeVaultMeBTC, address(oracle));
        miner.setManager(address(manager));

        uint256[4] memory powerCosts = [uint256(50_000), 150_000, 400_000, 1_000_000];
        uint256[4] memory hashCosts = [uint256(100_000), 250_000, 600_000, 1_500_000];
        modelId = miner.addModel(1000, 20, 10_000, 1_000_000, THRESHOLD, "ipfs://MODEL", powerCosts, hashCosts);
        miner.finalizeModel(modelId);

        payToken.mint(user, 1_000_000_000);
        vm.prank(user);
        payToken.approve(address(miner), type(uint256).max);
    }

    // --- buyFromModel gate ---

    function test_BuySucceeds_WhenOracleNotSet() public {
        // no setLiquidityOracle call → oracle is address(0) → gate skipped
        vm.prank(user);
        uint256 tokenId = miner.buyFromModel(modelId, 1);
        assertEq(miner.ownerOf(tokenId), user);
    }

    function test_BuySucceeds_WhenThresholdZero() public {
        uint256[4] memory pc = [uint256(50_000), 150_000, 400_000, 1_000_000];
        uint256[4] memory hc = [uint256(100_000), 250_000, 600_000, 1_500_000];
        uint16 freeModel = miner.addModel(500, 10, 5_000, 500_000, 0, "ipfs://FREE", pc, hc);
        miner.finalizeModel(freeModel);
        miner.setLiquidityOracle(address(oracle));
        // oracle returns 0 liquidity but threshold is 0 → always open
        oracle.setLiquidity(0);
        vm.prank(user);
        uint256 tokenId = miner.buyFromModel(freeModel, 1);
        assertEq(miner.ownerOf(tokenId), user);
    }

    function test_BuyReverts_WhenLiquidityBelowThreshold() public {
        miner.setLiquidityOracle(address(oracle));
        oracle.setLiquidity(THRESHOLD - 1);
        vm.prank(user);
        vm.expectRevert(bytes("liquidity gate"));
        miner.buyFromModel(modelId, 1);
    }

    function test_BuySucceeds_WhenLiquidityAtThreshold() public {
        miner.setLiquidityOracle(address(oracle));
        oracle.setLiquidity(THRESHOLD);
        vm.prank(user);
        uint256 tokenId = miner.buyFromModel(modelId, 1);
        assertEq(miner.ownerOf(tokenId), user);
    }

    function test_BuySucceeds_WhenLiquidityAboveThreshold() public {
        miner.setLiquidityOracle(address(oracle));
        oracle.setLiquidity(THRESHOLD * 5);
        vm.prank(user);
        uint256 tokenId = miner.buyFromModel(modelId, 1);
        assertEq(miner.ownerOf(tokenId), user);
    }

    // --- isModelLive ---

    function test_IsModelLive_FalseWhenLiquidityBelowThreshold() public {
        miner.setLiquidityOracle(address(oracle));
        oracle.setLiquidity(THRESHOLD - 1);
        assertFalse(miner.isModelLive(modelId));
    }

    function test_IsModelLive_TrueWhenLiquidityMeetsThreshold() public {
        miner.setLiquidityOracle(address(oracle));
        oracle.setLiquidity(THRESHOLD);
        assertTrue(miner.isModelLive(modelId));
    }

    function test_IsModelLive_FalseWhenNotFinalized() public {
        uint256[4] memory pc = [uint256(50_000), 150_000, 400_000, 1_000_000];
        uint256[4] memory hc = [uint256(100_000), 250_000, 600_000, 1_500_000];
        uint16 unfinalized = miner.addModel(500, 10, 5_000, 500_000, 0, "ipfs://NOPE", pc, hc);
        // not finalized
        assertFalse(miner.isModelLive(unfinalized));
    }

    function test_IsModelLive_FalseWhenInvalidModelId() public {
        // model 99 does not exist → maxSupply == 0 → returns false (no revert)
        assertFalse(miner.isModelLive(99));
    }

    function test_IsModelLive_TrueWhenOracleNotSet() public {
        // oracle not set → fallback skips check → any threshold passes
        assertTrue(miner.isModelLive(modelId));
    }

    // --- setLiquidityOracle ---

    function test_SetLiquidityOracle_OnlyOwner() public {
        vm.prank(user);
        vm.expectRevert();
        miner.setLiquidityOracle(address(oracle));
    }

    function test_SetLiquidityOracle_AllowsZeroAddress() public {
        miner.setLiquidityOracle(address(oracle));
        miner.setLiquidityOracle(address(0)); // deactivate
        assertEq(address(miner.liquidityOracle()), address(0));
        // gate should be skipped again → buy works without liquidity
        vm.prank(user);
        uint256 tokenId = miner.buyFromModel(modelId, 1);
        assertEq(miner.ownerOf(tokenId), user);
    }

    // --- Multi-model independence ---

    function test_MultipleModels_IndependentThresholds() public {
        uint256[4] memory pc = [uint256(50_000), 150_000, 400_000, 1_000_000];
        uint256[4] memory hc = [uint256(100_000), 250_000, 600_000, 1_500_000];
        uint16 freeModel = miner.addModel(500, 10, 5_000, 500_000, 0, "ipfs://FREE", pc, hc);
        miner.finalizeModel(freeModel);

        miner.setLiquidityOracle(address(oracle));
        oracle.setLiquidity(THRESHOLD - 1); // below threshold of modelId, but freeModel has 0

        // free model (threshold=0) → succeeds
        vm.prank(user);
        uint256 tokenId = miner.buyFromModel(freeModel, 1);
        assertEq(miner.ownerOf(tokenId), user);

        // gated model → reverts
        vm.prank(user);
        vm.expectRevert(bytes("liquidity gate"));
        miner.buyFromModel(modelId, 1);
    }

    // --- Quantity parity ---

    function test_GateAppliesEquallyToAllQuantities() public {
        miner.setLiquidityOracle(address(oracle));
        oracle.setLiquidity(THRESHOLD - 1);

        vm.prank(user);
        vm.expectRevert(bytes("liquidity gate"));
        miner.buyFromModel(modelId, 1);

        vm.prank(user);
        vm.expectRevert(bytes("liquidity gate"));
        miner.buyFromModel(modelId, 5);

        oracle.setLiquidity(THRESHOLD);

        vm.prank(user);
        miner.buyFromModel(modelId, 5);
    }
}
