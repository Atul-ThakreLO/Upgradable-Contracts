// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployProxy} from "../../script/DeployProxy.s.sol";
import {ILogers} from "../../src/Interfaces/Ilogers.sol";
import {Handler} from "./Handler.t.sol";
import {ActorManagement} from "./Helper/ActorManagement.sol";

contract Invariants is StdInvariant, Test {
    address proxy;
    Handler handler;
    address[] actors;

    function setUp() public {
        DeployProxy deployProxy = new DeployProxy();
        proxy = deployProxy.deployProxy();
        handler = new Handler(proxy);
        actors = handler.actorManagement().getActors();
        targetContract(address(handler));
    }

    function invariant_totalBalance_equal_supplyBalance() public view {
        uint256 balance = address(proxy).balance;
        assertEq(balance, handler.totalSupply());
    }

    function invariant_userBalance_less_totalBalance() public view {
        uint256 balance = address(proxy).balance;
        uint256 actorsLength = actors.length;
        for(uint256 i = 0; i < actorsLength; i++){
            address actor = actors[i];
            assert(balance >= handler.userBalance(actor));
        }
    }
}
