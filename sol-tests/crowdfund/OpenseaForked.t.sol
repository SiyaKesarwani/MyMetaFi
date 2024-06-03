// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "../TestUtils.sol";
import "../DummyERC721.sol";
import "../OpenseaTestUtils.sol";
import "../../contracts/crowdfund/SingleNFTCrowdfund.sol";
import "../../contracts/globals/Globals.sol";
import "../../contracts/globals/LibGlobals.sol";
import "contracts/collective/Collective.sol";
import "../../contracts/utils/Proxy.sol";

contract OpenseaFulfillOrderTest is TestUtils, OpenseaTestUtils {
    SingleNFTCrowdfund scf;
    DummyERC721 token;
    uint256 tokenId;
    ICollectiveCrowdfund.GovernanceOpts defaultGovernanceOpts = ICollectiveCrowdfund.GovernanceOpts(
            604800, 86400, 8000);

    uint256 sellerPrivateKey = 0xDEADBEEF;
    address payable seller = payable(vm.addr(sellerPrivateKey));

    IOpenseaExchange SEAPORT = IOpenseaExchange(0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC);

    constructor() OpenseaTestUtils(SEAPORT) {
        token = new DummyERC721();
        tokenId = token.mint(seller);

        Globals globals = new Globals(address(this));

        SingleNFTCrowdfund singleNFTCrowdfundImpl = new SingleNFTCrowdfund(globals);
        vm.deal(address(this), 25e17);

        // Create a BuyCrowdfund
        scf = SingleNFTCrowdfund(
            payable(
                address(
                    new Proxy{ value: 25e17 }(
                        singleNFTCrowdfundImpl,
                        abi.encodeCall(
                            SingleNFTCrowdfund.initialize,
                            SingleNFTCrowdfund.SingleNFTCrowdfundOptions({
                                collectiveTitleName: "TestOpenseaForked",
                                nftContractAddress: token,
                                nftTokenId: tokenId,
                                fundraiseGoal: 100e18, // 100 ETH
                                crowdFundDuration: 30 * 24 * 60 * 60, //30 days
                                lowerLimitInvestment: 1e16, 
                                initialContributor: address(this),
                                governanceOpts: defaultGovernanceOpts
                            })
                        )
                    )
                )
            )
        );
    }

    function testForked_canBuyListedNFTFromOS() public onlyForked {
        uint256 listPrice = 100e18;
        uint256 duration = 7 days;

        // Create OpenSea dutch auction listing
        vm.startPrank(seller);
        token.setApprovalForAll(address(SEAPORT), true);
        IOpenseaExchange.Order memory order = _createFullOpenseaOrderParams(
            BuyOpenseaListingParams({
                maker: seller,
                buyer: address(scf),
                token: IERC721(address(token)),
                tokenId: tokenId,
                listPrice: listPrice,
                startTime: block.timestamp,
                duration: duration,
                zone: address(0),
                conduitKey: bytes32(0)
            })
        );
        vm.stopPrank();

        bytes32 orderHash = SEAPORT.getOrderHash(
            IOpenseaExchange.OrderComponents({
                offerer: order.parameters.offerer,
                zone: order.parameters.zone,
                offer: order.parameters.offer,
                consideration: order.parameters.consideration,
                orderType: order.parameters.orderType,
                startTime: order.parameters.startTime,
                endTime: order.parameters.endTime,
                zoneHash: order.parameters.zoneHash,
                salt: order.parameters.salt,
                conduitKey: order.parameters.conduitKey,
                counter: 0
            })
        );

        // Generate signature for order
        bytes32 domainSeparator = 0xb50c8913581289bd2e066aeef89fceb9615d490d673131fd1a7047436706834e;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sellerPrivateKey,
            keccak256(abi.encodePacked(bytes2(0x1901), domainSeparator, orderHash))
        );
        order.signature = abi.encodePacked(r, s, v);

        // Buy OpenSea listing
        // Contribute and delegate with contributor1
        address payable contributor1 = _randomAddress();
        address delegate1 = contributor1;
        vm.deal(contributor1, 20e18);
        vm.prank(contributor1);
        scf.contribute{ value: 10e18 }(delegate1);
        // Contributing with contributor2
        address payable contributor2 = _randomAddress();
        address delegate2 = contributor2;
        vm.deal(contributor2, 20e18);
        vm.prank(contributor2);
        scf.contribute{ value: 20e18 }(delegate2);
        // Contributing again with contributor1 with another delegate
        address delegate1_ = contributor2;
        vm.prank(contributor1);
        scf.contribute{ value: 10e18 }(delegate1_);
        // Contributing with contributor3
        address payable contributor3 = _randomAddress();
        address delegate3 = contributor2;
        vm.deal(contributor3, 20e18);
        vm.prank(contributor3);
        scf.contribute{ value: 20e18 }(delegate3);
        // Contributing with contributor4
        address payable contributor4 = _randomAddress();
        address delegate4 = contributor2;
        vm.deal(contributor4, 20e18);
        vm.prank(contributor4);
        scf.contribute{ value: 20e18 }(delegate4);
        // Contributing with contributor5
        address payable contributor5 = _randomAddress();
        address delegate5 = contributor2;
        vm.deal(contributor5, 20e18);
        vm.prank(contributor5);
        scf.contribute{ value: 20e18 }(delegate5);

        vm.prank(contributor5);
        ICollective collective_ = scf.buy(
            payable(address(SEAPORT)),
            uint96(listPrice),
            abi.encodeCall(SEAPORT.fulfillOrder, (order, bytes32(0)))
        );

        assertEq(token.ownerOf(tokenId), address(collective_));
        assertEq(address(scf).balance, 25e17);
    }
}
