const { network } = require("hardhat");
const { deployedGlobals } = require("../deploy_Globals");
const { deployedCollectiveFactory } = require("../deploy_CollectiveFactory");
const { deployedCollectiveImplementation } = require("../deploy_Collective");
const { deployedDistributor } = require("../deploy_Distributor");
const { deployedGiveawayCollectiveFactory } = require("../deploy_GiveawayCollectiveFactory");
const { deployedGiveawayCollectiveImplementation } = require("../deploy_GiveawayCollective");
const { utils } = require("ethers");
const axios = require("axios");
require("dotenv").config();

const { 
    OPENSEA_ZONE,
    OPENSEA_CONDUIT_KEY,
    FEE_RECIPIENT,
    FEE_BPS,
    VALID_SIGNER,
    OPENSEA_SEAPORT,
    SAFE_WALLET
} = require(`../config.json`)[`${hre.network.name}`];

const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY_1;
const MY_PRIVATE_KEY_1 = process.env.MY_PRIVATE_KEY_1;

async function main() {
    const [deployer, contri1, contri2, contri3, contri4] = await ethers.getSigners();
    console.log("Deployer Address: ",deployer.address);
    const balanceBefore = (await deployer.provider.getBalance(deployer.address))

    console.log("Balance Before: ", utils.formatEther(balanceBefore.toString()))

    const deployedGlobalsObject = await deployedGlobals();
    const deployedGlobalsContract = deployedGlobalsObject.instance;
    console.log("Globals Deployed Address : ", deployedGlobalsContract.address); 

    const deployedCollectiveFactoryAddress = await deployedCollectiveFactory(deployedGlobalsContract.address);
    console.log("CollectiveFactory Deployed Address : ", deployedCollectiveFactoryAddress.address); 

    const deployedCollectiveImplementationAddress = await deployedCollectiveImplementation(deployedGlobalsContract.address);
    console.log("Collective Implementation Address : ", deployedCollectiveImplementationAddress.address); 

    const deployedDistributorAddress = await deployedDistributor(deployedGlobalsContract.address);
    console.log("Distributor Address : ", deployedDistributorAddress.address); 

    const deployedGiveawayCollectiveFactoryAddress = await deployedGiveawayCollectiveFactory(deployedGlobalsContract.address);
    const deployedGiveawayCollectiveFactoryContract = deployedGiveawayCollectiveFactoryAddress.instance;
    console.log("GiveawayCollectiveFactory Deployed Address : ", deployedGiveawayCollectiveFactoryAddress.address); 

    const deployedGiveawayCollectiveImplementationAddress = await deployedGiveawayCollectiveImplementation(deployedGlobalsContract.address);
    const deployedGiveawayCollectiveContract = deployedGiveawayCollectiveImplementationAddress.instance;
    console.log("GiveawayCollective Implementation Address : ", deployedGiveawayCollectiveImplementationAddress.address); 


    //----------------------------------------- setting ALL GLOBAL ADDRESSES ---------------------------------------------------
    const calldata = [];
    const setFeeRecipient = (await deployedGlobalsContract.populateTransaction.setAddress(3, FEE_RECIPIENT)).data;
    const setOpenseaConduitKey = (await deployedGlobalsContract.populateTransaction.setBytes32(4, OPENSEA_CONDUIT_KEY)).data;
    const setOpenseaZone = (await deployedGlobalsContract.populateTransaction.setAddress(5, OPENSEA_ZONE)).data;
    const setValidSigner = (await deployedGlobalsContract.populateTransaction.setAddress(9, VALID_SIGNER)).data;
    const setFeeBps = (await deployedGlobalsContract.populateTransaction.setUint256(10, FEE_BPS)).data;
    const setOpenseaSeaport = (await deployedGlobalsContract.populateTransaction.setAddress(11, OPENSEA_SEAPORT)).data;
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
    console.log("Collective Factory Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(6));
    console.log("Collective Implementation Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(7));
    console.log("Distributor Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(8));
    console.log("Giveaway Collective Factory Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(13));
    console.log("Giveaway Collective Implementation Address Set By MultiSig : ", await deployedGlobalsContract.getAddress(14));

    const balanceAfter = await deployer.provider.getBalance(deployer.address)
    console.log("Balance Before: ", utils.formatEther(balanceBefore.toString()))
    console.log("Balance After:     ", utils.formatEther(balanceAfter.toString()))
    console.log("Deployment Fees:   ", utils.formatEther((balanceBefore.sub(balanceAfter)).toString()))

    // ----------------------------------------------------------------------------------------------------------------
    
    const myAccount1 = new ethers.Wallet(MY_PRIVATE_KEY_1, deployer.provider);
    const _collectiveTitleName = "TestGiveawayCollective"
    const _creator = myAccount1.address;
    const _preciousToken = "0x4a1c82542ebdb854ece6ce5355b5c48eb299ecd8"
    const _preciousTokenId = 97;
    const _maxWinners = 10;
    const _giveawayStartTime = ethers.BigNumber.from('1697654984')
    const _giveawayDuration = ethers.BigNumber.from('86400')
    const _canClaimNFTBack = false;
    const _voteDuration= ethers.BigNumber.from('604800')
    const _vetoDuration = ethers.BigNumber.from('86400')
    const _passThresholdBps = ethers.BigNumber.from('8000')

    const opts = deployedGiveawayCollectiveContract.GiveawayCollectiveOptions = {
      collectiveTitleName : _collectiveTitleName,
      creator : _creator,
      preciousToken: _preciousToken,
      preciousTokenId : _preciousTokenId,
      maxWinners : _maxWinners,
      giveawayStartTime : _giveawayStartTime,
      giveawayDuration : _giveawayDuration,
      canClaimNFTBack : _canClaimNFTBack,
      governanceOpts : {
        voteDuration : _voteDuration,
        vetoDuration : _vetoDuration,
        passThresholdBps : _passThresholdBps
      }
    }

	  /// To Calculate the next Contract address of the proxy to be deployed by deployedGiveawayCollectiveFactoryContract
    const nonce = await deployer.provider.getTransactionCount(deployedGiveawayCollectiveFactoryContract.address);
    const nextGiveawayCollectiveAddress = ethers.utils.getContractAddress({from : deployedGiveawayCollectiveFactoryContract.address, nonce : nonce});
  
    /// First approve the NFT from creator's account
    const nftContract = await ethers.getContractAt('IERC721', _preciousToken);
    const approveToken = await nftContract.connect(myAccount1).approve(nextGiveawayCollectiveAddress, _preciousTokenId);
    await approveToken.wait();

    const createGiveawayCollective_tx = await deployedGiveawayCollectiveFactoryContract
      .connect(deployer)
      .createGiveawayCollective(
      opts
    );
    const txReceipt = await(await createGiveawayCollective_tx.wait());
    const txHash = await txReceipt.transactionHash;
    const GC_FACTORY_ARTIFACT = await ethers.getContractFactory('GiveawayCollectiveFactory');
    const iface = GC_FACTORY_ARTIFACT.interface;
    const topic = iface.getEventTopic("GiveawayCollectiveCreated");
  
    const createdGiveawayCollectiveAddress = await fetchGiveawayContractFromEvent(txHash, iface, topic);
    console.log("Created Giveaway Collective Address...", createdGiveawayCollectiveAddress);

    // Now check the owner of NFT (it should be the newly created contract)
    const nftOwner = await nftContract.ownerOf(_preciousTokenId);
    console.log("New nft owner is....", nftOwner);

    // ----------------------------------------------------------------------------------------------------------------

  async function fetchGiveawayContractFromEvent(txHash, iface, topic) {
    let txReceipt = await deployer.provider.getTransactionReceipt(txHash)
    if(txReceipt == null) {
      let txData = await deployer.provider.getTransaction(txHash);
      txReceipt = await txData.wait();
    }
    const logs = await txReceipt.logs;
    const filtered = await logs.filter((log) => log.topics[0] == topic);
    const parsedEvent = await iface.parseLog(filtered[0])
    return parsedEvent.args.gCollective;
  }
}

  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });