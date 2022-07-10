// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

struct Owner {
    string name;
    string taxID;
    address payable etherID;
    bool authority;
}

// The 'x' and 'y' are coordinates for the bottom left corner of a block.
// Blocks are always squares and the edge length is given by 'size'
struct Block {
    uint128 x;
    uint128 y;
    uint128 size;
    address owner;
    saleStatus status;
    address requester; //address of somebody who wants to buy the block
    uint256 offeredAmount;
}
enum saleStatus {ForSale, NotForSale, Accepted}
    