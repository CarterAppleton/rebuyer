// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.20;

import { Rebuyer } from "../src/Rebuyer.sol";

import { ILpLocker } from "../src/interface/ILpLocker.sol";
import { IV3SwapRouter } from "../src/interface/IV3SwapRouter.sol";
import { ERC20 } from "@solady/tokens/ERC20.sol";
import { Script } from "forge-std/Script.sol";

contract DeployScript is Script {
  // Fill this in with your recently launched clanker
  // Example: https://basescan.org/tx/0xc1e36967e6623a75cfc215c4b08609a5d1a969e77c63f72a0e9aa3f2c3db0c97#eventlog
  //
  address lpLocker = 0xA837903670837c374317dc7C9da475b2Fdc375bF;
  uint256 lpTokenId = 1_319_118;

  // Select which target token you want to buy
  address target = 0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed;

  // And the token generated from the clanker that buys it
  address pair = 0x4200000000000000000000000000000000000006;

  function setUp() public { }

  function run() public {
    vm.startBroadcast();

    new Rebuyer({
      // https://basescan.org/address/0x2626664c2603336E57B271c5C0b26F421741e481
      _router: IV3SwapRouter(0x2626664c2603336E57B271c5C0b26F421741e481),
      _lpLocker: ILpLocker(lpLocker),
      _target: ERC20(target),
      _pair: ERC20(pair),
      _lpTokenId: lpTokenId,
      _incentivePercent: 5,
      _poolFee: 3000
    });

    vm.stopBroadcast();
  }
}
