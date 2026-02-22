// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MeBTCTestBase} from "./helpers/MeBTCTestBase.sol";

contract MiningManagerClaimTest is MeBTCTestBase {
    function _claimOneReward(address claimant, uint256 tokenId) internal returns (uint256 reward) {
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256 before = mebtc.balanceOf(claimant);
        vm.startPrank(claimant);
        payToken.approve(address(manager), type(uint256).max);
        manager.claim(ids);
        vm.stopPrank();
        reward = mebtc.balanceOf(claimant) - before;
    }

    function test_ClaimRequiresSlot() public {
        uint256 tokenId = _buyOne(user);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);

        vm.expectRevert(bytes("slot"));
        manager.claim(ids);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);
        manager.claim(ids);
        vm.stopPrank();

        assertGt(mebtc.balanceOf(user), 0);
        assertGt(payToken.balanceOf(demandVault), 0);
    }

    function test_PreviewMatchesClaim_UsdcOnly() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        (uint256 r, uint256 f) = manager.preview(tokenId, user);

        uint256 demandBefore = payToken.balanceOf(demandVault);
        uint256 mebtcBefore = mebtc.balanceOf(user);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        manager.claim(ids);
        vm.stopPrank();

        assertEq(mebtc.balanceOf(user) - mebtcBefore, r);
        assertEq(payToken.balanceOf(demandVault) - demandBefore, f);
    }

    function test_ClaimWithMebtcFeeSplit() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        oracle.setReady(true);
        oracle.setPrice(1_000_000); // 1 USDC

        (uint256 r, uint256 f) = manager.preview(tokenId, user);
        uint16 shareBps = 3000; // 30%

        uint256 mebtcUsdc = (f * shareBps) / 10_000;
        uint256 usdcPart = f - mebtcUsdc;
        uint256 mebtcAmount = (mebtcUsdc * 1e8) / 1_000_000;

        vm.prank(address(manager));
        mebtc.mint(user, mebtcAmount + r);

        uint256 demandBefore = payToken.balanceOf(demandVault);
        uint256 feeVaultBefore = mebtc.balanceOf(feeVaultMeBTC);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        mebtc.approve(address(manager), type(uint256).max);
        manager.claimWithMebtc(ids, shareBps);
        vm.stopPrank();

        assertEq(payToken.balanceOf(demandVault) - demandBefore, usdcPart);
        assertEq(mebtc.balanceOf(feeVaultMeBTC) - feeVaultBefore, mebtcAmount);
    }

    function test_BuyFromModelSetsActiveImmediately() public {
        uint256 ts = block.timestamp;
        uint256 tokenId = _buyOne(user);

        uint256 effHash = manager.currentEffHash(tokenId);
        uint256 effPower = manager.currentEffPower(tokenId);

        assertGt(effHash, 0);
        assertGt(effPower, 0);
        assertEq(manager.lastSettleTime(tokenId), ts);
        assertEq(manager.lastClaimedBlockIndex(tokenId), manager.blockIndex());
        assertEq(manager.totalEffectiveHash(), effHash);
    }

    function test_RewardDistribution_MultipleMinersWithDifferentUpgrades() public {
        address user3 = address(0xC0FFEE);
        payToken.mint(user3, 1_000_000_000);

        uint256 tokenA = _buyOne(user);
        uint256 tokenB = _buyOne(user2);
        uint256 tokenC = _buyOne(user3);

        vm.prank(user2);
        miner.requestUpgradeHash(tokenB);

        vm.startPrank(user3);
        miner.requestUpgradeHash(tokenC);
        miner.requestUpgradeHash(tokenC);
        vm.stopPrank();

        // Pending upgrades are not active before the next claim.
        assertEq(manager.currentEffHash(tokenA), 1000);
        assertEq(manager.currentEffHash(tokenB), 1000);
        assertEq(manager.currentEffHash(tokenC), 1000);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL());

        // First claim settles old values and then activates pending upgrades.
        uint256 rewardA1 = _claimOneReward(user, tokenA);
        uint256 rewardB1 = _claimOneReward(user2, tokenB);
        uint256 rewardC1 = _claimOneReward(user3, tokenC);

        assertEq(rewardA1, rewardB1);
        assertEq(rewardB1, rewardC1);

        assertEq(manager.currentEffHash(tokenA), 1000);
        assertEq(manager.currentEffHash(tokenB), 1025);
        assertEq(manager.currentEffHash(tokenC), 1050);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL());

        (uint256 previewA2,) = manager.preview(tokenA, user);
        (uint256 previewB2,) = manager.preview(tokenB, user2);
        (uint256 previewC2,) = manager.preview(tokenC, user3);

        assertGt(previewB2, previewA2);
        assertGt(previewC2, previewB2);

        uint256 rewardA2 = _claimOneReward(user, tokenA);
        uint256 rewardB2 = _claimOneReward(user2, tokenB);
        uint256 rewardC2 = _claimOneReward(user3, tokenC);

        assertEq(rewardA2, previewA2);
        assertEq(rewardB2, previewB2);
        assertEq(rewardC2, previewC2);

        uint256 normA = (rewardA2 * 1e9) / manager.currentEffHash(tokenA);
        uint256 normB = (rewardB2 * 1e9) / manager.currentEffHash(tokenB);
        uint256 normC = (rewardC2 * 1e9) / manager.currentEffHash(tokenC);

        // Allow tiny integer-rounding drift, but require proportional payout per hash.
        assertApproxEqAbs(normA, normB, 2_000_000);
        assertApproxEqAbs(normB, normC, 2_000_000);
    }
}
