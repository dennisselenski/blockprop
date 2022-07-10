// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;
import {Helpers} from "./Helpers.sol";
import {Owner, Block, saleStatus} from "./Types.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

uint128 constant taxPercentage = 6;

// Our contract inherits from ERC721. The ERC721 constructor expectes a name
// and a symbol for our token
contract Blockprop is ERC721("Blockprop", "BP") {

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
        // We assume the propertyID of the very first property is just 0. TODO: change
        uint256 propertyID = 0;

        // Create the authority and add it to the owners mapping. We assume the
        // taxID of the authority is 0
        authority = msg.sender;
        owners[msg.sender] = Owner("Authority", "0", payable(authority), true);

        // Create the initial block, assign it to the authority and add it to
        // the blocks mapping
        Block memory firstBlock = Block(0, 0, maxSize(), payable(msg.sender), propertyID, saleStatus.NotForSale, address(0), 0);
        uint256 blockID = Helpers.getBlockID(firstBlock);
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
        return type(uint128).max-1;// We do -1 because we want an even number for further division
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

    // Function for the land registry to registrate owners
    function registerOwner(string memory _taxID, address payable _etherID, string memory _name) public {
            //converting to bytes using keccak is needed to compare strings in Solidity
            require(keccak256(bytes(owners[msg.sender].taxID)) == keccak256(bytes("0")), "Only the authority can registry owners.");
            owners[_etherID] = Owner(_name, _taxID, _etherID, false);
    }


    // Function for somebody who wants to make an offer for a block
    function makeOffer(uint256 _propertyID, uint256 _offeredAmount) public {       
        require(msg.sender != blocks[_propertyID].owner, "This is your property already.");
        require(blocks[_propertyID].status == saleStatus.ForSale, "This property is not up for sale right now.");
        blocks[_propertyID].requester = msg.sender;
        blocks[_propertyID].offeredAmount = _offeredAmount;
    }

    //Function to decline a received offer
    function declineOffer(uint256 _propertyID) public {
        require(msg.sender == blocks[_propertyID].owner, "You have to be the owner of the property.");
        require(blocks[_propertyID].requester != address(0), "There is no offer for this property.");
        blocks[_propertyID].status = saleStatus.ForSale;
        blocks[_propertyID].requester = address(0);
        blocks[_propertyID].offeredAmount = 0;
    }

    // Function to accept a received offer
    function acceptOffer(uint256 _propertyID) public {
        require(msg.sender == blocks[_propertyID].owner, "You have to be the owner of the property.");
        require(blocks[_propertyID].requester != address(0), "There is no offer for this property.");      
        blocks[_propertyID].status = saleStatus.Accepted;       
    }

    //Function to transferMoney
    function transferMoney(uint256 _propertyID) public payable {
        require(blocks[_propertyID].status == saleStatus.Accepted, "The offer was not accepted yet.");
        require(msg.sender == blocks[_propertyID].requester, "You put no offer for this property.");
        //send constant taxPercentage(beginning of code) to the autority address
        owners[authority].etherID.transfer((blocks[_propertyID].offeredAmount/100*taxPercentage));
        //send offeredAmount to previous owner
        owners[blocks[_propertyID].owner].etherID.transfer(blocks[_propertyID].offeredAmount);
        //set requester as new owner
        blocks[_propertyID].owner = blocks[_propertyID].requester;
        //reset other values
        blocks[_propertyID].status = saleStatus.NotForSale;
        blocks[_propertyID].requester = address(0);
        blocks[_propertyID].offeredAmount = 0;
    }

    // Function to change wether your block is for sale or not
    function changeStatus(uint256 _propertyID, saleStatus _status) public {      
        // only callable by the owner of the block
        require(msg.sender == blocks[_propertyID].owner, "You have to be the owner of the property.");
        blocks[_propertyID].status = _status;
    }

}