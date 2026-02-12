// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MeBTCTestBase} from "./helpers/MeBTCTestBase.sol";

contract OracleTwapTest is MeBTCTestBase {
    function test_ClaimWithMebtcFallsBackWhenTwapNotReady() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        (, uint256 fee) = manager.preview(tokenId, user);
        assertGt(fee, 0);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256 demandBefore = payToken.balanceOf(demandVault);
        uint256 feeVaultBefore = mebtc.balanceOf(feeVaultMeBTC);

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        manager.claimWithMebtc(ids, 1000);
        vm.stopPrank();

        assertEq(payToken.balanceOf(demandVault) - demandBefore, fee);
        assertEq(mebtc.balanceOf(feeVaultMeBTC) - feeVaultBefore, 0);
    }

    function test_ClaimWithMebtcFallsBackWhenPriceZero() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        oracle.setReady(true);
        oracle.setPrice(0);

        (, uint256 fee) = manager.preview(tokenId, user);
        assertGt(fee, 0);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256 demandBefore = payToken.balanceOf(demandVault);
        uint256 feeVaultBefore = mebtc.balanceOf(feeVaultMeBTC);

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        manager.claimWithMebtc(ids, 1000);
        vm.stopPrank();

        assertEq(payToken.balanceOf(demandVault) - demandBefore, fee);
        assertEq(mebtc.balanceOf(feeVaultMeBTC) - feeVaultBefore, 0);
    }

    function test_UpgradeWithMebtcFallsBackWhenTwapNotReady() public {
        uint256 tokenId = _buyOne(user);

        uint256 demandBefore = payToken.balanceOf(demandVault);
        uint256 feeVaultBefore = mebtc.balanceOf(feeVaultMeBTC);

        vm.prank(user);
        miner.requestUpgradeHashWithMebtc(tokenId, 1000);

        assertGt(payToken.balanceOf(demandVault) - demandBefore, 0);
        assertEq(mebtc.balanceOf(feeVaultMeBTC) - feeVaultBefore, 0);
    }

    function test_UpgradeWithMebtcFallsBackWhenPriceZero() public {
        uint256 tokenId = _buyOne(user);

        oracle.setReady(true);
        oracle.setPrice(0);

        uint256 demandBefore = payToken.balanceOf(demandVault);
        uint256 feeVaultBefore = mebtc.balanceOf(feeVaultMeBTC);

        vm.prank(user);
        miner.requestUpgradeHashWithMebtc(tokenId, 1000);

        assertGt(payToken.balanceOf(demandVault) - demandBefore, 0);
        assertEq(mebtc.balanceOf(feeVaultMeBTC) - feeVaultBefore, 0);
    }
}
