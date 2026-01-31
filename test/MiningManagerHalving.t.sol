// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

import {MeBTCTestBase} from "./helpers/MeBTCTestBase.sol";

contract MiningManagerHalvingTest is MeBTCTestBase {
    using stdStorage for StdStorage;

    function _store(string memory sig, uint256 val) internal {
        uint256 slot = stdstore.target(address(manager)).sig(sig).find();
        vm.store(address(manager), bytes32(slot), bytes32(val));
    }

    function _storeKey(string memory sig, uint256 key, uint256 val) internal {
        uint256 slot = stdstore.target(address(manager)).sig(sig).with_key(key).find();
        vm.store(address(manager), bytes32(slot), bytes32(val));
    }

    function test_HalvingAtBoundary() public {
        uint256 tokenId = _buyOne(user);

        uint256 halvingBlocks = manager.HALVING_BLOCKS();
        uint256 interval = manager.CLAIM_INTERVAL();
        vm.warp(block.timestamp + interval * 5);

        _store("blockIndex()", uint256(halvingBlocks - 1));
        _store("lastUpdate()", uint256(block.timestamp - interval));
        _store("currentReward()", uint256(manager.INITIAL_REWARD()));
        _store("totalEffectiveHash()", 1);

        _storeKey("currentEffHash(uint256)", tokenId, 1);
        _storeKey("currentEffPower(uint256)", tokenId, 1);
        _storeKey("lastSettleTime(uint256)", tokenId, uint256(block.timestamp));
        _storeKey("lastClaimedBlockIndex(uint256)", tokenId, uint256(halvingBlocks - 2));

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.prank(user);
        manager.claim(ids);

        assertEq(manager.blockIndex(), halvingBlocks);
        assertEq(manager.currentReward(), manager.INITIAL_REWARD() / 2);
    }

    function test_NoEmissionWhenTotalHashZero() public {
        uint256 interval = manager.CLAIM_INTERVAL();
        vm.warp(block.timestamp + interval * 5);

        _store("blockIndex()", 7);
        _store("lastUpdate()", uint256(block.timestamp - interval * 3));
        _store("totalEffectiveHash()", 0);

        vm.prank(address(stakeVault));
        manager.onStakeChange(user);

        assertEq(manager.blockIndex(), 7);
    }
}
