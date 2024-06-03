// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "contracts/crowdfund/CollectiveCrowdfundFactory.sol";
import "contracts/crowdfund/SingleNFTCrowdfund.sol";
import "contracts/crowdfund/CollectionNFTCrowdfund.sol";
import "contracts/globals/Globals.sol";
import "contracts/globals/LibGlobals.sol";

import "forge-std/Test.sol";
import "../TestUtils.sol";
import "../DummyERC721.sol";

import {console} from "forge-std/console.sol";

contract CollectiveCrowdfundFactoryTest is Test, TestUtils {
    Globals globals = new Globals(address(this));
    CollectiveCrowdfundFactory collectiveCrowdfundFactory = new CollectiveCrowdfundFactory(globals);
    SingleNFTCrowdfund singleNFTCrowdfund = new SingleNFTCrowdfund(globals);
    CollectionNFTCrowdfund collectionNFTCrowdfund = new CollectionNFTCrowdfund(globals);

    constructor() {
        globals.setAddress(LibGlobals.GLOBAL_SINGLE_BUY_CF_IMPL, address(singleNFTCrowdfund));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTION_BUY_CF_IMPL, address(collectionNFTCrowdfund));
    }

    function _hashFixedGovernanceOpts(
        ICollectiveCrowdfund.GovernanceOpts memory opts
    ) internal pure returns (bytes32 h) {
        assembly {
            h := keccak256(opts, 0xC0)
        }
    }

    function testGlobals() public {
        assertEq(globals.getAddress(LibGlobals.GLOBAL_SINGLE_BUY_CF_IMPL), address(singleNFTCrowdfund));
        assertEq(globals.getAddress(LibGlobals.GLOBAL_COLLECTION_BUY_CF_IMPL), address(collectionNFTCrowdfund));
    }

    function testCreateSingleNFTCrowdfund(
        string memory randomStr,
        uint88 randomUint88,
        uint16 randomBps
    ) public {
        // Minimum value of fundraise goal should be kept 1000 to avoid underflow error for calculating 2.5%
        vm.assume(randomUint88 >= 1e18);
        // Minimum ratio of accept votes to consider a proposal passed, in bps, where 10,000 == 100%.
        vm.assume(randomBps <= 1e4 && randomBps >= 5e3);

        // Create an NFT.
        DummyERC721 nftContract = new DummyERC721();
        uint256 tokenId = nftContract.mint(address(this));

        // Fundraisegoal is uint96 but we should test here with smaller datatype to overcome overflow error 
        // while calculating `initialContribution` within 2.5 to 20%
        uint96 _fundraiseGoal = randomUint88;
        // Initial contribution should lie between `_lowerLimitInvestment` and 20% of Goal
        // Here we are giving 2.5% of atleast 1 ether goal (0.025) which is always greater than 0.01 ether
        uint96 _initialContribution = (_fundraiseGoal * 25) / 1000;
        uint96 _lowerLimitInvestment = 0.01 ether;

        SingleNFTCrowdfund.SingleNFTCrowdfundOptions memory opts = SingleNFTCrowdfund.SingleNFTCrowdfundOptions({
            collectiveTitleName: randomStr,
            nftContractAddress: nftContract,
            nftTokenId: tokenId,
            fundraiseGoal: _fundraiseGoal,
            // This is to avoid overflows when adding to `block.timestamp`.
            crowdFundDuration: uint40(_randomRange(1, type(uint40).max - block.timestamp)),
            lowerLimitInvestment: _lowerLimitInvestment, 
            initialContributor: _randomAddress(),
            governanceOpts: ICollectiveCrowdfund.GovernanceOpts({
                voteDuration: 86400,
                vetoDuration: 86400,
                passThresholdBps: randomBps
            })
        });

        SingleNFTCrowdfund inst = collectiveCrowdfundFactory.createSingleNFTCrowdfund{ value: _initialContribution }(
            opts
        );

        // Check that value are initialized to what we expect.
        assertEq(address(inst.nftContract()), address(opts.nftContractAddress));
        assertEq(inst.nftTokenId(), opts.nftTokenId);
        assertEq(inst.expiry(), uint40(block.timestamp + opts.crowdFundDuration));
        assertEq(inst.fundraiseGoal(), opts.fundraiseGoal);
        assertEq(inst.totalContributions(), _initialContribution);
        // assertEq(inst.governanceOptsHash(), _hashFixedGovernanceOpts(opts.governanceOpts));
        assertEq(inst.lowerLimitInvestment(), opts.lowerLimitInvestment);
        assertEq(inst.settledPrice(), 0);
        (uint256 ethContributed, , ,) = inst.getContributorInfo(opts.initialContributor);
        assertEq(ethContributed, _initialContribution);
        assertEq(inst.delegationsByContributor(opts.initialContributor), opts.initialContributor);
    }

    function testCreateCollectionNFTCrowdfund(
        string memory randomStr,
        uint88 randomUint88,
        uint16 randomBps
    ) public {
        // Minimum value of fundraise goal should be kept 1000 to avoid underflow error for calculating 2.5%
        vm.assume(randomUint88 >= 1e18);
        // Minimum ratio of accept votes to consider a proposal passed, in bps, where 10,000 == 100%.
        vm.assume(randomBps <= 1e4 && randomBps >= 5e3);

        // Create an NFT contract.
        DummyERC721 nftContract = new DummyERC721();

        // Fundraisegoal is uint96 but we should test here with smaller datatype to overcome overflow error 
        // while calculating `initialContribution` within 2.5 to 20%
        uint96 _fundraiseGoal = randomUint88;
        // Initial contribution should lie between `_lowerLimitInvestment` and 20% of Goal
        // Here we are giving maximum i.e. 20%
        uint96 _initialContribution = (_fundraiseGoal * 20) / 100;
        uint96 _lowerLimitInvestment = (_fundraiseGoal * 25) / 1000;

        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
            collectiveTitleName: randomStr,
            nftContractAddress: nftContract,
            fundraiseGoal: _fundraiseGoal,
            // This is to avoid overflows when adding to `block.timestamp`.
            crowdFundDuration: uint40(_randomRange(1, type(uint40).max - block.timestamp)),
            lowerLimitInvestment: _lowerLimitInvestment, 
            initialContributor: _randomAddress(),
            governanceOpts: ICollectiveCrowdfund.GovernanceOpts({
                voteDuration: 259200,
                vetoDuration: 259200,
                passThresholdBps: randomBps
            })
        });

        CollectionNFTCrowdfund inst = collectiveCrowdfundFactory.createCollectionNFTCrowdfund{ value: _initialContribution }(
            opts
        );

        // Check that value are initialized to what we expect.
        assertEq(address(inst.nftContract()), address(opts.nftContractAddress));
        assertEq(inst.expiry(), uint40(block.timestamp + opts.crowdFundDuration));
        assertEq(inst.fundraiseGoal(), opts.fundraiseGoal);
        assertEq(inst.totalContributions(), _initialContribution);
        // assertEq(inst.governanceOptsHash(), _hashFixedGovernanceOpts(opts.governanceOpts));
        assertEq(inst.lowerLimitInvestment(), opts.lowerLimitInvestment);
        assertEq(inst.settledPrice(), 0);
        (uint256 ethContributed, , ,) = inst.getContributorInfo(opts.initialContributor);
        assertEq(ethContributed, _initialContribution);
        assertEq(inst.delegationsByContributor(opts.initialContributor), opts.initialContributor);
    }

    function test_CannotCreateCollectiveWithInvalidPassThresholdBps(
        string memory randomStr,
        uint16 randomBps
    ) public {
        //  BPs must be invalid for this test to work.
        vm.assume(randomBps > 1e4 || randomBps < 5e3);

        // Create an NFT contract.
        DummyERC721 nftContract = new DummyERC721();

        // Fundraisegoal is uint96 but we should test here with smaller datatype to overcome overflow error 
        // while calculating `initialContribution` within 2.5 to 20%
        uint96 _fundraiseGoal = 1000;
        // Initial contribution should lie between `_lowerLimitInvestment` and 20% of Goal
        // Here we are giving more than `_lowerLimitInvestment`
        uint96 _initialContribution = (_fundraiseGoal * 25) / 1000;
        uint96 _lowerLimitInvestment = (_fundraiseGoal * 10) / 1000;

        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
            collectiveTitleName: randomStr,
            nftContractAddress: nftContract,
            fundraiseGoal: _fundraiseGoal,
            // This is to avoid overflows when adding to `block.timestamp`.
            crowdFundDuration: uint40(_randomRange(1, type(uint40).max - block.timestamp)),
            lowerLimitInvestment: _lowerLimitInvestment, 
            initialContributor: _randomAddress(),
            governanceOpts: ICollectiveCrowdfund.GovernanceOpts({
                voteDuration: 86400,
                vetoDuration: 86400,
                passThresholdBps: randomBps
            })
        });
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.WrongGovernanceValues.selector));
        collectiveCrowdfundFactory.createCollectionNFTCrowdfund{ value: _initialContribution }(opts);
    }

    function test_CannotCreateCollectiveWithWrongVotePeriod(
        string memory randomStr,
        uint40 randomUint40
    ) public {
        // Vote duration should be invalid to pass this test
        vm.assume(randomUint40 < 86400 || randomUint40 > 604800);

        // Create an NFT contract.
        DummyERC721 nftContract = new DummyERC721();

        // Fundraisegoal is uint96 but we should test here with smaller datatype to overcome overflow error 
        // while calculating `initialContribution` within 2.5 to 20%
        uint96 _fundraiseGoal = 10000000000000000000000000;
        // Initial contribution should lie between `_lowerLimitInvestment` and 20% of Goal
        // Here we are giving minimum i.e. 2.5%
        uint96 _initialContribution = (_fundraiseGoal * 25) / 1000;
        // Lower Limit Investment can be less than or equal to 2.5% of `Fundraise Goal`
        uint96 _lowerLimitInvestment = 1e16;

        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
            collectiveTitleName: randomStr,
            nftContractAddress: nftContract,
            fundraiseGoal: _fundraiseGoal,
            // This is to avoid overflows when adding to `block.timestamp`.
            crowdFundDuration: uint40(_randomRange(1, type(uint40).max - block.timestamp)),
            lowerLimitInvestment: _lowerLimitInvestment, 
            initialContributor: _randomAddress(),
            governanceOpts: ICollectiveCrowdfund.GovernanceOpts({
                voteDuration: randomUint40, 
                vetoDuration: 259200,
                passThresholdBps: 10000
            })
        });
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.WrongGovernanceValues.selector));
        collectiveCrowdfundFactory.createCollectionNFTCrowdfund{ value: _initialContribution }(opts);
    }

    function test_CannotCreateCollectiveWithWrongVetoPeriod(
        string memory randomStr,
        uint40 randomUint40
    ) public {
        // Veto duration should be invalid to pass this test
        vm.assume(randomUint40 < 86400 || randomUint40 > 259200);

        // Create an NFT contract.
        DummyERC721 nftContract = new DummyERC721();

        // Fundraisegoal is uint96 but we should test here with smaller datatype to overcome overflow error 
        // while calculating `initialContribution` within 2.5 to 20%
        uint96 _fundraiseGoal = 150000000000000000000;
        // Initial contribution should lie between `_lowerLimitInvestment` and 20% of Goal
        // Here we are giving equal to `_lowerLimitInvestment`
        uint96 _initialContribution = (_fundraiseGoal * 25) / 1000;
        uint96 _lowerLimitInvestment = (_fundraiseGoal * 25) / 1000;

        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
            collectiveTitleName: randomStr,
            nftContractAddress: nftContract,
            fundraiseGoal: _fundraiseGoal,
            // This is to avoid overflows when adding to `block.timestamp`.
            crowdFundDuration: uint40(_randomRange(1, type(uint40).max - block.timestamp)),
            lowerLimitInvestment: _lowerLimitInvestment, 
            initialContributor: _randomAddress(),
            governanceOpts: ICollectiveCrowdfund.GovernanceOpts({
                voteDuration: 604800,
                vetoDuration: randomUint40,
                passThresholdBps: 5000
            })
        });
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.WrongGovernanceValues.selector));
        collectiveCrowdfundFactory.createCollectionNFTCrowdfund{ value: _initialContribution }(opts);
    }

    function test_CannotCreateCollectiveWithZeroInitialContribution(
        string memory randomStr
    ) public {

        // Create an NFT.
        DummyERC721 nftContract = new DummyERC721();

        // Fundraisegoal is uint96 but we should test here with smaller datatype to overcome overflow error 
        // while calculating `initialContribution` within 2.5 to 20%
        uint96 _fundraiseGoal = 600000000000;
        uint96 _lowerLimitInvestment = (_fundraiseGoal * 20) / 1000;
        uint96 _upperLimitInvestment = (_fundraiseGoal * 20) / 100;

        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
            collectiveTitleName: randomStr,
            nftContractAddress: nftContract,
            fundraiseGoal: _fundraiseGoal,
            // This is to avoid overflows when adding to `block.timestamp`.
            crowdFundDuration: uint40(_randomRange(1, type(uint40).max - block.timestamp)),
            lowerLimitInvestment: _lowerLimitInvestment, 
            initialContributor: _randomAddress(),
            governanceOpts: ICollectiveCrowdfund.GovernanceOpts({
                voteDuration: 604800,
                vetoDuration: 86400,
                passThresholdBps: 5400
            })
        });
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.ContributionNotWithinLimit.selector, _lowerLimitInvestment,
        _upperLimitInvestment));
        // Giving 0 callValue to pass this test
        collectiveCrowdfundFactory.createCollectionNFTCrowdfund(opts);
    }

    function test_CannotCreateCollectiveWithLessThanMinimumInitialContribution(
        string memory randomStr
    ) public {

        // Create an NFT.
        DummyERC721 nftContract = new DummyERC721();

        // Fundraisegoal is uint96 but we should test here with smaller datatype to overcome overflow error 
        // while calculating `initialContribution` within 2.5 to 20%
        uint96 _fundraiseGoal = 600000000000;
        // Initial contribution should lie between `_lowerLimitInvestment` and 20% of Goal
        // Here we are giving less than `_lowerLimitInvestment` to pass this test
        uint96 _initialContribution = (_fundraiseGoal * 15) / 1000;
        uint96 _lowerLimitInvestment = (_fundraiseGoal * 20) / 1000;
        uint96 _upperLimitInvestment = (_fundraiseGoal * 20) / 100;

        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
            collectiveTitleName: randomStr,
            nftContractAddress: nftContract,
            fundraiseGoal: _fundraiseGoal,
            // This is to avoid overflows when adding to `block.timestamp`.
            crowdFundDuration: uint40(_randomRange(1, type(uint40).max - block.timestamp)),
            lowerLimitInvestment: _lowerLimitInvestment, 
            initialContributor: _randomAddress(),
            governanceOpts: ICollectiveCrowdfund.GovernanceOpts({
                voteDuration: 604800,
                vetoDuration: 86400,
                passThresholdBps: 5400
            })
        });
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.ContributionNotWithinLimit.selector, _lowerLimitInvestment,
        _upperLimitInvestment));
        collectiveCrowdfundFactory.createCollectionNFTCrowdfund{ value: _initialContribution }(opts);
    }

    function test_CannotCreateCollectiveWithZeroAddress(
        string memory randomStr
    ) public {

        // Create an NFT.
        DummyERC721 nftContract = new DummyERC721();

        // Fundraisegoal is uint96 but we should test here with smaller datatype to overcome overflow error 
        // while calculating `initialContribution` within 2.5 to 20%
        uint96 _fundraiseGoal = 600000000000;
        // Initial contribution should lie between `_lowerLimitInvestment` and 20% of Goal
        uint96 _initialContribution = (_fundraiseGoal * 20) / 1000;
        uint96 _lowerLimitInvestment = (_fundraiseGoal * 20) / 1000;

        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts = CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions({
            collectiveTitleName: randomStr,
            nftContractAddress: nftContract,
            fundraiseGoal: _fundraiseGoal,
            // This is to avoid overflows when adding to `block.timestamp`.
            crowdFundDuration: uint40(_randomRange(1, type(uint40).max - block.timestamp)),
            lowerLimitInvestment: _lowerLimitInvestment, 
            initialContributor: address(0),
            governanceOpts: ICollectiveCrowdfund.GovernanceOpts({
                voteDuration: 604800,
                vetoDuration: 86400,
                passThresholdBps: 5400
            })
        });
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.InvalidContributor.selector));
        // Giving address(0) as initial contributor to pass this test
        collectiveCrowdfundFactory.createCollectionNFTCrowdfund{ value: _initialContribution }(opts);
    }
}
