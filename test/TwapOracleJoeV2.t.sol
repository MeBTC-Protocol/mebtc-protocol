// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {TwapOracleJoeV2} from "../src/core/TwapOracleJoeV2.sol";

contract MockJoePair {
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 private price0Cumulative;
    uint256 private price1Cumulative;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function setReserves(uint112 r0, uint112 r1, uint32 ts) external {
        reserve0 = r0;
        reserve1 = r1;
        blockTimestampLast = ts;
    }

    function setCumulative(uint256 p0, uint256 p1) external {
        price0Cumulative = p0;
        price1Cumulative = p1;
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function price0CumulativeLast() external view returns (uint256) {
        return price0Cumulative;
    }

    function price1CumulativeLast() external view returns (uint256) {
        return price1Cumulative;
    }
}

contract TwapOracleJoeV2Test is Test {
    address internal mebtc = address(0xBEEF);
    address internal usdc = address(0xCAFE);

    uint256 internal minUsdc = 1_000_000; // 1 USDC
    uint32 internal window = 600;

    function _deployOracle(uint112 reserve0, uint112 reserve1, uint32 ts, uint256 p0, uint256 p1)
        internal
        returns (TwapOracleJoeV2 oracle, MockJoePair pair)
    {
        pair = new MockJoePair(mebtc, usdc);
        pair.setReserves(reserve0, reserve1, ts);
        pair.setCumulative(p0, p1);
        oracle = new TwapOracleJoeV2(mebtc, usdc, address(pair), minUsdc, window);
    }

    function test_IsReadyFalseWhenLiquidityLow() public {
        (TwapOracleJoeV2 oracle,) =
            _deployOracle(100_000_000, 500_000, uint32(block.timestamp), 0, 0);
        assertFalse(oracle.isReady());
    }

    function test_IsReadyFalseWhenWindowNotElapsed() public {
        uint32 ts = uint32(block.timestamp);
        (TwapOracleJoeV2 oracle,) = _deployOracle(100_000_000, 1_000_000, ts, 0, 0);
        vm.warp(ts + window - 1);
        assertFalse(oracle.isReady());
    }

    function test_IsReadyTrueAfterWindow() public {
        uint32 ts = uint32(block.timestamp);
        (TwapOracleJoeV2 oracle,) = _deployOracle(100_000_000, 1_000_000, ts, 0, 0);
        vm.warp(ts + window);
        assertTrue(oracle.isReady());
    }

    function test_PriceRevertsWhenLiquidityLow() public {
        (TwapOracleJoeV2 oracle,) =
            _deployOracle(100_000_000, 500_000, uint32(block.timestamp), 0, 0);
        vm.expectRevert(bytes("liquidity"));
        oracle.priceMebtcInUsdc();
    }

    function test_PriceRevertsWhenWindowNotElapsed() public {
        uint32 ts = uint32(block.timestamp);
        (TwapOracleJoeV2 oracle,) = _deployOracle(100_000_000, 1_000_000, ts, 0, 0);
        vm.warp(ts + window - 1);
        vm.expectRevert(bytes("window"));
        oracle.priceMebtcInUsdc();
    }

    function test_PriceReturnsExpectedValue() public {
        uint32 ts = uint32(block.timestamp);
        (TwapOracleJoeV2 oracle,) = _deployOracle(100_000_000, 1_000_000, ts, 0, 0);

        vm.warp(ts + window);
        uint256 price = oracle.priceMebtcInUsdc();
        assertApproxEqAbs(price, 1_000_000, 1); // rounding tolerance
    }
}
