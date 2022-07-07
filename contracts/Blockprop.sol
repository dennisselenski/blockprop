// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

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
        uint256 propertyID;
    }

    // Mapping to get the owner struct by it's etherID
    mapping(address => Owner) public owners; // formerly idToOwner

    // Mapping to get the block struct by it's unique 256 bit tokenID
    mapping(uint256 => Block) public blocks; // fomerly idToBlock

    // Mapping to get a list with all blocks belonging to a property indexed by
    // it's propertyID
    mapping(uint256 => Block[]) public properties;

    // Mapping to get a list with all propertyIDs from an owner (indexed by the owners add)
    mapping(address => uint256[]) public assets;

    /*** events ***/
    //TODO compare https://stackoverflow.com/questions/67485324/solidity-typeerror-overriding-function-is-missing-override-specifier
    // either inherit ERC721 or implement these events
    //event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    //event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    //event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // We assume that only the authority deploys the smart contract and
    // calls the constructor. The authority owns everything at the beginning.
    // We also assume that the taxID of the authority is 0
    constructor() {
        // We assume the propertyID of the very first property is just 0
        uint256 propertyID = 0;

        // Create the authority and add it to the owners mapping. We assume the
        // taxID of the authority is 0
        owners[msg.sender] = Owner("Authority", "0", payable(msg.sender), true);

        // Create the initial block, assign it to the authority and add it to
        // the blocks mapping
        Block memory firstBlock = Block(0, 0, maxSize(), payable(msg.sender), propertyID);
        uint256 blockID = getBlockID(firstBlock);
        blocks[blockID] = firstBlock;

        // Create a list with all blocks belonging to the property and add the
        // blocks
        Block[] storage _blockArray = properties[propertyID];
        _blockArray.push(firstBlock);
        properties[propertyID] = _blockArray;

        // Create an asset list, add the first asset and add the list to the
        // assets maping
        uint256[] storage _propertyIDList = assets[msg.sender];
        _propertyIDList.push(propertyID);
        assets[msg.sender] = _propertyIDList;
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
