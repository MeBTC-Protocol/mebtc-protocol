// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {MinerNFT} from "../src/nft/MinerNFT.sol";
import {MeBTC} from "../src/token/MeBTC.sol";
import {MeBTCTestBase, MockPayToken, MockTwapOracle} from "./helpers/MeBTCTestBase.sol";

contract MinerNFTManagerTest is MeBTCTestBase {
    function test_SetManagerZeroReverts() public {
        vm.expectRevert(bytes("manager=0"));
        miner.setManager(address(0));
    }
}

contract MinerNFTBuyRequiresManagerTest is Test {
    MockPayToken internal payToken;
    MockTwapOracle internal oracle;
    MinerNFT internal miner;

    address internal demandVault = address(0xBEEF);
    address internal feeVaultMeBTC = address(0xFEE1);
    address internal project = address(0xCAFE);
    address internal royalty = address(0xD00D);

    function setUp() public {
        payToken = new MockPayToken("MockUSD", "mUSD", 6);
        oracle = new MockTwapOracle(false, 0);
        MeBTC mebtc = new MeBTC(address(0x1234));

        miner = new MinerNFT(
            address(payToken),
            demandVault,
            feeVaultMeBTC,
            project,
            royalty,
            0,
            address(mebtc),
            address(oracle)
        );
    }

    function test_BuyRequiresManagerSet() public {
        vm.expectRevert(bytes("manager=0"));
        miner.buyFromModel(1, 1);
    }
}
