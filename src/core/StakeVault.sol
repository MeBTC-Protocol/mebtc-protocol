// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

interface IStakeChangeHook {
    function onStakeChange(address owner) external;
}

contract StakeVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant TIER1_THRESHOLD = 10_000e8;
    uint256 public constant TIER2_THRESHOLD = 50_000e8;
    uint256 public constant TIER3_THRESHOLD = 250_000e8;

    uint16 public constant TIER1_HASH_BPS = 500;
    uint16 public constant TIER1_POWER_BPS = 500;
    uint16 public constant TIER2_HASH_BPS = 1000;
    uint16 public constant TIER2_POWER_BPS = 1200;
    uint16 public constant TIER3_HASH_BPS = 1500;
    uint16 public constant TIER3_POWER_BPS = 2000;

    uint256 public constant TIER1_LOCK = 30 days;
    uint256 public constant TIER2_LOCK = 90 days;
    uint256 public constant TIER3_LOCK = 180 days;

    IERC20 public immutable mebtc;
    IStakeChangeHook public immutable miningManager;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint64) public unlockTime;

    event Staked(address indexed user, uint256 amount, uint256 newBalance, uint8 tier, uint64 unlockAt);
    event Unstaked(address indexed user, uint256 amount, uint256 newBalance, uint8 tier);

    constructor(address _mebtc, address _miningManager) {
        require(_mebtc != address(0) && _miningManager != address(0), "arg=0");
        mebtc = IERC20(_mebtc);
        miningManager = IStakeChangeHook(_miningManager);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "amount=0");
        uint256 oldBalance = stakedBalance[msg.sender];
        uint8 oldTier = _tierForBalance(oldBalance);

        mebtc.safeTransferFrom(msg.sender, address(this), amount);

        uint256 newBalance = oldBalance + amount;
        stakedBalance[msg.sender] = newBalance;

        uint8 newTier = _tierForBalance(newBalance);
        if (newTier > oldTier) {
            uint64 newUnlock = uint64(block.timestamp + _lockForTier(newTier));
            if (newUnlock > unlockTime[msg.sender]) {
                unlockTime[msg.sender] = newUnlock;
            }
        }

        emit Staked(msg.sender, amount, newBalance, newTier, unlockTime[msg.sender]);
        miningManager.onStakeChange(msg.sender);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "amount=0");
        require(block.timestamp >= unlockTime[msg.sender], "locked");

        uint256 bal = stakedBalance[msg.sender];
        require(bal >= amount, "balance");

        uint256 newBalance = bal - amount;
        stakedBalance[msg.sender] = newBalance;

        mebtc.safeTransfer(msg.sender, amount);

        uint8 newTier = _tierForBalance(newBalance);
        emit Unstaked(msg.sender, amount, newBalance, newTier);
        miningManager.onStakeChange(msg.sender);
    }

    function getStakeInfo(address user)
        external
        view
        returns (uint256 balance, uint8 tier, uint64 unlockAt, uint16 hashBonusBps, uint16 powerBonusBps)
    {
        balance = stakedBalance[user];
        tier = _tierForBalance(balance);
        unlockAt = unlockTime[user];
        (hashBonusBps, powerBonusBps) = _bonusesForTier(tier);
    }

    function _tierForBalance(uint256 balance) internal pure returns (uint8) {
        if (balance >= TIER3_THRESHOLD) return 3;
        if (balance >= TIER2_THRESHOLD) return 2;
        if (balance >= TIER1_THRESHOLD) return 1;
        return 0;
    }

    function _bonusesForTier(uint8 tier) internal pure returns (uint16 hashBonusBps, uint16 powerBonusBps) {
        if (tier == 1) return (TIER1_HASH_BPS, TIER1_POWER_BPS);
        if (tier == 2) return (TIER2_HASH_BPS, TIER2_POWER_BPS);
        if (tier == 3) return (TIER3_HASH_BPS, TIER3_POWER_BPS);
        return (0, 0);
    }

    function _lockForTier(uint8 tier) internal pure returns (uint256) {
        if (tier == 1) return TIER1_LOCK;
        if (tier == 2) return TIER2_LOCK;
        if (tier == 3) return TIER3_LOCK;
        return 0;
    }
}
