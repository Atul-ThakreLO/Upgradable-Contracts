// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ILogers {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function transferFromTo(address from, address to, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function getBalanceOfUser(address user) external view returns (uint256);
    function getVersion() external pure returns (uint256);
}
