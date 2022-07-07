pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

/* import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; */

// Our contract inherits from ERC721. The ERC721 constructor expectes a name
// and a symbol for our token
contract Blockprop /* is ERC721("Blockprop", "BP") */ {

    struct Owner {
        string name;
        string taxID;
        address payable etheriumID;
        bool authority;
    }

    // The 'x' and 'y' are coordinates for the bottom left corner of a block.
    // Blocks are always squares and the edge length is given by 'size'
    struct Block {
        uint128 x;
        uint128 y;
        uint128 size;
        string taxID;
        uint256 propertyID;
    }

    // Mapping to get the owner struct by it's taxID
    mapping(string => Owner) public owners; // formerly idToOwner

    // Mapping to get the block struct by it's unique 256 bit ID
    mapping(uint256 => Block) public blocks; // fomerly idToBlock

    // Mapping to get a list with all blocks belonging to a property indexed by
    // it's propertyID
    mapping(uint256 => Block[]) public properties;

    // Mapping to get a list with all propertyIDs from an owner (indexed by the owners taxID)
    mapping(string => uint256[]) public assets;

    /*** events ***/
    //TODO compare https://stackoverflow.com/questions/67485324/solidity-typeerror-overriding-function-is-missing-override-specifier
    // either inherit ERC721 or implement these events
    //event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    //event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    //event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // We assume that only the authority deploys the smart contract and
    // calls the constructor. The authority owns everything at the beginning.
    // We also assume that the taxID of the authority is 0
    constructor() public {
        // Create the authority and add it to the owners mapping
        Owner storage auth = Owner("Authority", 0, msg.sender, true);
        owners[auth.taxID] = auth;

        // Create the initial block, assign it to the authority and add it to
        // the blocks mapping. We assume that the propertyID of the first block
        // is 0
        Block storage firstBlock = Block(0, 0, maxSize(), auth.taxID, 0);
        blockID = getBlockID(firstBlock);
        blocks[blockID] = firstBlock;

        // Create a list with all blocks belonging to the property and add the
        // blocks
        Block[] property;
        porperty.push(firstBlock);
        properties[firstBlock.propertyID] = property;

        // Create an asset list, add the first asset and add the list to the
        // assets maping
        uint256[] asset;
        asset.push(firstBlock.propertyID);
        assets[auth.taxID] = asset;
    }

    // Returns the maximum size a property object can have
    function maxSize() public view returns (uint128) {
        return 2 ** 128 - 1;
    }

    // create ID by writing x and y in one variable which produces unique identifier
    function getBlockID(Block memory block) public returns (uint256) {
        uint256 id = block.y >> 128;
        id = id | block.x;
        return id;
    }

    /* // convinience function to add a block to an address in all relevant data structures */
    /* function addStructToAddress(Block memory block, address owner) private { */
    /*     block.owner = owner; */
    /*     uint256 id = getId(block); */
    /*     idToBlock[id] = block; */
    /**/
    /*     uint256[] storage list = ownerToPropertyList[owner]; */
    /*     list.push(id); */
    /*     ownerToPropertyList[owner] = list; */
    /* } */

    /* // extension of balanceOf returning the total size of the owner's property */
    /* function areaBalanceOf(address _owner) external view returns (uint256) { */
    /*     uint256[] memory list = ownerToPropertyList[_owner]; */
    /*     uint256 totalArea = 0; */
    /*     for (uint i=0; i<list.length; i++) { */
    /*         uint256 iArea = idToBlock[list[i]].size; */
    /*         totalArea += iArea ** 2; */
    /*     } */
    /*     return totalArea; */
    /* } */
    /**/
    /* /*** ERC721 functions ***/ */
    /* // number of tokens for given owner */
    /* function balanceOf(address _owner) public override view returns (uint256) { */
    /*     uint256[] memory list = ownerToPropertyList[_owner]; */
    /*     return list.length; */
    /* } */
    /* // owner for property */
    /* function ownerOf(uint256 _tokenId) public override view returns (address) { */
    /*     return idToBlock[_tokenId].owner; */
    /* } */
    /**/
    /* // function for the land registry to registry owners */
    /* function registrateOwner(address _taxID, address payable _etheriumID, string memory _name) private returns (bool) { */
    /*         idToOwner[_taxID] = owner(_taxID, _etheriumID, _name); */
    /*         return true; */
    /* } */
    /**/
    /**/
    /* // TODO transfer */

}
