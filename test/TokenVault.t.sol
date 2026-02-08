// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

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

contract TokenVaultTest is Test {
    MockERC20 internal token;
    TokenVault internal vault;

    address internal engine = address(0xE11E);
    address internal user = address(0xB0B);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 6);
        vault = new TokenVault(address(token));
    }

    function test_InitOnlyInitializer() public {
        vm.prank(user);
        vm.expectRevert(bytes("!init"));
        vault.init(engine);
    }

    function test_InitRequiresEngineNonZero() public {
        vm.expectRevert(bytes("engine=0"));
        vault.init(address(0));
    }

    function test_InitOnlyOnce() public {
        vault.init(engine);
        vm.expectRevert(bytes("!init"));
        vault.init(engine);
    }

    function test_TransferToOnlyEngine() public {
        vault.init(engine);
        token.mint(address(vault), 1_000_000);

        vm.prank(user);
        vm.expectRevert(bytes("!engine"));
        vault.transferTo(user, 1);

        vm.prank(engine);
        vault.transferTo(user, 1_000_000);

        assertEq(token.balanceOf(user), 1_000_000);
        assertEq(token.balanceOf(address(vault)), 0);
    }

    function test_BalanceReflectsTokenBalance() public {
        vault.init(engine);
        token.mint(address(vault), 123);
        assertEq(vault.balance(), 123);
    }
}
