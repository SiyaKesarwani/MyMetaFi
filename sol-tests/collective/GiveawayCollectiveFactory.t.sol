// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "../../contracts/collective/GiveawayCollectiveFactory.sol";
import "../../contracts/collective/GiveawayCollective.sol";
import "../../contracts/globals/Globals.sol";
import "../../contracts/utils/LibSafeCast.sol"; 
import "../TestUtils.sol";
import "../DummyERC721.sol";

contract GiveawayCollectiveFactoryTest is Test, TestUtils {
    using LibSafeCast for uint256;

    event GiveawayCollectiveCreated(
        GiveawayCollective indexed gCollective,
        GiveawayCollective.GiveawayCollectiveOptions opts
    );

    Globals globals = new Globals(address(this));
    GiveawayCollectiveFactory giveawayFactory = new GiveawayCollectiveFactory(globals);
    GiveawayCollective giveawayCollectiveImpl = new GiveawayCollective(globals);
    address recipient = 0xe5ba98010c85e1386F5C06b9E947DFFF92553796;
    uint256 bps = 250;
    DummyERC721 nftContract = new DummyERC721(); // NFT contract

    constructor() {
        globals.setAddress(LibGlobals.GLOBAL_GIVEAWAY_COLLECTIVE_FACTORY, address(giveawayFactory));
        globals.setAddress(LibGlobals.GLOBAL_GIVEAWAY_COLLECTIVE_IMPL, address(giveawayCollectiveImpl));
        globals.setAddress(LibGlobals.GLOBAL_FEE_RECIPIENT, recipient);
        globals.setUint256(LibGlobals.GLOBAL_FEE_BPS, bps);
    }

    function _hashPreciousNFT(
        IERC721 preciousToken,
        uint256 preciousTokenId
    ) internal pure returns (bytes32 h) {
            h = keccak256(abi.encodePacked(preciousToken, preciousTokenId));
    }

    function testCreateGiveawayCollective(
        string memory randomStr
    ) external {
        address creator = _randomAddress();
        IERC721 preciousToken = nftContract;
        uint256 preciousTokenId = nftContract.mint(creator);
        uint256 maxWinners = 50;
        uint40 giveawayStartTime = uint40(block.timestamp);
        uint40 giveawayDuration = 3 days;
        bool canClaimNFTBack = false;
        ICollective.GovernanceOpts memory opts = ICollective.GovernanceOpts({
            voteDuration: 3 days,
            vetoDuration: 3 days,
            passThresholdBps: 6000
        });

        GiveawayCollective.GiveawayCollectiveOptions memory inputOpts = GiveawayCollective.GiveawayCollectiveOptions({
            collectiveTitleName: randomStr,
            creator: creator,
            preciousToken: preciousToken,
            preciousTokenId: preciousTokenId,
            maxWinners: maxWinners,
            giveawayStartTime: giveawayStartTime, 
            giveawayDuration: giveawayDuration,
            canClaimNFTBack: canClaimNFTBack,
            governanceOpts: opts
        });

        uint256 nonceOfFactory = vm.getNonce(address(giveawayFactory));
        address payable nextCollectiveAddress = payable(StdUtils.computeCreateAddress(address(giveawayFactory), nonceOfFactory));
        vm.prank(creator);
        preciousToken.approve(nextCollectiveAddress, preciousTokenId);

        vm.expectEmit(true, false, false, true);
        emit GiveawayCollectiveCreated(
            GiveawayCollective(nextCollectiveAddress),
            inputOpts
        );
        GiveawayCollective gCollective = giveawayFactory.createGiveawayCollective(inputOpts);

        ICollective.GovernanceOpts memory values = gCollective.getGovernanceValues();
        assertEq(values.voteDuration, opts.voteDuration);
        assertEq(values.vetoDuration, opts.vetoDuration);
        assertEq(values.passThresholdBps, opts.passThresholdBps);
        assertEq(gCollective.preciousNFTHash(), _hashPreciousNFT(preciousToken, preciousTokenId));
        assertEq(gCollective.creator(), creator);
        // assertEq(gCollective.leader(), address(0));
        assertEq(gCollective.maxWinners(), maxWinners);
        assertEq(gCollective.activatedWinners(), 0);
        assertEq(gCollective.expiry(), giveawayStartTime + giveawayDuration);
        assertEq(gCollective.winnerActivated(_randomAddress()), false);
        assertEq(gCollective.delegationsByWinner(_randomAddress()), address(0));
    }

    function test_CannotReinitializeGiveawayCollective(
        string memory randomStr
    ) external {
        address creator = _randomAddress();
        IERC721 preciousToken = nftContract;
        uint256 preciousTokenId = nftContract.mint(creator);
        uint256 maxWinners = 50;
        uint40 giveawayStartTime = uint40(block.timestamp);
        uint40 giveawayDuration = 3 days;
        bool canClaimNFTBack = false;
        ICollective.GovernanceOpts memory opts = ICollective.GovernanceOpts({
            voteDuration: 1 days,
            vetoDuration: 1 days,
            passThresholdBps: 5678
        });

        GiveawayCollective.GiveawayCollectiveOptions memory inputOpts = GiveawayCollective.GiveawayCollectiveOptions({
            collectiveTitleName: randomStr,
            creator: creator,
            preciousToken: preciousToken,
            preciousTokenId: preciousTokenId,
            maxWinners: maxWinners,
            giveawayStartTime: giveawayStartTime, 
            giveawayDuration: giveawayDuration,
            canClaimNFTBack: canClaimNFTBack,
            governanceOpts: opts
        });

        uint256 nonceOfFactory = vm.getNonce(address(giveawayFactory));
        address payable nextCollectiveAddress = payable(StdUtils.computeCreateAddress(address(giveawayFactory), nonceOfFactory));
        vm.prank(creator);
        preciousToken.approve(nextCollectiveAddress, preciousTokenId);

        GiveawayCollective gCollective = giveawayFactory.createGiveawayCollective(inputOpts);

        vm.expectRevert(abi.encodeWithSelector(Implementation.OnlyConstructorError.selector));
        gCollective.initializeGiveaway(inputOpts);
    }

    function test_CannotCreateGiveawayCollectiveIfCreatorIsNotOwner(
        string memory randomStr
    ) external {
        address creator = _randomAddress();
        IERC721 preciousToken = nftContract;
        uint256 preciousTokenId = nftContract.mint(creator);
        uint256 maxWinners = 50;
        uint40 giveawayStartTime = uint40(block.timestamp);
        uint40 giveawayDuration = 3 days;
        bool canClaimNFTBack = false;
        ICollective.GovernanceOpts memory opts = ICollective.GovernanceOpts({
            voteDuration: 604800,
            vetoDuration: 86400,
            passThresholdBps: 5400
        });

        GiveawayCollective.GiveawayCollectiveOptions memory inputOpts = GiveawayCollective.GiveawayCollectiveOptions({
            collectiveTitleName: randomStr,
            creator: _randomAddress(), // Passing random address to pass this test
            preciousToken: preciousToken,
            preciousTokenId: preciousTokenId,
            maxWinners: maxWinners,
            giveawayStartTime: giveawayStartTime, 
            giveawayDuration: giveawayDuration,
            canClaimNFTBack: canClaimNFTBack,
            governanceOpts: opts
        });

        uint256 nonceOfFactory = vm.getNonce(address(giveawayFactory));
        address payable nextCollectiveAddress = payable(StdUtils.computeCreateAddress(address(giveawayFactory), nonceOfFactory));
        vm.prank(creator);
        preciousToken.approve(nextCollectiveAddress, preciousTokenId);

        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.CreatorShouldApproveNFTFirst.selector,
        "Creator is not NFT Owner || NFT is not approved"));
        giveawayFactory.createGiveawayCollective(inputOpts);
    }

    function test_CannotCreateGiveawayCollectiveIfNFTNotApprovedFirst(
        string memory randomStr
    ) external {
        address creator = _randomAddress();
        IERC721 preciousToken = nftContract;
        uint256 preciousTokenId = nftContract.mint(creator);
        uint256 maxWinners = 50;
        uint40 giveawayStartTime = uint40(block.timestamp);
        uint40 giveawayDuration = 3 days;
        bool canClaimNFTBack = false;
        ICollective.GovernanceOpts memory opts = ICollective.GovernanceOpts({
            voteDuration: 604800,
            vetoDuration: 86400,
            passThresholdBps: 5400
        });

        GiveawayCollective.GiveawayCollectiveOptions memory inputOpts = GiveawayCollective.GiveawayCollectiveOptions({
            collectiveTitleName: randomStr,
            creator: creator,
            preciousToken: preciousToken,
            preciousTokenId: preciousTokenId,
            maxWinners: maxWinners,
            giveawayStartTime: giveawayStartTime, 
            giveawayDuration: giveawayDuration,
            canClaimNFTBack: canClaimNFTBack,
            governanceOpts: opts
        });

        // Not approving to pass this test

        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.CreatorShouldApproveNFTFirst.selector,
        "Creator is not NFT Owner || NFT is not approved"));
        giveawayFactory.createGiveawayCollective(inputOpts);
    }

    function test_CannotCreateGiveawayCollectiveWithInvalidPassThresholdBps(
        string memory randomStr,
        uint40 randomUint40,
        uint16 randomBps
    ) external {
        // vote duration can vary from 1 to 7 days and veto duration can vary from 1 to 3 days
        vm.assume(randomUint40 <= 3 days && randomUint40 >= 1 days);
        //  BPs must be invalid for this test to work.
        vm.assume(randomBps > 1e4 || randomBps < 5e3);
        address creator = _randomAddress();
        IERC721 preciousToken = nftContract;
        uint256 preciousTokenId = nftContract.mint(creator);
        uint256 maxWinners = 50;
        uint40 giveawayStartTime = uint40(block.timestamp);
        uint40 giveawayDuration = 3 days;
        bool canClaimNFTBack = false;
        ICollective.GovernanceOpts memory opts = ICollective.GovernanceOpts({
            voteDuration: randomUint40,
            vetoDuration: randomUint40,
            passThresholdBps: randomBps
        });

        GiveawayCollective.GiveawayCollectiveOptions memory inputOpts = GiveawayCollective.GiveawayCollectiveOptions({
            collectiveTitleName: randomStr,
            creator: creator,
            preciousToken: preciousToken,
            preciousTokenId: preciousTokenId,
            maxWinners: maxWinners,
            giveawayStartTime: giveawayStartTime, 
            giveawayDuration: giveawayDuration,
            canClaimNFTBack: canClaimNFTBack,
            governanceOpts: opts
        });

        uint256 nonceOfFactory = vm.getNonce(address(giveawayFactory));
        address payable nextCollectiveAddress = payable(StdUtils.computeCreateAddress(address(giveawayFactory), nonceOfFactory));
        vm.prank(creator);
        preciousToken.approve(nextCollectiveAddress, preciousTokenId);

        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.WrongGovernanceValues.selector));
        giveawayFactory.createGiveawayCollective(inputOpts);
    }

    function test_CannotCreateCollectiveWithWrongVoteOrVetoPeriod(
        string memory randomStr,
        uint40 randomUint40,
        uint16 randomBps
    ) external {
        // vote duration can vary from 1 to 7 days and veto duration can vary from 1 to 3 days
        vm.assume(randomUint40 < 1 days);
        //  BPs must be invalid for this test to work.
        vm.assume(randomBps <= 1e4 && randomBps >= 5e3);
        address creator = _randomAddress();
        IERC721 preciousToken = nftContract;
        uint256 preciousTokenId = nftContract.mint(creator);
        uint256 maxWinners = 50;
        uint40 giveawayStartTime = uint40(block.timestamp);
        uint40 giveawayDuration = 3 days;
        bool canClaimNFTBack = false;
        ICollective.GovernanceOpts memory opts = ICollective.GovernanceOpts({
            voteDuration: randomUint40,
            vetoDuration: randomUint40,
            passThresholdBps: randomBps
        });

        GiveawayCollective.GiveawayCollectiveOptions memory inputOpts = GiveawayCollective.GiveawayCollectiveOptions({
            collectiveTitleName: randomStr,
            creator: creator,
            preciousToken: preciousToken,
            preciousTokenId: preciousTokenId,
            maxWinners: maxWinners,
            giveawayStartTime: giveawayStartTime, 
            giveawayDuration: giveawayDuration,
            canClaimNFTBack: canClaimNFTBack,
            governanceOpts: opts
        });

        uint256 nonceOfFactory = vm.getNonce(address(giveawayFactory));
        address payable nextCollectiveAddress = payable(StdUtils.computeCreateAddress(address(giveawayFactory), nonceOfFactory));
        vm.prank(creator);
        preciousToken.approve(nextCollectiveAddress, preciousTokenId);

        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.WrongGovernanceValues.selector));
        giveawayFactory.createGiveawayCollective(inputOpts);
    }

    function test_CreatorCannotBeZeroAddress(
        string memory randomStr
    ) external {
        address creator = address(0); // Zero address to pass this test
        IERC721 preciousToken = nftContract;
        uint256 preciousTokenId = nftContract.mint(creator);
        uint256 maxWinners = 50;
        uint40 giveawayStartTime = uint40(block.timestamp);
        uint40 giveawayDuration = 3 days;
        bool canClaimNFTBack = false;
        ICollective.GovernanceOpts memory opts = ICollective.GovernanceOpts({
            voteDuration: 3 days,
            vetoDuration: 1 days,
            passThresholdBps: 7000
        });

        GiveawayCollective.GiveawayCollectiveOptions memory inputOpts = GiveawayCollective.GiveawayCollectiveOptions({
            collectiveTitleName: randomStr,
            creator: creator,
            preciousToken: preciousToken,
            preciousTokenId: preciousTokenId,
            maxWinners: maxWinners,
            giveawayStartTime: giveawayStartTime, 
            giveawayDuration: giveawayDuration,
            canClaimNFTBack: canClaimNFTBack,
            governanceOpts: opts
        });

        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.ZeroAddressCreator.selector));
        giveawayFactory.createGiveawayCollective(inputOpts);
    }
}