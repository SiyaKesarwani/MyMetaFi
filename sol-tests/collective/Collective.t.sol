// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "contracts/crowdfund/CollectiveCrowdfundFactory.sol";
import "contracts/crowdfund/SingleNFTCrowdfund.sol";
import "contracts/crowdfund/CollectionNFTCrowdfund.sol";
import "contracts/collective/CollectiveFactory.sol";
import "../../contracts/collective/Collective.sol";
import "../../contracts/collective/distribution/Distributor.sol";
import "../../contracts/globals/Globals.sol";
import "../../contracts/utils/Proxy.sol";
import "../TestUtils.sol";
import "../crowdfund/TestERC721Vault.sol";
import "./DummyCallTarget.sol";
import "../DummyERC20.sol";

contract CollectiveTest is Test, TestUtils {

    event DistributionClaimedByCollectiveContributor(
        ICollective indexed collective,
        address indexed contributorAddress,
        IDistributor.TokenType tokenType,
        address token,
        uint256 amountClaimed
    );

    ICollective createdCollective;
    string defaultCollectiveTitleName = "Crowdfund";
    uint96 defaultFundraiseGoal = 4100 ether; 
    uint96 defaultCallValueToBuyNFT = 4000 ether;
    uint40 defaultCrowdFundDuration = 30 * 24 * 60 * 60; //30 days
    uint96 defaultLowerLimitInvestment = 1e16; // Minimum investment amount selected by the host can be between 0.01ETH - 2.5% of fundraise goal
    uint96 defaultUpperLimitInvestment = 820 ether; // Maximum investment amount set at the backend is 20 ETH
    address defaultInitialContributor = 0xB9E1765eb11aF3B4C607f0D4e72b1A62F5DF302F;
    uint96 defaultInitialContribution = 102.5 ether; // Minimum 2.5% 
    ICollectiveCrowdfund.GovernanceOpts defaultGovernanceOpts = ICollectiveCrowdfund.GovernanceOpts(
            604800, 86400, 8000);

    Globals globals = new Globals(address(this));
    CollectiveCrowdfundFactory collectiveCrowdfundFactory = new CollectiveCrowdfundFactory(globals);
    SingleNFTCrowdfund singleNFTCrowdfund = new SingleNFTCrowdfund(globals);
    CollectionNFTCrowdfund collectionNFTCrowdfund = new CollectionNFTCrowdfund(globals);
    CollectiveFactory collectiveFactory = new CollectiveFactory(globals);
    Collective collective = new Collective(globals);
    TestERC721Vault erc721Vault = new TestERC721Vault();
    Distributor distributor = new Distributor(globals);
    DummyCallTarget callTarget = new DummyCallTarget();
    IERC721 preciousToken = erc721Vault.token(); 
    uint256 tokenId = erc721Vault.mint();
    DummyERC20 erc20 = new DummyERC20();
    SingleNFTCrowdfund scf;

    address payable feeRecipient = payable(0xe5ba98010c85e1386F5C06b9E947DFFF92553796);
    uint16 feeBps = 250;
    address openseaSeaport = address(erc721Vault);

    constructor() {
        globals.setAddress(LibGlobals.GLOBAL_SINGLE_BUY_CF_IMPL, address(singleNFTCrowdfund));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTION_BUY_CF_IMPL, address(collectionNFTCrowdfund));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_FACTORY, address(collectiveFactory));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_IMPL, address(collective));
        globals.setAddress(LibGlobals.GLOBAL_DISTRIBUTOR, address(distributor));
        globals.setAddress(LibGlobals.GLOBAL_FEE_RECIPIENT, feeRecipient);
        globals.setUint256(LibGlobals.GLOBAL_FEE_BPS, feeBps);
        globals.setAddress(LibGlobals.GLOBAL_VALIDSIGNER, 0x73C6D4A841dAb46BF11F7eBa1E379cD087B95CE4);
        globals.setAddress(LibGlobals.GLOBAL_OPENSEA_SEAPORT, openseaSeaport);
    }

    function setUp() public{
        SingleNFTCrowdfund.SingleNFTCrowdfundOptions memory opts = SingleNFTCrowdfund.SingleNFTCrowdfundOptions({
            collectiveTitleName: defaultCollectiveTitleName,
            nftContractAddress: preciousToken,
            nftTokenId: tokenId,
            fundraiseGoal: defaultFundraiseGoal,
            crowdFundDuration: defaultCrowdFundDuration,
            lowerLimitInvestment: defaultLowerLimitInvestment, 
            initialContributor: defaultInitialContributor,
            governanceOpts: defaultGovernanceOpts
        });
        scf = collectiveCrowdfundFactory.createSingleNFTCrowdfund{ value: defaultUpperLimitInvestment }(
            opts
        );
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        hoax(contributor1, defaultUpperLimitInvestment);
        scf.contribute{ value: defaultUpperLimitInvestment }(contributor1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        hoax(contributor2, defaultUpperLimitInvestment);
        scf.contribute{ value: defaultUpperLimitInvestment }(contributor2);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        hoax(contributor3, defaultUpperLimitInvestment);
        scf.contribute{ value: defaultUpperLimitInvestment }(contributor3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        hoax(contributor4, defaultUpperLimitInvestment);
        scf.contribute{ value: defaultUpperLimitInvestment }(contributor4);
        vm.prank(contributor3);
        createdCollective = scf.buy(
            payable(openseaSeaport),
            defaultCallValueToBuyNFT,
            abi.encodeCall(erc721Vault.claim, (tokenId))
        );
        assertEq(address(feeRecipient).balance, 100 ether);
    }

    function testCollectiveCreatedSuccessfully() external {
        assertEq(createdCollective.getGovernanceValues().voteDuration, 604800);
        assertEq(createdCollective.getGovernanceValues().vetoDuration, 86400);
        assertEq(createdCollective.getGovernanceValues().passThresholdBps, 8000);
        assertEq(createdCollective.getTotalVotingPowerOfCollective(), defaultFundraiseGoal);
        assertEq(createdCollective.preciousNFTHash(), keccak256(abi.encodePacked(preciousToken, tokenId)));
        assertEq(createdCollective.crowdfundAddress(), address(scf));
    }

    function testOnlyOpenseaCanSendETH() external {
        hoax(openseaSeaport, 1 ether);
        (bool ok, ) = payable(address(createdCollective)).call{value: 1 ether}("");
        require(ok, "Failed");
    }

    function testCreateNativeDistributionWithoutFeeBps() external {
        globals.setUint256(LibGlobals.GLOBAL_DISTRIBUTOR_FEE_BPS, 0);
        hoax(openseaSeaport, 10 ether);
        (bool ok, ) = payable(address(createdCollective)).call{value: 10 ether}("");
        require(ok, "Failed");
        bytes memory distributionCalldata = abi.encodeWithSelector(Collective.executeProposalCreateDistribution.selector,
        10 ether, IDistributor.TokenType.Native, address(0));
        ICollective.ArbitraryCall memory callData = ICollective.ArbitraryCall({
            target: payable(address(createdCollective)),
            value: 0,
            data: distributionCalldata,
            expectedResultHash: 0x0
        });
        vm.prank(defaultInitialContributor);
        createdCollective.executeProposalArbitraryCall(callData, preciousToken, tokenId, "0x");
        assertEq(address(createdCollective).balance, 0);
        assertEq(address(feeRecipient).balance, 100 ether);
        assertEq(address(distributor).balance, 10 ether);
    }

    function testCreateTokenDistributionWithoutFeeBps() external {
        globals.setUint256(LibGlobals.GLOBAL_DISTRIBUTOR_FEE_BPS, 0);
        erc20.deal(address(createdCollective), 100);
        bytes memory distributionCalldata = abi.encodeWithSelector(Collective.executeProposalCreateDistribution.selector,
        100, IDistributor.TokenType.Erc20, address(erc20));
        ICollective.ArbitraryCall memory callData = ICollective.ArbitraryCall({
            target: payable(address(createdCollective)),
            value: 0,
            data: distributionCalldata,
            expectedResultHash: 0x0
        });
        vm.prank(defaultInitialContributor);
        createdCollective.executeProposalArbitraryCall(callData, preciousToken, tokenId, "0x");
        assertEq(erc20.balanceOf(address(createdCollective)), 0);
        assertEq(erc20.balanceOf(address(feeRecipient)), 0);
        assertEq(erc20.balanceOf(address(distributor)), 100);
    }

    function test_CannotReinitialize() external {
        Collective.CollectiveInitData memory initData;
        vm.expectRevert(abi.encodeWithSelector(Implementation.OnlyConstructorError.selector));
        createdCollective.initialize(initData);
    }

    function test_CannotReceiveETHFromOtherThanOpensea() external {
        hoax(address(this), 1 ether);
        vm.expectRevert();
        payable(address(createdCollective)).transfer(1 ether);
    }

    function test_CannotCallArbitraryCallWithWrongPreciousList() external {
        ICollective.ArbitraryCall memory callData = ICollective.ArbitraryCall({
            target: payable(address(this)),
            value: 0,
            data: "0x",
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(ICollective.BadPreciousListError.selector));
        vm.prank(defaultInitialContributor);
        createdCollective.executeProposalArbitraryCall(callData, preciousToken, 190, "0x");
    }

    function test_CannotCallArbitraryCallIfGloballyDisabled() external {
        globals.setBool(LibGlobals.GLOBAL_DISABLE_MMF_ACTIONS, true);
        ICollective.ArbitraryCall memory callData = ICollective.ArbitraryCall({
            target: payable(address(this)),
            value: 0,
            data: "0x",
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(Collective.OnlyWhenEnabledError.selector));
        vm.prank(defaultInitialContributor);
        createdCollective.executeProposalArbitraryCall(callData, preciousToken, tokenId, "0x");
    }

    function test_NonContributorCannotCallArbitraryCall() external{
        ICollective.ArbitraryCall memory callData = ICollective.ArbitraryCall({
            target: payable(address(this)),
            value: 0,
            data: "0x",
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(ICollectiveCrowdfund.OnlyCollectiveContributor.selector));
        createdCollective.executeProposalArbitraryCall(callData, preciousToken, tokenId, "0x");
    }

    function test_CannotCreateZeroAmountDistribution() external {
        bytes memory distributionCalldata = abi.encodeWithSelector(Collective.executeProposalCreateDistribution.selector,
        0, IDistributor.TokenType.Native, address(0));
        ICollective.ArbitraryCall memory callData = ICollective.ArbitraryCall({
            target: payable(address(createdCollective)),
            value: 0,
            data: distributionCalldata,
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(Collective.ArbitraryCallFailed.selector, 
        abi.encodeWithSelector(Collective.ZeroAmountDistribution.selector)));
        vm.prank(defaultInitialContributor);
        createdCollective.executeProposalArbitraryCall(callData, preciousToken, tokenId, "0x");
    }

    function test_CannotCreateNativeDistributionIfZeroEtherAvailable() external {
        bytes memory distributionCalldata = abi.encodeWithSelector(Collective.executeProposalCreateDistribution.selector,
        10 ether, IDistributor.TokenType.Native, address(0));
        ICollective.ArbitraryCall memory callData = ICollective.ArbitraryCall({
            target: payable(address(createdCollective)),
            value: 0,
            data: distributionCalldata,
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(Collective.ArbitraryCallFailed.selector, 
        abi.encodeWithSelector(Collective.InsufficientAmount.selector, 10 ether, 0)));
        vm.prank(defaultInitialContributor);
        createdCollective.executeProposalArbitraryCall(callData, preciousToken, tokenId, "0x");
    }

    function test_CannotCreateTokenDistributionIfLessTokenAvailable() external {
        erc20.deal(address(createdCollective), 10);
        bytes memory distributionCalldata = abi.encodeWithSelector(Collective.executeProposalCreateDistribution.selector,
        100, IDistributor.TokenType.Erc20, address(erc20));
        ICollective.ArbitraryCall memory callData = ICollective.ArbitraryCall({
            target: payable(address(createdCollective)),
            value: 0,
            data: distributionCalldata,
            expectedResultHash: 0x0
        });
        vm.expectRevert(abi.encodeWithSelector(Collective.ArbitraryCallFailed.selector, 
        abi.encodeWithSelector(Collective.InsufficientAmount.selector, 100, 10)));
        vm.prank(defaultInitialContributor);
        createdCollective.executeProposalArbitraryCall(callData, preciousToken, tokenId, "0x");
    }
}