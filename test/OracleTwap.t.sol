// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MeBTCTestBase} from "./helpers/MeBTCTestBase.sol";

contract OracleTwapTest is MeBTCTestBase {
    function test_ClaimWithMebtcRequiresTwapReady() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.prank(user);
        vm.expectRevert(bytes("twap"));
        manager.claimWithMebtc(ids, 1000);
    }

    function test_ClaimWithMebtcRequiresPrice() public {
        uint256 tokenId = _buyOne(user);
        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() * 2);

        oracle.setReady(true);
        oracle.setPrice(0);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.prank(user);
        vm.expectRevert(bytes("price"));
        manager.claimWithMebtc(ids, 1000);
    }

    function test_UpgradeWithMebtcRequiresTwapReady() public {
        uint256 tokenId = _buyOne(user);

        vm.prank(user);
        vm.expectRevert(bytes("twap"));
        miner.requestUpgradeHashWithMebtc(tokenId, 1000);
    }

    function test_UpgradeWithMebtcRequiresPrice() public {
        uint256 tokenId = _buyOne(user);

        oracle.setReady(true);
        oracle.setPrice(0);

        vm.prank(user);
        vm.expectRevert(bytes("price"));
        miner.requestUpgradeHashWithMebtc(tokenId, 1000);
    }
}
