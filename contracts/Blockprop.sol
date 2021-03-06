// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;
import { Helpers } from "./Helpers.sol";
import { Owner, Block } from "./Types.sol";

uint128 constant taxPercentage = 6;

contract Blockprop {    

    enum saleStatus { ForSale, NotForSale, Accepted }

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
        uint256 blockID = Helpers.getBlockID(0, 0);
        blocks[blockID] = Block(0, 0, maxSize(), payable(msg.sender), propertyID, saleStatus.NotForSale, address(0), 0);
        blocksList.push(blockID);

        // Add the blockID to the property
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

    function getPropertyIDs(address owner) public view returns (uint256[] memory) {
        return assets[owner];
    }
    function getBlockIDs(uint propertyID) public view returns (uint256[] memory) {
        return properties[propertyID];
    }
    // split newPropertyBlocks (a list of blocks) from the property with the given propertyID 
    // (referred to as 'original property') and create a new property
    function splitProperty(uint256 propertyID, uint256[] memory newPropertyBlocks) public {
        // check if the caller owns the given property
        uint256[] memory senderAssets = assets[msg.sender];
        require(Helpers.existsInArray(propertyID, senderAssets), "You do not own this property");

        // check if all blocks in newPropertyBlocks are part of the property beloning to the given propertyID
        uint256[] memory origProperty = properties[propertyID];
        for (uint i = 0; i < newPropertyBlocks.length; i++) {
            require(Helpers.existsInArray(newPropertyBlocks[i], origProperty), 
            "At least one block is not part of the given property");
        }
        
        // run through original property and change propertyID on all relevant blocks
        // also create a new list for the remains of the original property 
        uint256 newPropertyID = Helpers.getNewPropertyID(propertyID);
        uint256[] memory origPropertyAfterSplit = new uint256[](origProperty.length - newPropertyBlocks.length);
        uint j = 0;
        for (uint i = 0; i < origProperty.length; i++) {
            // if this is supposed to be added to the new property
            if (Helpers.existsInArray(origProperty[i], newPropertyBlocks)) {
                // set propertyID to new value
                Block storage _block = blocks[origProperty[i]];
                _block.propertyID = newPropertyID;
            }
            else {
                // add blockID to list of remaining original property
                origPropertyAfterSplit[j] = (origProperty[i]);
                j++;
            }
        }

        // update properties mapping
        properties[newPropertyID] = newPropertyBlocks;
        properties[propertyID] = origPropertyAfterSplit;

        // update assets mapping
        uint256[] storage assetsList = assets[msg.sender];
        assetsList.push(newPropertyID);
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

    function splitBlock(uint _blockID) public returns (uint[4] memory) {
        // Get the block struct from our contract
        Block storage b = blocks[_blockID];

        // If this block does not exists, throw an error
        assert(b.owner != address(0));

        // If block size is 1, we have already reached the minimal division
        assert(b.size > 1);

        // Divide the size by two, the point (x,y) stays the same
        b.size = b.size / 2;

        // Create the 3 new blocks and their blockIDs
        Block memory b2 = Block(b.x + b.size, b.y, b.size, b.owner, b.propertyID, saleStatus.NotForSale, address(0), 0);
        Block memory b3 = Block(b.x, b.y + b.size, b.size, b.owner, b.propertyID, saleStatus.NotForSale, address(0), 0);
        Block memory b4 = Block(b.x + b.size, b.y + b.size, b.size, b.owner, b.propertyID, saleStatus.NotForSale, address(0), 0);
        uint b2ID = Helpers.getBlockID(b2);
        uint b3ID = Helpers.getBlockID(b3);
        uint b4ID = Helpers.getBlockID(b4);

        // Add them to the blocks mapping and to blockList
        blocks[b2ID] = b2;
        blocks[b3ID] = b3;
        blocks[b4ID] = b4;
        blocksList.push(b2ID);
        blocksList.push(b3ID);
        blocksList.push(b4ID);

        // Add the blockIDs to the properties mapping
        uint[] storage property = properties[b.propertyID];
        assert(property.length != 0);
        property.push(b2ID);
        property.push(b3ID);
        property.push(b4ID);

        return [ _blockID, b2ID, b3ID, b4ID ];
    }

    // Function for the land registry to registrate owners
    function registerOwner(string memory _taxID, address payable _etherID, string memory _name) public {
            require(owners[msg.sender].authority, "Only the authority can registry owners.");
            owners[_etherID] = Owner(_name, _taxID, _etherID, false);
    }

   
    // Function for somebody who wants to make an offer for a property
    function makeOffer(uint256 _propertyID, uint256 _offeredAmount) public { 
        //List of BlockIDs belonging to the propertyID
        uint256[] memory blockIDList = properties[_propertyID];

        require(msg.sender != blocks[blockIDList[0]].owner, "This is your property already.");
        require(blocks[blockIDList[0]].status == saleStatus.ForSale, "This property is not up for sale right now.");

        //change values in all belonging blocks 
        for(uint i = 0; i < blockIDList.length; i++) {
                 blocks[blockIDList[i]].requester = msg.sender;
                 blocks[blockIDList[i]].offeredAmount = _offeredAmount;
        }
    }

    //Function to decline a received offer
    function declineOffer(uint256 _propertyID) public {
        //List of BlockIDs belonging to the propertyID
        uint256[] memory blockIDList = properties[_propertyID];

        require(msg.sender == blocks[blockIDList[0]].owner, "You have to be the owner of the property.");
        require(blocks[blockIDList[0]].requester != address(0), "There is no offer for this property");

        //change values in all belonging blocks
        for(uint i = 0; i < blockIDList.length; i++) {                
                blocks[blockIDList[i]].status = saleStatus.ForSale;
                blocks[blockIDList[i]].requester = address(0);
                blocks[blockIDList[i]].offeredAmount = 0;
        }
    }

    // Function to accept a received offer
    function acceptOffer(uint256 _propertyID) public {
        //List of BlockIDs belonging to the propertyID
        uint256[] memory blockIDList = properties[_propertyID];

        require(msg.sender == blocks[blockIDList[0]].owner, "You have to be the owner of the property.");
        require(blocks[blockIDList[0]].requester != address(0), "There is no offer for this property");

        //change status in all blocks of this property
        for(uint i = 0; i < blockIDList.length; i++) {
                blocks[blockIDList[i]].status = saleStatus.Accepted;
        }    
    }

    //Function to transfer money
    function transferMoney(uint256 _propertyID) public payable {
        //List of BlockIDs belonging to the propertyID
        uint256[] memory blockIDList = properties[_propertyID];

        require(blocks[blockIDList[0]].status == saleStatus.Accepted, "The offer was not accepted yet.");
        require(msg.sender == blocks[blockIDList[0]].requester, "You put no offer for this property.");
        require(msg.value == blocks[blockIDList[0]].offeredAmount, "You sent incorrect amount of funds.");

        //send constant taxPercentage(beginning of code) to the autority address
        uint taxAmount = (blocks[blockIDList[0]].offeredAmount/100)*taxPercentage;
        payable(authority).transfer(taxAmount);
        // send offeredAmount to seller
        address seller = blocks[blockIDList[0]].owner;
        payable(seller).transfer(blocks[blockIDList[0]].offeredAmount - taxAmount);

        //change values in all belonging blocks
        for(uint i = 0; i < blockIDList.length; i++) {
            Block storage _block = blocks[blockIDList[i]];
            _block.owner = msg.sender;
            _block.status = saleStatus.NotForSale;
            _block.requester = address(0);
            _block.offeredAmount = 0;               
        }

        // Add the property to the assets of the buyer
        uint[] storage buyerAssets = assets[msg.sender];
        buyerAssets.push(_propertyID);

        // Remove the property of the assets of the seller
        uint[] storage sellerAssets = assets[seller];
        uint[] memory newSellerAssets = new uint[](sellerAssets.length - 1);
        uint j = 0;
        for(uint i = 0; i < sellerAssets.length; i++) {
            if(sellerAssets[i] != _propertyID) {
                newSellerAssets[j] = _propertyID;
                j++;
            }
        }
        assets[seller] = newSellerAssets;
    }

    function transferProperty(uint256 _propertyID, address _newOwner) public {
        //List of BlockIDs belonging to the propertyID
        uint256[] memory blockIDList = properties[_propertyID];

        require(msg.sender == authority, "Only the authority can transfer property.");
        require(msg.sender == blocks[blockIDList[0]].owner, "You have to be the owner of the property.");

        //change values in all belonging blocks
        for(uint i = 0; i < blockIDList.length; i++) {
            Block storage _block = blocks[blockIDList[i]];
            _block.owner = _newOwner;             
        }

        // Add the property to the assets of the buyer
        uint[] storage buyerAssets = assets[_newOwner];
        buyerAssets.push(_propertyID);

        // Remove the property of the assets of the seller
        uint[] storage sellerAssets = assets[msg.sender];
        uint[] memory newSellerAssets = new uint[](sellerAssets.length - 1);
        uint j = 0;
        for(uint i = 0; i < sellerAssets.length; i++) {
            if(sellerAssets[i] != _propertyID) {
                newSellerAssets[j] = _propertyID;
                j++;
            }
        }
        assets[msg.sender] = newSellerAssets;
    }

    receive() external payable {
        
    }

    // Function to change wether your property is for sale or not
    function changeStatus(uint256 _propertyID, saleStatus _status) public { 
        //List of BlockIDs belonging to the propertyID
        uint256[] memory blockIDList = properties[_propertyID];

        require(msg.sender == blocks[blockIDList[0]].owner, "You have to be the owner of the property.");

        //change the status in all belonging blocks
        for(uint i = 0; i < blockIDList.length; i++) {
                blocks[blockIDList[i]].status = _status;             
        }  
    }
}
