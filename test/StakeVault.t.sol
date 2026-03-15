// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MeBTCTestBase} from "./helpers/MeBTCTestBase.sol";

contract StakeVaultTest is MeBTCTestBase {
    function _mintMebtc(address to, uint256 amount) internal {
        vm.prank(address(manager));
        mebtc.mint(to, amount);
    }

    function test_StakeSetsTierAndUnlockTime() public {
        uint256 amount = 10_000e8;
        _mintMebtc(user, amount);

        vm.startPrank(user);
        mebtc.approve(address(stakeVault), type(uint256).max);
        stakeVault.stake(amount);
        vm.stopPrank();

        (uint256 balance, uint8 tier, uint64 unlockAt, uint16 hashBonusBps, uint16 powerBonusBps) =
            stakeVault.getStakeInfo(user);

        assertEq(balance, amount);
        assertEq(tier, 1);
        assertEq(hashBonusBps, stakeVault.TIER1_HASH_BPS());
        assertEq(powerBonusBps, stakeVault.TIER1_POWER_BPS());
        assertEq(unlockAt, uint64(block.timestamp + stakeVault.TIER1_LOCK()));
    }

    function test_UnlockExtendsOnlyOnTierIncrease() public {
        _mintMebtc(user, 60_000e8);

        vm.startPrank(user);
        mebtc.approve(address(stakeVault), type(uint256).max);
        stakeVault.stake(10_000e8);
        uint64 unlockTier1 = stakeVault.unlockTime(user);

        vm.warp(block.timestamp + 1 days);
        stakeVault.stake(5_000e8);
        uint64 unlockStillTier1 = stakeVault.unlockTime(user);
        assertEq(unlockStillTier1, unlockTier1);

        vm.warp(block.timestamp + 1 days);
        stakeVault.stake(40_000e8);
        uint64 unlockTier2 = stakeVault.unlockTime(user);
        vm.stopPrank();

        assertGt(unlockTier2, unlockTier1);
        assertEq(unlockTier2, uint64(block.timestamp + stakeVault.TIER2_LOCK()));
    }

    function test_UnstakeBeforeUnlockReverts() public {
        _mintMebtc(user, 10_000e8);

        vm.startPrank(user);
        mebtc.approve(address(stakeVault), type(uint256).max);
        stakeVault.stake(10_000e8);

        vm.expectRevert(bytes("locked"));
        stakeVault.unstake(1e8);
        vm.stopPrank();
    }

    function test_UnstakeAfterUnlockReducesBalanceAndTier() public {
        _mintMebtc(user, 10_000e8);

        vm.startPrank(user);
        mebtc.approve(address(stakeVault), type(uint256).max);
        stakeVault.stake(10_000e8);
        uint64 unlockAt = stakeVault.unlockTime(user);

        vm.warp(unlockAt);
        stakeVault.unstake(5_000e8);
        vm.stopPrank();

        (uint256 balance, uint8 tier,, uint16 hashBonusBps, uint16 powerBonusBps) =
            stakeVault.getStakeInfo(user);
        assertEq(balance, 5_000e8);
        assertEq(tier, 0);
        assertEq(hashBonusBps, 0);
        assertEq(powerBonusBps, 0);
    }
}
