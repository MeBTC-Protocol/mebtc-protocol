// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MeBTCTestBase} from "./helpers/MeBTCTestBase.sol";

contract PerformanceLoadTest is MeBTCTestBase {
    function _claimBatch(address claimant, uint256 firstTokenId, uint256 count) internal {
        uint256[] memory ids = new uint256[](count);
        for (uint256 i; i < count; i++) {
            ids[i] = firstTokenId + i;
        }

        vm.startPrank(claimant);
        payToken.approve(address(manager), type(uint256).max);
        manager.claim(ids);
        vm.stopPrank();
    }

    function test_BatchClaimScaling() public {
        uint256 interval = manager.CLAIM_INTERVAL();

        uint256 first1 = _buyMany(user, 1);
        uint256 first5 = _buyMany(user, 5);
        uint256 first20 = _buyMany(user, 20);
        uint256 first50 = _buyMany(user, 50);

        vm.warp(block.timestamp + interval * 2);

        _claimBatch(user, first1, 1);
        _claimBatch(user, first5, 5);
        _claimBatch(user, first20, 20);
        _claimBatch(user, first50, 50);
    }

    function test_LoadSimulation_Scaled() public {
        uint256 interval = manager.CLAIM_INTERVAL();
        uint256 count = 200;

        uint256 first = _buyMany(user, count);
        vm.warp(block.timestamp + interval * 2);

        _claimBatch(user, first, count);
    }
}
