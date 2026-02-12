// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITwapOracle {
    function isReady() external view returns (bool);
    function priceMebtcInUsdc() external view returns (uint256);
    function updateIfDue() external returns (bool);
    function getPriceForFees() external view returns (uint256 price, bool isFresh);
    function lastGoodPrice() external view returns (uint256);
    function lastGoodTimestamp() external view returns (uint32);
    function maxPriceAge() external view returns (uint32);
}
