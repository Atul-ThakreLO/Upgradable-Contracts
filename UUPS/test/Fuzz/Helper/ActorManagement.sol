// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

contract ActorManagement is Test {
    address[] public actors;

    function initializeActors(uint256 count) public {
        _initializeActor(count);
    }

    /**
     * @dev How we generate multiple address with efficient and fast way:
     * use keccak256 to hash --> returns 32 bytes (256 bits) --> hence cast to uint256 --> address are of 20 bytes (160 bits)
     * --> hence cast to uint160 --> then finally address.
     */
    function _initializeActor(uint256 _count) internal {
        for (uint256 i = 0; i < _count; i++) {
            address actor = address(uint160(uint256(keccak256(abi.encodePacked("actor", i)))));
            actors.push(actor);
            vm.deal(actor, 1000 ether);
        }
    }

    function getCurrentActor(uint256 seed) public view returns (address) {
        seed = bound(seed, 0, actors.length - 1);
        return actors[seed];
    }

    function getActors() public view returns (address[] memory) {
        return actors;
    }
}
