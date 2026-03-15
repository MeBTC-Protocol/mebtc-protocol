// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

import {MeBTCTestBase} from "./helpers/MeBTCTestBase.sol";

contract ResyncMinerTest is MeBTCTestBase {
    using stdStorage for StdStorage;

    function _store(string memory sig, uint256 val) internal {
        uint256 slot = stdstore.target(address(manager)).sig(sig).find();
        vm.store(address(manager), bytes32(slot), bytes32(val));
    }

    function _storeKey(string memory sig, uint256 key, uint256 val) internal {
        uint256 slot = stdstore.target(address(manager)).sig(sig).with_key(key).find();
        vm.store(address(manager), bytes32(slot), bytes32(val));
    }

    function test_ResyncMinerFixesPositiveDrift() public {
        uint256 tokenId = _buyOne(user);
        uint256 expectedHash = manager.currentEffHash(tokenId);
        assertGt(expectedHash, 100);

        _storeKey("currentEffHash(uint256)", tokenId, expectedHash - 100);
        _store("totalEffectiveHash()", expectedHash - 100);

        manager.resyncMiner(tokenId);

        assertEq(manager.currentEffHash(tokenId), expectedHash);
        assertEq(manager.totalEffectiveHash(), expectedHash);
    }

    function test_ResyncMinerRevertsWhenTotalTooLow() public {
        uint256 tokenId = _buyOne(user);
        uint256 expectedHash = manager.currentEffHash(tokenId);

        _storeKey("currentEffHash(uint256)", tokenId, expectedHash + 1000);
        _store("totalEffectiveHash()", 500);

        vm.expectRevert(bytes("total"));
        manager.resyncMiner(tokenId);
    }
}
