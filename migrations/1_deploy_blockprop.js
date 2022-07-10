const Helpers = artifacts.require("Helpers");
const Blockprop = artifacts.require("Blockprop");

module.exports = function (deployer) {
    deployer.deploy(Helpers);
    deployer.link(Helpers, Blockprop);
    deployer.deploy(Blockprop)
    .then(() => Blockprop.deployed())
    .then(instance => console.log("The contracts address is: "+instance.address));
};
