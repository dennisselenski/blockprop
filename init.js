// Contracts
const Blockprop = artifacts.require("Blockprop");

// Utils
// const ether = (n) => {
//   return new web3.utils.BN(
//     web3.utils.toWei(n.toString(), 'ether')
//   )
// }

module.exports = async function(callback) {
  try {
    // Fetch accounts from wallet - these are unlocked
    const accounts = await web3.eth.getAccounts()
    console.log(accounts)

    // Set up users, account 0 = authority
    const authority = accounts[0]
    const account1 = accounts[1]
    const account2 = accounts[2]

    console.log('Account 1', account1) 
    console.log('Account 2', account2) 
    // Fetch the deployed exchange
    const instance = await Blockprop.deployed()
    console.log('Blockprop fetched', instance.address)

    await instance.registerOwner("456def", account1, "Bob Dylan")
    await instance.registerOwner("123abc", account2, "John Doe")
    let u1 = await instance.owners(account1)
    let u2 = await instance.owners(account2)
    console.log('User 1:', u1)
    console.log('User 2:', u2)
    //todo call makeoffer from other addresses
  }
  catch(error) {
    console.log(error)
  }

  callback()
}