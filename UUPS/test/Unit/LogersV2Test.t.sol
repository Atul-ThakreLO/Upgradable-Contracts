// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {LogersV2} from "../../src/LogersV2.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LogersV2Test is Test {
    LogersV2 logersV2;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");
    uint256 constant AMOUNT_TO_DEPOSIT = 2e18;

    function setUp() public {
        logersV2 = new LogersV2();
        vm.deal(user, 5e18);
    }

    // function testInitializeOwner() public {
    //     // logersV2.initialize();
    //     console.log(logersV2.owner());
    //     // assertEq(address(this), logersV2.owner());
    // }

    function testDepositMoreThanZero() public {
        vm.expectRevert(LogersV2.LogersV2__AmountShouldMoreThanZero.selector);
        logersV2.deposit{value: 0}();
    }

    function testWithdrawMoreThanZero() public {
        vm.expectRevert(LogersV2.LogersV2__AmountShouldMoreThanZero.selector);
        logersV2.withdraw(0);
    }

    function testAuthorizeUpgradeCanCallOnlyOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(this)));
        logersV2.authorizeUpgrade(address(0));
    }

    modifier deposit() {
        vm.prank(user);
        logersV2.deposit{value: AMOUNT_TO_DEPOSIT}();
        _;
    }

    function testDeposit() public deposit {
        assertEq(address(logersV2).balance, AMOUNT_TO_DEPOSIT);
        assertEq(logersV2.getBalanceOfUser(user), AMOUNT_TO_DEPOSIT);
    }

    function testInsuffiecientBalance() public deposit {
        uint256 userDepositedBalance = logersV2.getBalanceOfUser(user);
        vm.startPrank(user);
        vm.expectRevert(LogersV2.LogersV2__InSufficientBalance.selector);
        logersV2.withdraw(userDepositedBalance + 1e18);
        vm.stopPrank();
    }

    function testDepositEmitEvent() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, false, true, address(logersV2));
        emit LogersV2.AmountDeposit(user, AMOUNT_TO_DEPOSIT);
        logersV2.deposit{value: AMOUNT_TO_DEPOSIT}();
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 userBalanceBeforeDeposit = user.balance;
        vm.prank(user);
        logersV2.deposit{value: AMOUNT_TO_DEPOSIT}();
        uint256 userDepositedBalance = logersV2.getBalanceOfUser(user);
        vm.prank(user);
        logersV2.withdraw(userDepositedBalance);
        uint256 userBalanceAfterDeposit = user.balance;
        assertEq(address(logersV2).balance, 0);
        assertEq(logersV2.getBalanceOfUser(user), 0);
        assertEq(userBalanceBeforeDeposit, userBalanceAfterDeposit);
    }

    function testTotalSupply() public deposit {
        uint256 totalSupply = logersV2.totalSupply();
        assertEq(totalSupply, AMOUNT_TO_DEPOSIT);
    }

    function testTransfer() public deposit {
        uint256 balanceBeforeTranfer = address(logersV2).balance;
        vm.prank(user);
        logersV2.transfer(user2, AMOUNT_TO_DEPOSIT);
        assertEq(balanceBeforeTranfer, user2.balance);
    }

    function testTransferFromTo() public deposit {
        uint256 balanceBeforeTranfer = address(logersV2).balance;
        assertEq(user2.balance, 0);
        assertEq(logersV2.totalSupply(), AMOUNT_TO_DEPOSIT);
        logersV2.transferFromTo(user, user2, AMOUNT_TO_DEPOSIT);
        assertEq(balanceBeforeTranfer, user2.balance);
        assertEq(logersV2.totalSupply(), 0);
    }
}
