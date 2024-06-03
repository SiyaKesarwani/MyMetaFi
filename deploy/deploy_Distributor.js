const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedDistributor = async (deployedGlobals) => {
    const [deployer] = await ethers.getSigners();
  const args = [deployedGlobals];

    const CF_FACTORY_ARTIFACT = await ethers.getContractFactory('Distributor');

    const deployDistributor = await CF_FACTORY_ARTIFACT.connect(deployer).deploy(args[0]);
    await deployDistributor.deployed();

    console.log(`Waiting for blocks confirmations of the deploying Distributor contract...`);
    console.log(`Confirmed!`);

    return {address: deployDistributor.address, args: args}; 
}

module.exports = {
    deployedDistributor
};
