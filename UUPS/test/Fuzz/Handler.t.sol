// SPDX-Lecense-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {ILogersV1} from "../../src/Interfaces/ILogersV1.sol";
import {ILogersV2} from "../../src/Interfaces/ILogersV2.sol";
import {ILogers} from "../../src/Interfaces/Ilogers.sol";
import {ActorManagement} from "./Helper/ActorManagement.sol";
import {UpgradeContract} from "../../script/UpgradeContract.s.sol";
import {LogersV2} from "../../src/LogersV2.sol";

contract Handler is Test {
    address immutable logers;
    ILogers public iLogers;
    ActorManagement public actorManagement;

    ////////////////////////////////////////////////////////////
    ///////////////////// Ghost Variables //////////////////////
    ////////////////////////////////////////////////////////////
    uint256 public totalSupply;
    mapping(address => uint256) public userBalance;
    bool internal isUpgraded;

    constructor(address _logers) {
        logers = _logers;
        iLogers = ILogers(logers);
        actorManagement = new ActorManagement();
        actorManagement.initializeActors(10);
    }

    function deposit(uint256 amount, uint256 seed) public {
        amount = bound(amount, 1, 1e30);
        address actor = actorManagement.getCurrentActor(seed);

        uint256 actorBalance = actor.balance;
        if (actorBalance < amount) {
            vm.deal(actor, amount);
        }

        vm.prank(actor);
        iLogers.deposit{value: amount}();
        userBalance[actor] += amount;
        totalSupply += amount;
    }

    function upgrade() public {
        // if(isUpgraded) {
        //     return;
        // }
        vm.assume(isUpgraded != true);
        LogersV2 logersV2 = new LogersV2();
        UpgradeContract upgradeContract = new UpgradeContract();
        upgradeContract.upgradeContract(logers, address(logersV2));
        isUpgraded = true;
    }

    function withdraw(uint256 amount, uint256 seed) public {
        address actor = actorManagement.getCurrentActor(seed);

        amount = bound(amount, 0, userBalance[actor]);

        vm.assume(amount > 0);

        vm.prank(actor);
        iLogers.withdraw(amount);

        userBalance[actor] -= amount;
        totalSupply -= amount;
    }

    function transfer(uint256 amount, uint256 seed1, uint256 seed2) public {
        vm.assume(isUpgraded == true);

        address actor = actorManagement.getCurrentActor(seed1);
        address actorTo = actorManagement.getCurrentActor(seed2);

        amount = bound(amount, 0, userBalance[actor]);

        vm.assume(amount > 0);

        vm.prank(actor);
        iLogers.transfer(actorTo, amount);

        userBalance[actor] -= amount;
        totalSupply -= amount;
    }

    function transferFrom(uint256 amount, uint256 seed1, uint256 seed2) public {
        vm.assume(isUpgraded == true);

        address actorFrom = actorManagement.getCurrentActor(seed1);
        address actorTo = actorManagement.getCurrentActor(seed2);

        amount = bound(amount, 0, userBalance[actorFrom]);

        vm.assume(amount > 0);

        iLogers.transferFromTo(actorFrom, actorTo, amount);

        userBalance[actorFrom] -= amount;
        totalSupply -= amount;
    }
}
