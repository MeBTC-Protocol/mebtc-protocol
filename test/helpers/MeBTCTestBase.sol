// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {MiningManager} from "../../src/core/MiningManager.sol";
import {MinerNFT} from "../../src/nft/MinerNFT.sol";
import {MeBTC} from "../../src/token/MeBTC.sol";
import {StakeVault} from "../../src/core/StakeVault.sol";

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
    uint256 internal lastGoodPrice_;
    uint32 internal lastGoodTimestamp_;
    uint32 internal maxAge = 7200;

    constructor(bool _ready, uint256 _price) {
        ready = _ready;
        price = _price;
    }

    function setReady(bool _ready) external {
        ready = _ready;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function isReady() external view returns (bool) {
        return ready;
    }

    function priceMebtcInUsdc() external view returns (uint256) {
        return price;
    }

    function updateIfDue() external returns (bool) {
        if (!ready) return false;
        if (price == 0) return false;
        lastGoodPrice_ = price;
        lastGoodTimestamp_ = uint32(block.timestamp);
        return true;
    }

    function getPriceForFees() external view returns (uint256 p, bool isFresh) {
        p = lastGoodPrice_;
        if (p == 0 || lastGoodTimestamp_ == 0) return (p, false);
        if (block.timestamp < lastGoodTimestamp_) return (p, false);
        uint32 age = uint32(block.timestamp) - lastGoodTimestamp_;
        isFresh = age <= maxAge;
    }

    function lastGoodPrice() external view returns (uint256) {
        return lastGoodPrice_;
    }

    function lastGoodTimestamp() external view returns (uint32) {
        return lastGoodTimestamp_;
    }

    function maxPriceAge() external view returns (uint32) {
        return maxAge;
    }

    uint256 internal liquidityAmount;

    function setLiquidity(uint256 _amount) external {
        liquidityAmount = _amount;
    }

    function usdcLiquidity() external view returns (uint256) {
        return liquidityAmount;
    }
}

abstract contract MeBTCTestBase is Test {
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
    address internal user2 = address(0xB0B);

    function setUp() public virtual {
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
        miner.finalizeModel(1);

        payToken.mint(user, 1_000_000_000);
        payToken.mint(user2, 1_000_000_000);
    }

    function _buyOne(address buyer) internal returns (uint256 tokenId) {
        vm.startPrank(buyer);
        payToken.approve(address(miner), type(uint256).max);
        tokenId = miner.buyFromModel(1, 1);
        vm.stopPrank();
    }

    function _buyMany(address buyer, uint256 quantity) internal returns (uint256 firstTokenId) {
        vm.startPrank(buyer);
        payToken.approve(address(miner), type(uint256).max);
        firstTokenId = miner.buyFromModel(1, quantity);
        vm.stopPrank();
    }
}
