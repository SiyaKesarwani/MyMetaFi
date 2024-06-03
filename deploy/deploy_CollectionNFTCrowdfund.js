const { ethers, network } = require("hardhat");
require("dotenv").config();

const deployedCollectionNFTCrowdfundImplementation = async (deployedGlobals) => {
    const [deployer] = await ethers.getSigners();
    const args = [deployedGlobals];

    const COLLECTION_NFT_ARTIFACT = await ethers.getContractFactory('CollectionNFTCrowdfund');

    const deployCollectionNFTCrowdfund = await COLLECTION_NFT_ARTIFACT.connect(deployer).deploy(args[0]);
    await deployCollectionNFTCrowdfund.deployed();

    console.log(`Waiting for blocks confirmations of the deploying CollectionNFTCrowdfund contract...`);
    console.log(`Confirmed!`);

    return {address: deployCollectionNFTCrowdfund.address, args: args};      
};

module.exports = {
  deployedCollectionNFTCrowdfundImplementation
};
