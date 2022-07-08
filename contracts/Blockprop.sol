// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Our contract inherits from ERC721. The ERC721 constructor expectes a name
// and a symbol for our token
contract Blockprop is ERC721("Blockprop", "BP") {

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
        // The property ID is the hash over all accending blockIDs belonging to
        // a property. TODO: write hash function
        uint256 propertyID;
    }

    // Mapping to get the owner struct by it's etherID
    mapping(address => Owner) public owners; // formerly idToOwner

    // Mapping to get the block struct by it's unique 256 bit blockID
    mapping(uint256 => Block) public blocks; // fomerly idToBlock

    // Mapping to get a list with all blocks belonging to a property indexed by
    // it's propertyID
    mapping(uint256 => Block[]) public properties;

    // Mapping to get a list with all propertyIDs from an owner (indexed by the owners add)
    mapping(address => uint256[]) public assets;

    address authority;

    // We assume that only the authority deploys the smart contract and
    // calls the constructor. The authority owns everything at the beginning.
    // We also assume that the taxID of the authority is 0
    constructor() {
        // Create the authority and add it to the owners mapping. We assume the
        // taxID of the authority is 0
        authority = msg.sender;
        owners[msg.sender] = Owner("Authority", "0", payable(authority), true);

        // The blockID of the first block is 0. We create a propertyID by using
        // only this first block
        uint firstBlockID = 0;
        uint[] memory blockIDList;
        blockIDList[0] = firstBlockID;
        uint propertyID = calculatePropertyID(blockIDList);

        // Create the initial block and add it to the blocks mapping
        blocks[firstBlockID] = Block(0, 0, maxSize(), payable(msg.sender), propertyID);

        // Create a list with all blocks belonging to the property and add the
        // blocks
        Block[] storage blockArray = properties[propertyID];
        blockArray.push(blocks[firstBlockID]);
        /* properties[propertyID] = _blockArray; */

        // Create an asset list, add the first asset and add the list to the
        // assets maping
        uint256[] storage propertyIDList = assets[msg.sender];
        propertyIDList.push(propertyID);
        /* assets[msg.sender] = _propertyIDList; */
    }

    function sort(uint[] memory data) public returns(uint[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    // Copied from: https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
    function quickSort(uint[] memory arr, int left, int right) internal {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function calculatePropertyID(uint[] memory ids) public returns (uint) {
        // Sort the array. Note: this is expensive but I don't see a better solution
        ids = sort(ids);

        // Hash the output string to get the propertyID
        bytes32 hash = keccak256(abi.encodePacked(ids));
        return uint(hash);
    }

    // This function is overloaded if we wanna call it with a block array
    function calculatePropertyID(Block[] memory _blocks) public returns (uint) {
        uint[] memory ids;

        // Iterate over all bocks, calculate the blockIDs and add them to an array
        for(uint i = 0; i < _blocks.length; i++) {
                ids[i] = getBlockID(_blocks[i]);
        }
        return calculatePropertyID(ids);
    }

    // Returns the maximum size a property object can have
    function maxSize() public pure returns (uint128) {
        return 2 ** 128 - 1;
    }

    // Create a unique blockID by writing x and y in one variable
    function getBlockID(Block memory _block) public pure returns (uint256) {
        uint256 id = _block.y >> 128;
        id = id | _block.x;
        return id;
    }

    // Extension of balanceOf returning the total size of the owner's property
    function areaBalanceOf(address _owner) external view returns (uint256) {
        uint256 totalArea = 0;
        uint256[] memory propertyIDlist = assets[_owner];
        for(uint i = 0; i < propertyIDlist.length; i++) {
            uint256 propertyID = propertyIDlist[i];
            Block[] memory blockList = properties[propertyID];
            for(uint j = 0; j < blockList.length; j++) {
                Block memory b = blockList[j];
                totalArea += b.size ** 2;
            }
        }
        return totalArea;
    }

    // ERC721 functions

    // Number of tokens for given owner
    function balanceOf(address _owner) public override view returns (uint256) {
        uint256[] memory list = assets[_owner];
        return list.length;
    }

    // Owner of block
    function ownerOf(uint256 _tokenID) public override view returns (address) {
        return blocks[_tokenID].owner;
    }

    // Function for the land registry to registry owners
    function registrateOwner(string memory _taxID, address payable _etherID, string memory _name) private returns (bool) {
            owners[_etherID] = Owner(_name, _taxID, _etherID, false);
            return true;
    }
}
