// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LogersV2} from "../src/LogersV2.sol";

contract UpgradeContract {
    function run() public returns {
        address recentlyDeployedProxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);
        vm.startBroadcast();
        LogersV2 logersV2 = new LogersV2();
        vm.stopBroadcats();
        address proxy = upgradeContract(recentlyDeployedProxy, address(logersV2));
        return proxy;
    }

    function upgradeContract(address proxy, address newImplementation) public returns (address) {
        vm.startBroadcast();
        LogersV2 proxy = LogersV2(payable(proxy));
        proxy.upgradeToAndCall(newImplementation, "");
        vm.stopBroadcast();

        return address(proxy);
    }
}