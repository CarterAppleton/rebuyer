// SPDX-License-Identifier: MIT
//
// https://basescan.org/address/0x2B8Df3ae4176d7b21DAC7Ae6051b512C5cBDe55B#code

pragma solidity ^0.8.20;

interface ILpLocker {
  function collectFees(address recipient, uint256 tokenId) external;

  function transferOwnership(address newOwner) external;
}
