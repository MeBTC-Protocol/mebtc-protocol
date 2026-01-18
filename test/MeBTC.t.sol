// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {MiningManager} from "../src/core/MiningManager.sol";
import {MinerNFT} from "../src/nft/MinerNFT.sol";
import {MeBTC} from "../src/token/MeBTC.sol";
import {StakeVault} from "../src/core/StakeVault.sol";

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

contract MockTwapOracle {
    bool internal ready;
    uint256 internal price;

    constructor(bool _ready, uint256 _price) {
        ready = _ready;
        price = _price;
    }

    function isReady() external view returns (bool) {
        return ready;
    }

    function priceMebtcInUsdc() external view returns (uint256) {
        return price;
    }
}

contract MeBTCTest is Test {
    MockPayToken internal payToken;
    MiningManager internal manager;
    MinerNFT internal miner;
    MeBTC internal mebtc;
    StakeVault internal stakeVault;
    MockTwapOracle internal oracle;

    address internal demandVault = address(0xBEEF);
    address internal feeVaultMeBTC = address(0xFEE1);
    address internal project = address(0xCAFE);
    address internal royalty = address(0xD00D);
    address internal user = address(0xA11CE);

    function setUp() public {
        payToken = new MockPayToken("MockUSD", "mUSD", 6);
        manager = new MiningManager(address(payToken));
        mebtc = new MeBTC(address(manager));
        oracle = new MockTwapOracle(false, 0);
        miner = new MinerNFT(address(payToken), demandVault, feeVaultMeBTC, project, royalty, 0, address(mebtc), address(oracle));
        stakeVault = new StakeVault(address(mebtc), address(manager));

        manager.init(address(mebtc), address(miner), address(stakeVault), demandVault, feeVaultMeBTC, address(oracle));
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
        new MiningManager(address(badToken));

        vm.expectRevert(bytes("decimals"));
        new MinerNFT(address(badToken), demandVault, feeVaultMeBTC, project, royalty, 0, address(mebtc), address(oracle));

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
        assertEq(r1, 0);
        assertEq(f1, 0);

        vm.warp(block.timestamp + manager.CLAIM_INTERVAL());
        (uint256 r2, uint256 f2) = manager.preview(tokenId, user);
        assertGt(r2, 0);
        assertGt(f2, 0);
    }

    function test_ClaimOnlyAfterGlobalSlot() public {
        uint256 tokenId = _buyOne();

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
}
