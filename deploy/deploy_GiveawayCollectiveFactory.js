const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedGiveawayCollectiveFactory = async (deployedGlobals) => {
  const [deployer] = await ethers.getSigners();
  const args = [deployedGlobals];

    const CF_FACTORY_ARTIFACT = await ethers.getContractFactory('GiveawayCollectiveFactory');

    const deployGiveawayCollectiveFactory = await CF_FACTORY_ARTIFACT.connect(deployer).deploy(args[0]);
    await deployGiveawayCollectiveFactory.deployed();

    console.log(`Waiting for blocks confirmations of the deploying GiveawayCollectiveFactory contract...`);
    console.log(`Confirmed!`);

    return {instance: deployGiveawayCollectiveFactory, address: deployGiveawayCollectiveFactory.address, args: args};   
}

module.exports = {
  deployedGiveawayCollectiveFactory
};
