// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITwapOracle {
    function isReady() external view returns (bool);
    function priceMebtcInUsdc() external view returns (uint256);
}
