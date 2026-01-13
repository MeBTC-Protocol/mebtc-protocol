// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {MiningManager} from "../src/core/MiningManager.sol";
import {MinerNFT} from "../src/nft/MinerNFT.sol";
import {MeBTC} from "../src/token/MeBTC.sol";

contract MockPayToken is ERC20 {
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 dec_) ERC20(name_, symbol_) {
        _decimals = dec_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MeBTCTest is Test {
    MockPayToken internal payToken;
    MiningManager internal manager;
    MinerNFT internal miner;
    MeBTC internal mebtc;

    address internal pool = address(0xBEEF);
    address internal project = address(0xCAFE);
    address internal royalty = address(0xD00D);
    address internal user = address(0xA11CE);

    function setUp() public {
        payToken = new MockPayToken("MockUSD", "mUSD", 6);
        manager = new MiningManager(address(payToken), pool);
        miner = new MinerNFT(address(payToken), pool, project, royalty, 0);
        mebtc = new MeBTC(address(manager));

        manager.init(address(mebtc), address(miner));
        miner.setManager(address(manager));

        uint256[4] memory powerCosts = [uint256(50_000), 150_000, 400_000, 1_000_000];
        uint256[4] memory hashCosts = [uint256(100_000), 250_000, 600_000, 1_500_000];
        miner.addModel(1000, 20, 10_000, 1_000_000, "ipfs://MODEL", powerCosts, hashCosts);
        miner.finalizeModel(1);

        payToken.mint(user, 1_000_000_000);
    }

    function _buyOne() internal returns (uint256 tokenId) {
        vm.startPrank(user);
        payToken.approve(address(miner), type(uint256).max);
        tokenId = miner.buyFromModel(1, 1);
        vm.stopPrank();
    }

    function test_PayTokenDecimalsEnforced() public {
        MockPayToken badToken = new MockPayToken("Bad", "BAD", 18);

        vm.expectRevert(bytes("decimals"));
        new MiningManager(address(badToken), pool);

        vm.expectRevert(bytes("decimals"));
        new MinerNFT(address(badToken), pool, project, royalty, 0);

        vm.expectRevert(bytes("decimals"));
        manager.setPayToken(address(badToken));

        vm.expectRevert(bytes("decimals"));
        miner.setPayToken(address(badToken));
    }

    function test_FirstMintStartsEmissionClock() public {
        uint256 before = manager.lastUpdate();
        vm.warp(before + 1234);
        _buyOne();
        assertEq(manager.lastUpdate(), block.timestamp);
    }

    function test_PreviewOnlyFullIntervals() public {
        uint256 tokenId = _buyOne();

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL() - 1);
        (uint256 r0, uint256 f0) = manager.preview(tokenId, user);
        assertEq(r0, 0);
        assertEq(f0, 0);

        vm.warp(block.timestamp + 1);
        (uint256 r1, uint256 f1) = manager.preview(tokenId, user);
        assertGt(r1, 0);
        assertGt(f1, 0);
    }

    function test_ClaimOnlyAfterGlobalSlot() public {
        uint256 tokenId = _buyOne();

        vm.startPrank(user);
        payToken.approve(address(manager), type(uint256).max);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.expectRevert(bytes("slot"));
        manager.claim(ids);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL());
        manager.claim(ids);
        vm.stopPrank();

        assertGt(mebtc.balanceOf(user), 0);
        assertGt(payToken.balanceOf(pool), 0);
    }
}
