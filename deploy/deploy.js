const { network } = require("hardhat");
const { deployedGlobals } = require("./deploy_Globals");
const { deployedCollectiveCrowdfundFactory } = require("./deploy_CollectiveCrowdfundFactory");
const { deployedSingleNFTCrowdfundImplementation } = require("./deploy_SingleNFTCrowdfund");
const { deployedCollectionNFTCrowdfundImplementation } = require("./deploy_CollectionNFTCrowdfund");
const { deployedCollectiveFactory } = require("./deploy_CollectiveFactory");
const { deployedCollectiveImplementation } = require("./deploy_Collective");
const { deployedDistributor } = require("./deploy_Distributor");
const { deployedGiveawayCollectiveFactory } = require("./deploy_GiveawayCollectiveFactory");
const { deployedGiveawayCollectiveImplementation } = require("./deploy_GiveawayCollective");
const { utils } = require("ethers");
const fs = require("fs");

const { 
    OPENSEA_ZONE,
    OPENSEA_CONDUIT_KEY,
    FEE_RECIPIENT,
    FEE_BPS,
    VALID_SIGNER,
    OPENSEA_SEAPORT,
    SAFE_WALLET
} = require(`./config.json`)[`${hre.network.name}`];

console.log(require(`./config.json`)[`${hre.network.name}`])

async function main() {
    const chainId = network.config.chainId;

    const [deployer] = await ethers.getSigners();
    console.log("Deployer Address: ",deployer.address);
    const balanceBefore = (await deployer.provider.getBalance(deployer.address))

    console.log("Balance Before: ", utils.formatEther(balanceBefore.toString()))

    const deployedGlobalsObject = await deployedGlobals();
    const deployedGlobalsContract = deployedGlobalsObject.instance;
    console.log("Globals Deployed Address : ", deployedGlobalsContract.address); 

    const deployedCollectiveCrowdfundFactoryAddress = await deployedCollectiveCrowdfundFactory(deployedGlobalsContract.address);
    console.log("CollectiveCrowdfundFactory Deployed Address : ", deployedCollectiveCrowdfundFactoryAddress.address);  

    const deployedSingleNFTCrowdfundImplementationAddress = await deployedSingleNFTCrowdfundImplementation(deployedGlobalsContract.address);
    console.log("SingleNFTCrowdfundImplementation Deployed Address : ", deployedSingleNFTCrowdfundImplementationAddress.address);  

    const deployedCollectionNFTCrowdfundImplementationAddress = await deployedCollectionNFTCrowdfundImplementation(deployedGlobalsContract.address);
    console.log("CollectionNFTCrowdfundImplementation Deployed Address : ", deployedCollectionNFTCrowdfundImplementationAddress.address); 

    const deployedCollectiveFactoryAddress = await deployedCollectiveFactory(deployedGlobalsContract.address);
    console.log("CollectiveFactory Deployed Address : ", deployedCollectiveFactoryAddress.address); 

    const deployedCollectiveImplementationAddress = await deployedCollectiveImplementation(deployedGlobalsContract.address);
    console.log("Collective Implementation Address : ", deployedCollectiveImplementationAddress.address); 

    const deployedDistributorAddress = await deployedDistributor(deployedGlobalsContract.address);
    console.log("Distributor Address : ", deployedDistributorAddress.address); 

    const deployedGiveawayCollectiveFactoryAddress = await deployedGiveawayCollectiveFactory(deployedGlobalsContract.address);
    console.log("GiveawayCollectiveFactory Deployed Address : ", deployedGiveawayCollectiveFactoryAddress.address); 

    const deployedGiveawayCollectiveImplementationAddress = await deployedGiveawayCollectiveImplementation(deployedGlobalsContract.address);
    console.log("GiveawayCollective Implementation Address : ", deployedGiveawayCollectiveImplementationAddress.address); 


    //----------------------------------------- setting ALL GLOBAL ADDRESSES ---------------------------------------------------
    const calldata = [];
    const setFeeRecipient = (await deployedGlobalsContract.populateTransaction.setAddress(3, FEE_RECIPIENT)).data;
    const setOpenseaConduitKey = (await deployedGlobalsContract.populateTransaction.setBytes32(4, OPENSEA_CONDUIT_KEY)).data;
    const setOpenseaZone = (await deployedGlobalsContract.populateTransaction.setAddress(5, OPENSEA_ZONE)).data;
    const setValidSigner = (await deployedGlobalsContract.populateTransaction.setAddress(9, VALID_SIGNER)).data;
    const setFeeBps = (await deployedGlobalsContract.populateTransaction.setUint256(10, FEE_BPS)).data;
    const setOpenseaSeaport = (await deployedGlobalsContract.populateTransaction.setAddress(11, OPENSEA_SEAPORT)).data;
    // setting the deployed address of GLOBAL_SINGLE_BUY_CF_IMPL
    const setSingleImpl = (await deployedGlobalsContract.populateTransaction.setAddress(1, deployedSingleNFTCrowdfundImplementationAddress.address)).data;
    // setting the deployed address of GLOBAL_COLLECTION_BUY_CF_IMPL
    const setCollectionImpl = (await deployedGlobalsContract.populateTransaction.setAddress(2, deployedCollectionNFTCrowdfundImplementationAddress.address)).data;
    // setting the deployed address of GLOBAL_COLLECTIVE_FACTORY
    const setCollectiveFactory = (await deployedGlobalsContract.populateTransaction.setAddress(6, deployedCollectiveFactoryAddress.address)).data;
    // setting the deployed address of GLOBAL_COLLECTIVE_IMPL
    const setCollectiveImpl = (await deployedGlobalsContract.populateTransaction.setAddress(7, deployedCollectiveImplementationAddress.address)).data;
    // setting the deployed address of GLOBAL_DISTRIBUTOR
    const setDistributor = (await deployedGlobalsContract.populateTransaction.setAddress(8, deployedDistributorAddress.address)).data;
    // setting the deployed address of GLOBAL_GIVEAWAY_COLLECTIVE_FACTORY
    const setGiveawayCollectiveFactory = (await deployedGlobalsContract.populateTransaction.setAddress(13, deployedGiveawayCollectiveFactoryAddress.address)).data;
    // setting the deployed address of GLOBAL_GIVEAWAY_COLLECTIVE_IMPL
    const setGiveawayCollectiveImpl = (await deployedGlobalsContract.populateTransaction.setAddress(14, deployedGiveawayCollectiveImplementationAddress.address)).data;
    // transfer ownership of global contract to multisig wallet
    const setMultiSig = (await deployedGlobalsContract.populateTransaction.transferMultiSig(SAFE_WALLET)).data;

    calldata.push(
      setFeeRecipient, 
      setOpenseaConduitKey, 
      setOpenseaZone, 
      setValidSigner, 
      setFeeBps, 
      setOpenseaSeaport,
      setSingleImpl,
      setCollectionImpl,
      setCollectiveFactory,
      setCollectiveImpl,
      setDistributor,
      setGiveawayCollectiveFactory,
      setGiveawayCollectiveImpl,
      setMultiSig
    );
    await (await deployedGlobalsContract.multicall(calldata)).wait();
    console.log("Fee Recipient Set By MultiSig : ", await deployedGlobalsContract.getAddress(3));
    console.log("Opensea Conduit Key Set By MultiSig : ", await deployedGlobalsContract.getBytes32(4));
    console.log("Opensea Zone Set By MultiSig : ", await deployedGlobalsContract.getAddress(5));
    console.log("Valid Signer Set By MultiSig : ", await deployedGlobalsContract.getAddress(9));
    console.log("Fee BPS Set By MultiSig : ", await deployedGlobalsContract.getUint256(10));
    console.log("Opensea Seaport Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(11));
    console.log("SingleNFT Crowdfund Implementation Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(1));
    console.log("CollectionNFT Crowdfund Implementation Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(2));
    console.log("Collective Factory Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(6));
    console.log("Collective Implementation Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(7));
    console.log("Distributor Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(8));
    console.log("Giveaway Collective Factory Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(13));
    console.log("Giveaway Collective Implementation Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(14));

    const balanceAfter = await deployer.provider.getBalance(deployer.address)
    console.log("Balance Before: ", utils.formatEther(balanceBefore.toString()))
    console.log("Balance After:     ", utils.formatEther(balanceAfter.toString()))
    console.log("Deployment Fees:   ", utils.formatEther((balanceBefore.sub(balanceAfter)).toString()))

    const addresses = {
      "DEPLOYED_GLOBALS_ADDRESS" : deployedGlobalsContract.address,
      "DEPLOYED_COLLECTIVE_CF_FACTORY_ADDRESS" : deployedCollectiveCrowdfundFactoryAddress.address,
      "DEPLOYED_SINGLE_NFT_IMPL_ADDRESS" : deployedSingleNFTCrowdfundImplementationAddress.address,
      "DEPLOYED_COLLECTION_NFT_IMPL_ADDRESS" : deployedCollectionNFTCrowdfundImplementationAddress.address,
      "DEPLOYED_COLLECTIVE_FACTORY_ADDRESS" : deployedCollectiveFactoryAddress.address,
      "DEPLOYED_COLLECTIVE_IMPL_ADDRESS" : deployedCollectiveImplementationAddress.address,
      "DEPLOYED_DISTRIBUTOR_IMPL_ADDRESS" : deployedDistributorAddress.address
    }

    const json_addresses = JSON.stringify(addresses);
    fs.writeFileSync(`./deploy/deployments/${network.name}.json`, json_addresses);
    console.log("Addresses Recorded to: " + `deploy/deployments/${network.name}.json`);

    //--------------------------------------------------------------------------------------------------------------------------

    // // * only verify on testnets or mainnets.
    // if (chainId != 31337 && process.env.ETHERSCAN_API_KEY) {
    //     await verify(deployedGlobalsContract.address, deployedGlobalsObject.args);
    //     await verify(deployedCollectiveCrowdfundFactoryAddress.address, deployedCollectiveCrowdfundFactoryAddress.args);
    //     await verify(deployedSingleNFTCrowdfundImplementationAddress.address, deployedSingleNFTCrowdfundImplementationAddress.args);
    //     await verify(deployedCollectionNFTCrowdfundImplementationAddress.address, deployedCollectionNFTCrowdfundImplementationAddress.args);
    //     await verify(deployedCollectiveFactoryAddress.address, deployedCollectiveFactoryAddress.args);
    //     await verify(deployedCollectiveImplementationAddress.address, deployedCollectiveImplementationAddress.args);
    //     await verify(deployedDistributorAddress.address, deployedDistributorAddress.args);
    // }
  }

// const verify = async (contractAddress, args) => {
//   console.log("Verifying contract...");
//   try {
//       await run("verify:verify", {
//           address: contractAddress,
//           constructorArguments: args,
//       });
//   } catch (e) {
//       if (e.message.toLowerCase().includes("already verified")) {
//           console.log("Already verified!");
//       } else {
//           console.log(e);
//       }
//   }
// };
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });