// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MeBTCTestBase, MockPayToken} from "./helpers/MeBTCTestBase.sol";

contract SecurityScenariosTest is MeBTCTestBase {
    function test_ClaimRevertsWhenAllowanceTooLow() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        (, uint256 fee) = manager.preview(tokenId, user);
        assertGt(fee, 0);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.startPrank(user);
        payToken.approve(address(manager), fee - 1);
        vm.expectRevert(bytes("allowance"));
        manager.claim(ids);
        vm.stopPrank();
    }

    function test_ClaimRevertsWhenBalanceTooLow() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        payToken.transfer(user2, payToken.balanceOf(user));
        vm.expectRevert(bytes("balance"));
        manager.claim(ids);
        vm.stopPrank();
    }

    function test_OldOwnerCannotClaimAfterTransfer() public {
        uint256 tokenId = _buyOne(user);

        vm.prank(user);
        miner.transferFrom(user, user2, tokenId);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        vm.expectRevert(bytes("!owner"));
        manager.claim(ids);
        vm.stopPrank();

        vm.startPrank(user2);
        payToken.approve(address(manager), type(uint256).max);
        manager.claim(ids);
        vm.stopPrank();
    }

    function test_OnlyOwnerCanSetPayToken() public {
        MockPayToken alt = new MockPayToken("Alt", "ALT", 6);

        vm.prank(user);
        vm.expectRevert();
        manager.setPayToken(address(alt));

        vm.prank(user);
        vm.expectRevert();
        miner.setPayToken(address(alt));
    }

    function test_OnMinerTransferOnlyMiner() public {
        vm.expectRevert(bytes("!miner"));
        manager.onMinerTransfer(user, user2, 1, 0);
    }

    function test_OnStakeChangeOnlyStakeVault() public {
        vm.expectRevert(bytes("!stake"));
        manager.onStakeChange(user);
    }

    function test_ClaimWithMebtcFallsBackWhenMebtcInsufficient() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        oracle.setReady(true);
        oracle.setPrice(1_000_000);

        (, uint256 fee) = manager.preview(tokenId, user);
        assertGt(fee, 0);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256 demandBefore = payToken.balanceOf(demandVault);
        uint256 feeVaultBefore = mebtc.balanceOf(feeVaultMeBTC);

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        manager.claimWithMebtc(ids, 2000);
        vm.stopPrank();

        assertEq(payToken.balanceOf(demandVault) - demandBefore, fee);
        assertEq(mebtc.balanceOf(feeVaultMeBTC) - feeVaultBefore, 0);
    }

    function test_ClaimWithMebtcRevertsWhenShareAboveMax() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);
        uint16 shareAboveMax = manager.MAX_MEBTC_SHARE_BPS() + 1;

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        vm.expectRevert(bytes("mebtc%"));
        manager.claimWithMebtc(ids, shareAboveMax);
        vm.stopPrank();
    }

    function test_UpgradeWithMebtcRevertsWhenShareAboveMax() public {
        uint256 tokenId = _buyOne(user);
        uint16 shareAboveMax = miner.MAX_MEBTC_SHARE_BPS() + 1;

        vm.prank(user);
        vm.expectRevert(bytes("mebtc%"));
        miner.requestUpgradeHashWithMebtc(tokenId, shareAboveMax);
    }
}
