// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;
import {Helpers} from "./Helpers.sol";
import {Owner, Block, saleStatus} from "./Types.sol";


uint128 constant taxPercentage = 6;

contract Blockprop {

    address authority;

    // Mapping to get the owner struct by it's etherID
    mapping(address => Owner) public owners;

    // Mapping to get a list with all propertyIDs from an owner (indexed by the
    // owners address)
    mapping(address => uint256[]) public assets;
    
    // Mapping to get a list with all blockIDs belonging to a property indexed by
    // it's propertyID
    mapping(uint256 => uint256[]) public properties;

    // List containg all blockIDs to access them from the outside (e.g. to get
    // the current status)
    uint256[] public blocksList;

    // Mapping to get the block struct by it's unique 256 bit blockID
    mapping(uint256 => Block) public blocks; 

    // We assume that only the authority deploys the smart contract and
    // calls the constructor. The authority owns everything at the beginning.
    // We also assume that the taxID of the authority is 0
    constructor() {
        // We assume the propertyID of the very first property is just 0
        uint256 propertyID = 0;

        // Create the authority and add it to the owners mapping. We assume the
        // taxID of the authority is 0
        authority = msg.sender;
        owners[msg.sender] = Owner("Authority", "0", payable(authority), true);

        // Create the initial block, assign it to the authority and add it to
        // the blocks mapping
        Block memory firstBlock = Block(0, 0, maxSize(), payable(msg.sender), saleStatus.NotForSale, address(0), 0);
        uint256 blockID = Helpers.getBlockID(firstBlock);
        blocks[blockID] = firstBlock;
        blocksList.push(blockID);

        // Create a list with all blocks belonging to the property and add the
        uint256[] storage blockArray = properties[propertyID];
        blockArray.push(blockID);

        // Create an asset list, add the first asset and add the list to the
        // assets maping
        uint256[] storage propertyIDList = assets[msg.sender];
        propertyIDList.push(propertyID);
    }

    // retuns the total number of blocks stored in blocksList
    function getNumberOfBlocks() public view returns(uint256) {
        return blocksList.length;
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
            uint256[] memory blockIDList = properties[propertyID];
            for(uint j = 0; j < blockIDList.length; j++) {
                uint256 blockID = blockIDList[j];
                Block memory b = blocks[blockID];
                totalArea += b.size ** 2;
            }
        }
        return totalArea;
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
        //todo: trade properties only
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
