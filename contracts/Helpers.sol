// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import { Owner, Block, saleStatus } from "./Types.sol";

library Helpers {

    // Create a unique blockID by writing x and y in one variable
    function getBlockID(Block memory _block) public pure returns (uint256) {
        // solidity shift apparently doesn't work
        uint256 id = _block.y * 2**128;
        id = id | _block.x;
        return id;
    }

    function getBlockID(uint128 x, uint128 y) public pure returns (uint256) {
        uint256 id = y * 2**128;
        id = id | x;
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
    function getNewPropertyID(uint oldPropertyID) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(getRandomness(), oldPropertyID)));
    }
}
