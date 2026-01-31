// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {MeBTC} from "../src/token/MeBTC.sol";

contract MeBTCMintTest is Test {
    address internal user = address(0xA11CE);

    function test_OnlyManagerCanMint() public {
        MeBTC token = new MeBTC(address(this));

        vm.prank(address(0xBEEF));
        vm.expectRevert(MeBTC.OnlyMM.selector);
        token.mint(user, 1);
    }

    function test_MaxSupplyCap() public {
        MeBTC token = new MeBTC(address(this));

        token.mint(user, token.MAX_SUPPLY());

        vm.expectRevert(MeBTC.MaxCap.selector);
        token.mint(user, 1);
    }
}
