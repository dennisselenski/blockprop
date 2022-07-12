// Contracts
const Blockprop = artifacts.require("Blockprop");

module.exports = async function(callback) {
  try {
    // Fetch accounts from wallet - these are unlocked
    const accounts = await web3.eth.getAccounts()

    // Fetch the deployed exchange
    const instance = await Blockprop.deployed()    

    await printBlocks(instance, "State after deployment:") 

    // Set up users, account 0 = authority
    const authority = accounts[0]
    const account1 = accounts[1]
    const account2 = accounts[2]

    await instance.registerOwner("456def", account1, "Satoshi Nakamoto")
    await instance.registerOwner("123abc", account2, "Vitalik Buterin")

    // await printBlocks(instance);
    let blockID0 = await instance.blocksList(0);
    await instance.splitBlock(blockID0);    

    await printBlocks(instance, "State after first block split:") 

    await splitAndPrint(authority, instance)

    await printBlocks(instance, "State after property split:") 

    let propertyIDs = await instance.getPropertyIDs(authority)
    let propertyToSell = BigInt(propertyIDs[1])

    await instance.transferProperty(propertyToSell, account1)

    await printBlocks(instance, "State after transfer:") 

    await saleProcess(instance, account2, account1, propertyToSell, 10)

    await printBlocks(instance, "State after sale:")   

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
async function printBlocks(instance, msg)
{
  console.log("▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀ ▀")
  console.log(msg)
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
async function saleProcess(instance, buyerAdr, sellerAdr, propertyToSell, amount) {
  await instance.changeStatus(propertyToSell, Blockprop.saleStatus.ForSale, {from: sellerAdr})
  await instance.makeOffer(propertyToSell, web3.utils.toWei(amount.toString()), {from: buyerAdr})
  await instance.acceptOffer(propertyToSell, {from: sellerAdr})
  await instance.transferMoney(propertyToSell, {from: buyerAdr, value:web3.utils.toWei(amount.toString()), to:instance.address})
}