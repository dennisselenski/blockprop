const Blockprop = artifacts.require("Blockprop");
blockList = []

module.exports = async function(callback) {
    try {
        const instance = await Blockprop.deployed()
        length = await instance.getNumberOfBlocks.call()

        for (i = 0; i < length; i++) {
            blockId = await instance.blocksList.call(i)
            blockId = Number(blockId)

            block = await instance.blocks.call(blockId)

            var blockObj = new Object()
            blockObj.x = BigInt(block.x)
            blockObj.y = BigInt(block.y)
            blockObj.size = BigInt(block.size)
            blockObj.owner = block.owner
            blockObj.propertyID = BigInt(block.propertyID)
            blockObj.requester = block.requester
            blockObj.offeredAmount = BigInt(block.offeredAmount)
            blockList.push(blockObj)
        }

    }
    catch(error) {
        console.log(error)
    }
  
    callback()

    console.log(blockList)
  }