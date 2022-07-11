const Blockprop = artifacts.require("Blockprop");
blockList = []
ownerList = []
ownerAdressList = []

module.exports = async function(callback) {
    try {
        const instance = await Blockprop.deployed()
        blockCount = await instance.getNumberOfBlocks.call()

        for (i = 0; i < blockCount; i++) {
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

            if (!ownerAdressList.includes(blockObj.owner)) {
                ownerAdressList.push(blockObj.owner)

                owner = await instance.owners.call(blockObj.owner)

                var ownerObj = new Object()
                ownerObj.name = owner.name
                ownerObj.taxID = owner.taxID
                ownerObj.etherID = owner.etherID
                ownerObj.authority = owner.authority
                ownerList.push(ownerObj)
            }
        }

    }
    catch(error) {
        console.log(error)
    }
  
    callback()

    var status = new Object()
    status.blockList = blockList
    status.ownerList = ownerList
    
    console.log(status)
  }