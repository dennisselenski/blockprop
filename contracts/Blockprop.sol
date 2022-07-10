// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

uint128 constant taxPercentage = 6;

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
        saleStatus status;
        address requester; //address of somebody who wants to buy the block
        uint256 offeredAmount;
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

    enum saleStatus {ForSale, NotForSale, Accepted}

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
function splitBlock(uint _blockID) public returns (uint[4] memory) {
        // Get the block struct from our contract
        Block storage b = blocks[_blockID];

        // If this block does not exists, throw an error
        assert(b.owner != address(0));

        // If block size is 1, we have already reached the minimal division
        assert(b.size > 1);

        // Save the old propertyID
        uint oldPropertyID = b.propertyID;

        // Divide the size by two, the point (x,y) stays the same
        b.size = b.size / 2;

        // Create the 3 new blocks
        Block memory b2 = Block(b.x + b.size, b.y, b.size, b.owner, oldPropertyID, saleStatus.ForSale, address(0), 0);
        Block memory b3 = Block(b.x, b.y + b.size, b.size, b.owner, oldPropertyID, saleStatus.ForSale, address(0), 0);
        Block memory b4 = Block(b.x + b.size, b.y + b.size, b.size, b.owner, oldPropertyID, saleStatus.ForSale, address(0), 0);

        // Now we need to modify the propertyID from all blocks. We first get
        // all blocks that belong to the property in order to calcualte it
        Block[] storage property = properties[oldPropertyID];
        assert(property.length != 0);

        // Let's iterate over all the blocks of the property and replace the
        // block we're dividing
        for (uint i = 0; i < property.length; i++) {
            if(getBlockID(property[i]) == _blockID) {
                property[i] = b;
                continue;
            }
        }
        // Let's add the three new blocks to the array
        property.push(b2);
        property.push(b3);
        property.push(b4);

        // Let's create the propertyID
        uint newPropertyID = calculatePropertyID(property);

        // Update the propertyID in the property array
        for (uint i = 0; i < property.length; i++) {
                property[i].propertyID = newPropertyID;
        }

        // Move the array to the new index
        properties[newPropertyID] = property;
        delete properties[oldPropertyID];

        // Now update the blocks array
        b.propertyID = newPropertyID;
        b2.propertyID = newPropertyID;
        b3.propertyID = newPropertyID;
        b4.propertyID = newPropertyID;
        blocks[getBlockID(b2)] = b2;
        blocks[getBlockID(b3)] = b3;
        blocks[getBlockID(b4)] = b4;

        // Update the assets array
        uint[] storage list = assets[b.owner];
        for (uint i = 0; i < list.length; i++) {
            if(list[i] == oldPropertyID) {
                list[i] = newPropertyID;
            }
        }

        return [ getBlockID(b), getBlockID(b2), getBlockID(b3), getBlockID(b4) ];
    }

    // Returns the maximum size a property object can have
    function maxSize() public pure returns (uint128) {
        return type(uint128).max-1;// We do -1 because we want an even number for further division
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