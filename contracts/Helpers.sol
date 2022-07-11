// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import { Owner, Block } from "./Types.sol";
import { Blockprop } from "./Blockprop.sol";

library Helpers {

    // Create a unique blockID by writing x and y in one variable
    function getBlockID(Block memory _block) public pure returns (uint256) {
        return getBlockID(_block.x, _block.y);
    }

    function getBlockID(uint128 x, uint128 y) public pure returns (uint256) {
        uint256 id = uint256(y) << 128;
        id = uint256(x) | id;
        return id;
    }

    // Get pseudo random value by hashing the current's block difficulty and
    // timestamp
    function getRandomness() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    // We can only get a new pseudo random value when a new block is added to
    // our blockchain. If we only use that random value for propertyIDs, it
    // created collision as soon as we request two propertyIDs during one block
    // lifetime. Thats the reason why we also use the old propertyID in order
    // to calculate the new one
    function getNewPropertyID(uint oldPropertyID) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(getRandomness(), oldPropertyID)));
    }

    // check wether value is in array and return the index of value if it is in array
    function existsInArray(uint value, uint[] memory array) public pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }
}
