// Library Definition

import {Owner, Block, saleStatus} from "./Types.sol";

library Helpers {

function splitBlock(uint _blockID, mapping(uint256 => Block) storage blocks, mapping(uint256 => Block[]) storage properties,     mapping(address => uint256[]) storage assets) public returns (uint[4] memory) {
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

    // Create a unique blockID by writing x and y in one variable
    function getBlockID(Block memory _block) public pure returns (uint256) {
        uint256 id = _block.y >> 128;
        id = id | _block.x;
        return id;
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
}