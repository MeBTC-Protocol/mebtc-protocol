// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MeBTC is ERC20 {
    error OnlyMM();
    error MaxCap();

    address public immutable miningManager;
    uint256 public constant MAX_SUPPLY = 21_000_000e18;

    constructor(address _mm) ERC20("MeBTC", "MBTC") {
        require(_mm != address(0), "mm=0");
        miningManager = _mm;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != miningManager) revert OnlyMM();
        if (totalSupply() + amount > MAX_SUPPLY) revert MaxCap();
        _mint(to, amount);
    }
}

