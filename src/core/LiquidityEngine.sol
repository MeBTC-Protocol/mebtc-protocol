// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {TokenVault} from "./TokenVault.sol";

interface IJoeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IJoePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract LiquidityEngine {
    using SafeERC20 for IERC20;
    uint16 public constant BPS = 10_000;
    uint16 public constant MAX_BURN_BPS = 2_000;
    uint8 public constant USDC_DECIMALS = 6;
    uint8 public constant MEBTC_DECIMALS = 8;

    address public immutable usdc;
    address public immutable mebtc;
    address public immutable factory;
    TokenVault public immutable demandVault;
    TokenVault public immutable feeVaultMeBTC;

    uint256 public immutable minUsdc;
    uint256 public immutable epochSeconds;
    uint16 public immutable burnBps;

    address public pair;
    uint256 public lastEpoch;

    event PairCreated(address pair);
    event EpochExecuted(uint256 epochTime, uint256 usdcIn, uint256 mebtcIn, uint256 lpMinted);
    event AutoCompounded(uint256 lpBurned, uint256 usdcOut, uint256 mebtcOut, uint256 lpMinted);

    constructor(
        address _usdc,
        address _mebtc,
        address _factory,
        address _demandVault,
        address _feeVaultMeBTC,
        uint256 _minUsdc,
        uint256 _epochSeconds,
        uint16 _burnBps
    ) {
        require(_usdc != address(0) && _mebtc != address(0), "token=0");
        require(_factory != address(0), "factory=0");
        require(_demandVault != address(0) && _feeVaultMeBTC != address(0), "vault=0");
        require(_epochSeconds > 0, "epoch=0");
        require(_burnBps <= MAX_BURN_BPS, "burn");

        usdc = _usdc;
        mebtc = _mebtc;
        factory = _factory;
        demandVault = TokenVault(_demandVault);
        feeVaultMeBTC = TokenVault(_feeVaultMeBTC);
        minUsdc = _minUsdc;
        epochSeconds = _epochSeconds;
        burnBps = _burnBps;
    }

    function executeEpoch() external {
        uint256 nextEpoch = lastEpoch + epochSeconds;
        if (nextEpoch == 0) nextEpoch = block.timestamp - (block.timestamp % epochSeconds);
        require(block.timestamp >= nextEpoch, "epoch");
        lastEpoch = nextEpoch;

        address lp = _ensurePair();
        _autoCompound(lp);
        _addLiquidity(lp);
    }

    function _ensurePair() internal returns (address lp) {
        lp = pair;
        if (lp != address(0)) return lp;

        lp = IJoeFactory(factory).getPair(usdc, mebtc);
        if (lp == address(0)) {
            lp = IJoeFactory(factory).createPair(usdc, mebtc);
        }
        pair = lp;
        emit PairCreated(lp);
    }

    function _autoCompound(address lp) internal {
        uint256 lpBal = IJoePair(lp).balanceOf(address(this));
        if (lpBal == 0 || burnBps == 0) return;

        uint256 burnAmount = (lpBal * burnBps) / BPS;
        if (burnAmount == 0) return;

        require(IJoePair(lp).transfer(lp, burnAmount), "lp transfer");
        (uint256 amount0, uint256 amount1) = IJoePair(lp).burn(address(this));

        (uint256 usdcAmt, uint256 mebtcAmt) = _sortAmounts(lp, amount0, amount1);
        uint256 minted = _mintLiquidity(lp, usdcAmt, mebtcAmt);
        emit AutoCompounded(burnAmount, usdcAmt, mebtcAmt, minted);
    }

    function _addLiquidity(address lp) internal {
        uint256 usdcBal = IERC20(usdc).balanceOf(address(demandVault));
        uint256 mebtcBal = IERC20(mebtc).balanceOf(address(feeVaultMeBTC));

        if (usdcBal < minUsdc || mebtcBal == 0) return;

        (uint256 usdcIn, uint256 mebtcIn) = _capByMin(usdcBal, mebtcBal);
        if (usdcIn == 0 || mebtcIn == 0) return;

        demandVault.transferTo(lp, usdcIn);
        feeVaultMeBTC.transferTo(lp, mebtcIn);

        uint256 minted = IJoePair(lp).mint(address(this));
        emit EpochExecuted(lastEpoch, usdcIn, mebtcIn, minted);
    }

    function _capByMin(uint256 usdcBal, uint256 mebtcBal) internal pure returns (uint256 usdcIn, uint256 mebtcIn) {
        uint256 usdcNorm = usdcBal * 10 ** (MEBTC_DECIMALS - USDC_DECIMALS);
        if (usdcNorm <= mebtcBal) {
            usdcIn = usdcBal;
            mebtcIn = usdcNorm;
        } else {
            mebtcIn = mebtcBal;
            usdcIn = mebtcBal / 10 ** (MEBTC_DECIMALS - USDC_DECIMALS);
        }
    }

    function _sortAmounts(address lp, uint256 amount0, uint256 amount1) internal view returns (uint256 usdcAmt, uint256 mebtcAmt) {
        if (IJoePair(lp).token0() == usdc) {
            usdcAmt = amount0;
            mebtcAmt = amount1;
        } else {
            usdcAmt = amount1;
            mebtcAmt = amount0;
        }
    }

    function _mintLiquidity(address lp, uint256 usdcAmt, uint256 mebtcAmt) internal returns (uint256 minted) {
        if (usdcAmt == 0 || mebtcAmt == 0) return 0;
        IERC20(usdc).safeTransfer(lp, usdcAmt);
        IERC20(mebtc).safeTransfer(lp, mebtcAmt);
        minted = IJoePair(lp).mint(address(this));
    }
}
