const Blockprop = artifacts.require("Blockprop");


module.exports = async function(callback) {
    try {
        const instance = await Blockprop.deployed()
        length = await instance.getNumberOfBlocks.call()

        for (i = 0; i < length; i++) {
            item = await instance.blocksList.call(i)
            console.log(Number(item))
        }

    }
    catch(error) {
        console.log(error)
    }
  
    callback()
  }