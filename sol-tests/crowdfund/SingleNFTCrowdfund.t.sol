// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "contracts/crowdfund/SingleNFTCrowdfund.sol";
import "contracts/collective/CollectiveFactory.sol";
import "contracts/collective/Collective.sol";
import "contracts/globals/Globals.sol";
import "contracts/globals/LibGlobals.sol";
import "contracts/utils/Proxy.sol";

import "forge-std/Test.sol";
import "../TestUtils.sol";
import "./TestERC721Vault.sol";
import "../DummyERC721.sol";

import {console} from "forge-std/console.sol";

contract SingleNFTCrowdfundTest is Test, TestUtils {

    event FeeTransferred(
        address feeRecipient,
        uint256 fee
    );
    event crowdfundExpired();

    string defaultCollectiveTitleName = "SingleNFTBuyCrowdfund";
    uint96 defaultFundraiseGoal = 4100 ether; 
    uint96 defaultCallValueToBuyNFT = 4000 ether;
    uint40 defaultCrowdFundDuration = 30 * 24 * 60 * 60; //30 days
    uint96 defaultLowerLimitInvestment = 1e16; // Minimum investment amount selected by the host can be between 0.01ETH - 2.5% of fundraise goal
    uint96 defaultUpperLimitInvestment = 820 ether; // Maximum investment amount set at the backend is 20 ETH
    address defaultInitialContributor = 0xB9E1765eb11aF3B4C607f0D4e72b1A62F5DF302F;
    uint96 defaultInitialContribution = 102.5 ether; // Minimum 2.5% 
    ICollectiveCrowdfund.GovernanceOpts defaultGovernanceOpts = ICollectiveCrowdfund.GovernanceOpts(
            86400, 259200, 5000);

    Globals globals = new Globals(address(this));
    CollectiveFactory collectiveFactory = new CollectiveFactory(globals);
    Collective collective = new Collective(globals);
    address newCollectiveAddress;
    TestERC721Vault erc721Vault = new TestERC721Vault();
    uint256 tokenId = erc721Vault.mint();
    SingleNFTCrowdfund singleNFTCrowdfundImpl;
    SingleNFTCrowdfund scf;

    address payable feeRecipient = payable(0xe5ba98010c85e1386F5C06b9E947DFFF92553796);
    uint16 feeBps = 250;
    address openseaSeaport = address(erc721Vault);

    constructor() {
        singleNFTCrowdfundImpl = new SingleNFTCrowdfund(globals);
        globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_FACTORY, address(collectiveFactory));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_IMPL, address(collective));
        uint256 collectiveFactoryNonce = vm.getNonce(address(collectiveFactory));
        newCollectiveAddress = StdUtils.computeCreateAddress(address(collectiveFactory), collectiveFactoryNonce);
        globals.setAddress(LibGlobals.GLOBAL_FEE_RECIPIENT, feeRecipient);
        globals.setUint256(LibGlobals.GLOBAL_FEE_BPS, feeBps);
        globals.setAddress(LibGlobals.GLOBAL_OPENSEA_SEAPORT, openseaSeaport);
    }

    function setUp() public{
        scf = SingleNFTCrowdfund(
            payable(
                address(
                    new Proxy{ value: defaultInitialContribution }(
                        singleNFTCrowdfundImpl,
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
    }

    function testShouldBeEligibleToBuyNFTIfGoalAchieved() external{
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        // Testing
        (uint256 ethContributed1, , ,) = scf.getContributorInfo(contributor1);
        assertEq(ethContributed1, defaultUpperLimitInvestment);
        assertEq(scf.delegationsByContributor(contributor1), contributor1);

        (uint256 ethContributedInitial, , ,) = scf.getContributorInfo(defaultInitialContributor);
        assertEq(ethContributedInitial, defaultInitialContribution);
        assertEq(scf.delegationsByContributor(defaultInitialContributor), defaultInitialContributor);

        (uint256 ethContributed2, , ,) = scf.getContributorInfo(contributor2);
        assertEq(ethContributed2, defaultUpperLimitInvestment);
        assertEq(scf.delegationsByContributor(contributor2), delegate2);

        (uint256 ethContributed3, , ,) = scf.getContributorInfo(contributor3);
        assertEq(ethContributed3, defaultUpperLimitInvestment);
        assertEq(scf.delegationsByContributor(contributor3), delegate3);

        (uint256 ethContributed4, , ,) = scf.getContributorInfo(contributor4);
        assertEq(ethContributed4, defaultUpperLimitInvestment);
        assertEq(scf.delegationsByContributor(contributor4), delegate4);

        (uint256 ethContributed5, , ,) = scf.getContributorInfo(contributor5);
        assertEq(ethContributed5, defaultUpperLimitInvestment);
        assertEq(scf.delegationsByContributor(contributor5), delegate5);

        assertEq(scf.totalContributions(), defaultFundraiseGoal + defaultInitialContribution);
        assertEq(scf.totalContributors(), 6);
    }

    function testBuyAlsoTransfersFeeToMyMetaFi() external{
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment/2 }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing again with contributor1 with another delegate
        address delegate1_ = contributor1;
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment/2 }(delegate1_);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), defaultFundraiseGoal + defaultInitialContribution);
        assertEq(scf.totalContributors(), 6);
        
        // Buying the NFT 
        vm.prank(defaultInitialContributor);
        vm.expectEmit(true, true, true, true);
        emit FeeTransferred(feeRecipient, 100 ether);
        ICollective collective_ = scf.buy(
            payable(openseaSeaport),
            defaultCallValueToBuyNFT,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
        
        // Check the created collective address
        assertEq(address(collective_), newCollectiveAddress);
        // Check that NFT is now transferred to Successful colllective or not
        assertEq(erc721Vault.checkOwner(tokenId), address(collective_));
        // Check the balance left in crowdfund contract
        assertEq((address(scf).balance), 102.5 ether);

        // Check the last person's contribution used in buying NFT
        (uint256 ethContributed, uint256 ethUsed, uint256 ethOwed, uint256 votingPower) = 
        scf.getContributorInfo(contributor5);
        assertEq(ethContributed, defaultUpperLimitInvestment);
        assertEq(ethUsed, 717.5 ether);
        assertEq(ethOwed, 102.5 ether);
        assertEq(votingPower, 717.5 ether);
        assertEq(scf.delegationsByContributor(contributor5), delegate5);
        // contributor5 can claim his left ETH back to his account.
        vm.prank(contributor5);
        scf.claimUnusedContribution(contributor5);
        assertEq(contributor5.balance, ethOwed);
        // Check the balance left in crowdfund contract
        assertEq((address(scf).balance), 0);
    }

    function testCanOnlyBuyNFTOfValueLeftAfterFee() external{
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment/2 }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing again with contributor1 with another delegate
        address delegate1_ = contributor1;
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment/2 }(delegate1_);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, 717.5 ether);
        vm.prank(contributor5);
        scf.contribute{ value: 717.5 ether}(delegate5);

        assertEq(scf.totalContributions(), defaultFundraiseGoal);
        assertEq(scf.totalContributors(), 6);
        
        // Buying the NFT of value Total contri - Fee {4100-(2.5% of 4000) = 4000}
        vm.prank(defaultInitialContributor);
        vm.expectEmit(true, true, true, true);
        emit FeeTransferred(feeRecipient, 100 ether);
        ICollective collective_ = scf.buy(
            payable(openseaSeaport),
            defaultCallValueToBuyNFT,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
        
        // Check the created collective address
        assertEq(address(collective_), newCollectiveAddress);
        // Check that NFT is now transferred to Successful colllective or not
        assertEq(erc721Vault.checkOwner(tokenId), address(collective_));
        // Check the balance left in crowdfund contract
        assertEq((address(scf).balance), 0);
    }

    function testCanBuyWithinFourteenDaysAfterExpirationIfGoalAchieved() external{
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment/2 }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing again with contributor1 with another delegate
        address delegate1_ = contributor1;
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment/2 }(delegate1_);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), defaultFundraiseGoal + defaultInitialContribution);
        assertEq(scf.totalContributors(), 6);

        // Setting block.timestamp to a time after expiration to pass this test
        vm.warp(block.timestamp + defaultCrowdFundDuration);

        // Setting block.timestamp to a time 14 days after expiration to pass this test
        vm.warp(block.timestamp + 1209600);
        
        // Buying the NFT 
        vm.prank(defaultInitialContributor);
        // vm.expectEmit();
        // emit ICollectiveFactory.CollectiveCreated();
        ICollective collective_ = scf.buy(
            payable(openseaSeaport),
            defaultCallValueToBuyNFT,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
        
        // Check the created collective address
        assertEq(address(collective_), newCollectiveAddress);
        // Check that NFT is now transferred to Successful colllective or not
        assertEq(erc721Vault.checkOwner(tokenId), address(collective_));
    }

    function testBuyNFTInLessAndRefundOthers() public {
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), defaultFundraiseGoal + defaultInitialContribution);

        // Buying the NFT at a low price than total contributions accepted. So, the person who contributed last will 
        // only contribute the left amount required.
        vm.prank(defaultInitialContributor);
        ICollective collective_ = scf.buy(
            payable(openseaSeaport),
            2000 ether,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
        
        // Check the created collective address
        assertEq(address(collective_), newCollectiveAddress);
        // Check that NFT is now transferred to Successful colelctive or not
        assertEq(erc721Vault.checkOwner(tokenId), address(collective_));

        // Check the values after buying
        assertEq(scf.settledPrice(), 2050 ether);
        
        // Check the third last person's contribution used in buying NFT
        (uint256 ethContributed3, uint256 ethUsed3, uint256 ethOwed3, uint256 votingPower3) = 
        scf.getContributorInfo(contributor3);
        assertEq(ethContributed3, defaultUpperLimitInvestment);
        assertEq(ethUsed3, 307.5 ether);
        assertEq(ethOwed3, 512.5 ether);
        assertEq(votingPower3, 307.5 ether);
        assertEq(scf.delegationsByContributor(contributor3), delegate3);
        // Check the third last person's contribution used in buying NFT
        uint256 ethUsed3_ = collective_.getDistributionShareOf(contributor3);
        assertEq(ethUsed3_, ethUsed3);
        // contributor3 can claim his left ETH back to his account.
        vm.prank(contributor3);
        scf.claimUnusedContribution(contributor3);
        assertEq(contributor3.balance, ethOwed3);

        // Check the second last person's contribution used in buying NFT
        (uint256 ethContributed4, uint256 ethUsed4, uint256 ethOwed4, uint256 votingPower4) = 
        scf.getContributorInfo(contributor4);
        assertEq(ethContributed4, defaultUpperLimitInvestment);
        assertEq(ethUsed4, 0 ether);
        assertEq(ethOwed4, 820 ether);
        assertEq(votingPower4, 0 ether);
        assertEq(scf.delegationsByContributor(contributor4), delegate4);
        // Check the second last person's contribution used in buying NFT
        uint256 ethUsed4_ = collective_.getDistributionShareOf(contributor4);
        assertEq(ethUsed4_, ethUsed4);
        // contributor4 can claim his left ETH back to his account.
        vm.prank(contributor4);
        scf.claimUnusedContribution(contributor4);
        assertEq(contributor4.balance, ethOwed4);

        // Check the last person's contribution used in buying NFT
        (uint256 ethContributed, uint256 ethUsed, uint256 ethOwed, uint256 votingPower) = 
        scf.getContributorInfo(contributor5);
        assertEq(ethContributed, defaultUpperLimitInvestment);
        assertEq(ethUsed, 0 ether);
        assertEq(ethOwed, 820 ether);
        assertEq(votingPower, 0 ether);
        assertEq(scf.delegationsByContributor(contributor5), delegate5);
        // Check the last person's contribution used in buying NFT
        uint256 ethUsed5 = collective_.getDistributionShareOf(contributor5);
        assertEq(ethUsed5, 0 ether);
        // contributor5 can claim his left ETH back to his account.
        vm.prank(contributor5);
        scf.claimUnusedContribution(contributor5);
        assertEq(contributor5.balance, ethOwed);
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Successful);
    }

    function testBuyNFTAndCheckVotingPower() public {
        // Contribute with 1 and delegate himself
        address payable contributor1 = _randomAddress();
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment/2 }(contributor1);
        // Contribute with 2 and delegate initial
        address payable contributor2 = _randomAddress();
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: 82 ether }(defaultInitialContributor); // Contributing only 10% first
        // Contributing again with 1 and delegating to 2
        vm.prank(contributor1);
        scf.contribute{ value: 328 ether }(contributor2);
        // Contributing again with 1 and delegating himself
        vm.prank(contributor1);
        scf.contribute{ value: 82 ether }(contributor1);
        // Contributing with 3 and delegating contributor1 to check his total delegated voting power now
        address payable contributor3 = _randomAddress();
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: 492 ether }(contributor1);
        // Contributing with 3 and delegating initial
        vm.prank(contributor3);
        scf.contribute{ value: 123 ether }(defaultInitialContributor);
        // Contributing with 4 and delegating himself
        address payable contributor4 = _randomAddress();
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: 164 ether }(contributor4);
        // Again contributing 
        vm.prank(contributor4);
        scf.contribute{ value: 656 ether }(contributor4);
        // Can delegate his intrinsic powers to initial
        vm.prank(contributor4);
        scf.updateOnlyDelegate(defaultInitialContributor);
        // Contributing with 3 and delegating initial again
        vm.prank(contributor3);
        scf.contribute{ value: 205 ether}(defaultInitialContributor);

        (uint256 ethContributedI, uint256 ethUsedI, uint256 ethOwedI, uint256 votingPowerI) = 
        scf.getContributorInfo(defaultInitialContributor);
        assertEq(ethContributedI, defaultInitialContribution);
        assertEq(ethUsedI, 0);
        assertEq(ethOwedI, 0);
        assertEq(votingPowerI, 0);
        assertEq(scf.delegationsByContributor(defaultInitialContributor), defaultInitialContributor);
        assertEq(scf.totalContributions(), 2644.5 ether);

        // Contribute with 5 and delegate himself
        address payable contributor5 = _randomAddress();
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(contributor5);
        // Contribute with 6 and delegate himself
        address payable contributor6 = _randomAddress();
        vm.deal(contributor6, defaultUpperLimitInvestment);
        vm.prank(contributor6);
        scf.contribute{ value: defaultUpperLimitInvestment }(contributor6);
        // Contribute with 6 and delegate himself
        address payable contributor7 = _randomAddress();
        vm.deal(contributor7, defaultUpperLimitInvestment);
        vm.prank(contributor7);
        scf.contribute{ value: 225.5 ether }(contributor7);
        // Contribute with 2 and delegate himself
        vm.prank(contributor2);
        scf.contribute{ value: 738 ether }(contributor2);
        // Contribute with 8 and delegate himself
        address payable contributor8 = _randomAddress();
        vm.deal(contributor8, defaultUpperLimitInvestment);
        vm.prank(contributor8);
        scf.contribute{ value: 82 ether }(defaultInitialContributor);

        assertEq(scf.totalContributions(), 5330 ether);

        // Buying the NFT at a low price than total contributions accepted. So, the person who contributed last will 
        // only contribute the left amount required.
        vm.prank(defaultInitialContributor);
        ICollective collective_ = scf.buy(
            payable(openseaSeaport),
            4600 ether,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
        
        // Check the created collective address
        assertEq(address(collective_), newCollectiveAddress);
        // Check that NFT is now transferred to Successful collective or not
        assertEq(erc721Vault.checkOwner(tokenId), address(collective_));
        // Check the values after buying
        assertEq(scf.settledPrice(), 4715 ether);

        (uint256 ethContributedIF, uint256 ethUsedIF, uint256 ethOwedIF, uint256 votingPowerIF) = 
        scf.getContributorInfo(defaultInitialContributor);
        assertEq(ethContributedIF, defaultInitialContribution);
        assertEq(ethUsedIF, defaultInitialContribution);
        assertEq(ethOwedIF, 0);
        assertEq(votingPowerIF, defaultInitialContribution);
        assertEq(scf.delegationsByContributor(defaultInitialContributor), defaultInitialContributor);
        // console.logUint(votingPowerIF + delegatedByContributorsIF);

        (uint256 ethContributed1, uint256 ethUsed1, uint256 ethOwed1, uint256 votingPower1) = 
        scf.getContributorInfo(contributor1);
        assertEq(ethContributed1, defaultUpperLimitInvestment);
        assertEq(ethUsed1, defaultUpperLimitInvestment);
        assertEq(ethOwed1, 0);
        assertEq(votingPower1, defaultUpperLimitInvestment);
        assertEq(scf.delegationsByContributor(contributor1), contributor1);
        // console.logUint(votingPower1 + delegatedByContributors1);

        (uint256 ethContributed2, uint256 ethUsed2, uint256 ethOwed2, uint256 votingPower2) = 
        scf.getContributorInfo(contributor2);
        assertEq(ethContributed2, defaultUpperLimitInvestment);
        assertEq(ethUsed2, 287 ether);
        assertEq(ethOwed2, 533 ether);
        assertEq(votingPower2, 287 ether);
        assertEq(scf.delegationsByContributor(contributor2), contributor2);
        // console.logUint(votingPower2 + delegatedByContributors2);

        (uint256 ethContributed3, uint256 ethUsed3, uint256 ethOwed3, uint256 votingPower3) = 
        scf.getContributorInfo(contributor3);
        assertEq(ethContributed3, defaultUpperLimitInvestment);
        assertEq(ethUsed3, defaultUpperLimitInvestment);
        assertEq(ethOwed3, 0);
        assertEq(votingPower3, 0);
        assertEq(scf.delegationsByContributor(contributor3), defaultInitialContributor);
        // console.logUint(votingPower3 + delegatedByContributors3);

        (uint256 ethContributed4, uint256 ethUsed4, uint256 ethOwed4, uint256 votingPower4) = 
        scf.getContributorInfo(contributor4);
        assertEq(ethContributed4, defaultUpperLimitInvestment);
        assertEq(ethUsed4, defaultUpperLimitInvestment);
        assertEq(ethOwed4, 0);
        assertEq(votingPower4, 0);
        assertEq(scf.delegationsByContributor(contributor4), defaultInitialContributor);
        // console.logUint(votingPower4 + delegatedByContributors4);

        (uint256 ethContributed5, uint256 ethUsed5, uint256 ethOwed5, uint256 votingPower5) = 
        scf.getContributorInfo(contributor5);
        assertEq(ethContributed5, defaultUpperLimitInvestment);
        assertEq(ethUsed5, defaultUpperLimitInvestment);
        assertEq(ethOwed5, 0);
        assertEq(votingPower5, defaultUpperLimitInvestment);
        assertEq(scf.delegationsByContributor(contributor5), contributor5);
        // console.logUint(votingPower5 + delegatedByContributors5);

        (uint256 ethContributed6, uint256 ethUsed6, uint256 ethOwed6, uint256 votingPower6) = 
        scf.getContributorInfo(contributor6);
        assertEq(ethContributed6, defaultUpperLimitInvestment);
        assertEq(ethUsed6, defaultUpperLimitInvestment);
        assertEq(ethOwed6, 0);
        assertEq(votingPower6, defaultUpperLimitInvestment);
        assertEq(scf.delegationsByContributor(contributor6), contributor6);
        // console.logUint(votingPower6 + delegatedByContributors6);

        (uint256 ethContributed7, uint256 ethUsed7, uint256 ethOwed7, uint256 votingPower7) = 
        scf.getContributorInfo(contributor7);
        assertEq(ethContributed7, 225.5 ether);
        assertEq(ethUsed7, 225.5 ether);
        assertEq(ethOwed7, 0);
        assertEq(votingPower7, 225.5 ether);
        assertEq(scf.delegationsByContributor(contributor7), contributor7);
        // console.logUint(votingPower7 + delegatedByContributors7);

        (uint256 ethContributed8, uint256 ethUsed8, uint256 ethOwed8, uint256 votingPower8) = 
        scf.getContributorInfo(contributor8);
        assertEq(ethContributed8, 82 ether);
        assertEq(ethUsed8, 0);
        assertEq(ethOwed8, 82 ether);
        assertEq(votingPower8, 0);
        assertEq(scf.delegationsByContributor(contributor8), defaultInitialContributor);
        // console.logUint(votingPower8 + delegatedByContributors8);
    }

    function testCanClaimMoneyBackIfBoughtForFree() public {
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), 4202.5 ether);

        vm.expectEmit(true, true, true, true);
        emit crowdfundExpired();
        vm.prank(defaultInitialContributor);
        scf.buy(
            payable(openseaSeaport),
            0,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Expired);
        // Check that NFT is now transferred to crowdfund
        assertEq(erc721Vault.checkOwner(tokenId), address(scf));
        // Check the values after buying
        assertEq(scf.settledPrice(), 0);
        assertTrue(scf.isGiftedNFT());

        vm.prank(contributor5);
        scf.claimUnusedContribution(contributor5);
        assertEq(contributor5.balance, defaultUpperLimitInvestment);
    }

    function test_CannotReinitialize() public {
        vm.expectRevert(abi.encodeWithSelector(Implementation.OnlyConstructorError.selector));
        SingleNFTCrowdfund.SingleNFTCrowdfundOptions memory opts;
        scf.initialize(opts);
    }

    function test_CannotBuyAfterFourteenDaysOfExpirationAlthoughFundraiseGoalAchieved() external{
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), defaultFundraiseGoal + defaultInitialContribution);
        assertEq(scf.totalContributors(), 6);

        // Setting block.timestamp to a time 14 days + 1 sec after expiration to pass this test
        vm.warp(block.timestamp + defaultCrowdFundDuration + 1209601);

        vm.prank(defaultInitialContributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.NotEligibleToBuy.selector));
        scf.buy(
            payable(openseaSeaport),
            defaultCallValueToBuyNFT,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
    }

    function test_CannotBuyIfFundraiseGoalIsnotAchieved() public {
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: contributor1.balance }(delegate1);
        // Not contributing enough to pass this test.
        vm.prank(defaultInitialContributor);
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.NotEligibleToBuy.selector));
        scf.buy(
            payable(openseaSeaport),
            defaultCallValueToBuyNFT,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
    }

    function test_CannotBuyNFTOfFundraiseGoalValueIfTotalContriIsNotMore() external{
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, 717.5 ether);
        vm.prank(contributor5);
        scf.contribute{ value: 717.5 ether }(delegate5);

        // Contributed equal amount to goal
        assertEq(scf.totalContributions(), 4100 ether);
        // Buying at same value to pass this test
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.ExceedsTotalContributions.selector, 
        4202.5 ether, scf.totalContributions()));
        vm.prank(defaultInitialContributor);
        scf.buy(
            payable(openseaSeaport),
            4100 ether,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
    }

    function test_CannotBuyNFTOfTotalContributionsValue() external{
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), 4202.5 ether);
        // Buying at same value to pass this test
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.ExceedsTotalContributions.selector, 
        4307.5625 ether, scf.totalContributions()));
        vm.prank(defaultInitialContributor);
        scf.buy(
            payable(openseaSeaport),
            4202.5 ether,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
    }

    function test_CannotBuyAboveTotalContributionsAmount() external{
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), 4202.5 ether);
        // Contributing enough to achieve fundraise goal but giving price more than total contributions to pass this test
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.ExceedsTotalContributions.selector, 
        4407.5 ether, scf.totalContributions()));
        vm.prank(defaultInitialContributor);
        scf.buy(
            payable(openseaSeaport),
            4300 ether,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
    }

    function test_OnlyCollectiveContributorsCanBuy() external{
        // Buying from address other than contributor to pass this test
        vm.prank(_randomAddress());
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.OnlyCollectiveContributor.selector));
        scf.buy(
            payable(openseaSeaport),
            defaultCallValueToBuyNFT,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
    }

    function test_BuyDoesNotTransferTokenWithWrongCallTarget() public {
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), 4202.5 ether);

        // Creating calldata of calling buy function which is already stuck somewhere
        bytes memory callData = abi.encodeCall(erc721Vault.claim, (tokenId));

        // Call random EOA, which will succeed but do nothing to pass this test
        address payable anyAddress = _randomAddress();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICollectiveCrowdfund.CallProhibited.selector,
                anyAddress,
                callData
            )
        );

        vm.prank(defaultInitialContributor);
        scf.buy(
            anyAddress, 
            defaultCallValueToBuyNFT,
            callData
        );
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Active);
    }

    function test_CannotBuyAgainIfBoughtForFree() public {
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), 4202.5 ether);

        vm.expectEmit(true, true, true, true);
        emit crowdfundExpired();
        vm.prank(defaultInitialContributor);
        scf.buy(
            payable(openseaSeaport),
            0,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Expired);
        // Check that NFT is now transferred to crowdfund
        assertEq(erc721Vault.checkOwner(tokenId), address(scf));
        // Check the values after buying
        assertEq(scf.settledPrice(), 0);
        assertTrue(scf.isGiftedNFT());

        // Trying to buy again
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.NotEligibleToBuy.selector));
        vm.prank(defaultInitialContributor);
        scf.buy(
            payable(openseaSeaport),
            defaultCallValueToBuyNFT,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
    }

    function test_BuyCannotReenter() public {
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, defaultUpperLimitInvestment);
        vm.prank(contributor1);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, defaultUpperLimitInvestment);
        vm.prank(contributor2);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor3;
        vm.deal(contributor3, defaultUpperLimitInvestment);
        vm.prank(contributor3);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor4;
        vm.deal(contributor4, defaultUpperLimitInvestment);
        vm.prank(contributor4);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor5;
        vm.deal(contributor5, defaultUpperLimitInvestment);
        vm.prank(contributor5);
        scf.contribute{ value: defaultUpperLimitInvestment }(delegate5);

        assertEq(scf.totalContributions(), 4202.5 ether);

        // Creating calldata of calling buy function which is already stuck somewhere
        bytes memory callData = abi.encodeCall(scf.contribute, (contributor5));
        // Attempt reentering back into the crowdfund directly.
        vm.expectRevert(
            abi.encodeWithSelector(
                ICollectiveCrowdfund.CallProhibited.selector,
                address(scf),
                callData
            )
        );
        vm.prank(defaultInitialContributor);
        scf.buy(payable(address(scf)), defaultCallValueToBuyNFT, callData);

        ReenteringContract reenteringContract = new ReenteringContract();

        // Creating calldata of calling buy function which is already stuck somewhere
        bytes memory callData1 = abi.encodeCall(reenteringContract.reenter, (scf));
        // Attempt reentering back into the crowdfund via a proxy.
        vm.expectRevert(
            abi.encodeWithSelector(
                ICollectiveCrowdfund.CallProhibited.selector,
                address(reenteringContract),
                callData1
            )
        );
        vm.prank(defaultInitialContributor);
        scf.buy(
            payable(address(reenteringContract)),
            defaultCallValueToBuyNFT,
            callData1
        );
        assertTrue(scf.getCrowdfundLifecycle() == ICollectiveCrowdfund.CrowdfundLifecycle.Active);
    }
}

contract ReenteringContract is Test {
    function reenter(SingleNFTCrowdfund scf) external payable {
        scf.contribute{ value: msg.value }(address(this));
    }
}