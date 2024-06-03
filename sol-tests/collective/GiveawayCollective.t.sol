// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "../../contracts/collective/GiveawayCollectiveFactory.sol";
import "../../contracts/collective/GiveawayCollective.sol";
import "../../contracts/collective/distribution/Distributor.sol";
import "../../contracts/globals/Globals.sol";
import "../../contracts/utils/Proxy.sol";
import "../TestUtils.sol";
import "../DummyERC721.sol";
import "./DummyCallTarget.sol";

contract GiveawayCollectiveTest is Test, TestUtils {

    Globals globals = new Globals(address(this));
    GiveawayCollectiveFactory giveawayFactory = new GiveawayCollectiveFactory(globals);
    GiveawayCollective giveawayCollectiveImpl = new GiveawayCollective(globals);
    DummyCallTarget callTarget = new DummyCallTarget();
    Distributor distributor = new Distributor(globals);
    DummyERC721 nftContract = new DummyERC721(); // NFT contract
    address payable feeRecipient = payable(0xe5ba98010c85e1386F5C06b9E947DFFF92553796);
    uint16 feeBps = 250;

    string defaultCollectiveTitleName = "GiveawayCollective";
    address defaultCreator = 0xB9E1765eb11aF3B4C607f0D4e72b1A62F5DF302F;
    IERC721 defaultPreciousToken = nftContract; // NFT contract;
    uint256 defaultPreciousTokenId = nftContract.mint(defaultCreator);
    uint256 defaultMaxWinners = 3;
    uint40 defaultGiveawayStartTime = uint40(block.timestamp);
    uint40 defaultGiveawayDuration = 3 days;
    ICollective.GovernanceOpts defaultGovernanceOpts = ICollective.GovernanceOpts(
            604800, 86400, 8000);

    constructor() {
        globals.setAddress(LibGlobals.GLOBAL_GIVEAWAY_COLLECTIVE_FACTORY, address(giveawayFactory));
        globals.setAddress(LibGlobals.GLOBAL_GIVEAWAY_COLLECTIVE_IMPL, address(giveawayCollectiveImpl));
        globals.setAddress(LibGlobals.GLOBAL_DISTRIBUTOR, address(distributor));
        globals.setAddress(LibGlobals.GLOBAL_FEE_RECIPIENT, feeRecipient);
        globals.setUint256(LibGlobals.GLOBAL_FEE_BPS, feeBps);
        globals.setAddress(LibGlobals.GLOBAL_VALIDSIGNER, 0x73C6D4A841dAb46BF11F7eBa1E379cD087B95CE4);
    }

    function testWinnerCanActivateMembershipInActiveGiveaway() external{
        GiveawayCollective gCollective = _createGiveawayCollective(false);
        address winner = _randomAddress();
        GiveawayCollective.ActivateMembershipCall memory activateParams = GiveawayCollective.ActivateMembershipCall({
            winner: winner,
            delegate: winner
        });

        bytes memory activateMembershipCalldata = abi.encodeWithSelector(GiveawayCollective.activateMembership.selector,activateParams);
        ICollective.ArbitraryCall memory callToActivate = ICollective.ArbitraryCall({
            target: payable(address(gCollective)),
            value: 0,
            data: activateMembershipCalldata,
            expectedResultHash: 0x0
        });
        gCollective.executeProposalArbitraryCall(callToActivate, defaultPreciousToken, defaultPreciousTokenId, "0x");

        assertEq(gCollective.creator(), defaultCreator);
        assertEq(gCollective.maxWinners(), defaultMaxWinners);
        assertEq(gCollective.activatedWinners(), 1);
        assertEq(gCollective.expiry(), defaultGiveawayStartTime + defaultGiveawayDuration);
        assertEq(gCollective.winnerActivated(winner), true);
        assertEq(gCollective.delegationsByWinner(winner), winner);
    }

    function test_CreatorCannotBeWinner() external{
        GiveawayCollective gCollective = _createGiveawayCollective(false);
        address winner = defaultCreator;
        GiveawayCollective.ActivateMembershipCall memory activateParams = GiveawayCollective.ActivateMembershipCall({
            winner: winner,
            delegate: winner
        });

        bytes memory activateMembershipCalldata = abi.encodeWithSelector(GiveawayCollective.activateMembership.selector,activateParams);
        ICollective.ArbitraryCall memory callToActivate = ICollective.ArbitraryCall({
            target: payable(address(gCollective)),
            value: 0,
            data: activateMembershipCalldata,
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.ArbitraryCallFailed.selector, 
        abi.encodeWithSelector(GiveawayCollective.InvalidWinner.selector)));
        gCollective.executeProposalArbitraryCall(callToActivate, defaultPreciousToken, defaultPreciousTokenId, "0x");

        assertEq(gCollective.creator(), defaultCreator);
        assertEq(gCollective.maxWinners(), defaultMaxWinners);
        assertEq(gCollective.activatedWinners(), 0);
        assertEq(gCollective.expiry(), defaultGiveawayStartTime + defaultGiveawayDuration);
        assertEq(gCollective.winnerActivated(winner), false);
        assertEq(gCollective.delegationsByWinner(winner), address(0));
    }

    function test_ZeroAddressCannotBeWinner() external{
        GiveawayCollective gCollective = _createGiveawayCollective(false);
        address winner = address(0);
        GiveawayCollective.ActivateMembershipCall memory activateParams = GiveawayCollective.ActivateMembershipCall({
            winner: winner,
            delegate: winner
        });

        bytes memory activateMembershipCalldata = abi.encodeWithSelector(GiveawayCollective.activateMembership.selector,activateParams);
        ICollective.ArbitraryCall memory callToActivate = ICollective.ArbitraryCall({
            target: payable(address(gCollective)),
            value: 0,
            data: activateMembershipCalldata,
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.ArbitraryCallFailed.selector, 
        abi.encodeWithSelector(GiveawayCollective.InvalidWinner.selector)));
        gCollective.executeProposalArbitraryCall(callToActivate, defaultPreciousToken, defaultPreciousTokenId, "0x");

        assertEq(gCollective.creator(), defaultCreator);
        assertEq(gCollective.maxWinners(), defaultMaxWinners);
        assertEq(gCollective.activatedWinners(), 0);
        assertEq(gCollective.expiry(), defaultGiveawayStartTime + defaultGiveawayDuration);
        assertEq(gCollective.winnerActivated(winner), false);
        assertEq(gCollective.delegationsByWinner(winner), winner);
    }

    function test_GiveawayCollectiveCannotBeWinner() external{
        GiveawayCollective gCollective = _createGiveawayCollective(false);
        address winner = address(gCollective);
        GiveawayCollective.ActivateMembershipCall memory activateParams = GiveawayCollective.ActivateMembershipCall({
            winner: winner,
            delegate: winner
        });

        bytes memory activateMembershipCalldata = abi.encodeWithSelector(GiveawayCollective.activateMembership.selector,activateParams);
        ICollective.ArbitraryCall memory callToActivate = ICollective.ArbitraryCall({
            target: payable(address(gCollective)),
            value: 0,
            data: activateMembershipCalldata,
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.ArbitraryCallFailed.selector, 
        abi.encodeWithSelector(GiveawayCollective.InvalidWinner.selector)));
        gCollective.executeProposalArbitraryCall(callToActivate, defaultPreciousToken, defaultPreciousTokenId, "0x");

        assertEq(gCollective.creator(), defaultCreator);
        assertEq(gCollective.maxWinners(), defaultMaxWinners);
        assertEq(gCollective.activatedWinners(), 0);
        assertEq(gCollective.expiry(), defaultGiveawayStartTime + defaultGiveawayDuration);
        assertEq(gCollective.winnerActivated(winner), false);
        assertEq(gCollective.delegationsByWinner(winner), address(0));
    }

    function test_CannotActivateIfGiveawayIsExpired() external{
        GiveawayCollective gCollective = _createGiveawayCollective(false);
        address winner = _randomAddress();
        GiveawayCollective.ActivateMembershipCall memory activateParams = GiveawayCollective.ActivateMembershipCall({
            winner: winner,
            delegate: winner
        });

        bytes memory activateMembershipCalldata = abi.encodeWithSelector(GiveawayCollective.activateMembership.selector,activateParams);
        ICollective.ArbitraryCall memory callToActivate = ICollective.ArbitraryCall({
            target: payable(address(gCollective)),
            value: 0,
            data: activateMembershipCalldata,
            expectedResultHash: 0x0
        });

        // Time is after 48 hrs to expire giveaway and pass this test
        // This will Automatically allow the creator to claim his nft back although
        // he has not set canClaimNFTBack to true.
        // Since nobody has activated within timeframe so he can claim.
        vm.warp(block.timestamp + gCollective.expiry() + 48 hours);
        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.ArbitraryCallFailed.selector, 
        abi.encodeWithSelector(GiveawayCollective.WrongLifecycle.selector, GiveawayCollective.GiveawayLifecycle.Expired)));
        gCollective.executeProposalArbitraryCall(callToActivate, defaultPreciousToken, defaultPreciousTokenId, "0x");

        assertEq(gCollective.creator(), defaultCreator);
        assertEq(gCollective.maxWinners(), defaultMaxWinners);
        assertEq(gCollective.activatedWinners(), 0);
        assertEq(gCollective.expiry(), defaultGiveawayStartTime + defaultGiveawayDuration);
        assertEq(gCollective.winnerActivated(winner), false);
        assertEq(gCollective.delegationsByWinner(winner), address(0));
    }

    function test_WinnerCanActivateOnlyOnce() external{
        GiveawayCollective gCollective = _createGiveawayCollective(false);
        address winner = _randomAddress();
        GiveawayCollective.ActivateMembershipCall memory activateParams = GiveawayCollective.ActivateMembershipCall({
            winner: winner,
            delegate: winner
        });

        bytes memory activateMembershipCalldata = abi.encodeWithSelector(GiveawayCollective.activateMembership.selector,activateParams);
        ICollective.ArbitraryCall memory callToActivate = ICollective.ArbitraryCall({
            target: payable(address(gCollective)),
            value: 0,
            data: activateMembershipCalldata,
            expectedResultHash: 0x0
        });
        gCollective.executeProposalArbitraryCall(callToActivate, defaultPreciousToken, defaultPreciousTokenId, "0x");

        // Same winner activating again to pass this test
        vm.expectRevert(abi.encodeWithSelector(GiveawayCollective.ArbitraryCallFailed.selector, 
        abi.encodeWithSelector(GiveawayCollective.WinnerHasAlreadyActivated.selector)));
        gCollective.executeProposalArbitraryCall(callToActivate, defaultPreciousToken, defaultPreciousTokenId, "0x");

        assertEq(gCollective.creator(), defaultCreator);
        assertEq(gCollective.maxWinners(), defaultMaxWinners);
        assertEq(gCollective.activatedWinners(), 1);
        assertEq(gCollective.expiry(), defaultGiveawayStartTime + defaultGiveawayDuration);
        assertEq(gCollective.winnerActivated(winner), true);
        assertEq(gCollective.delegationsByWinner(winner), winner);
    }

    function _createGiveawayCollective(
        bool _canClaimNFTBack
    ) private returns(GiveawayCollective){

        uint256 nonceOfFactory = vm.getNonce(address(giveawayFactory));
        address payable nextCollectiveAddress = payable(StdUtils.computeCreateAddress(address(giveawayFactory), nonceOfFactory));
        vm.prank(defaultCreator);
        defaultPreciousToken.approve(nextCollectiveAddress, defaultPreciousTokenId);

        GiveawayCollective.GiveawayCollectiveOptions memory inputOpts = GiveawayCollective.GiveawayCollectiveOptions({
            collectiveTitleName: defaultCollectiveTitleName,
            creator: defaultCreator,
            preciousToken: defaultPreciousToken,
            preciousTokenId: defaultPreciousTokenId,
            maxWinners: defaultMaxWinners,
            giveawayStartTime: defaultGiveawayStartTime, 
            giveawayDuration: defaultGiveawayDuration,
            canClaimNFTBack: _canClaimNFTBack,
            governanceOpts: defaultGovernanceOpts
        });

        GiveawayCollective gCollective = giveawayFactory.createGiveawayCollective(inputOpts);
        return gCollective;
    }

}