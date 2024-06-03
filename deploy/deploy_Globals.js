const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedGlobals = async () => {
    const [deployer] = await ethers.getSigners();
    const args = [deployer.address];

    const GLOBALS_ARTIFACT = await ethers.getContractFactory('Globals');

    const deployGlobals = await GLOBALS_ARTIFACT.connect(deployer).deploy(args[0]);
    await deployGlobals.deployed();   

    console.log(`Waiting for blocks confirmations of the deploying Globals contract...`);
    console.log(`Confirmed!`);
    return {instance: deployGlobals, args: args};   
}

module.exports = {
    deployedGlobals
};

