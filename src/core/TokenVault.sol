// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenVault {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public engine;
    address private initializer;

    constructor(address _token) {
        require(_token != address(0), "token=0");
        token = IERC20(_token);
        initializer = msg.sender;
    }

    function init(address _engine) external {
        require(msg.sender == initializer, "!init");
        require(_engine != address(0), "engine=0");
        require(engine == address(0), "inited");
        engine = _engine;
        initializer = address(0);
    }

    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transferTo(address to, uint256 amount) external {
        require(msg.sender == engine, "!engine");
        token.safeTransfer(to, amount);
    }
}
