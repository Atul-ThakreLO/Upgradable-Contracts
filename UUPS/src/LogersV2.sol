// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @custom:oz-upgrades-from LogersV1
contract LogersV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    error LogersV2__AmountShouldMoreThanZero();
    error LogersV2__InSufficientBalance();
    error LogersV2_TransferFailed();

    event AmountDeposit(address indexed sender, uint256 indexed amount);
    event TransferComplete(address indexed from, address indexed to, uint256 indexed amount);

    mapping(address usere => uint256 balance) private userBalance;

    modifier greaterThanZero() {
        if (msg.value <= 0) {
            revert LogersV2__AmountShouldMoreThanZero();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(_msgSender());
    }

    function deposite() public payable greaterThanZero {
        userBalance[_msgSender()] += msg.value;
        emit AmountDeposit(_msgSender(), msg.value);
    }

    function withdraw(uint256 amount) public {
        _transferFromTo(_msgSender(), _msgSender(), amount);
    }

    function transfer(address to, uint256 amount) public {
        _transferFromTo(_msgSender(), to, amount);
    }

    function transferFromTo(address from, address to, uint256 amount) public {
        _transferFromTo(from, to, amount);
    }

    function _transferFromTo(address from, address to, uint256 amount) internal {
        if (amount <= 0) {
            revert LogersV2__AmountShouldMoreThanZero();
        }
        if (userBalance[from] < amount) {
            revert LogersV2__InSufficientBalance();
        }
        userBalance[from] -= amount;
        (bool success,) = payable(to).call{value: amount}("");
        if (!success) {
            revert LogersV2_TransferFailed();
        }
        emit TransferComplete(from, to, amount);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalanceOfUser(address user) public view returns (uint256) {
        return userBalance[user];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function authorizeUpgrade(address newImplementation) public {
        _authorizeUpgrade(newImplementation);
    }
}
