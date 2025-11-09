// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LogersV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    error LogersV1__AmountShouldMoreThanZero();
    error LogersV1__InSufficientBalance();
    error LogersV1_TransferFailed();


    event AmountDeposit(address indexed sender, uint256 indexed amount);

    mapping(address usere => uint256 balance) private userBalance;

    modifier greaterThanZero() {
        if(msg.value <= 0) {
            revert LogersV1__AmountShouldMoreThanZero();
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    function deposite() public payable greaterThanZero {
        userBalance[msg.sender] += msg.value;
        emit AmountDeposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        if(amount <= 0) {
            revert LogersV1__AmountShouldMoreThanZero();
        }
        if(userBalance[msg.sender] < amount) {
            revert LogersV1__InSufficientBalance();
        }
        userBalance[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) {
            revert LogersV1_TransferFailed();
        }
    }

    function getBalanceOfUser(address user) public view returns (uint256) {
        return userBalance[user];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}