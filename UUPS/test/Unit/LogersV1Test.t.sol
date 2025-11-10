// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {LogersV1} from "../../src/LogersV1.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LogersV1Test is Test {
    LogersV1 logersV1;
    address user = makeAddr("user");
    uint256 constant AMOUNT_TO_DEPOSIT = 2e18;

    function setUp() public {
        logersV1 = new LogersV1();
        vm.deal(user, 5e18);
    }

    // function testInitializeOwner() public {
    //     // logersV1.initialize();
    //     console.log(logersV1.owner());
    //     // assertEq(address(this), logersV1.owner());
    // }

    function testDepositMoreThanZero() public {
        vm.expectRevert(LogersV1.LogersV1__AmountShouldMoreThanZero.selector);
        logersV1.deposite{value: 0}();
    }

    function testWithdrawMoreThanZero() public {
        vm.expectRevert(LogersV1.LogersV1__AmountShouldMoreThanZero.selector);
        logersV1.withdraw(0);
    }

    function testAuthorizeUpgradeCanCallOnlyOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(this)));
        logersV1.authorizeUpgrade(address(0));
    }

    modifier deposit() {
        vm.prank(user);
        logersV1.deposite{value: AMOUNT_TO_DEPOSIT}();
        _;
    }

    function testDeposit() public deposit {
        assertEq(address(logersV1).balance, AMOUNT_TO_DEPOSIT);
        assertEq(logersV1.getBalanceOfUser(user), AMOUNT_TO_DEPOSIT);
    }

    function testInsuffiecientBalance() public deposit {
        uint256 userDepositedBalance = logersV1.getBalanceOfUser(user);
        vm.startPrank(user);
        vm.expectRevert(LogersV1.LogersV1__InSufficientBalance.selector);
        logersV1.withdraw(userDepositedBalance + 1e18);
        vm.stopPrank();
    }

    function testDepositEmitEvent() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, false, true, address(logersV1));
        emit LogersV1.AmountDeposit(user, AMOUNT_TO_DEPOSIT);
        logersV1.deposite{value: AMOUNT_TO_DEPOSIT}();
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 userBalanceBeforeDeposit = user.balance;
        vm.prank(user);
        logersV1.deposite{value: AMOUNT_TO_DEPOSIT}();
        uint256 userDepositedBalance = logersV1.getBalanceOfUser(user);
        vm.prank(user);
        logersV1.withdraw(userDepositedBalance);
        uint256 userBalanceAfterDeposit = user.balance;
        assertEq(address(logersV1).balance, 0);
        assertEq(logersV1.getBalanceOfUser(user), 0);
        assertEq(userBalanceBeforeDeposit, userBalanceAfterDeposit);
    }
}
