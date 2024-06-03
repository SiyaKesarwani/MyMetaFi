const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedCollectiveImplementation = async (deployedGlobals) => {
    const [deployer] = await ethers.getSigners();
  const args = [deployedGlobals];

    const CF_FACTORY_ARTIFACT = await ethers.getContractFactory('Collective');

    const deployCollective = await CF_FACTORY_ARTIFACT.connect(deployer).deploy(args[0]);
    await deployCollective.deployed();

    console.log(`Waiting for blocks confirmations of the deploying Collective contract...`);
    console.log(`Confirmed!`);

    return {instance: deployCollective, address: deployCollective.address, args: args}; 
}

module.exports = {
    deployedCollectiveImplementation
};
