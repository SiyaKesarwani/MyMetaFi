const { network } = require("hardhat");
const { deployedGlobals } = require("../deploy_Globals");
const { deployedCollectiveCrowdfundFactory } = require("../deploy_CollectiveCrowdfundFactory");
const { deployedSingleNFTCrowdfundImplementation } = require("../deploy_SingleNFTCrowdfund");
const { deployedCollectionNFTCrowdfundImplementation } = require("../deploy_CollectionNFTCrowdfund");
const { deployedCollectiveFactory } = require("../deploy_CollectiveFactory");
const { deployedCollectiveImplementation } = require("../deploy_Collective");
const { deployedDistributor } = require("../deploy_Distributor");
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

async function main() {
    const [deployer, contri1, contri2, contri3, contri4] = await ethers.getSigners();
    console.log("Deployer Address: ",deployer.address);
    const balanceBefore = (await deployer.provider.getBalance(deployer.address))

    console.log("Balance Before: ", utils.formatEther(balanceBefore.toString()))

    const deployedGlobalsObject = await deployedGlobals();
    const deployedGlobalsContract = deployedGlobalsObject.instance;
    console.log("Globals Deployed Address : ", deployedGlobalsContract.address); 

    const deployedCollectiveCrowdfundFactoryAddress = await deployedCollectiveCrowdfundFactory(deployedGlobalsContract.address);
    const deployedCrowdfundFactoryContract = deployedCollectiveCrowdfundFactoryAddress.instance;
    console.log("CollectiveCrowdfundFactory Deployed Address : ", deployedCollectiveCrowdfundFactoryAddress.address);  

    const deployedSingleNFTCrowdfundImplementationAddress = await deployedSingleNFTCrowdfundImplementation(deployedGlobalsContract.address);
    const deployedSingleContract = deployedSingleNFTCrowdfundImplementationAddress.instance;
    console.log("SingleNFTCrowdfundImplementation Deployed Address : ", deployedSingleNFTCrowdfundImplementationAddress.address);  

    const deployedCollectionNFTCrowdfundImplementationAddress = await deployedCollectionNFTCrowdfundImplementation(deployedGlobalsContract.address);
    console.log("CollectionNFTCrowdfundImplementation Deployed Address : ", deployedCollectionNFTCrowdfundImplementationAddress.address); 

    const deployedCollectiveFactoryAddress = await deployedCollectiveFactory(deployedGlobalsContract.address);
    console.log("CollectiveFactory Deployed Address : ", deployedCollectiveFactoryAddress.address); 

    const deployedCollectiveImplementationAddress = await deployedCollectiveImplementation(deployedGlobalsContract.address);
    console.log("Collective Implementation Address : ", deployedCollectiveImplementationAddress.address); 

    const deployedDistributorAddress = await deployedDistributor(deployedGlobalsContract.address);
    console.log("Distributor Address : ", deployedDistributorAddress.address); 


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

    const balanceAfter = await deployer.provider.getBalance(deployer.address)
    console.log("Balance Before: ", utils.formatEther(balanceBefore.toString()))
    console.log("Balance After:     ", utils.formatEther(balanceAfter.toString()))
    console.log("Deployment Fees:   ", utils.formatEther((balanceBefore.sub(balanceAfter)).toString()))

    // ----------------------------------------------------------------------------------------------------------------

    const _collectiveTitleName = "TestCollectionCollective"
    const _nftContractAddress = "0x524cab2ec69124574082676e6f654a18df49a048"
    const _nftTokenId = 12912;
    const _fundraiseGoal = ethers.utils.parseEther('0.66625')
    const _crowdFundDuration = ethers.BigNumber.from('86400')
    const _lowerLimitInvestment =  ethers.utils.parseEther('0.13325')
    const _initialContributor = deployer.address
    const _initialContribution = ethers.utils.parseEther('0.13325')
    const _voteDuration= ethers.BigNumber.from('604800')
    const _vetoDuration = ethers.BigNumber.from('86400')
    const _passThresholdBps = ethers.BigNumber.from('8000')

    const opts = deployedSingleContract.SingleNFTCrowdfundOptions = {
      collectiveTitleName : _collectiveTitleName,
      nftContractAddress : _nftContractAddress,
      nftTokenId : _nftTokenId,
      fundraiseGoal : _fundraiseGoal,
      crowdFundDuration : _crowdFundDuration,
      lowerLimitInvestment : _lowerLimitInvestment,
      initialContributor : _initialContributor,
      governanceOpts : {
        voteDuration : _voteDuration,
        vetoDuration : _vetoDuration,
        passThresholdBps : _passThresholdBps
      }
    }
    const createSingleNFTCollective_tx = await deployedCrowdfundFactoryContract
      .connect(deployer)
      .createSingleNFTCrowdfund(
      opts, {value : _initialContribution, gasLimit : 6000000}
    );
    const txReceipt = await(await createSingleNFTCollective_tx.wait());
    const txHash = await txReceipt.transactionHash;
    const CF_FACTORY_ARTIFACT = await ethers.getContractFactory('CollectiveCrowdfundFactory');
    const iface = CF_FACTORY_ARTIFACT.interface;
    const topic = iface.getEventTopic("SingleNFTCrowdfundCreated");
  
    const createdCrowdfundCollectiveAddress = await fetchCrowdFundContractFromEvent(txHash, iface, topic);
    console.log("Created Crowdfund Address...", createdCrowdfundCollectiveAddress);

    // ----------------------------------------------------------------------------------------------------------------

    const singleCrowdfund = await ethers.getContractAt('SingleNFTCrowdfund', createdCrowdfundCollectiveAddress);

    const contribute_tx1 = await singleCrowdfund.connect(contri1).contribute(
      contri1.address, {value : _initialContribution, gasLimit : 6000000}
    );
    await(await contribute_tx1.wait());

    const balanceContri1 = await deployer.provider.getBalance(contri1.address)
    console.log("Balance contri1: ", utils.formatEther(balanceContri1.toString()))

    const contribute_tx2 = await singleCrowdfund.connect(contri2).contribute(
      contri2.address, {value : _initialContribution, gasLimit : 6000000}
    );
    await(await contribute_tx2.wait());

    const balanceContri2 = await deployer.provider.getBalance(contri2.address)
    console.log("Balance contri2: ", utils.formatEther(balanceContri2.toString()))

    const contribute_tx3 = await singleCrowdfund.connect(contri3).contribute(
      contri3.address, {value : _initialContribution, gasLimit : 6000000}
    );
    await(await contribute_tx3.wait());

    const balanceContri3 = await deployer.provider.getBalance(contri3.address)
    console.log("Balance contri3: ", utils.formatEther(balanceContri3.toString()))

    const contribute_tx4 = await singleCrowdfund.connect(contri4).contribute(
      contri4.address, {value : _initialContribution, gasLimit : 6000000}
    );
    await(await contribute_tx4.wait());

    const balanceContri4 = await deployer.provider.getBalance(contri4.address)
    console.log("Balance contri4: ", utils.formatEther(balanceContri4.toString()))

    const contribution = await singleCrowdfund.totalContributions();

    console.log('Total contributions...',utils.formatEther(contribution.toString()));
		const delay = ms => new Promise(res => setTimeout(res, ms));
		await delay(3000);
    const options1 = {
      method: 'GET',
      url: `https://api.opensea.io/api/v2/orders/ethereum/seaport/listings?asset_contract_address=${_nftContractAddress}&token_ids=${_nftTokenId}`,
      headers: {accept: 'application/json', 'X-API-KEY': '4785c83986be468086c0013031ea576c'}
    };
    
    let response = await axios
    .request(options1)
    .then(function (response) {
      return response;
    })
    .catch(function (error) {
      console.error(error);
    });

		const order_hash = await response.data.orders[0].order_hash;
		console.log("order_hash==========>>>>>>", order_hash);
		await delay(3000);
    const options = {
      method: 'POST',
      url: 'https://api.opensea.io/api/v2/listings/fulfillment_data',
      headers: {
        'content-type': 'application/json',
        'X-API-KEY': '4785c83986be468086c0013031ea576c'
      },
      data: {
        listing: {
          hash: order_hash,
          chain: 'ethereum',
          protocol_address: '0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC'
        },
        fulfiller: {address: deployer.address}
      }
    };
      
      let BasicOrderParameters = await axios
        .request(options)
        .then(function (response) {
          return response.data.fulfillment_data.transaction.input_data.parameters;
        })
        .catch(function (error) {
          console.error(error);
        });

    console.log("BasicOrderParameters==========>>>>>>>>>",BasicOrderParameters);

    const price = await response.data.orders[0].current_price;
    console.log("price=================>>>>>>>>", price)

    const seaportContract = await ethers.getContractAt('IOpenseaExchange', OPENSEA_SEAPORT);

    console.log("Buying............");

    const buyCalldata = (await seaportContract.populateTransaction.fulfillBasicOrder_efficient_6GL6yc(BasicOrderParameters)).data;
    const buy_tx = await singleCrowdfund.connect(deployer).buy(
          seaportContract.address, price, buyCalldata, {gasLimit : 6000000}
    );
    var buyTxReceipt = await(await buy_tx.wait());
    const buyTxHash = await buyTxReceipt.transactionHash;
    const SINGLE_ARTIFACT = await ethers.getContractFactory('SingleNFTCrowdfund');
    const ifaceSingle = SINGLE_ARTIFACT.interface;
    const successfulTopic = ifaceSingle.getEventTopic("Successful");

    const createdCollectiveAddress = await fetchSuccessfulCollectiveContractFromEvent(buyTxHash, ifaceSingle, successfulTopic);
    console.log("Created Collective Address...", createdCollectiveAddress);

    // ----------------------------------------------------------------------------------------------------------------
    // Signer
    const impersonatedSigner = new ethers.Wallet(DEPLOYER_PRIVATE_KEY, deployer.provider);

    const sellingPrice = ethers.utils.parseEther("0.0002");

    console.log("Listing on Opensea............");

    var openseaFeeBPS = 0.025e4;
    var openseaFee = sellingPrice*(openseaFeeBPS)/(1e4);
    var listPrice = sellingPrice-(openseaFee);
    const openseaFeeAddress = "0x0000a26b00c1F0DF003000390027140000fAa719";
    const conduitControllerAddress = "0x00000000F9490004C11Cef243f5400493c00Ad63"

    console.log("Opensea fee address...", openseaFeeBPS)
    console.log("Opensea fees...", openseaFee)
    console.log("Actual List price...", listPrice)

    var listingParams = {
      conduitController : conduitControllerAddress,
      seaport : OPENSEA_SEAPORT,
      sellingPrice : sellingPrice,
      listPrice : listPrice,
      fees : [openseaFee], 
      feeRecipients : [openseaFeeAddress],
      preciousToken : _nftContractAddress,
      preciousTokenId : _nftTokenId
    }

    const deployedCollectiveContract = await ethers.getContractAt('Collective', createdCollectiveAddress);

    const listToOpensea_tx = await deployedCollectiveContract.populateTransaction.executeProposalListToOpensea(
      listingParams);

    console.log("listToOpensea_tx...", listToOpensea_tx)

    const typedData = await getTypedData(
      createdCollectiveAddress,
      listToOpensea_tx.data,
      _nftContractAddress,
      _nftTokenId
    )

    console.log(typedData, "=-=-=-=-=-=")
    console.log(impersonatedSigner.address, "_++_+_+_+_+_+");
    const signature = await impersonatedSigner._signTypedData(typedData.domain, typedData.types, typedData.message)
    console.log(signature, "........signature")

    const arbitrary_call_tx = await deployedCollectiveContract.connect(deployer).executeProposalArbitraryCall(
      {
        target: createdCollectiveAddress,
        value: 0,
        data: listToOpensea_tx.data,
        expectedResultHash: ethers.constants.HashZero
      },
      _nftContractAddress,
      _nftTokenId,
      signature
    )

    const listTxReceipt = await(await arbitrary_call_tx.wait());
    const lisTxHash = await listTxReceipt.transactionHash;
    const COLLECTIVE_ARTIFACT = await ethers.getContractFactory('Collective');
    const ifaceList = COLLECTIVE_ARTIFACT.interface;
    const topicList = ifaceList.getEventTopic("OpenseaOrderListed");

    const orderHash = await fetchOrderHashFromEvent(lisTxHash, ifaceList, topicList);
    console.log("Listed order hash...", orderHash);

    console.log("Balance of Collective...", await deployer.provider.getBalance(createdCollectiveAddress));

// ----------------------------------------------------------------------------------------------------------------

async function fetchOrderHashFromEvent(txHash, iface, topic) {
	let txReceipt = await deployer.provider.getTransactionReceipt(txHash)
	if(txReceipt == null) {
		let txData = await deployer.provider.getTransaction(txHash);
		txReceipt = await txData.wait();
	}
  const logs = await txReceipt.logs;
  const filtered = await logs.filter((log) => log.topics[0] == topic);
	const parsedEvent = await iface.parseLog(filtered[0])
	return parsedEvent.args.orderHash;
}

async function getTypedData(contractAddress, callData, nftTokenContract, nftId) {
    
  const domain = {
    name: "Collective",
    version: "1",
    chainId: network.config.chainId,
    verifyingContract: contractAddress,
  };

  const ExecuteProposal = [
    { name: "target", type: "address" },
    { name: "value", type: "uint256" },
    { name: "data", type: "bytes" },
    { name: 'expectedResultHash', type: 'bytes32'},
    { name: "preciousToken", type: "address" },
    { name: "preciousTokenId", type: "uint256" },
    { name: 'nonce', type: 'uint256'}
  ]  
  const message = {
    target: contractAddress,
    value: 0,
    data: callData,
    expectedResultHash: ethers.constants.HashZero,
    preciousToken: nftTokenContract,
    preciousTokenId: nftId, // 1,
    nonce: (await deployedCollectiveContract.nonce()).toString()
  };

  const typedData = {
    types: {
      ExecuteProposal,
    },
    primaryType: "ExecuteProposal",
    domain,
    message
  };

  return typedData;
}

  async function fetchCrowdFundContractFromEvent(txHash, iface, topic) {
    let txReceipt = await deployer.provider.getTransactionReceipt(txHash)
    if(txReceipt == null) {
      let txData = await deployer.provider.getTransaction(txHash);
      txReceipt = await txData.wait();
    }
    const logs = await txReceipt.logs;
    const filtered = await logs.filter((log) => log.topics[0] == topic);
    const parsedEvent = await iface.parseLog(filtered[0])
    return parsedEvent.args.crowdfund;
  }

  async function fetchSuccessfulCollectiveContractFromEvent(txHash, iface, topic) {
    let txReceipt = await deployer.provider.getTransactionReceipt(txHash)
    if(txReceipt == null) {
      let txData = await deployer.provider.getTransaction(txHash);
      txReceipt = await txData.wait();
    }
    const logs = await txReceipt.logs;
    const filtered = await logs.filter((log) => log.topics[0] == topic);
    const parsedEvent = await iface.parseLog(filtered[0])
    return parsedEvent.args.collective;
  }
}

  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });