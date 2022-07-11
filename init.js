// Contracts
const Blockprop = artifacts.require("Blockprop");

module.exports = async function(callback) {
  try {
    // Fetch accounts from wallet - these are unlocked
    const accounts = await web3.eth.getAccounts()

    // Fetch the deployed exchange
    const instance = await Blockprop.deployed()

    // Set up users, account 0 = authority
    const authority = accounts[0]
    const account1 = accounts[1]
    const account2 = accounts[2]

    await instance.registerOwner("456def", account1, "Satoshi Nakamoto")
    await instance.registerOwner("123abc", account2, "Vitalik Buterin")
    let u1 = await instance.owners(account1)
    let u2 = await instance.owners(account2)

    // await printBlocks(instance);
    let blockID0 = await instance.blocksList(0);
    console.log("split first block");
    await instance.splitBlock(blockID0);

    await splitAndPrint(authority, instance)

    await printBlocks(instance)
        //todo call makeoffer from other addresses

  }
  catch(error) {
    console.log(error)
  }
  callback()
}

// takes the first property of authority and splits two blocks off of it
async function splitAndPrint(authority, instance)
{
  let propertyIDs = await instance.getPropertyIDs(authority)
  let propertyToSplit = propertyIDs[0]
  let blockIDs = await instance.getBlockIDs(BigInt(propertyToSplit))
  // save blockIDs as BigInts
  blockNums = []
  blockIDs.forEach(element => {
    blockNums.push(BigInt(element))
  });
  // only take the first 2
  blockNums = blockNums.slice(0,2)

  await instance.splitProperty(propertyToSplit, blockNums)
}
async function printBlocks(instance)
{
  console.log("▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀")
  console.log("current state of the blocks:")
  blockList = []
  ownerList = []
  ownerAdressList = []
  
  blockCount = await instance.getNumberOfBlocks()

  for (i = 0; i < blockCount; i++) {
      blockId = await instance.blocksList(i)
      block = await instance.blocks(BigInt(blockId))

      var blockObj = new Object()
      blockObj.id = BigInt(blockId)
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

          owner = await instance.owners(blockObj.owner)

          var ownerObj = new Object()
          ownerObj.name = owner.name
          ownerObj.taxID = owner.taxID
          ownerObj.etherID = owner.etherID
          ownerObj.authority = owner.authority
          ownerList.push(ownerObj)
      }
  }

  var status = new Object()
  status.blockList = blockList
  status.ownerList = ownerList
  
  console.log(status)
}