// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {LiquidityEngine, IJoeFactory, IJoePair} from "../src/core/LiquidityEngine.sol";
import {TokenVault} from "../src/core/TokenVault.sol";

contract MockERC20 is ERC20 {
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

contract FalseReturnERC20 is ERC20 {
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

    function transfer(address, uint256) public override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) public override returns (bool) {
        return false;
    }
}

contract MockPair is IJoePair {
    address public token0;
    address public token1;

    mapping(address => uint256) public override balanceOf;

    uint256 public mintAmount = 1;
    uint256 public burnAmount0;
    uint256 public burnAmount1;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function setMintAmount(uint256 amount) external {
        mintAmount = amount;
    }

    function setBurnAmounts(uint256 amount0, uint256 amount1) external {
        burnAmount0 = amount0;
        burnAmount1 = amount1;
    }

    function mint(address to) external returns (uint256 liquidity) {
        liquidity = mintAmount;
        balanceOf[to] += liquidity;
    }

    function burn(address to) external returns (uint256 amount0, uint256 amount1) {
        uint256 lp = balanceOf[address(this)];
        require(lp > 0, "no lp");
        balanceOf[address(this)] = 0;

        amount0 = burnAmount0;
        amount1 = burnAmount1;

        if (amount0 > 0) {
            ERC20(token0).transfer(to, amount0);
        }
        if (amount1 > 0) {
            ERC20(token1).transfer(to, amount1);
        }
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "lp");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }
}

    contract MockFactory is IJoeFactory {
        address public lastPair;

        function getPair(address, address) external view returns (address pair) {
            return lastPair;
        }

        function createPair(address tokenA, address tokenB) external returns (address pair) {
            require(lastPair == address(0), "exists");
            MockPair p = new MockPair(tokenA, tokenB);
            lastPair = address(p);
            return address(p);
        }
    }

    contract LiquidityEngineTest is Test {
        MockERC20 internal usdc;
        MockERC20 internal mebtc;
        TokenVault internal demandVault;
        TokenVault internal feeVault;
        MockFactory internal factory;

        function _deployEngine(uint256 minUsdc, uint256 epochSeconds, uint16 burnBps)
            internal
            returns (LiquidityEngine)
        {
            LiquidityEngine engine = new LiquidityEngine(
                address(usdc),
                address(mebtc),
                address(factory),
                address(demandVault),
                address(feeVault),
                minUsdc,
                epochSeconds,
                burnBps
            );
            demandVault.init(address(engine));
            feeVault.init(address(engine));
            return engine;
        }

        function setUp() public {
            usdc = new MockERC20("USDC", "USDC", 6);
            mebtc = new MockERC20("MeBTC", "MBTC", 8);
            demandVault = new TokenVault(address(usdc));
            feeVault = new TokenVault(address(mebtc));
            factory = new MockFactory();
        }

        function test_ExecuteEpochRequiresTime() public {
            LiquidityEngine engine = _deployEngine(1_000_000, 3600, 0);

            // lastEpoch is now set to block.timestamp in the constructor, so nextEpoch = lastEpoch + epochSeconds
            uint256 epochDue = engine.lastEpoch() + engine.epochSeconds();
            if (block.timestamp < epochDue) {
                vm.expectRevert(bytes("epoch"));
                engine.executeEpoch();
                vm.warp(epochDue);
                engine.executeEpoch();
            } else {
                engine.executeEpoch();
            }

            uint256 firstEpoch = engine.lastEpoch();

            // Make the revert check deterministic on local and forked chains.
            vm.warp(firstEpoch);
            vm.expectRevert(bytes("epoch"));
            engine.executeEpoch();

            vm.warp(firstEpoch + engine.epochSeconds());
            engine.executeEpoch();

            assertGt(engine.lastEpoch(), 0);
            assertTrue(factory.lastPair() != address(0));
        }

        function test_AddLiquidityCapsByMin() public {
            LiquidityEngine engine = _deployEngine(1_000_000, 3600, 0);

            usdc.mint(address(demandVault), 5_000_000); // 5 USDC
            mebtc.mint(address(feeVault), 100_000_000); // 1 MeBTC (8 decimals)

            vm.warp(engine.lastEpoch() + engine.epochSeconds());
            engine.executeEpoch();

            address pairAddr = factory.lastPair();
            assertTrue(pairAddr != address(0));

            assertEq(usdc.balanceOf(address(demandVault)), 4_000_000);
            assertEq(mebtc.balanceOf(address(feeVault)), 0);

            assertEq(usdc.balanceOf(pairAddr), 1_000_000);
            assertEq(mebtc.balanceOf(pairAddr), 100_000_000);
        }

        function test_AddLiquidityRespectsMinUsdc() public {
            LiquidityEngine engine = _deployEngine(2_000_000, 3600, 0);

            usdc.mint(address(demandVault), 1_000_000); // below minUsdc
            mebtc.mint(address(feeVault), 100_000_000);

            vm.warp(engine.lastEpoch() + engine.epochSeconds());
            engine.executeEpoch();

            assertEq(usdc.balanceOf(address(demandVault)), 1_000_000);
            assertEq(mebtc.balanceOf(address(feeVault)), 100_000_000);
        }

        function test_AutoCompoundBurnsAndMintsLp() public {
            LiquidityEngine engine = _deployEngine(1_000_000, 3600, 1000); // 10% burn

            // First epoch creates the pair (no liquidity yet)
            vm.warp(engine.lastEpoch() + engine.epochSeconds());
            engine.executeEpoch();

            MockPair pair = MockPair(factory.lastPair());
            pair.setMintAmount(100);
            pair.mint(address(engine)); // LP balance = 100

            usdc.mint(address(pair), 1_000_000);
            mebtc.mint(address(pair), 100_000_000);
            pair.setBurnAmounts(1_000_000, 100_000_000);

            pair.setMintAmount(50);

            uint256 beforeLp = pair.balanceOf(address(engine));
            assertEq(beforeLp, 100);

            vm.warp(engine.lastEpoch() + engine.epochSeconds());
            engine.executeEpoch();

            uint256 afterLp = pair.balanceOf(address(engine));
            // burn 10, mint 50 => 140
            assertEq(afterLp, 140);
        }

        function test_FailedTokenTransferRevertsEpoch() public {
            FalseReturnERC20 badUsdc = new FalseReturnERC20("BAD", "BAD", 6);
            FalseReturnERC20 badMebtc = new FalseReturnERC20("BADM", "BADM", 8);
            demandVault = new TokenVault(address(badUsdc));
            feeVault = new TokenVault(address(badMebtc));
            factory = new MockFactory();

            LiquidityEngine engine = new LiquidityEngine(
                address(badUsdc),
                address(badMebtc),
                address(factory),
                address(demandVault),
                address(feeVault),
                1_000_000,
                3600,
                1000
            );
            demandVault.init(address(engine));
            feeVault.init(address(engine));

            // Create pair (first epoch, no liquidity triggers _addLiquidity skip via minUsdc)
            vm.warp(engine.lastEpoch() + engine.epochSeconds());
            engine.executeEpoch();

            // Seed vaults so _addLiquidity is triggered in the next epoch
            badUsdc.mint(address(demandVault), 2_000_000);
            badMebtc.mint(address(feeVault), 100_000_000);

            vm.warp(engine.lastEpoch() + engine.epochSeconds());
            // SafeERC20 reverts on false-returning tokens — no silent failure, no phantom LP minting
            vm.expectRevert();
            engine.executeEpoch();
        }
    }
