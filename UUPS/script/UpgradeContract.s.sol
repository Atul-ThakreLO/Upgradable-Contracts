// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LogersV2} from "../src/LogersV2.sol";

contract UpgradeContract is Script {
    function run() public returns (address) {
        address recentlyDeployedProxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);
        vm.startBroadcast();
        LogersV2 logersV2 = new LogersV2();
        vm.stopBroadcast();
        address proxy = upgradeContract(recentlyDeployedProxy, address(logersV2));
        return proxy;
    }

    function upgradeContract(address _proxy, address _newImplementation) public returns (address) {
        vm.startBroadcast(LogersV2(_proxy).owner());

        /// @dev You can also use LogersV1 or UUPSUpgradeable (from openzeppelin) for casting the proxy, here V2 is used.
        LogersV2 proxy = LogersV2(payable(_proxy));
        proxy.upgradeToAndCall(_newImplementation, "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
