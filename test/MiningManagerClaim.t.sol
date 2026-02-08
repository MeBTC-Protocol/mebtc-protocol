// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MeBTCTestBase} from "./helpers/MeBTCTestBase.sol";

contract MiningManagerClaimTest is MeBTCTestBase {
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
}
