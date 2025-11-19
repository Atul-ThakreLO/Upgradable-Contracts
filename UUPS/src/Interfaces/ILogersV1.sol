// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ILogersV1 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getBalanceOfUser(address user) external view returns (uint256);
}
