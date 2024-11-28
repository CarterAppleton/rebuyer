// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ILpLocker, Rebuyer } from "../src/Rebuyer.sol";
import { IV3SwapRouter } from "../src/interface/IV3SwapRouter.sol";
import { ERC20 } from "@solady/tokens/ERC20.sol";
import { Test } from "forge-std/Test.sol";

contract RebuyerTest is Test {
  Rebuyer rebuyer;

  ERC20 target = ERC20(0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed);
  ERC20 pair = ERC20(0x4200000000000000000000000000000000000006);

  address eoa = 0xd0f6d77c8E980D0f63Eeb6A73c1665DDE24203AC;

  function setUp() public {
    vm.selectFork(vm.createFork(vm.envString("BASE_MAINNET_RPC_URL")));
    vm.rollFork(23_249_615);

    ILpLocker lpLocker = ILpLocker(0xA837903670837c374317dc7C9da475b2Fdc375bF);

    rebuyer = new Rebuyer({
      _router: IV3SwapRouter(0x2626664c2603336E57B271c5C0b26F421741e481),
      _lpLocker: lpLocker,
      _target: target,
      _pair: pair,
      // Using $BUG as the example Clanker
      _lpTokenId: 1_319_118,
      _incentivePercent: 1,
      _poolFee: 3000
    });

    // Rebuyer is expected to be the owner of the position
    vm.prank(0x51f3b880207Db19635702e2bf9660Dc4b659bb41);
    lpLocker.transferOwnership(address(rebuyer));
  }

  function test_spend_onlyEOA() public {
    vm.prank(address(1), address(2));
    vm.expectRevert(Rebuyer.OnlyExternal.selector);
    rebuyer.spend();
  }

  function test_spend_noFees() public {
    vm.prank(eoa, eoa);
    rebuyer.spend();

    vm.prank(eoa, eoa);
    vm.expectRevert();
    rebuyer.spend();
  }

  function test_spend_works() public {
    uint256 initialBalance = target.balanceOf(eoa);

    deal(address(target), address(rebuyer), 1 ether);
    deal(address(pair), address(rebuyer), 2 ether);

    vm.prank(eoa, eoa);
    rebuyer.spend();

    assertGe(target.balanceOf(eoa) - initialBalance, 0);
    assertEq(target.balanceOf(address(rebuyer)), 0);
    assertEq(pair.balanceOf(address(rebuyer)), 0);
  }
}
