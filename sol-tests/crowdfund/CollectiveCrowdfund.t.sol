// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "contracts/crowdfund/CollectiveCrowdfundFactory.sol";
import "contracts/crowdfund/SingleNFTCrowdfund.sol";
import "contracts/crowdfund/CollectionNFTCrowdfund.sol";
import "contracts/collective/CollectiveFactory.sol";
import "contracts/collective/Collective.sol";
import "contracts/globals/Globals.sol";
import "contracts/globals/LibGlobals.sol";
import "contracts/utils/ReentrancyGuard.sol";
import "contracts/utils/LibAddress.sol";

import "forge-std/Test.sol";
import "../TestUtils.sol";
import "./TestERC721Vault.sol";

import {console} from "forge-std/console.sol";

contract CollectiveCrowdfundTest is Test, TestUtils {

    event TransferredToCollective(ICollectiveCrowdfund crowdfund, uint256 amount);
    event ClaimedUnusedContribution(address receiver, uint256 amount);

    Globals globals = new Globals(address(this));
    CollectiveCrowdfundFactory collectiveCrowdfundFactory = new CollectiveCrowdfundFactory(globals);
    SingleNFTCrowdfund singleNFTCrowdfund = new SingleNFTCrowdfund(globals);
    CollectionNFTCrowdfund collectionNFTCrowdfund = new CollectionNFTCrowdfund(globals);
    CollectiveFactory collectiveFactory = new CollectiveFactory(globals);
    Collective collective = new Collective(globals);
    address newCollectiveAddress;
    TestERC721Vault erc721Vault = new TestERC721Vault();
    uint256 tokenId = erc721Vault.mint();

    string defaultCollectiveTitleName = "Crowdfund";
    uint96 defaultFundraiseGoal = 100 ether; // 100 ETH
    uint40 defaultCrowdFundDuration = 30 * 24 * 60 * 60; //30 days
    uint96 defaultLowerLimitInvestment = 1e16; // Minimum investment amount selected by the host can be between 0.01ETH - 2.5% of fundraise goal
    uint96 defaultUpperLimitInvestment = 20 ether; // Maximum investment amount set at the backend is 20 ETH
    address defaultInitialContributor = 0xB9E1765eb11aF3B4C607f0D4e72b1A62F5DF302F;
    uint96 defaultInitialContribution = 2.5 ether; // Minimum 2.5%
    ICollectiveCrowdfund.GovernanceOpts defaultGovernanceOpts = ICollectiveCrowdfund.GovernanceOpts(
            604800, 86400, 8000);
    address openseaSeaport = address(erc721Vault);

    constructor() {
        globals.setAddress(LibGlobals.GLOBAL_SINGLE_BUY_CF_IMPL, address(singleNFTCrowdfund));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTION_BUY_CF_IMPL, address(collectionNFTCrowdfund));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_FACTORY, address(collectiveFactory));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_IMPL, address(collective));
        uint256 collectiveFactoryNonce = vm.getNonce(address(collectiveFactory));
        newCollectiveAddress = StdUtils.computeCreateAddress(address(collectiveFactory), collectiveFactoryNonce);
        globals.setAddress(LibGlobals.GLOBAL_FEE_RECIPIENT, address(0xe5ba98010c85e1386F5C06b9E947DFFF92553796));
        globals.setUint256(LibGlobals.GLOBAL_FEE_BPS, 250);
        globals.setAddress(LibGlobals.GLOBAL_OPENSEA_SEAPORT, openseaSeaport);
    }

    function createSingleNFTCollective(
        uint96 fundraiseGoal,
        uint96 lowerLimitInvestment
    ) private returns(SingleNFTCrowdfund scf){
        SingleNFTCrowdfund.SingleNFTCrowdfundOptions memory opts = SingleNFTCrowdfund.SingleNFTCrowdfundOptions({
            collectiveTitleName: defaultCollectiveTitleName,
            nftContractAddress: erc721Vault.token(),
            nftTokenId: tokenId,
            fundraiseGoal: fundraiseGoal,
            crowdFundDuration: defaultCrowdFundDuration,
            lowerLimitInvestment: lowerLimitInvestment, 
            initialContributor: defaultInitialContributor,
            governanceOpts: defaultGovernanceOpts
        });

        scf = collectiveCrowdfundFactory.createSingleNFTCrowdfund{ value: defaultInitialContribution }(
            opts
        );
        return scf;
    }

    function createCollectionNFTCollective(
        uint96 fundraiseGoal,
        uint96 lowerLimitInvestment
    ) private returns(CollectionNFTCrowdfund ccf){
        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
            collectiveTitleName: defaultCollectiveTitleName,
            nftContractAddress: erc721Vault.token(),
            fundraiseGoal: fundraiseGoal,
            crowdFundDuration: defaultCrowdFundDuration,
            lowerLimitInvestment: lowerLimitInvestment, 
            initialContributor: defaultInitialContributor,
            governanceOpts: defaultGovernanceOpts
        });

        ccf = collectiveCrowdfundFactory.createCollectionNFTCrowdfund{ value: defaultInitialContribution }(
            opts
        );
        return ccf;
    }

    function testOldContributorCanContributeBelowLowerLimitInvestment() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        vm.deal(defaultInitialContributor, defaultLowerLimitInvestment-1);
        // Contributor defaultInitialContributor is contributing again with less value than lower limit
        vm.prank(defaultInitialContributor);
        ccf.contribute{ value: defaultInitialContributor.balance }(defaultInitialContributor);
    }

    function testContributeAndDelegate_InitialContributor() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = defaultInitialContributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        ccf.contribute{ value: contributor.balance }(delegate);

        // Testing Contribution
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(contributor);
        assertEq(ethContributed, 3 ether);
        assertEq(defaultInitialContributor, ccf.delegationsByContributor(contributor));
    }

    function testContributeAndDelegate_Himself() external{
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 20 ether);
        vm.prank(contributor);
        scf.contribute{ value: contributor.balance }(delegate);

        // Testing Contribution
        (uint256 ethContributed, , ,) = scf.getContributorInfo(contributor);
        assertEq(ethContributed, 20 ether);
        assertEq(contributor, scf.delegationsByContributor(contributor));
    }

    function testContributeAndChangeDelegate() external{
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 5 ether);
        vm.prank(contributor);
        scf.contribute{ value: contributor.balance }(delegate);

        // Testing Contribution
        (uint256 ethContributed, , ,) = scf.getContributorInfo(contributor);
        assertEq(ethContributed, 5 ether);
        assertEq(scf.delegationsByContributor(contributor), contributor);

        // Changing Only Delegate
        address changeDelegate = defaultInitialContributor;
        vm.prank(contributor);
        scf.updateOnlyDelegate(changeDelegate);
        assertEq(scf.delegationsByContributor(contributor), changeDelegate);
    }

    function testDelegateOneAnother() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, 10 ether);
        vm.prank(contributor1);
        ccf.contribute{ value: 10 ether }(delegate1);
        // Contributing and delegate contributor1
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor1;
        vm.deal(contributor2, 2 ether);
        vm.prank(contributor2);
        ccf.contribute{ value: 2 ether }(delegate2);

        // Contri1 now decided to delegate Host 
        vm.prank(contributor1);
        ccf.updateOnlyDelegate(defaultInitialContributor);

        // Testing
        (uint256 ethContributed1, , ,) = ccf.getContributorInfo(contributor1);
        assertEq(ethContributed1, 10 ether);

        (uint256 ethContributed, , ,) = ccf.getContributorInfo(defaultInitialContributor);
        assertEq(ethContributed, defaultInitialContribution);
        assertEq(ccf.delegationsByContributor(defaultInitialContributor), defaultInitialContributor);

        (uint256 ethContributed2, , ,) = ccf.getContributorInfo(contributor2);
        assertEq(ethContributed2, 2 ether);
        assertEq(ccf.delegationsByContributor(contributor2), contributor1);

        assertEq(ccf.totalContributions(), defaultInitialContribution + 12 ether);
        assertEq(ccf.totalContributors(), 3);
    }

    function testClaimUnusedContributionAfterExpiration() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        scf.contribute{ value: 3 ether }(delegate);
        assertEq(contributor.balance, 0);
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Active);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Expired);
        (uint256 ethContributed, , ,) = scf.getContributorInfo(contributor);
        assertEq(ethContributed, 3 ether);
        vm.prank(contributor);
        scf.claimUnusedContribution(contributor);
        assertEq(contributor.balance, 3 ether);
    }

    function testClaimUnusedContributionAfterBuyingNFT() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, 20 ether);
        vm.prank(contributor1);
        scf.contribute{ value: 20 ether }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = defaultInitialContributor;
        vm.deal(contributor2, 20 ether);
        vm.prank(contributor2);
        scf.contribute{ value: 20 ether }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = defaultInitialContributor;
        vm.deal(contributor3, 20 ether);
        vm.prank(contributor3);
        scf.contribute{ value: 20 ether }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = defaultInitialContributor;
        vm.deal(contributor4, 20 ether);
        vm.prank(contributor4);
        scf.contribute{ value: 20 ether }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = defaultInitialContributor;
        vm.deal(contributor5, 20 ether);
        vm.prank(contributor5);
        scf.contribute{ value: 20 ether }(delegate5);
        // Contributing with contributor6
        address payable contributor6 = _randomAddress();
        address delegate6 = defaultInitialContributor;
        vm.deal(contributor6, 20 ether);
        vm.prank(contributor6);
        scf.contribute{ value: 20 ether }(delegate6);

        assertEq(scf.totalContributions(), 122.5 ether);

        // Buying the NFT at a low price than total contributions accepted. So, the person who contributed last will 
        // only contribute the left amount required.
        vm.prank(contributor5);
        ICollective collective_ = scf.buy(
            payable(openseaSeaport),
            100 ether,
            abi.encodeCall(erc721Vault.claim, (tokenId)));
        
        // Check the created collective address
        assertEq(address(collective_), newCollectiveAddress);
        // Check that NFT is now transferred to successful colelctive or not
        assertEq(erc721Vault.checkOwner(tokenId), address(collective_));

        // Check the values after buying
        // assertEq(address(0xB9E1765eb11aF3B4C607f0D4e72b1A62F5DF302F), collective_);
        assertEq(scf.settledPrice(), 102.5 ether);
        // Check the last person's contribution
        (uint256 ethContributed6, uint256 ethUsed6, uint256 ethOwed6, uint256 votingPower6) = scf.getContributorInfo(contributor6);
        assertEq(ethContributed6, 20 ether);
        assertEq(ethUsed6, 0);
        assertEq(ethOwed6, 20 ether);
        assertEq(votingPower6, 0);
        (uint256 ethContributed5, uint256 ethUsed5, uint256 ethOwed5, uint256 votingPower5) = scf.getContributorInfo(contributor5);
        assertEq(ethContributed5, 20 ether);
        assertEq(ethUsed5, 20 ether);
        assertEq(ethOwed5, 0);
        assertEq(votingPower5, 0);

        // contributor6 can claim all his contributed ETH back to his account.
        vm.prank(contributor6);
        scf.claimUnusedContribution(contributor6);
        assertEq(contributor6.balance, ethContributed6);
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Successful);

        // Contributors whose all ETH is used in buying NFT cannot claim.
        vm.prank(contributor5);
        vm.expectRevert(ICollectiveCrowdfund.NothingToClaim.selector);
        scf.claimUnusedContribution(contributor5);
        assertEq(contributor5.balance, ethOwed5);
        vm.prank(contributor4);
        vm.expectRevert(ICollectiveCrowdfund.NothingToClaim.selector);
        scf.claimUnusedContribution(contributor4);
    }

    function testTransferUnusedContributionAfterBuyingNFT() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, 20 ether);
        vm.prank(contributor1);
        scf.contribute{ value: 20 ether }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = defaultInitialContributor;
        vm.deal(contributor2, 20 ether);
        vm.prank(contributor2);
        scf.contribute{ value: 20 ether }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = defaultInitialContributor;
        vm.deal(contributor3, 20 ether);
        vm.prank(contributor3);
        scf.contribute{ value: 20 ether }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = defaultInitialContributor;
        vm.deal(contributor4, 20 ether);
        vm.prank(contributor4);
        scf.contribute{ value: 20 ether }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = defaultInitialContributor;
        vm.deal(contributor5, 20 ether);
        vm.prank(contributor5);
        scf.contribute{ value: 20 ether }(delegate5);
        // Contributing with contributor6
        address payable contributor6 = _randomAddress();
        address delegate6 = defaultInitialContributor;
        vm.deal(contributor6, 20 ether);
        vm.prank(contributor6);
        scf.contribute{ value: 20 ether }(delegate6);

        assertEq(scf.totalContributions(), 122.5 ether);

        // Buying the NFT at a low price than total contributions accepted. So, the person who contributed last will 
        // only contribute the left amount required.
        vm.prank(contributor6);
        ICollective collective_ = scf.buy(
            payable(openseaSeaport),
            97.5 ether,
            abi.encodeCall(erc721Vault.claim, (tokenId)));
        
        // Check the created collective address
        assertEq(address(collective_), newCollectiveAddress);
        // Check that NFT is now transferred to successful colelctive or not
        assertEq(erc721Vault.checkOwner(tokenId), address(collective_));

        // Check the values after buying
        // assertEq(address(0xB9E1765eb11aF3B4C607f0D4e72b1A62F5DF302F), collective_);
        assertEq(scf.settledPrice(), 99.9375 ether);
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Successful);
        // Check the last person's contribution
        (uint256 ethContributed6, uint256 ethUsed6, uint256 ethOwed6, uint256 votingPower6) = scf.getContributorInfo(contributor6);
        assertEq(ethContributed6, 20 ether);
        assertEq(ethUsed6, 0);
        assertEq(ethOwed6, 20 ether);
        assertEq(votingPower6, 0);
        (uint256 ethContributed5, uint256 ethUsed5, uint256 ethOwed5, uint256 votingPower5) = scf.getContributorInfo(contributor5);
        assertEq(ethContributed5, 20 ether);
        assertEq(ethUsed5, 17.4375 ether);
        assertEq(ethOwed5, 2.5625 ether);
        assertEq(votingPower5, 0);

        // Create a new Collective with lower goal to transfer the funds to....
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(80 ether, defaultLowerLimitInvestment);

        // contributor6 can transfer all his contributed ETH to new Crowdfund to the upper limit and then accept the rest in his account
        vm.prank(contributor6);
        vm.expectEmit(true, true, true, true);
        emit TransferredToCollective(ccf, 16 ether);
        vm.expectEmit(true, true, true, true);
        emit ClaimedUnusedContribution(contributor6, 4 ether);
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
        (uint256 ethTransferred6, , ,) = ccf.getContributorInfo(contributor6);
        assertEq(ethTransferred6, 16 ether);
        assertEq(contributor6.balance, 4 ether);

        // contributor5 can transfer whole amount to other active collective
        vm.prank(contributor5);
        vm.expectEmit(true, true, true, true);
        emit TransferredToCollective(ccf, ethOwed5);
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
        (uint256 ethTransferred5, , ,) = ccf.getContributorInfo(contributor5);
        assertEq(ethTransferred5, ethOwed5);

        // Contributors whose all ETH is used in buying NFT cannot transfer.
        vm.prank(contributor4);
        vm.expectRevert(ICollectiveCrowdfund.NothingToClaim.selector);
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
    }

    function testTransferUnusedContributionToAnotherCollectiveAfterExpiration() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        scf.contribute{ value: 3 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to....
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Transferring all unused ETH to New collective to pass this test
        vm.prank(contributor);
        vm.expectEmit(true, true, true, true);
        emit TransferredToCollective(ccf, 3 ether);
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(contributor);
        assertEq(ethContributed, 3 ether);
    }

    function testTransferUnusedContributionToAnotherCollectiveHavingLessUpperLimit() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 20 ether);
        vm.prank(contributor);
        scf.contribute{ value: 20 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to.... And setting less upper limit to pass this test
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(80 ether, defaultLowerLimitInvestment);
        // Transferring all unused ETH to New collective to pass this test
        vm.prank(contributor);
        vm.expectEmit(true, true, true, true);
        emit TransferredToCollective(ccf, 16 ether);
        vm.expectEmit(true, true, true, true);
        emit ClaimedUnusedContribution(contributor, 4 ether);
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(contributor);
        assertEq(ethContributed, 16 ether);
        assertEq(contributor.balance, 4 ether);
    }

    function testOldContributorCanTransferUnusedContributionUptoLimitLeftAndClaimRest() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // defaultInitialContributor is contributing his max
        uint256 valueLeft = 20 ether-defaultInitialContribution;
        vm.deal(defaultInitialContributor, valueLeft);
        vm.prank(defaultInitialContributor);
        scf.contribute{ value: valueLeft }(defaultInitialContributor);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to.... Also created by defaultInitialContributor
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Transferring all unused ETH to New collective to pass this test
        vm.prank(defaultInitialContributor);
        vm.expectEmit(true, true, true, true);
        emit TransferredToCollective(ccf, valueLeft);
        vm.expectEmit(true, true, true, true);
        emit ClaimedUnusedContribution(defaultInitialContributor, defaultInitialContribution);
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(defaultInitialContributor);
        assertEq(ethContributed, 20 ether);
        assertEq(defaultInitialContributor.balance, defaultInitialContribution);
    }

    function testOldContributorCanTransferBelowLowerLimitOfNewCollective() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment-1);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        vm.deal(contributor, defaultLowerLimitInvestment-1);
        vm.prank(contributor);
        scf.contribute{ value: defaultLowerLimitInvestment-1 }(contributor);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to.... Also created by defaultInitialContributor
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        vm.deal(contributor, defaultLowerLimitInvestment);
        vm.prank(contributor);
        ccf.contribute{ value: defaultLowerLimitInvestment }(contributor);
        // Old Contributor is Transferring all unused ETH to New collective to pass this test
        vm.prank(contributor);
        vm.expectEmit(true, true, true, true);
        emit TransferredToCollective(ccf, defaultLowerLimitInvestment-1);
        scf.transferUnusedContribution(payable(address(ccf)), contributor);
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(contributor);
        assertEq(ethContributed, (2*defaultLowerLimitInvestment)-1);
    }

    function test_CannotTransferUnusedContributionToAnotherCollectiveBeforeExpiration() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        scf.contribute{ value: 3 ether }(delegate);
        // Create a new Collective to transfer the funds to....
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Transferring all unused ETH to New collective without expiration of collective to pass this test
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.WrongLifecycle.selector, ICollectiveCrowdfund.CrowdfundLifecycle.Active));
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
    }

    function test_CannotTransferUnusedContributionToAnotherCollectiveByNonContributor() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        scf.contribute{ value: 3 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to....
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Calling from a non-contributor to pass this test
        vm.prank(_randomAddress());
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.OnlyCollectiveContributor.selector));
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
    }

    function test_CannotAcceptContributionFromCrowdfundNotFromOurFactory() public {
        // Not creating this collective from our factory to pass this test
        SingleNFTCrowdfund scf = SingleNFTCrowdfund(
            payable(
                address(
                    new Proxy{ value: defaultInitialContribution }(
                        singleNFTCrowdfund,
                        abi.encodeCall(
                            SingleNFTCrowdfund.initialize,
                            SingleNFTCrowdfund.SingleNFTCrowdfundOptions({
                                collectiveTitleName: defaultCollectiveTitleName,
                                nftContractAddress: erc721Vault.token(),
                                nftTokenId: tokenId,
                                fundraiseGoal: defaultFundraiseGoal,
                                crowdFundDuration: defaultCrowdFundDuration,
                                lowerLimitInvestment: defaultLowerLimitInvestment, 
                                initialContributor: defaultInitialContributor,
                                governanceOpts: defaultGovernanceOpts
                            })
                        )
                    )
                )
            )
        );
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        scf.contribute{ value: 3 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to....
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Transferring all unused ETH to New collective to pass this test
        vm.deal(address(scf), defaultLowerLimitInvestment);
        vm.prank(address(scf));
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.InvalidCrowdfund.selector, address(scf)));
        ccf.acceptContributionFromCollective{value : defaultLowerLimitInvestment}(delegate, defaultInitialContributor);
    }

    function test_CannotTransferToCrowdfundNotFromOurFactory() public {
        // Create a new Collective 
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        ccf.contribute{ value: 3 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);

        // Not creating this collective from our factory to pass this test
        SingleNFTCrowdfund scf = SingleNFTCrowdfund(
            payable(
                address(
                    new Proxy{ value: defaultInitialContribution }(
                        singleNFTCrowdfund,
                        abi.encodeCall(
                            SingleNFTCrowdfund.initialize,
                            SingleNFTCrowdfund.SingleNFTCrowdfundOptions({
                                collectiveTitleName: defaultCollectiveTitleName,
                                nftContractAddress: erc721Vault.token(),
                                nftTokenId: tokenId,
                                fundraiseGoal: defaultFundraiseGoal,
                                crowdFundDuration: defaultCrowdFundDuration,
                                lowerLimitInvestment: defaultLowerLimitInvestment, 
                                initialContributor: defaultInitialContributor,
                                governanceOpts: defaultGovernanceOpts
                            })
                        )
                    )
                )
            )
        );
        // Transferring all unused ETH to New collective to pass this test
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.InvalidCrowdfund.selector, address(scf)));
        ccf.transferUnusedContribution(payable(address(scf)), defaultInitialContributor);
    }

    function test_CannotTransferToInactiveCrowdfund() public {
        // Create a new Collective 
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Create a new Collective
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);

        // Transferring all unused ETH to New collective which is Inactive now to pass this test
        vm.prank(defaultInitialContributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.InvalidCrowdfund.selector, address(scf)));
        ccf.transferUnusedContribution(payable(address(scf)), defaultInitialContributor);
    }

    function test_CannotClaimUnusedContributionByNonContributor() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        scf.contribute{ value: 3 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Claiming back the contributed ETH from wrong address to pass this test
        vm.prank(_randomAddress());
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.OnlyCollectiveContributor.selector));
        scf.claimUnusedContribution(contributor);
    }

    function test_CannotClaimAgainAfterSuccessfulClaim() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 20 ether);
        vm.prank(contributor);
        scf.contribute{ value: 20 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Claiming back the contributed ETH as crowdfund has expired.
        vm.prank(contributor);
        scf.claimUnusedContribution(contributor);
        assertEq(contributor.balance, 20 ether);
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.UnusedFundAlreadyClaimed.selector));
        scf.claimUnusedContribution(contributor);
    }

    function test_CannotClaimAfterSuccessfulTransferToAnotherCollective() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 20 ether);
        vm.prank(contributor);
        scf.contribute{ value: 20 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to.... And setting less upper limit to pass this test
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(80 ether, defaultLowerLimitInvestment);
        // Transferring all unused ETH to New collective to pass this test
        vm.prank(contributor);
        vm.expectEmit(true, true, true, true);
        emit TransferredToCollective(ccf, 16 ether);
        vm.expectEmit(true, true, true, true);
        emit ClaimedUnusedContribution(contributor, 4 ether);
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(contributor);
        assertEq(ethContributed, 16 ether);
        assertEq(contributor.balance, 4 ether);
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.UnusedFundAlreadyClaimed.selector));
        scf.claimUnusedContribution(contributor);
    }

    function test_CannotClaimUnusedContributionBeforeExpiration() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        scf.contribute{ value: 3 ether }(delegate);
        // Transferring all unused ETH without expiration of collective to pass this test
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.WrongLifecycle.selector, 
        ICollectiveCrowdfund.CrowdfundLifecycle.Active));
        scf.claimUnusedContribution(contributor);
    }

    function test_CannotTransferAgainAfterSuccessfulTransferToAnotherCollective() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 20 ether);
        vm.prank(contributor);
        scf.contribute{ value: 20 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to.... And setting less upper limit to pass this test
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(80 ether, defaultLowerLimitInvestment);
        // Transferring all unused ETH to New collective to pass this test
        vm.prank(contributor);
        vm.expectEmit(true, true, true, true);
        emit TransferredToCollective(ccf, 16 ether);
        vm.expectEmit(true, true, true, true);
        emit ClaimedUnusedContribution(contributor, 4 ether);
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(contributor);
        assertEq(ethContributed, 16 ether);
        assertEq(contributor.balance, 4 ether);
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.UnusedFundAlreadyClaimed.selector));
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
    }

    function test_CannotTransferIfLimitIsExceededInNewCollectiveButCanClaimBack() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        vm.deal(contributor, 2 ether);
        vm.prank(contributor);
        scf.contribute{ value: 2 ether }(contributor);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to.... And setting less upper limit to pass this test
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(100 ether, defaultLowerLimitInvestment);
        // Transferring the upperlimit from this contributor
        vm.deal(contributor, 20 ether);
        vm.prank(contributor);
        ccf.contribute{ value: 20 ether }(contributor);
        // Transferring all unused ETH to New collective to pass this test
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.TransferToCollectiveFailed.selector));
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
        vm.prank(contributor);
        scf.claimUnusedContribution(contributor);
        assertEq(contributor.balance, 2 ether);
    }

    function test_NewContributorCannotTransferLessThanLowerLimitOfNewCollective() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment-1);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        vm.deal(contributor, defaultLowerLimitInvestment-1);
        vm.prank(contributor);
        scf.contribute{ value: defaultLowerLimitInvestment-1 }(contributor);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to.... And setting less upper limit to pass this test
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Transferring lesser amount to New collective to pass this test
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.TransferToCollectiveFailed.selector));
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
    }

    function test_CannotTransferAgainAfterSuccessfulClaim() public {
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 20 ether);
        vm.prank(contributor);
        scf.contribute{ value: 20 ether }(delegate);
        // Setting block.timestamp to a time after expiration 
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        // Create a new Collective to transfer the funds to.... And setting less upper limit to pass this test
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Transferring all unused ETH to New collective to pass this test
        vm.prank(contributor);
        scf.claimUnusedContribution(contributor);
        assertEq(contributor.balance, 20 ether);
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.UnusedFundAlreadyClaimed.selector));
        scf.transferUnusedContribution(payable(address(ccf)), defaultInitialContributor);
    }

    function test_CannotContributeWithWrongDelegate() external{
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        // Any random delegate to pass this test
        address delegate = address(0);
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.InvalidDelegate.selector));
        scf.contribute{ value: contributor.balance }(delegate);
    }

    function test_CannotContributeFromItsOwnAddress() external{
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate from crowdfund address to pass this test
        vm.deal(address(scf), 3 ether);
        vm.prank(address(scf));
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.InvalidContributor.selector));
        scf.contribute{ value: 3 ether }(address(scf));
    }

    function test_CannotContributeFromZeroAddress() external{
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate from crowdfund address to pass this test
        vm.deal(address(0), 3 ether);
        vm.prank(address(0));
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.InvalidContributor.selector));
        scf.contribute{ value: 3 ether }(address(0));
    }

    function test_CannotContributeAfterExpiration() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 3 ether);
        vm.prank(contributor);
        // Setting block.timestamp to a time after expiration to pass this test
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.WrongLifecycle.selector, ICollectiveCrowdfund.CrowdfundLifecycle.Expired));
        ccf.contribute{ value: contributor.balance }(delegate);
    }

    function test_OldContributorCannotContributeZeroAmount() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contributor defaultInitialContributor is contributing again with 0 value to pass this test
        vm.prank(defaultInitialContributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.CannotAcceptZeroContribution.selector));
        ccf.contribute(defaultInitialContributor);
    }

    function test_NewContributorCannotContributeBelowLowerLimitInvestment() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        // Contributing less to pass this test
        vm.deal(contributor, defaultLowerLimitInvestment-1);
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.ContributionNotWithinLimit.selector, defaultLowerLimitInvestment,
        defaultUpperLimitInvestment));
        ccf.contribute{ value: contributor.balance }(delegate);
    }

    function test_NewContributorContributeAboveUpperLimitInvestment() external{
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        // Contributing more to pass this test
        vm.deal(contributor, defaultUpperLimitInvestment+1);
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.ContributionNotWithinLimit.selector, defaultLowerLimitInvestment,
        defaultUpperLimitInvestment));
        scf.contribute{ value: contributor.balance }(delegate);
    }

    function test_OldContributorCannotContributeAboveUpperLimitInvestment() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 25 ether);
        vm.prank(contributor);
        ccf.contribute{ value: 20 ether}(delegate);
        // Contributing more to pass this test
        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.ContributionNotWithinLimit.selector, defaultLowerLimitInvestment,
        defaultUpperLimitInvestment));
        ccf.contribute{ value: 5 ether}(delegate);
    }

    function test_CannotChangeDelegateByNonContributor() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 5 ether);
        vm.prank(contributor);
        ccf.contribute{ value: contributor.balance }(delegate);

        // Testing Contribution
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(contributor);
        assertEq(ethContributed, 5 ether);
        assertEq(ccf.delegationsByContributor(contributor), contributor);

        // Changing Only Delegate
        address changeDelegate = defaultInitialContributor;
        // Calling function from a non-contributor to pass this test
        vm.prank(_randomAddress());
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.OnlyCollectiveContributor.selector));
        ccf.updateOnlyDelegate(changeDelegate);
    }

    function test_CannotChangeDelegateToNonContributor() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate.
        address payable contributor = _randomAddress();
        address delegate = contributor;
        vm.deal(contributor, 5 ether);
        vm.prank(contributor);
        ccf.contribute{ value: contributor.balance }(delegate);

        // Testing Contribution
        (uint256 ethContributed, , ,) = ccf.getContributorInfo(contributor);
        assertEq(ethContributed, 5 ether);
        assertEq(ccf.delegationsByContributor(contributor), contributor);

        // Changing Only Delegate to a random address to pass this test
        address changeDelegate = _randomAddress();

        vm.prank(contributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.InvalidDelegate.selector));
        ccf.updateOnlyDelegate(changeDelegate);
    }

    function test_CannotSendETHToCrowdfundExternally() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        hoax(address(_randomAddress()), 1 ether);
        vm.expectRevert();
        payable(address(ccf)).transfer(1 ether);
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        hoax(address(_randomAddress()), 1 ether);
        vm.expectRevert();
        payable(address(scf)).transfer(1 ether);
    }

    function test_CannotReenterOnClaimingUnusedFund() external{
        CollectionNFTCrowdfund ccf = createCollectionNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Contribute and delegate through ReenteringContract
        ReenteringContractToClaim reenteringContract = new ReenteringContractToClaim(address(ccf));
        hoax(address(reenteringContract), 1 ether);
        ccf.contribute{ value: 1 ether }(address(reenteringContract));
        // This crowdfund is now expired
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        vm.prank(address(reenteringContract));
        vm.expectRevert(abi.encodeWithSelector(LibAddress.EthTransferFailed.selector, address(reenteringContract), 
        abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector)));
        ccf.claimUnusedContribution(payable(address(reenteringContract)));
    }

    function test_CannotReenterOnTransferringToAnotherCollective() external{
        SingleNFTCrowdfund scf = createSingleNFTCollective(defaultFundraiseGoal, defaultLowerLimitInvestment);
        // Transfer the funds from scf to new contract
        ReenteringContractToTransfer reenteringContract = new ReenteringContractToTransfer(address(scf), address(collectiveCrowdfundFactory));
        hoax(address(reenteringContract), 1 ether);
        scf.contribute{ value: 1 ether }(address(reenteringContract));
        // This crowdfund is now expired
        vm.warp(block.timestamp + defaultCrowdFundDuration);
        vm.prank(address(reenteringContract));
        vm.expectRevert(abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector));
        scf.transferUnusedContribution(payable(address(reenteringContract)), address(reenteringContract));
    }
}

contract ReenteringContractToClaim is Test {
    CollectionNFTCrowdfund public ccf;
    constructor(address _ccf){
        ccf = CollectionNFTCrowdfund(_ccf);
    }

    // Fallback is called when DepositFunds sends Ether to this contract.
    fallback() external payable {
        if (address(ccf).balance >= 1 ether) {
            ccf.claimUnusedContribution(payable(address(this)));
        }
    }
}

contract ReenteringContractToTransfer is Test {
    // Lifecycle of a crowdfund
    enum CrowdfundLifecycle {
        Invalid,
        Busy, // Temporary. mid-settlement state
        Active,
        Expired,
        Successful
    }

    SingleNFTCrowdfund public oldCrowdfund;
    CollectiveCrowdfundFactory public collectiveCrowdfundFactory;
    constructor(address _scf, address _factory){
        oldCrowdfund = SingleNFTCrowdfund(_scf);
        collectiveCrowdfundFactory = CollectiveCrowdfundFactory(_factory);
    }

    function factory() external view returns(address){
        return(address(collectiveCrowdfundFactory));
    }

    function getCrowdfundLifecycle() external view returns (CrowdfundLifecycle){
        return(CrowdfundLifecycle.Active);
    }

    function getContributorInfo(
        address contributor
    ) 
        external 
        view 
        returns(uint256 ethContributed, uint256 ethUsed, uint256 ethOwed, uint256 votingPower){
            return(0, 0, 0, 0);
        }

    function fundraiseGoal() external returns(uint96){
        return(100 ether);
    }

    function lowerLimitInvestment() external view returns(uint96){
        return(0 ether);
    }

    function acceptContributionFromCollective(address contributor, address delegate) external payable{
        if (address(oldCrowdfund).balance >= 1 ether) {
            oldCrowdfund.transferUnusedContribution(payable(address(this)), address(this));
        }
    }
}
