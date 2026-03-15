// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITwapOracle} from "./ITwapOracle.sol";

interface IJoePairLike {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
}

contract TwapOracleJoeV2 is ITwapOracle {
    uint256 private constant Q112 = 2 ** 112;
    uint8 private constant MEBTC_DECIMALS = 8;

    address public immutable mebtc;
    address public immutable usdc;
    IJoePairLike public immutable pair;
    uint256 public immutable minUsdcLiquidity;
    uint32 public immutable window;
    uint32 public immutable updateInterval;
    uint32 public immutable maxPriceAge;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public lastTimestamp;
    uint256 public lastGoodPrice;
    uint32 public lastGoodTimestamp;

    event OracleUpdated(uint256 price0Cumulative, uint256 price1Cumulative, uint32 timestamp);
    event PriceCached(uint256 priceUsdc, uint32 timestamp);

    constructor(
        address _mebtc,
        address _usdc,
        address _pair,
        uint256 _minUsdcLiquidity,
        uint32 _window
    ) {
        require(_mebtc != address(0) && _usdc != address(0), "token=0");
        require(_pair != address(0), "pair=0");
        require(_window > 0, "window=0");
        require(_window <= type(uint32).max / 2, "window");
        mebtc = _mebtc;
        usdc = _usdc;
        pair = IJoePairLike(_pair);
        minUsdcLiquidity = _minUsdcLiquidity;
        window = _window;
        updateInterval = _window * 2;
        maxPriceAge = _window * 2;

        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast();
        (,, uint32 ts) = pair.getReserves();
        lastTimestamp = ts;
    }

    function update() external {
        updateIfDue();
    }

    function isReady() external view returns (bool) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if (_usdcReserve(reserve0, reserve1) < minUsdcLiquidity) return false;

        (,, uint32 blockTimestamp) = _currentCumulativePrices();
        uint32 elapsed = blockTimestamp - lastTimestamp;
        return elapsed >= window;
    }

    function priceMebtcInUsdc() external view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        require(_usdcReserve(reserve0, reserve1) >= minUsdcLiquidity, "liquidity");

        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            _currentCumulativePrices();
        uint32 elapsed = blockTimestamp - lastTimestamp;
        require(elapsed >= window, "window");

        uint256 priceAverage;
        if (pair.token0() == mebtc) {
            priceAverage = (price0Cumulative - price0CumulativeLast) / elapsed;
        } else {
            priceAverage = (price1Cumulative - price1CumulativeLast) / elapsed;
        }

        // priceAverage is UQ112x112 in raw token units (usdc per mebtc).
        uint256 priceUsdc = (priceAverage * 10 ** MEBTC_DECIMALS) / Q112;
        require(priceUsdc > 0, "price");
        return priceUsdc;
    }

    function updateIfDue() public returns (bool updated) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            _currentCumulativePrices();
        if (blockTimestamp <= lastTimestamp) return false;

        uint32 elapsed = blockTimestamp - lastTimestamp;
        if (elapsed < updateInterval) return false;

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if (_usdcReserve(reserve0, reserve1) < minUsdcLiquidity) return false;

        uint256 priceAverage;
        if (pair.token0() == mebtc) {
            priceAverage = (price0Cumulative - price0CumulativeLast) / elapsed;
        } else {
            priceAverage = (price1Cumulative - price1CumulativeLast) / elapsed;
        }

        uint256 priceUsdc = (priceAverage * 10 ** MEBTC_DECIMALS) / Q112;
        if (priceUsdc > 0) {
            lastGoodPrice = priceUsdc;
            lastGoodTimestamp = blockTimestamp;
            emit PriceCached(priceUsdc, blockTimestamp);
        }

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        lastTimestamp = blockTimestamp;
        emit OracleUpdated(price0Cumulative, price1Cumulative, blockTimestamp);
        return true;
    }

    function getPriceForFees() external view returns (uint256 price, bool isFresh) {
        price = lastGoodPrice;
        uint32 ts = lastGoodTimestamp;
        if (price == 0 || ts == 0) return (price, false);
        if (block.timestamp < ts) return (price, false);
        uint32 age = uint32(block.timestamp) - ts;
        isFresh = age <= maxPriceAge;
    }

    function usdcLiquidity() external view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        return _usdcReserve(reserve0, reserve1);
    }

    function _currentCumulativePrices()
        internal
        view
        returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp)
    {
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        blockTimestamp = uint32(block.timestamp);
        if (blockTimestampLast != blockTimestamp && reserve0 > 0 && reserve1 > 0) {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            uint256 price0 = (uint256(reserve1) * Q112) / uint256(reserve0);
            uint256 price1 = (uint256(reserve0) * Q112) / uint256(reserve1);
            price0Cumulative += price0 * timeElapsed;
            price1Cumulative += price1 * timeElapsed;
        }
    }

    function _usdcReserve(uint112 reserve0, uint112 reserve1) internal view returns (uint256) {
        if (pair.token0() == usdc) return uint256(reserve0);
        return uint256(reserve1);
    }
}
