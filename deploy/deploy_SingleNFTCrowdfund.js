const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedSingleNFTCrowdfundImplementation = async (deployedGlobals) => {
    const [deployer] = await ethers.getSigners();
    const args = [deployedGlobals];

    const SINGLE_NFT_ARTIFACT = await ethers.getContractFactory('SingleNFTCrowdfund');

    const deploySingleNFTCrowdfund = await SINGLE_NFT_ARTIFACT.connect(deployer).deploy(args[0]);
    await deploySingleNFTCrowdfund.deployed();

    console.log(`Waiting for blocks confirmations of the deploying SingleNFTCrowdfund contract...`);
    console.log(`Confirmed!`);

    return {instance: deploySingleNFTCrowdfund, address: deploySingleNFTCrowdfund.address, args: args};     
}

module.exports = {
  deployedSingleNFTCrowdfundImplementation
};
