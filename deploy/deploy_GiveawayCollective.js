const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedGiveawayCollectiveImplementation = async (deployedGlobals) => {
    const [deployer] = await ethers.getSigners();
  const args = [deployedGlobals];

    const CF_FACTORY_ARTIFACT = await ethers.getContractFactory('GiveawayCollective');

    const deployGiveawayCollective = await CF_FACTORY_ARTIFACT.connect(deployer).deploy(args[0]);
    await deployGiveawayCollective.deployed();

    console.log(`Waiting for blocks confirmations of the deploying GiveawayCollective contract...`);
    console.log(`Confirmed!`);

    return {instance: deployGiveawayCollective, address: deployGiveawayCollective.address, args: args}; 
}

module.exports = {
  deployedGiveawayCollectiveImplementation
};
