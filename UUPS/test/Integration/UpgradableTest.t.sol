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

    uint256 AMOUNT_TO_DEPOSITE  = 3e10;
    uint256 AMOUNT_FOR_USER = 5e18;

    function setUp() public {
        deployProxy = new DeployProxy();
        upgradeContract = new UpgradeContract();
        vm.deal(user, AMOUNT_FOR_USER);
    }

    function testV1Implementation() public {
        address proxy = deployProxy.deployProxy();
        LogersV1 v1 = LogersV1(proxy);
        uint256 balance = v1.getBalanceOfUser(address(0));
        assertEq(balance, 0);

    }

    function testUpgrade() public {
        address proxy = deployProxy.deployProxy();
        LogersV2 v2 = new LogersV2();
        address newV2 = upgradeContract.upgradeContract(proxy, address(v2));
        uint256 version = LogersV2(proxy).getVersion();

        console.log("Proxy", proxy);
        console.log("v2", address(v2));
        console.log("newV2", newV2);
        console.log("version", version);
        assertEq(version, 2);
    }

    function testDepositeInV1AndBalanceFromV2() public {
        address proxy = deployProxy.deployProxy();
        LogersV1 v1 = LogersV1(proxy);

        vm.prank(user);
        v1.deposite{value: AMOUNT_TO_DEPOSITE}();
        uint256 balanceFromV1 = v1.getBalanceOfUser(user);

        LogersV2 v2Implemetation = new LogersV2();
        upgradeContract.upgradeContract(proxy, address(v2Implemetation));


        LogersV2 v2 = LogersV2(proxy);
        uint256 balanceFromV2 = v2.getBalanceOfUser(user);

        console.log("V1 balance", balanceFromV1);
        console.log("V2 balance", balanceFromV2);
        assertEq(balanceFromV1, AMOUNT_TO_DEPOSITE);
        assertEq(balanceFromV2, AMOUNT_TO_DEPOSITE);
        assertEq(balanceFromV1, balanceFromV2);
    }
}