// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ILpLocker } from "./interface/ILpLocker.sol";
import { IV3SwapRouter } from "./interface/IV3SwapRouter.sol";
import { ERC20 } from "@solady/tokens/ERC20.sol";

/// @title Rebuyer
/// @notice Collects Clanker fees and uses them to buy and burn the target
///         token. Small amounts of the target token are paid out as an
///         incentive for triggering a rebuy.
///
///         Clanker
///         -> LpLocker (Clanker, Pair)
///         -> Rebuyer (Clanker, Pair)
///         -> Swap (Pair -> Target)
///         -> Burn (Target)
contract Rebuyer {
  error OnlyExternal();

  /// @notice Router for token swaps
  IV3SwapRouter public immutable router;

  /// @notice Clanker's LpLocker for collecting fees
  ILpLocker public immutable lpLocker;

  /// @notice Target token that will be bought and burned
  ERC20 public immutable target;

  /// @notice Pair token that will be used to buy target
  ERC20 public immutable pair;

  /// @notice LP token ID that generates fees
  uint256 public immutable lpTokenId;

  /// @notice Percentage of `target` tokens given as incentive
  uint256 public immutable incentivePercent;

  /// @notice Fee for the `target` and `pair` pool
  uint24 public immutable poolFee;

  /// @notice Emitted when caller receives their incentive payment
  /// @param caller The address receiving the incentive
  /// @param burned Amount of tokens burned
  /// @param incentive Amount of tokens given as incentive
  event Spent(address indexed caller, uint256 burned, uint256 incentive);

  /// @notice Create a new Rebuyer
  /// @param _router Router for swapping tokens
  /// @param _lpLocker LpLocker contract for fee collection
  /// @param _target Token that will be bought
  /// @param _pair LP token token used to buy target
  /// @param _lpTokenId Token ID in LpLocker to collect fees from
  /// @param _incentivePercent Percentage of bought tokens given as incentive
  /// @param _poolFee Fee for the `_target` and `_pair` pool
  constructor(
    IV3SwapRouter _router,
    ILpLocker _lpLocker,
    ERC20 _target,
    ERC20 _pair,
    uint256 _lpTokenId,
    uint256 _incentivePercent,
    uint24 _poolFee
  ) {
    router = _router;
    target = _target;
    pair = _pair;
    incentivePercent = _incentivePercent;
    lpLocker = _lpLocker;
    lpTokenId = _lpTokenId;
    poolFee = _poolFee;

    // Allow the router to spend pair
    pair.approve(address(_router), type(uint256).max);
  }

  function spend() external {
    // Avoid flashloan class of attacks
    // @dev It is still possible to have inter-block or multi-block
    //      attacks.
    //
    if (msg.sender != tx.origin) revert OnlyExternal();

    // Collect all fees
    //
    lpLocker.collectFees(address(this), lpTokenId);

    // Make the swap
    //
    router.exactInputSingle(
      IV3SwapRouter.ExactInputSingleParams({
        tokenIn: address(pair),
        tokenOut: address(target),
        fee: poolFee,
        recipient: address(this),
        amountIn: pair.balanceOf(address(this)),
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      })
    );

    // Pay incentive & burn the rest
    // @dev Using 0xdead as the burn address as Clanker ERC20s are
    //      not burnable and cannot be sent to address(0).
    //
    uint256 balance = target.balanceOf(address(this));
    uint256 incentive = (balance * incentivePercent) / 100;
    uint256 burn = balance - incentive;

    target.transfer(address(0xdead), burn);
    target.transfer(msg.sender, incentive);

    emit Spent({ caller: msg.sender, burned: burn, incentive: incentive });
  }
}
