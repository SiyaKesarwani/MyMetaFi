const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedCollectiveCrowdfundFactory = async (deployedGlobals) => {
  const [deployer] = await ethers.getSigners();
  const args = [deployedGlobals];

    const CF_FACTORY_ARTIFACT = await ethers.getContractFactory('CollectiveCrowdfundFactory');

    const deployCollectiveCrowdfundFactory = await CF_FACTORY_ARTIFACT.connect(deployer).deploy(args[0]);
    await deployCollectiveCrowdfundFactory.deployed();

    console.log(`Waiting for blocks confirmations of the deploying CollectiveCrowdfundFactory contract...`);
    console.log(`Confirmed!`);

  return {instance: deployCollectiveCrowdfundFactory, address: deployCollectiveCrowdfundFactory.address, args: args}; 
}

module.exports = {
  deployedCollectiveCrowdfundFactory
};
