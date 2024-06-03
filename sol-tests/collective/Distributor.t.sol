// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import "forge-std/Test.sol";

// import "contracts/crowdfund/CollectiveCrowdfundFactory.sol";
// import "contracts/crowdfund/SingleNFTCrowdfund.sol";
// import "contracts/crowdfund/CollectionNFTCrowdfund.sol";
// import "contracts/collective/CollectiveFactory.sol";
// import "contracts/collective/Collective.sol";
// import "contracts/globals/Globals.sol";
// import "contracts/globals/LibGlobals.sol";
// import "../../contracts/collective/distribution/Distributor.sol";
// import "../../contracts/globals/Globals.sol";
// import "../../contracts/utils/Proxy.sol";
// import "../../contracts/utils/LibAddress.sol";
// import "../DummyERC20.sol";
// import "../DummyERC721.sol";
// import "../TestUtils.sol";
// import "../crowdfund/TestERC721Vault.sol";

// contract DistributorTest is Test, TestUtils {
//     Globals globals = new Globals(address(this));
//     CollectiveCrowdfundFactory collectiveCrowdfundFactory = new CollectiveCrowdfundFactory(globals);
//     SingleNFTCrowdfund singleNFTCrowdfund = new SingleNFTCrowdfund(globals);
//     CollectionNFTCrowdfund collectionNFTCrowdfund = new CollectionNFTCrowdfund(globals);
//     CollectiveFactory collectiveFactory = new CollectiveFactory(globals);
//     Collective collective = new Collective(globals);
//     address newCollectiveAddress;
//     TestERC721Vault erc721Vault = new TestERC721Vault();
//     uint256 tokenId_1 = erc721Vault.mint();
//     uint256 tokenId_2 = erc721Vault.mint();
//     Distributor distributor = new Distributor(globals);

//     address payable feeRecipient = payable(0xe5ba98010c85e1386F5C06b9E947DFFF92553796);
//     uint16 feeBps = 250;
//     address openseaSeaport = address(erc721Vault);

//     string defaultCollectiveTitleName = "Crowdfund";
//     uint96 defaultFundraiseGoal = 4100 ether; 
//     uint96 defaultCallValueToBuyNFT = 4000 ether;
//     uint40 defaultCrowdFundDuration = 30 * 24 * 60 * 60; //30 days
//     uint96 defaultLowerLimitInvestment = 1e16; // Minimum investment amount selected by the host can be between 0.01ETH - 2.5% of fundraise goal
//     uint96 defaultUpperLimitInvestment = 820 ether; // Maximum investment amount set at the backend is 20 ETH
//     address defaultInitialContributor = 0xB9E1765eb11aF3B4C607f0D4e72b1A62F5DF302F;
//     uint96 defaultInitialContribution = 102.5 ether; // Minimum 2.5% 
//     ICollectiveCrowdfund.GovernanceOpts defaultGovernanceOpts = ICollectiveCrowdfund.GovernanceOpts(
//             604800, 86400, 8000);

//     constructor() {
//         globals.setAddress(LibGlobals.GLOBAL_SINGLE_BUY_CF_IMPL, address(singleNFTCrowdfund));
//         globals.setAddress(LibGlobals.GLOBAL_COLLECTION_BUY_CF_IMPL, address(collectionNFTCrowdfund));
//         globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_FACTORY, address(collectiveFactory));
//         globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_IMPL, address(collective));
//         uint256 collectiveFactoryNonce = vm.getNonce(address(collectiveFactory));
//         newCollectiveAddress = StdUtils.computeCreateAddress(address(collectiveFactory), collectiveFactoryNonce);
//         globals.setAddress(LibGlobals.GLOBAL_DISTRIBUTOR, address(distributor));
//         globals.setAddress(LibGlobals.GLOBAL_FEE_RECIPIENT, feeRecipient);
//         globals.setUint256(LibGlobals.GLOBAL_FEE_BPS, feeBps);
//         globals.setAddress(LibGlobals.GLOBAL_VALIDSIGNER, address(0x73C6D4A841dAb46BF11F7eBa1E379cD087B95CE4));
//         globals.setAddress(LibGlobals.GLOBAL_OPENSEA_SEAPORT, openseaSeaport);
//     }

//     function createSingleNFTCollective(
//         uint96 fundraiseGoal,
//         uint96 lowerLimitInvestment
//     ) private returns(SingleNFTCrowdfund scf){
//         SingleNFTCrowdfund.SingleNFTCrowdfundOptions memory opts = SingleNFTCrowdfund.SingleNFTCrowdfundOptions({
//             collectiveTitleName: defaultCollectiveTitleName,
//             nftContractAddress: erc721Vault.token(),
//             nftTokenId: tokenId_2,
//             fundraiseGoal: fundraiseGoal,
//             crowdFundDuration: defaultCrowdFundDuration,
//             lowerLimitInvestment: lowerLimitInvestment, 
//             initialContributor: defaultInitialContributor,
//             governanceOpts: defaultGovernanceOpts
//         });

//         scf = collectiveCrowdfundFactory.createSingleNFTCrowdfund{ value: defaultUpperLimitInvestment }(
//             opts
//         );
//         return scf;
//     }

//     function createCollectionNFTCollective(
//         uint96 fundraiseGoal,
//         uint96 lowerLimitInvestment
//     ) private returns(CollectionNFTCrowdfund ccf){
//         CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
//             collectiveTitleName: defaultCollectiveTitleName,
//             nftContractAddress: erc721Vault.token(),
//             fundraiseGoal: fundraiseGoal,
//             crowdFundDuration: defaultCrowdFundDuration,
//             lowerLimitInvestment: lowerLimitInvestment, 
//             initialContributor: defaultInitialContributor,
//             governanceOpts: defaultGovernanceOpts
//         });

//         ccf = collectiveCrowdfundFactory.createCollectionNFTCrowdfund{ value: defaultUpperLimitInvestment }(
//             opts
//         );
//         return ccf;
//     }

//     function testBuyAndDistributeEarnings() public {
//         // Create a new Collective with lower goal to transfer the funds to....
//         CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
//         address payable contributor1 = _randomAddress();
//         hoax(contributor1, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor1);
//         // Contributing with contributor2
//         address payable contributor2 = _randomAddress();
//         hoax(contributor2, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor2);
//         // Contributing with contributor3
//         address payable contributor3 = _randomAddress();
//         hoax(contributor3, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor3);
//         // Contributing with contributor4
//         address payable contributor4 = _randomAddress();
//         hoax(contributor4, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor4);
        
//         assertEq(ccf.totalContributions(), defaultFundraiseGoal);

//         // Buying the NFT 
//         vm.prank(defaultInitialContributor);
//         ICollective collective_ = ccf.buy(
//             tokenId_1,
//             payable(openseaSeaport),
//             defaultCallValueToBuyNFT,
//             abi.encodeCall(erc721Vault.claim, (tokenId_1))
//         );
        
//         // Check the created collective address
//         assertEq(address(collective_), newCollectiveAddress);
//         // Check that NFT is now transferred to successful collective or not
//         assertEq(erc721Vault.checkOwner(tokenId_1), address(collective_));

//         // Check the values after buying
//         assertEq(ccf.settledPrice(), defaultFundraiseGoal);

//         // Check the default's contribution
//         (uint256 ethContributedI, uint256 ethUsedI, uint256 ethOwedI, uint256 votingPowerI) = 
//         ccf.getContributorInfo(defaultInitialContributor);
//         assertEq(ethContributedI, defaultUpperLimitInvestment);
//         assertEq(ethUsedI, defaultUpperLimitInvestment);
//         assertEq(ethOwedI, 0);
//         assertEq(votingPowerI, defaultUpperLimitInvestment);
//         assertEq(ccf.delegationsByContributor(defaultInitialContributor), defaultInitialContributor);

//         // Send some ETH to collective (as earnings)
//         vm.deal(address(collective_), defaultFundraiseGoal);   
        
//         ICollective[] memory collectiveAddresses = new ICollective[](1);
//         collectiveAddresses[0] = collective_;

//         assertEq((collective_.getClaimableAmountOfContributor(contributor4)), defaultUpperLimitInvestment);
//         assertEq((distributor.getClaimAmountOfContributorFromCollectives(collectiveAddresses, contributor4)), defaultUpperLimitInvestment);

//         // This will first send the fee to feeRecipient
//         // Call createDistributionAndClaim() for the first time and check:
//         // It should first create the distribution 
//         collective_.createDistributionAndClaim(defaultInitialContributor);
//         assertEq((address(defaultInitialContributor).balance), defaultUpperLimitInvestment);
//         assertEq((collective_.getClaimableAmountOfContributor(defaultInitialContributor)), 0);
        
//         // Check amount to be claimed after distribution is created
//         assertEq((collective_.getClaimableAmountOfContributor(contributor4)), defaultUpperLimitInvestment);
//         vm.prank(contributor4);
//         collective_.createDistributionAndClaim(contributor4);
//         assertEq((address(contributor4).balance), defaultUpperLimitInvestment);  
        
//         // Call batchClaim() after distribution has been created
//         vm.prank(contributor1);
//         distributor.batchClaim(collectiveAddresses);
//         assertEq((address(contributor1).balance), defaultUpperLimitInvestment);  
        
//         vm.prank(contributor2);
//         distributor.batchClaim(collectiveAddresses);
//         assertEq((address(contributor2).balance), defaultUpperLimitInvestment);  
        
//         assertEq((collective_.getClaimableAmountOfContributor(contributor3)), defaultUpperLimitInvestment);
//         vm.prank(contributor3);
//         distributor.batchClaim(collectiveAddresses);
//         assertEq((address(contributor3).balance), defaultUpperLimitInvestment);       

//         assertEq((distributor.getClaimAmountOfContributorFromCollectives(collectiveAddresses, contributor4)), 0);
//         assertEq((collective_.getClaimableAmountOfContributor(contributor4)), 0);

//         assertEq((address(distributor).balance), 0);
//         assertEq((distributor.getRemainingMemberSupply(collective_, 1)), 0);
//     }

//     function testClaimEarningsFromCollectives() public {
//         // Create a new Collective with lower goal to transfer the funds to....
//         CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
//         address payable contributor1 = _randomAddress();
//         hoax(contributor1, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor1);
//         // Contributing with contributor2
//         address payable contributor2 = _randomAddress();
//         hoax(contributor2, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor2);
//         // Contributing with contributor3
//         address payable contributor3 = _randomAddress();
//         hoax(contributor3, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor3);
//         // Contributing with contributor4
//         address payable contributor4 = _randomAddress();
//         hoax(contributor4, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor4);

//         vm.prank(defaultInitialContributor);
//         ICollective collection_Collective = ccf.buy(
//             tokenId_1,
//             payable(openseaSeaport),
//             defaultCallValueToBuyNFT,
//             abi.encodeCall(erc721Vault.claim, (tokenId_1))
//         );
//         // Send some ETH to collective (as earnings)
//         hoax(openseaSeaport, defaultFundraiseGoal);
//         (bool ok1, ) = payable(address(collection_Collective)).call{value: defaultFundraiseGoal}("");
//         require(ok1, "Failed");
//         // payable(address(collection_Collective)).transfer(defaultFundraiseGoal);

//         SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
//         hoax(contributor1, defaultUpperLimitInvestment);
//         scf.contribute{ value: defaultUpperLimitInvestment }(contributor1);
//         hoax(contributor2, defaultUpperLimitInvestment);
//         scf.contribute{ value: defaultUpperLimitInvestment }(contributor2);
//         hoax(contributor3, defaultUpperLimitInvestment);
//         scf.contribute{ value: defaultUpperLimitInvestment }(contributor3);
//         hoax(contributor4, defaultUpperLimitInvestment);
//         scf.contribute{ value: defaultUpperLimitInvestment }(contributor4);

//         vm.prank(contributor3);
//         ICollective single_Collective = scf.buy(
//             payable(openseaSeaport),
//             defaultCallValueToBuyNFT,
//             abi.encodeCall(erc721Vault.claim, (tokenId_2))
//         );
//         // Send some ETH to collective (as earnings)
//         hoax(openseaSeaport, defaultFundraiseGoal);
//         (bool ok2, ) = payable(address(single_Collective)).call{value: defaultFundraiseGoal}("");
//         require(ok2, "Failed");
//         // payable(address(single_Collective)).transfer(defaultFundraiseGoal);
        
//         ICollective[] memory collectiveAddresses = new ICollective[](2);
//         collectiveAddresses[0] = collection_Collective;
//         collectiveAddresses[1] = single_Collective;

//         assertEq((single_Collective.getClaimableAmountOfContributor(contributor4)), defaultUpperLimitInvestment);
//         assertEq((distributor.getClaimAmountOfContributorFromCollectives(collectiveAddresses, contributor4)), 
//         defaultUpperLimitInvestment*2);
        
//         // Call batchClaim() and create distributions for both collectives 
//         vm.prank(contributor1);
//         distributor.batchClaim(collectiveAddresses);
//         assertEq((address(contributor1).balance), defaultUpperLimitInvestment*2);  

//         assertEq((address(distributor).balance), ((defaultFundraiseGoal-defaultUpperLimitInvestment)*2));
//         assertEq((distributor.getRemainingMemberSupply(single_Collective, 1)), 
//         defaultFundraiseGoal-defaultUpperLimitInvestment);
//     }

//     function test_CannotCallBatchClaimByNonContributor() public {
//         CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
//         address payable contributor1 = _randomAddress();
//         hoax(contributor1, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor1);
//         // Contributing with contributor2
//         address payable contributor2 = _randomAddress();
//         hoax(contributor2, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor2);
//         // Contributing with contributor3
//         address payable contributor3 = _randomAddress();
//         hoax(contributor3, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor3);
//         // Contributing with contributor4
//         address payable contributor4 = _randomAddress();
//         hoax(contributor4, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor4);

//         // Buying the NFT
//         vm.prank(defaultInitialContributor);
//         ICollective collective_ = ccf.buy(
//             tokenId_1,
//             payable(openseaSeaport),
//             defaultCallValueToBuyNFT,
//             abi.encodeCall(erc721Vault.claim, (tokenId_1))
//         );

//         // Send some ETH to collective (as earnings)
//         vm.deal(address(collective_), defaultFundraiseGoal);

//         ICollective[] memory collectiveAddresses = new ICollective[](1);
//         collectiveAddresses[0] = collective_;
        
//         vm.prank(address(this));
//         vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.OnlyCollectiveContributor.selector));
//         distributor.batchClaim(collectiveAddresses);
//     }

//     function test_CannotClaimEarningAgain() public {
//         CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
//         address payable contributor1 = _randomAddress();
//         hoax(contributor1, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor1);
//         // Contributing with contributor2
//         address payable contributor2 = _randomAddress();
//         hoax(contributor2, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor2);
//         // Contributing with contributor3
//         address payable contributor3 = _randomAddress();
//         hoax(contributor3, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor3);
//         // Contributing with contributor4
//         address payable contributor4 = _randomAddress();
//         hoax(contributor4, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor4);

//         // Buying the NFT at a low price than total contributions accepted. So, the person who contributed last will 
//         // only contribute the left amount required.
//         vm.prank(defaultInitialContributor);
//         ICollective collective_ = ccf.buy(
//             tokenId_1,
//             payable(openseaSeaport),
//             defaultCallValueToBuyNFT,
//             abi.encodeCall(erc721Vault.claim, (tokenId_1))
//         );

//         // Send some ETH to collective (as earnings)
//         vm.deal(address(collective_), defaultFundraiseGoal);

//         ICollective[] memory collectiveAddresses = new ICollective[](1);
//         collectiveAddresses[0] = collective_;

//         collective_.createDistributionAndClaim(contributor4);
//         assertEq((address(contributor4).balance), defaultUpperLimitInvestment);  
//         assertEq(address(collective_).balance, 0);
//         assertEq(address(distributor).balance, (defaultFundraiseGoal - defaultUpperLimitInvestment));
        
//         // Claiming again to pass this test
//         // From batchClaim()
//         vm.prank(contributor4);
//         distributor.batchClaim(collectiveAddresses);
//         assertEq((address(contributor4).balance), defaultUpperLimitInvestment);  
//         // From createDistributionAndClaim()
//         collective_.createDistributionAndClaim(contributor4);
//         assertEq((address(contributor4).balance), defaultUpperLimitInvestment);  
//         // From claim()
//         IDistributor.DistributionInfo memory disInfo = IDistributor.DistributionInfo({
//             tokenType: IDistributor.TokenType.Native,
//             distributionId: 1,
//             token: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
//             collective: collective_,
//             memberSupply: defaultFundraiseGoal,
//             totalShares: defaultFundraiseGoal
//         });
//         vm.prank(address(collective_));
//         vm.expectRevert(abi.encodeWithSelector(Distributor.DistributionAlreadyClaimed.selector, 
//         1, contributor4));
//         distributor.claim(disInfo, contributor4);
//     }

//     function test_CannotClaimZeroEarnings() public {
//         // Create a new Collective with lower goal to transfer the funds to....
//         CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
//         address payable contributor1 = _randomAddress();
//         hoax(contributor1, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor1);
//         // Contributing with contributor2
//         address payable contributor2 = _randomAddress();
//         hoax(contributor2, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor2);
//         // Contributing with contributor3
//         address payable contributor3 = _randomAddress();
//         hoax(contributor3, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor3);
//         // Contributing with contributor4
//         address payable contributor4 = _randomAddress();
//         hoax(contributor4, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor4);

//         // Buying the NFT at a low price than total contributions accepted. So, the person who contributed last will 
//         // only contribute the left amount required.
//         vm.prank(defaultInitialContributor);
//         ICollective collective_ = ccf.buy(
//             tokenId_1,
//             payable(openseaSeaport),
//             defaultCallValueToBuyNFT,
//             abi.encodeCall(erc721Vault.claim, (tokenId_1))
//         );

//         // Not sending any ETH to collective to pass this test
//         vm.prank(address(this));
//         vm.expectRevert(abi.encodeWithSelector(ICollective.CannotClaimZeroEarnings.selector, 0));
//         collective_.createDistributionAndClaim(contributor3);
//     }

//     function test_OnlyCollectiveCanCallDistributorClaim() public {
//         IDistributor.DistributionInfo memory disInfo = IDistributor.DistributionInfo({
//             tokenType: IDistributor.TokenType.Native,
//             distributionId: 1,
//             token: address(0),
//             collective: collective,
//             memberSupply: 0,
//             totalShares: 0
//         });
//         // Calling with address of this contract to pass this test
//         vm.expectRevert(Distributor.OnlyCollectiveCanCall.selector);
//         distributor.claim(disInfo, _randomAddress());
//     }

//     function test_CannotCallDistributorClaimWithInvalidInfo() public {
//         Collective.CollectiveInitData memory initData;
//         Collective _collective = Collective(
//             payable(address(new Proxy(collective, abi.encodeCall(Collective.initialize, initData))))
//         );
//         IDistributor.DistributionInfo memory disInfo = IDistributor.DistributionInfo({
//             tokenType: IDistributor.TokenType.Native,
//             distributionId: 1,
//             token: address(0),
//             collective: _collective,
//             memberSupply: 0,
//             totalShares: 0
//         });
//         // Calling with collective address but wrong info to pass this test
//         vm.prank(address(_collective));
//         vm.expectRevert(abi.encodeWithSelector(Distributor.InvalidDistributionInfo.selector, disInfo));
//         distributor.claim(disInfo, _randomAddress());
//     }

//     function test_OnlyCollectiveCanCallCreateNativeDistribution() public {
//         // Calling from this contract to pass this test
//         vm.expectRevert(Distributor.OnlyCollectiveCanCall.selector);
//         distributor.createNativeDistribution(collective);
//     }

//     function test_CannotCallCreateNativeDistributionWithoutSupplyingAmount() public {
//         Collective.CollectiveInitData memory initData;
//         Collective _collective = Collective(
//             payable(address(new Proxy(collective, abi.encodeCall(Collective.initialize, initData))))
//         );
//         // Calling with collective address but wrong info to pass this test
//         vm.prank(address(_collective));
//         // Not supplying ETH to pass this test
//         vm.expectRevert(abi.encodeWithSelector(Distributor.InvalidDistributionSupply.selector, 0));
//         distributor.createNativeDistribution(_collective);
//     }

//     function test_CannotReenterOnClaimDistribution() public {
//         CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
//         address payable contributor1 = _randomAddress();
//         hoax(contributor1, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor1);
//         // Contributing with contributor2
//         address payable contributor2 = _randomAddress();
//         hoax(contributor2, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor2);
//         // Contributing with contributor3
//         address payable contributor3 = _randomAddress();
//         hoax(contributor3, defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor3);
//         // Contributing with Reentering contract
//         ReenteringContract reenteringContract = new ReenteringContract(address(distributor));
//         hoax(address(reenteringContract), defaultUpperLimitInvestment);
//         ccf.contribute{ value: defaultUpperLimitInvestment }(contributor3);

//         // Buying the NFT at a low price than total contributions accepted. So, the person who contributed last will 
//         // only contribute the left amount required.
//         vm.prank(defaultInitialContributor);
//         ICollective collective_ = ccf.buy(
//             tokenId_1,
//             payable(openseaSeaport),
//             defaultCallValueToBuyNFT,
//             abi.encodeCall(erc721Vault.claim, (tokenId_1))
//         );

//         // Send some ETH to collective (as earnings)
//         vm.deal(address(collective_), defaultFundraiseGoal);

//         // Create distribution first
//         collective_.createDistributionAndClaim(contributor3);
//         assertEq((address(contributor3).balance), defaultUpperLimitInvestment); 

//         // Set collective address in ReenteringContract
//         reenteringContract.setCollective(address(collective_));

//         // Calling claim() for reenteringContract to pass this test
//         IDistributor.DistributionInfo memory disInfo = IDistributor.DistributionInfo({
//             tokenType: IDistributor.TokenType.Native,
//             distributionId: 1,
//             token: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
//             collective: collective_,
//             memberSupply: defaultFundraiseGoal,
//             totalShares: defaultFundraiseGoal
//         });
//         vm.prank(address(reenteringContract));
//         vm.expectRevert(abi.encodeWithSelector(LibAddress.EthTransferFailed.selector, address(reenteringContract), 
//         abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector)));
//         collective_.createDistributionAndClaim(payable(address(reenteringContract)));
//         vm.prank(address(collective_));
//         distributor.claim(disInfo, address(reenteringContract));
//         // Any contract who is a contributor can only claim distribution once
//         // Maybe he is calling again and again to claim more funds.. but he will
//         assertEq((address(reenteringContract).balance), defaultUpperLimitInvestment);
//     }
// }

// contract ReenteringContract is Test {
//     ICollective public collective;
//     Distributor public distributor;

//     constructor (address _distributor){
//         distributor = Distributor(_distributor);
//     }
//     function setCollective(address _collective) external{
//         collective = ICollective(_collective);
//     }

//     // Fallback is called when DepositFunds sends Ether to this contract.
//     fallback() external payable {
//         if (address(distributor).balance >= 1 ether) {
//             collective.createDistributionAndClaim(payable(address(this)));
//         }
//     }
// }