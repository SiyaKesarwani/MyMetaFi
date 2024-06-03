const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedCollectiveFactory = async (deployedGlobals) => {
  const [deployer] = await ethers.getSigners();
  const args = [deployedGlobals];

    const CF_FACTORY_ARTIFACT = await ethers.getContractFactory('CollectiveFactory');

    const deployCollectiveFactory = await CF_FACTORY_ARTIFACT.connect(deployer).deploy(args[0]);
    await deployCollectiveFactory.deployed();

    console.log(`Waiting for blocks confirmations of the deploying CollectiveFactory contract...`);
    console.log(`Confirmed!`);

    return {address: deployCollectiveFactory.address, args: args};   
}

module.exports = {
  deployedCollectiveFactory
};
