// SPDX-License_Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployProxy} from "../../script/DeployProxy.s.sol";
import {UpgradeContract} from "../../script/UpgradeContract.s.sol";
import {LogersV1} from "../../src/LogersV1.sol";
import {LogersV2} from "../../src/LogersV2.sol";

contract UpgradeableTest is Test {
    DeployProxy deployProxy;
    UpgradeContract upgradeContract;
    address user = makeAddr("user");

    uint256 AMOUNT_TO_DEPOSIT = 3e10;
    uint256 AMOUNT_FOR_USER = 5e18;

    function setUp() public {
        deployProxy = new DeployProxy();
        upgradeContract = new UpgradeContract();
        vm.deal(user, AMOUNT_FOR_USER);
    }

    function testV1Implementation() public {
        address proxy = deployProxy.deployProxy();
        LogersV1 logersV1 = LogersV1(proxy);
        uint256 balance = logersV1.getBalanceOfUser(address(0));
        assertEq(balance, 0);
    }

    function testUpgrade() public {
        address proxy = deployProxy.deployProxy();
        LogersV2 v2 = new LogersV2();
        address proxyV2 = upgradeContract.upgradeContract(proxy, address(v2));
        uint256 version = LogersV2(proxy).getVersion();

        console.log("Proxy", proxy);
        console.log("v2", address(v2));
        console.log("proxyV2", proxyV2);
        console.log("version", version);
        assertEq(version, 2);
    }

    function testDepositeInV1AndBalanceFromV2() public {
        address proxy = deployProxy.deployProxy();
        LogersV1 logersV1 = LogersV1(proxy);

        vm.prank(user);
        logersV1.deposit{value: AMOUNT_TO_DEPOSIT}();
        uint256 balanceFromV1 = logersV1.getBalanceOfUser(user);

        LogersV2 v2Implemetation = new LogersV2();
        upgradeContract.upgradeContract(proxy, address(v2Implemetation));

        LogersV2 logersV2 = LogersV2(proxy);
        uint256 balanceFromV2 = logersV2.getBalanceOfUser(user);

        console.log("logersV1 balance", balanceFromV1);
        console.log("logersV2 balance", balanceFromV2);
        assertEq(balanceFromV1, AMOUNT_TO_DEPOSIT);
        assertEq(balanceFromV2, AMOUNT_TO_DEPOSIT);
        assertEq(balanceFromV1, balanceFromV2);
    }

    function testWithdrawWithV2() public {
        address proxy = deployProxy.deployProxy();
        LogersV2 v2 = new LogersV2();
        upgradeContract.upgradeContract(proxy, address(v2));
        LogersV2 logersV2 = LogersV2(proxy);
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

    function testBlanaceAfterUpgradeViaMultipleUser() public {
        address proxy = deployProxy.deployProxy();
        LogersV1 logersV1 = LogersV1(proxy);

        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");

        vm.prank(user);
        logersV1.deposit{value: AMOUNT_TO_DEPOSIT}();

        hoax(user2, AMOUNT_FOR_USER);
        logersV1.deposit{value: AMOUNT_TO_DEPOSIT - 1e10}();

        hoax(user3, AMOUNT_FOR_USER);
        logersV1.deposit{value: (AMOUNT_TO_DEPOSIT + 3e10)}();

        uint256 balanceOfUserBeforeUpgrade = logersV1.getBalanceOfUser(user);
        uint256 balanceOfUser2BeforeUpgrade = logersV1.getBalanceOfUser(user2);
        uint256 balanceOfUser3BeforeUpgrade = logersV1.getBalanceOfUser(user3);

        console.log("Before", balanceOfUserBeforeUpgrade, balanceOfUser2BeforeUpgrade, balanceOfUser3BeforeUpgrade);

        LogersV2 v2 = new LogersV2();
        upgradeContract.upgradeContract(proxy, address(v2));
        LogersV2 logersV2 = LogersV2(proxy);

        vm.prank(user2);
        logersV2.deposit{value: AMOUNT_TO_DEPOSIT}();

        uint256 balanceOfUserAfterUpgrade = logersV2.getBalanceOfUser(user);
        uint256 balanceOfUser2AfterUpgrade = logersV2.getBalanceOfUser(user2);
        uint256 balanceOfUser3AfterUpgrade = logersV2.getBalanceOfUser(user3);

        console.log("After", balanceOfUserAfterUpgrade, balanceOfUser2AfterUpgrade, balanceOfUser3AfterUpgrade);

        assertEq(balanceOfUserBeforeUpgrade, balanceOfUserAfterUpgrade);
        assertEq(balanceOfUser2BeforeUpgrade + AMOUNT_TO_DEPOSIT, balanceOfUser2AfterUpgrade);
        assertEq(balanceOfUser3BeforeUpgrade, balanceOfUser3AfterUpgrade);
    }

    function testWithdrawWithV2AfterUpgrade() public {
        address proxy = deployProxy.deployProxy();
        LogersV1 logersV1 = LogersV1(proxy);

        address user2 = makeAddr("user2");

        vm.prank(user);
        logersV1.deposit{value: AMOUNT_TO_DEPOSIT}();

        hoax(user2, AMOUNT_FOR_USER);
        logersV1.deposit{value: AMOUNT_TO_DEPOSIT - 1e10}();

        LogersV2 v2 = new LogersV2();
        upgradeContract.upgradeContract(proxy, address(v2));
        LogersV2 logersV2 = LogersV2(proxy);

        uint256 totalSupplyBeforeUserWithdraw = logersV2.totalSupply();
        console.log("totalSupplyBeforeUserWithdraw", totalSupplyBeforeUserWithdraw);
        vm.prank(user);
        logersV2.withdraw(AMOUNT_TO_DEPOSIT);

        uint256 totalSupplyAfterUserWithdraw = logersV2.totalSupply();
        console.log("totalSupplyAfterUserWithdraw", totalSupplyAfterUserWithdraw);

        assertEq(totalSupplyAfterUserWithdraw, totalSupplyBeforeUserWithdraw - AMOUNT_TO_DEPOSIT);
        assertEq(totalSupplyAfterUserWithdraw, logersV2.getBalanceOfUser(user2));

        vm.prank(user2);
        logersV2.withdraw(totalSupplyAfterUserWithdraw);

        uint256 totalSupplyAfterUser2Withdraw = logersV2.totalSupply();
        console.log("totalSupplyAfterUser2Withdraw", totalSupplyAfterUser2Withdraw);

        assertEq(totalSupplyAfterUser2Withdraw, 0);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////// Remaining Tests are in Inverient tests //////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////
}
