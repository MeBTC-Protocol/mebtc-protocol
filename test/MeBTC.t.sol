// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MeBTCTestBase, MockPayToken} from "./helpers/MeBTCTestBase.sol";
import {MiningManager} from "../src/core/MiningManager.sol";
import {MinerNFT} from "../src/nft/MinerNFT.sol";

contract MeBTCTest is MeBTCTestBase {
    function test_PayTokenDecimalsEnforced() public {
        MockPayToken badToken = new MockPayToken("Bad", "BAD", 18);

        vm.expectRevert(bytes("decimals"));
        new MiningManager(address(badToken));

        vm.expectRevert(bytes("decimals"));
        new MinerNFT(
            address(badToken),
            demandVault,
            feeVaultMeBTC,
            project,
            royalty,
            0,
            address(mebtc),
            address(oracle)
        );

        vm.expectRevert(bytes("decimals"));
        manager.setPayToken(address(badToken));

        vm.expectRevert(bytes("decimals"));
        miner.setPayToken(address(badToken));
    }

    function test_FirstMintStartsEmissionClock() public {
        uint256 before = manager.lastUpdate();
        vm.warp(before + 1234);
        _buyOne(user);
        assertEq(manager.lastUpdate(), block.timestamp);
    }

    function test_PreviewOnlyFullIntervals() public {
        uint256 tokenId = _buyOne(user);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() - 1);
        (uint256 r0, uint256 f0) = manager.preview(tokenId, user);
        assertEq(r0, 0);
        assertEq(f0, 0);

        vm.warp(block.timestamp + 1);
        (uint256 r1, uint256 f1) = manager.preview(tokenId, user);
        assertGt(r1, 0);
        assertGt(f1, 0);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL());
        (uint256 r2, uint256 f2) = manager.preview(tokenId, user);
        assertGt(r2, 0);
        assertGt(f2, 0);
        assertGe(r2, r1);
        assertGe(f2, f1);
    }

    function test_ClaimOnlyAfterGlobalSlot() public {
        uint256 tokenId = _buyOne(user);

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.expectRevert(bytes("slot"));
        manager.claim(ids);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);
        manager.claim(ids);
        vm.stopPrank();

        assertGt(mebtc.balanceOf(user), 0);
        assertGt(payToken.balanceOf(demandVault), 0);
    }

    function test_NoRetroRewardsOnFirstMiner() public {
        uint256 interval = manager.CLAIM_INTERVAL();
        vm.warp(block.timestamp + interval * 5);

        uint256 tokenId = _buyOne(user);

        vm.warp(block.timestamp + interval);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        manager.claim(ids);
        vm.stopPrank();

        assertEq(manager.blockIndex(), 1);
        assertEq(mebtc.balanceOf(user), manager.INITIAL_REWARD());
    }
}
