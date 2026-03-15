// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";

import {MockPayToken, MockTwapOracle} from "./helpers/MeBTCTestBase.sol";
import {MiningManager} from "../src/core/MiningManager.sol";
import {MinerNFT} from "../src/nft/MinerNFT.sol";
import {MeBTC} from "../src/token/MeBTC.sol";
import {StakeVault} from "../src/core/StakeVault.sol";

contract InvariantHandler is Test {
    uint256 internal constant MAX_TRACKED_TOKENS = 120;

    MiningManager internal manager;
    MinerNFT internal miner;
    MockPayToken internal payToken;
    MeBTC internal mebtc;
    StakeVault internal stakeVault;
    MockTwapOracle internal oracle;

    address[] internal actors;

    uint256[] internal tokenIds;
    mapping(uint256 => address) internal trackedOwner;
    mapping(address => uint256[]) internal ownedTokens;
    mapping(uint256 => uint256) internal ownedIndex;

    constructor(
        MiningManager _manager,
        MinerNFT _miner,
        MockPayToken _payToken,
        MeBTC _mebtc,
        StakeVault _stakeVault,
        MockTwapOracle _oracle,
        address[] memory _actors
    ) {
        manager = _manager;
        miner = _miner;
        payToken = _payToken;
        mebtc = _mebtc;
        stakeVault = _stakeVault;
        oracle = _oracle;
        actors = _actors;

        for (uint256 i; i < actors.length; i++) {
            address actor = actors[i];
            vm.startPrank(actor);
            payToken.approve(address(miner), type(uint256).max);
            payToken.approve(address(manager), type(uint256).max);
            mebtc.approve(address(manager), type(uint256).max);
            mebtc.approve(address(stakeVault), type(uint256).max);
            vm.stopPrank();

            vm.prank(address(manager));
            mebtc.mint(actor, 200_000e8);
        }

        oracle.setReady(true);
        oracle.setPrice(1_000_000);
    }

    function tokenIdsLength() external view returns (uint256) {
        return tokenIds.length;
    }

    function tokenIdAt(uint256 idx) external view returns (uint256) {
        return tokenIds[idx];
    }

    function trackedOwnerOf(uint256 tokenId) external view returns (address) {
        return trackedOwner[tokenId];
    }

    function buy(uint256 actorSeed, uint256 qtySeed) external {
        if (tokenIds.length >= MAX_TRACKED_TOKENS) return;

        address actor = actors[actorSeed % actors.length];
        uint256 qty = bound(qtySeed, 1, 3);
        uint256 remaining = MAX_TRACKED_TOKENS - tokenIds.length;
        if (qty > remaining) qty = remaining;

        vm.startPrank(actor);
        uint256 firstId;
        try miner.buyFromModel(1, qty) returns (uint256 id) {
            firstId = id;
        } catch {
            vm.stopPrank();
            return;
        }
        vm.stopPrank();

        for (uint256 i; i < qty; i++) {
            uint256 tokenId = firstId + i;
            tokenIds.push(tokenId);
            trackedOwner[tokenId] = actor;
            ownedIndex[tokenId] = ownedTokens[actor].length;
            ownedTokens[actor].push(tokenId);
        }
    }

    function transfer(uint256 tokenSeed, uint256 toSeed) external {
        if (tokenIds.length == 0) return;
        uint256 tokenId = tokenIds[tokenSeed % tokenIds.length];
        address from = trackedOwner[tokenId];
        address to = actors[toSeed % actors.length];
        if (from == address(0) || to == from) return;

        vm.prank(from);
        miner.transferFrom(from, to, tokenId);

        _removeToken(from, tokenId);
        trackedOwner[tokenId] = to;
        ownedIndex[tokenId] = ownedTokens[to].length;
        ownedTokens[to].push(tokenId);
    }

    function claim(uint256 tokenSeed) external {
        if (tokenIds.length == 0) return;
        if (block.timestamp < manager.lastUpdate() + manager.CLAIM_INTERVAL()) return;

        uint256 tokenId = tokenIds[tokenSeed % tokenIds.length];
        address owner = trackedOwner[tokenId];
        if (owner == address(0)) return;

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.prank(owner);
        try manager.claim(ids) {} catch {}
    }

    function claimWithMebtc(uint256 tokenSeed, uint256 shareSeed) external {
        if (tokenIds.length == 0) return;
        if (block.timestamp < manager.lastUpdate() + manager.CLAIM_INTERVAL()) return;

        uint256 tokenId = tokenIds[tokenSeed % tokenIds.length];
        address owner = trackedOwner[tokenId];
        if (owner == address(0)) return;

        uint16 share = uint16(bound(shareSeed, 0, manager.MAX_MEBTC_SHARE_BPS()));

        if (share > 0) {
            (uint256 r, uint256 f) = manager.preview(tokenId, owner);
            r;
            uint256 mebtcUsdc = (f * share) / 10_000;
            uint256 mebtcAmount = (mebtcUsdc * 1e8) / oracle.priceMebtcInUsdc();
            if (mebtc.balanceOf(owner) < mebtcAmount) return;
        }
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        vm.prank(owner);
        try manager.claimWithMebtc(ids, share) {} catch {}
    }

    function requestUpgradeHash(uint256 tokenSeed) external {
        if (tokenIds.length == 0) return;
        uint256 tokenId = tokenIds[tokenSeed % tokenIds.length];
        address owner = trackedOwner[tokenId];
        if (owner == address(0)) return;

        vm.prank(owner);
        try miner.requestUpgradeHash(tokenId) {} catch {}
    }

    function requestUpgradePower(uint256 tokenSeed) external {
        if (tokenIds.length == 0) return;
        uint256 tokenId = tokenIds[tokenSeed % tokenIds.length];
        address owner = trackedOwner[tokenId];
        if (owner == address(0)) return;

        vm.prank(owner);
        try miner.requestUpgradePower(tokenId) {} catch {}
    }

    function stake(uint256 actorSeed, uint256 amountSeed) external {
        address actor = actors[actorSeed % actors.length];
        uint256 bal = mebtc.balanceOf(actor);
        if (bal == 0) return;

        uint256 amount = bound(amountSeed, 1e8, bal);
        vm.prank(actor);
        stakeVault.stake(amount);
    }

    function unstake(uint256 actorSeed, uint256 amountSeed) external {
        address actor = actors[actorSeed % actors.length];
        if (block.timestamp < stakeVault.unlockTime(actor)) return;
        uint256 bal = stakeVault.stakedBalance(actor);
        if (bal == 0) return;

        uint256 amount = bound(amountSeed, 1e8, bal);
        vm.prank(actor);
        stakeVault.unstake(amount);
    }

    function resync(uint256 tokenSeed) external {
        if (tokenIds.length == 0) return;
        uint256 tokenId = tokenIds[tokenSeed % tokenIds.length];
        manager.resyncMiner(tokenId);
    }

    function warp(uint256 secondsSeed) external {
        uint256 secondsForward = bound(secondsSeed, 1, 200 days);
        vm.warp(block.timestamp + secondsForward);
    }

    function _removeToken(address owner, uint256 tokenId) internal {
        uint256 idx = ownedIndex[tokenId];
        uint256 lastIdx = ownedTokens[owner].length - 1;
        if (idx != lastIdx) {
            uint256 lastId = ownedTokens[owner][lastIdx];
            ownedTokens[owner][idx] = lastId;
            ownedIndex[lastId] = idx;
        }
        ownedTokens[owner].pop();
    }
}

contract InvariantMiningManagerTest is StdInvariant, Test {
    MockPayToken internal payToken;
    MiningManager internal manager;
    MinerNFT internal miner;
    MeBTC internal mebtc;
    StakeVault internal stakeVault;
    MockTwapOracle internal oracle;

    InvariantHandler internal handler;

    address internal demandVault = address(0xBEEF);
    address internal feeVaultMeBTC = address(0xFEE1);
    address internal project = address(0xCAFE);
    address internal royalty = address(0xD00D);
    address internal user = address(0xA11CE);
    address internal user2 = address(0xB0B);

    function setUp() public {
        payToken = new MockPayToken("MockUSD", "mUSD", 6);
        manager = new MiningManager(address(payToken));
        mebtc = new MeBTC(address(manager));
        oracle = new MockTwapOracle(false, 0);
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
        stakeVault = new StakeVault(address(mebtc), address(manager));

        manager.init(address(mebtc), address(miner), address(stakeVault), demandVault, feeVaultMeBTC, address(oracle));
        miner.setManager(address(manager));

        uint256[4] memory powerCosts = [uint256(50_000), 150_000, 400_000, 1_000_000];
        uint256[4] memory hashCosts = [uint256(100_000), 250_000, 600_000, 1_500_000];
        miner.addModel(1000, 20, 10_000, 1_000_000, 0, "ipfs://MODEL", powerCosts, hashCosts);
        miner.finalizeModel(1);

        payToken.mint(user, 1_000_000_000);
        payToken.mint(user2, 1_000_000_000);

        address[] memory actors = new address[](3);
        actors[0] = user;
        actors[1] = user2;
        actors[2] = address(0xC0C0);

        payToken.mint(actors[2], 1_000_000_000);

        handler = new InvariantHandler(manager, miner, payToken, mebtc, stakeVault, oracle, actors);
        targetContract(address(handler));
    }

    function invariant_totalEffectiveHashMatchesSum() public view {
        uint256 total;
        uint256 len = handler.tokenIdsLength();
        for (uint256 i; i < len; i++) {
            uint256 id = handler.tokenIdAt(i);
            total += manager.currentEffHash(id);
        }
        assertEq(manager.totalEffectiveHash(), total);
    }

    function invariant_supplyCap() public view {
        assertLe(mebtc.totalSupply(), mebtc.MAX_SUPPLY());
    }

    function invariant_lastClaimedLeBlockIndex() public view {
        uint256 len = handler.tokenIdsLength();
        uint256 bi = manager.blockIndex();
        for (uint256 i; i < len; i++) {
            uint256 id = handler.tokenIdAt(i);
            assertLe(manager.lastClaimedBlockIndex(id), bi);
        }
    }

    function invariant_pendingRemainderBounded() public view {
        uint256 len = handler.tokenIdsLength();
        for (uint256 i; i < len; i++) {
            uint256 id = handler.tokenIdAt(i);
            assertLt(manager.pendingRewardRemainder(id), 1e12);
        }
    }

    function invariant_trackedOwnersMatchNft() public view {
        uint256 len = handler.tokenIdsLength();
        for (uint256 i; i < len; i++) {
            uint256 id = handler.tokenIdAt(i);
            assertEq(miner.ownerOf(id), handler.trackedOwnerOf(id));
        }
    }
}
