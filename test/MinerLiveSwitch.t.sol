// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {MiningManager} from "../src/core/MiningManager.sol";
import {MinerNFT} from "../src/nft/MinerNFT.sol";
import {MeBTC} from "../src/token/MeBTC.sol";
import {StakeVault} from "../src/core/StakeVault.sol";
import {MockPayToken, MockTwapOracle} from "./helpers/MeBTCTestBase.sol";

contract MinerLiveSwitchTest is Test {
    MockPayToken internal payToken;
    MockTwapOracle internal oracle;
    MiningManager internal manager;
    MinerNFT internal miner;
    MeBTC internal mebtc;
    StakeVault internal stakeVault;

    address internal demandVault = address(0xBEEF);
    address internal feeVaultMeBTC = address(0xFEE1);
    address internal project = address(0xCAFE);
    address internal royalty = address(0xD00D);
    address internal user = address(0xA11CE);

    function setUp() public {
        payToken = new MockPayToken("MockUSD", "mUSD", 6);
        oracle = new MockTwapOracle(false, 0);
        manager = new MiningManager(address(payToken));
        mebtc = new MeBTC(address(manager));
        stakeVault = new StakeVault(address(mebtc), address(manager));
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

        manager.init(
            address(mebtc),
            address(miner),
            address(stakeVault),
            demandVault,
            feeVaultMeBTC,
            address(oracle)
        );
        miner.setManager(address(manager));

        uint256[4] memory powerCosts = [uint256(50_000), 150_000, 400_000, 1_000_000];
        uint256[4] memory hashCosts = [uint256(100_000), 250_000, 600_000, 1_500_000];
        miner.addModel(1000, 20, 10_000, 1_000_000, 0, "ipfs://MODEL", powerCosts, hashCosts);

        payToken.mint(user, 1_000_000_000);
        vm.prank(user);
        payToken.approve(address(miner), type(uint256).max);
    }

    function test_LiveSwitchFinalizeUnblocksBuy() public {
        vm.prank(user);
        vm.expectRevert(bytes("not live"));
        miner.buyFromModel(1, 1);

        miner.finalizeModel(1);

        (,,,,, bool finalized,,,,) = miner.getModel(1);
        assertTrue(finalized);

        vm.prank(user);
        uint256 tokenId = miner.buyFromModel(1, 1);
        assertEq(miner.ownerOf(tokenId), user);
        assertGt(manager.currentEffHash(tokenId), 0);
    }
}
