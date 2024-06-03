// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../tokens/ERC721Receiver.sol";
import "../utils/LibSafeERC721.sol";
import "../utils/LibSafeCast.sol";
import "../utils/EIP712.sol";
import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";
import "../utils/LibAddress.sol";

import "./ICollective.sol";
import "./distribution/IDistributor.sol";

/// @notice The governance contract that also custodies the precious NFTs.  
contract GiveawayCollective is ICollective, ERC721Receiver, Implementation, EIP712, ReentrancyGuard {
    using LibSafeCast for uint256;
    using LibSafeERC721 for IERC721;
    using LibAddress for address payable;

    /// @notice Lifecycle of a giveaway collective
    enum GiveawayLifecycle {
        Active,
        Expired,
        Successful
    }

    /// @notice Arguments used to initialize the `Giveaway Collective`.
    struct GiveawayCollectiveOptions {
        // The name of the Giveaway Collective.
        string collectiveTitleName;
        // The creator of this giveaway
        address creator;
        // The ERC721 contract of the NFT to be fractionalised.
        IERC721 preciousToken;
        // ID of the NFT to be fractionalised.
        uint256 preciousTokenId;
        // Maximum number of winners in this giveaway.
        uint256 maxWinners;
        // When this giveaway will start, in seconds.
        uint40 giveawayStartTime;
        // How long this collective is active for participants to join giveaway, in seconds.
        uint40 giveawayDuration;
        // Will the creator take back his nft if not enough people join
        bool canClaimNFTBack;
        // Governance options.
        GovernanceOpts governanceOpts;
    }

    /// @notice Arguments used to activate membership
    struct ActivateMembershipCall {
        address winner;
        address delegate;
        // address leader;
    }

    error WrongGovernanceValues();
    error WrongLifecycle(GiveawayLifecycle lc);
    error WinnerHasAlreadyActivated();
    error InvalidDelegate();
    error InvalidWinner();
    error OnlyCreatorCanCall();
    error ZeroAddressCreator();
    error OnlyWinner();
    error ArbitraryCallFailed(
        bytes revertData
    );
    error UnexpectedCallResultHash(
        bytes32 resultHash,
        bytes32 expectedResultHash
    );
    error NotEnoughEth(
        uint256 callValue, 
        uint256 ethAvailable
    );
    error OnlySelfCallAllowed();
    error OnlyWhenEnabledError();
    error CreatorShouldApproveNFTFirst(string message);

    event MembershipActivated(address winner);
    event DelegateUpdated(
        address winner, 
        address delegate
    );
    event GiveawayExpiredAndNFTClaimed(address creator);

    event DistributionCreated(
        IDistributor.TokenType tokenType,
        uint256 amount
    );
    
    /// @inheritdoc ICollective
    uint256 public nonce;

    /// @inheritdoc ICollective
    bytes32 public preciousNFTHash;

    /// @notice The address of creator in case he will be given his nft back
    address public creator;

    // /// @notice The address of leader to be decided from backend
    // address public leader;

    /// @notice Maximum number of winners in this giveaway.
    uint256 public maxWinners;

    /// @notice Number of winners who have activated their membership.
    uint256 public activatedWinners;

    /// @notice When this collective expires.
    uint40 public expiry;

    /// @notice Mapping of Winners to check they have activated membership or not.
    mapping(address => bool) public winnerActivated;

    /// @notice Whom a winner last delegated to.
    mapping(address => address) public delegationsByWinner;

    /// @notice Will the creator take back his nft if not enough people join
    bool public canClaimNFTBack;

    /// @notice typehash as per EIP712 standard
    bytes32 constant EXECUTE_ARBITRARY_CALL_TYPEHASH = keccak256(
        "ExecuteProposal(address target,uint256 value,bytes data,bytes32 expectedResultHash,address preciousToken,uint256 preciousTokenId,uint256 nonce)");

    /// @notice The order hash of listed NFT
    bytes32 private _orderHash;

    /// @notice The OrderComps after NFT is listed (to cancel the listing)
    IOpenseaExchange.OrderComponents[] private _orderCompsOfListedNFT;

    /// @notice Governance parameters, fixed from the inception of this collective. But CAN BE changed later on proposals.
    GovernanceOpts private _governanceValues;

    /// @notice This is createDistribution flag
    IDistributor.DistributionInfo private _distInfo;
    
    /// @notice The `Globals` contract storing global configuration values. 
    /// This contract is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    modifier onlyWhenNotGloballyDisabled() {
        if (_GLOBALS.getBool(LibGlobals.GLOBAL_DISABLE_MMF_ACTIONS)) {
            revert OnlyWhenEnabledError();
        }
        _;
    }

    /// @notice Set the `Globals` contract address.
    constructor(IGlobals globals) EIP712("GiveawayCollective", "1") {
        _GLOBALS = globals;
    }

    /// @inheritdoc ICollective
    function crowdfundAddress() external pure returns (address){
        return(address(0));
    }

    /// @inheritdoc ICollective
    function getTotalVotingPowerOfCollective() external pure returns (uint96){
        return(0);
    }

    // As distribution can only be called once
    // So, restrict this function to receive ETH only from seaport contract
    receive() external payable {
        if(msg.sender != _GLOBALS.getAddress(LibGlobals.GLOBAL_OPENSEA_SEAPORT)){
            revert();
        }
    }

    /// @inheritdoc ICollective
    function initialize(
        CollectiveInitData memory initData
    ) 
        external  
        view
        onlyConstructor
    {
        revert();
    }

    function initializeGiveaway(
        GiveawayCollectiveOptions memory initData
    ) 
        external 
        onlyConstructor 
    {   
        // Check the creator should not be zero address
        if(initData.creator == address(0)){
            revert ZeroAddressCreator();
        }
        // Check that the creator should be the owner of the nft and
        // He must have approved this contract first
        if(initData.preciousToken.ownerOf(initData.preciousTokenId) != initData.creator ||
            initData.preciousToken.getApproved(initData.preciousTokenId) != address(this)){
                revert CreatorShouldApproveNFTFirst("Creator is not NFT Owner || NFT is not approved");
        }
        // Check vote duration is within the limit (1 to 7 days only)
        // Check veto duration is within the limit (1 to 3 days only)
        // Check the pass threshold BPS is within limit or not (where 100% = 10,000 and 50% = 5000)
        if(initData.governanceOpts.voteDuration < 86400 || initData.governanceOpts.voteDuration > 604800 ||
            initData.governanceOpts.vetoDuration < 86400 || initData.governanceOpts.vetoDuration > 259200 ||
            initData.governanceOpts.passThresholdBps > 1e4 || initData.governanceOpts.passThresholdBps < 5e3){
                revert WrongGovernanceValues();
        }
        // Transfer the nft to this contract
        initData.preciousToken.safeTransferFrom(initData.creator, address(this), initData.preciousTokenId);
        // Set the governance parameters.
        _governanceValues = GovernanceOpts({
            voteDuration: initData.governanceOpts.voteDuration,
            vetoDuration: initData.governanceOpts.vetoDuration,
            passThresholdBps: initData.governanceOpts.passThresholdBps
        });
        // Set the precious nft details.
        _setPreciousNFT(initData.preciousToken, initData.preciousTokenId);
        // Set the creator address
        creator = initData.creator;
        // Set the max no. of winners of this giveaway
        maxWinners = initData.maxWinners;
        // Set the flag if the creator wants to reclaim back his nft
        canClaimNFTBack = initData.canClaimNFTBack;
        // Set the expiry of this collective
        expiry = initData.giveawayStartTime + initData.giveawayDuration;
    }

    /// @inheritdoc ICollective
    function getGovernanceValues() external view returns(GovernanceOpts memory gv){
        return _governanceValues;
    }

    /// @notice Returns the claimable earning of individual
    /// @param winner The contributor whose earning is being fetched
    function getClaimableAmountOfContributor(
        address winner
    ) 
        external 
        view 
        returns(uint128 claimableAmount)
    {
        IDistributor.DistributionInfo memory distInfo = _distInfo;
        // Get the address of the token distributor.
        IDistributor distributor = IDistributor(
            _GLOBALS.getAddress(LibGlobals.GLOBAL_DISTRIBUTOR)
        );

        if(address(distInfo.collective) == address(this)){
            if(distributor.hasCollectiveContributorClaimed(this, winner, 1)){
                return 0;
            }
            claimableAmount = (distInfo.memberSupply/activatedWinners).safeCastUint256ToUint128();
        }
        else{
            claimableAmount = getDistributionShareOf(winner).safeCastUint256ToUint128();
        }
    }

    /// @notice If this collective is Successful/Active
    /// then activated members can update their delegates
    function updateOnlyDelegate(
        address newDelegate
    ) 
        external 
        onlyDelegateCall 
    {  
        // Only allow if collective is Successful/Active
        {
            GiveawayLifecycle lc = getGiveawayLifecycle();
            if (lc != GiveawayLifecycle.Successful || lc != GiveawayLifecycle.Active) {
                revert WrongLifecycle(lc);
            }
        }

        // Only allow if he is activated member
        if(winnerActivated[msg.sender] != true){
            revert OnlyWinner(); 
        }
        _updateDelegate(msg.sender, newDelegate);
    }

    /// @notice Lists the NFT on Opensea
    /// @param listingParams All new listing params
    function executeProposalListToOpensea(
        ListingCall memory listingParams
    ) 
        external  
        returns(bytes32 orderHash) 
    {
        _checkIfSelfCall();
        
        // Only allow to list the nft for selling while Giveaway is Successful.
        {
            GiveawayLifecycle lc = getGiveawayLifecycle();
            if (lc != GiveawayLifecycle.Successful) {
                revert WrongLifecycle(lc);
            }
        }

        // Check the seaport address is same as stored in Globals
        // Otherwise first update in globals
        if(IOpenseaExchange(_GLOBALS.getAddress(LibGlobals.GLOBAL_OPENSEA_SEAPORT)) != listingParams.seaport){
            revert SeaportNotMatchingGlobals
            (
                _GLOBALS.getAddress(LibGlobals.GLOBAL_OPENSEA_SEAPORT), 
                address(listingParams.seaport)
            );
        }

        // Check the fee recipients to receive funds on sold
        if (listingParams.fees.length != listingParams.feeRecipients.length) {
            revert InvalidFeeRecipients();
        }

        // Check that the precious list is valid.
        _checkValidPreciousList(listingParams.preciousToken, listingParams.preciousTokenId);

        // Only applicable if the owner of NFT is this contract
        _checkHasPrecious(listingParams.preciousToken, listingParams.preciousTokenId);

        // If we are not listing the NFT for the first time
        bytes32 lastOrderHash = _orderHash;
        if(lastOrderHash != bytes32(0)){
            // If it is not sold then, cancel last listing first using `_orderCompsOfListedNFT`
            IOpenseaExchange.OrderComponents[] memory orderComps;
            orderComps = _orderCompsOfListedNFT;
            listingParams.seaport.cancel(orderComps);
            emit OpenseaLastOrderCancelled(lastOrderHash,  listingParams.preciousToken,  listingParams.preciousTokenId);
        }
        // List the NFT for sale for the first time OR
        // List it again after cancelling last order "IF NOT SOLD"
        // Create a (basic) seaport 721 sell order.
        IOpenseaExchange.Order[] memory orders = new IOpenseaExchange.Order[](1);
        IOpenseaExchange.Order memory order = orders[0];
        IOpenseaExchange.OrderParameters memory orderParams = order.parameters;
        orderParams.offerer = address(this);
        orderParams.startTime = block.timestamp;
        orderParams.endTime = block.timestamp + 60 * 60 * 24 * 30; //30 days
        orderParams.zone = _GLOBALS.getAddress(LibGlobals.GLOBAL_OPENSEA_ZONE);
        orderParams.orderType = orderParams.zone == address(0)
            ? IOpenseaExchange.OrderType.FULL_OPEN
            : IOpenseaExchange.OrderType.FULL_RESTRICTED; 
        orderParams.salt = 0;
        orderParams.conduitKey = _GLOBALS.getBytes32(LibGlobals.GLOBAL_OPENSEA_CONDUIT_KEY);
        orderParams.totalOriginalConsiderationItems = 1 + listingParams.fees.length;
        // What we are selling.
        orderParams.offer = new IOpenseaExchange.OfferItem[](1);
        {
            IOpenseaExchange.OfferItem memory offer = orderParams.offer[0];
            offer.itemType = IOpenseaExchange.ItemType.ERC721;
            offer.token = address(listingParams.preciousToken);
            offer.identifierOrCriteria = listingParams.preciousTokenId;
            offer.startAmount = 1;
            offer.endAmount = 1;
        }
        // What we want for it.
        orderParams.consideration = new IOpenseaExchange.ConsiderationItem[](1 + listingParams.fees.length);
        {
            IOpenseaExchange.ConsiderationItem memory cons = orderParams.consideration[0];
            cons.itemType = IOpenseaExchange.ItemType.NATIVE;
            cons.token = address(0);
            cons.identifierOrCriteria = 0;
            cons.startAmount = cons.endAmount = listingParams.listPrice;
            cons.recipient = payable(address(this));
            for (uint256 i; i < listingParams.fees.length; ++i) {
                cons = orderParams.consideration[1 + i];
                cons.itemType = IOpenseaExchange.ItemType.NATIVE;
                cons.token = address(0);
                cons.identifierOrCriteria = 0;
                cons.startAmount = cons.endAmount = listingParams.fees[i];
                cons.recipient = listingParams.feeRecipients[i];
            }
        }
        (address conduit, ) = listingParams.conduitController.getConduit(_GLOBALS.getBytes32(LibGlobals.GLOBAL_OPENSEA_CONDUIT_KEY));
        listingParams.preciousToken.approve(conduit, listingParams.preciousTokenId);
        require(listingParams.preciousToken.getApproved(listingParams.preciousTokenId) == conduit, 
        "Collective: NFT unpproved");
        
        orderHash = _getOrderHash(orderParams, listingParams.seaport);

        // Validate the order on-chain so no signature is required to fill it.
        assert(listingParams.seaport.validate(orders));

        _orderHash = orderHash;

        emit OpenseaOrderListed(
            orderParams,
            orderHash,
            listingParams.preciousToken,
            listingParams.preciousTokenId,
            listingParams.sellingPrice,
            orderParams.endTime
        );
    }

    /// @notice Activate the winners' membership
    function activateMembership(
        ActivateMembershipCall memory activateParams
    ) external{
        _checkIfSelfCall();

        // Creator cannot be a winner/zeroAddress/this contract
        if(
            activateParams.winner == creator || 
            activateParams.winner == address(0) || 
            activateParams.winner == address(this)
        ){
            revert InvalidWinner();
        }
        
        // Only allow to activate membership while Giveaway is Active.
        {
            GiveawayLifecycle lc = getGiveawayLifecycle();
            if (lc != GiveawayLifecycle.Active) {
                revert WrongLifecycle(lc);
            }
        }

        // Only allow if he has not already activated
        if(winnerActivated[activateParams.winner] == true){
            revert WinnerHasAlreadyActivated(); 
        }

        // Every check has passed, now update the values.
        activatedWinners += 1;
        winnerActivated[activateParams.winner] = true;
        _updateDelegate(activateParams.winner, activateParams.delegate);
        // if(leader != activateParams.leader){
        //     leader = activateParams.leader;
        // }
        emit MembershipActivated(activateParams.winner);
    }

    /// @notice Creator claims NFT back if `claimNFTBack` is true 
    /// and not enough people participated
    function claimNFTBack(
        IERC721 preciousToken,
        uint256 preciousTokenId
    ) 
        external 
        onlyDelegateCall 
        nonReentrant
    {
        // Check that the precious list is valid.
        _checkValidPreciousList(preciousToken, preciousTokenId);

        // Only applicable if the owner of NFT is this contract
        _checkHasPrecious(preciousToken, preciousTokenId);

        // Only creator can call this function.
        if(msg.sender != creator){
            revert OnlyCreatorCanCall();
        }
        // Only allow to claim NFT back by creator while Giveaway is Expired.
        {
            GiveawayLifecycle lc = getGiveawayLifecycle();
            if (lc != GiveawayLifecycle.Expired) {
                revert WrongLifecycle(lc);
            }
        }

        // Give the NFT back to the owner
        preciousToken.safeTransferFrom(address(this), msg.sender, preciousTokenId);
        emit GiveawayExpiredAndNFTClaimed(msg.sender);  
    }

    // /// @notice Create a ETH distribution if it is not created yet,
    // ///         by moving the collective's entire balance
    // ///         to the `Distributor` contract and immediately creating a
    // ///        distribution governed by this collective.
    // ///         Also claim all the earnings of caller from this collective
    // ///        This function can be called by anyone externally or `batchClaim()` from Distributor contract
    // /// @param winner The contributor whose earning will be claimed
    // function createDistributionAndClaim(
    //     address winner
    // ) 
    //     external  
    //     onlyWhenNotGloballyDisabled
    //     onlyDelegateCall
    //     nonReentrant
    // {   
    //     // This giveaway should be succsessful and caller should be an active winner.
    //     if(getDistributionShareOf(winner) == 0){
    //         revert CannotClaimZeroEarnings(0);
    //     }

    //     // Get the address of the token distributor.
    //     IDistributor distributor = IDistributor(
    //         _GLOBALS.getAddress(LibGlobals.GLOBAL_DISTRIBUTOR)
    //     );

    //     // If distribution is not created yet,
    //     // then first create distribution and claim earning for the caller
    //     if(address(_distInfo.collective) != address(this)){
    //         (uint128 memberSupply, uint128 earning) = _getMemberSupplyOfCollective();
    //         address payable feeRecipient = payable(_GLOBALS.getAddress(LibGlobals.GLOBAL_FEE_RECIPIENT)); 
    //         // Transfer the fee to the platform
    //         feeRecipient.transferEth(earning - memberSupply);
    //         _distInfo = _createDistribution(IDistributor.TokenType.Native, distributor, memberSupply);
    //     }
    //     else{
    //         if(distributor.hasCollectiveContributorClaimed(this, winner, 1))
    //             return; 
    //     }
    //     // Claim earnings of the caller from this collective
    //     uint128 amountClaimed = distributor.claim(_distInfo, winner);
    //     if(amountClaimed < 1) {
    //         revert CannotClaimZeroEarnings(amountClaimed);
    //     }
    // }

    /// @notice Update the governance values of this collective
    /// @param governanceValues New governanceValues for this collective.
    function executeProposalUpdateGovernanceValues(
        GovernanceOpts memory governanceValues
    ) 
        external
    {
        _checkIfSelfCall();
        
        // Only allow to updatate governance values while Giveaway is Successful.
        {
            GiveawayLifecycle lc = getGiveawayLifecycle();
            if (lc != GiveawayLifecycle.Successful) {
                revert WrongLifecycle(lc);
            }
        }

        // Check vote duration is within the limit (1 to 7 days only)
        // Check veto duration is within the limit (1 to 3 days only)
        // Check the pass threshold BPS is within limit or not (where 100% = 10,000 and 50% = 5000)
        if(governanceValues.voteDuration < 86400 || governanceValues.voteDuration > 604800 ||
            governanceValues.vetoDuration < 86400 || governanceValues.vetoDuration > 259200 ||
            governanceValues.passThresholdBps > 1e4 || governanceValues.passThresholdBps < 5e3){
                revert WrongGovernanceValues();
            }
        _governanceValues = governanceValues;
        emit GovernanceValuesUpdated(governanceValues);
    }

    /// @inheritdoc ICollective
    function executeProposalArbitraryCall(
        ArbitraryCall calldata call,
        IERC721 preciousToken,
        uint256 preciousTokenId,
        bytes calldata signature
    )
        external  
        onlyWhenNotGloballyDisabled
        onlyDelegateCall
    {
        // Check that the precious list is valid.
        _checkValidPreciousList(preciousToken,preciousTokenId);
        
        // If distribution is not created then, 
        // no any amount should be sent in contract.
        if(address(_distInfo.collective) != address(this)){
            require(call.value == 0);
        }

        // Keep track of which preciouses we had before the calls
        // so we can check that we still have them later.
        bool hadPrecious = _getHasPrecious(preciousToken, preciousTokenId);

        // {
        //     bytes32 hash = _hashArbitraryCall(
        //         call,
        //         preciousToken, 
        //         preciousTokenId);
        //     require(ECDSA.recover(hash, signature) == _GLOBALS.getAddress(LibGlobals.GLOBAL_VALIDSIGNER), 
        //     "Collective: invalid signature");
        // }
        nonce++;

        _executeArbitraryCall(call);
        
        // If we had a precious beforehand, ensure that we still have it now.
        if (hadPrecious) {
            _checkHasPrecious(preciousToken, preciousTokenId);
        }
        emit ArbitraryCallExecuted(call.target, call.data);
    }

    /// @inheritdoc ICollective
    function getDistributionShareOf(
        address winner
    ) 
        public 
        view 
        onlyDelegateCall
        returns (uint256)
    {
        GiveawayLifecycle lc = getGiveawayLifecycle();
        // If the giveaway is SUccessful then only a winner can have share
        if(lc == GiveawayLifecycle.Successful){
            if(!_assertIsWinner(winner)){
                return(0);
            }
            // If he is activated winner then,
            (uint128 memberSupply, ) = _getMemberSupplyOfCollective();
            return(memberSupply / activatedWinners);
        }
        // If Giveaway is not Successful yet, return 0.
        return(0);
    }

    /// @notice Get the current lifecycle of the crowdfund.
    function getGiveawayLifecycle() public view returns (GiveawayLifecycle){
        if(activatedWinners == maxWinners){
            // If all the winners have activated membership then declare Successful
            return GiveawayLifecycle.Successful;
        }
        // If max no. of winners have not activated
        if(block.timestamp >= (expiry + 172800)){
            // If after 48 hrs max nobody has activated and creator wants his nft back or not
            // He can claim his nft back
            if(canClaimNFTBack || activatedWinners < 1){
                // And creator wants his NFT back
                return GiveawayLifecycle.Expired;
            }
            // And creator does not want his NFT back then divide membership into Activated members
            // And declare Giveaway as Successful
            return GiveawayLifecycle.Successful;
        }
        // If before 48 hrs max no. of winners have not activated 
        // And creator wants/does not want his NFT back
        return GiveawayLifecycle.Active;
    }

    /// @dev `getOrderHash()` wants an `OrderComponents` struct, which is an `OrderParameters`
    /// struct but with the last field (`totalOriginalConsiderationItems`)
    /// replaced with the maker's nonce. Since we (the maker) never increment
    /// our seaport nonce, it is always 0.
    /// So we temporarily set the `totalOriginalConsiderationItems` field to 0,
    /// force cast the `OrderParameters` into a `OrderComponents` type, call
    /// `getOrderHash()`, and then restore the `totalOriginalConsiderationItems`
    /// field's value before returning.
    function _getOrderHash(
        IOpenseaExchange.OrderParameters memory orderParams,
        IOpenseaExchange seaport
    ) 
        private 
        returns(bytes32 orderHash) 
    {
        uint256 origTotalOriginalConsiderationItems = orderParams.totalOriginalConsiderationItems;
        orderParams.totalOriginalConsiderationItems = 0;
        IOpenseaExchange.OrderComponents memory orderComps;
        assembly {
            orderComps := orderParams
        }
        orderHash = seaport.getOrderHash(orderComps);
        // Storing it in contract to Cancel last listing and listing again
        _orderCompsOfListedNFT.push(orderComps);
        orderParams.totalOriginalConsiderationItems = origTotalOriginalConsiderationItems;
    }

    // Common function for updating delegate from `updateOnlyDelegate()` and `_contribute()`
    function _updateDelegate(
        address winner, 
        address newDelegate
    ) 
        private 
    {
        // Check the delegated Address should be either a Winner or Himself and Non-Null
        if((!_assertIsWinner(newDelegate) && newDelegate != winner)){
            revert InvalidDelegate();
        }

        // Get the old delegate to avoid updating if it is same as new
        address oldDelegate = delegationsByWinner[winner];

        // If the delegate is same as older delegate
        if((oldDelegate == newDelegate)){
            return;
        }

        // Update delegate.
        delegationsByWinner[winner] = newDelegate;
        emit DelegateUpdated(winner, newDelegate);
    }

    // For every Arbitrary call
    function _executeArbitraryCall(
        ArbitraryCall memory call
    ) private {
        // ArbitraryCall memory call = calls[idx];
        // Check that we have enough ETH to execute the call.
        if (address(this).balance < call.value) {
            revert NotEnoughEth(call.value, address(this).balance);
        }
        // Execute the call.
        (bool s, bytes memory r) = call.target.call{ value: call.value }(call.data);
        if (!s) {
            // Call failed. If not optional, revert.
            revert ArbitraryCallFailed(r);
        } else {
            // Call succeeded.
            // If we have a nonzero expectedResultHash, check that the result data
            // from the call has a matching hash.
            if (call.expectedResultHash != bytes32(0)) {
                bytes32 resultHash = keccak256(r);
                if (resultHash != call.expectedResultHash) {
                    revert UnexpectedCallResultHash(resultHash, call.expectedResultHash);
                }
            }
        }
    }

    // To set the precious NFT on creation of this collective
    function _setPreciousNFT(
        IERC721 preciousToken,
        uint256 preciousTokenId
    ) 
        private 
    {
        preciousNFTHash = _hashPreciousNFT(preciousToken, preciousTokenId);
    }
    
    /// @notice Create a token distribution by moving the collective's entire balance
    ///         to the `Distributor` contract and immediately creating a
    ///         distribution governed by this collective.
    /// @param tokenType The type of token to distribute.
    /// @param distributor The distributor contract.
    /// @param memberSupply The total balance of this collective.
    /// @return distInfo The information about the created distribution.
    function _createDistribution(
        IDistributor.TokenType tokenType,
        IDistributor distributor,
        uint256 memberSupply
    ) 
        private 
        returns(IDistributor.DistributionInfo memory distInfo)
    {
        emit DistributionCreated(tokenType, memberSupply);
        // Create a native token distribution.
        if (tokenType == IDistributor.TokenType.Native) {
            return distributor.createNativeDistribution
                { value: memberSupply }(ICollective(address(this)));
        }
    }

    /// @notice To check if this collective is eligible to create distribution or not
    function _getMemberSupplyOfCollective() private view returns(uint128 memberSupply, uint128 earning){
            earning = (address(this).balance).safeCastUint256ToUint128();
            uint96 fee = (earning * _GLOBALS.getUint256(LibGlobals.GLOBAL_FEE_BPS) / 1e4).safeCastUint256ToUint96();
            memberSupply = earning - fee;
    } 

    // Assert that `who` is a winner of this giveaway.
    function _assertIsWinner(
        address who
    ) 
        private 
        view 
        returns(bool)
    {
        return (winnerActivated[who] == true);
    }

    /// @notice To check the proposal executions calls are from this contract Arbitrary call Only
    function _checkIfSelfCall() private view {
        if(msg.sender != address(this)) {
            revert OnlySelfCallAllowed();
        }
    }

    /// @notice Check that the precious list is valid.
    function _checkValidPreciousList(
        IERC721 preciousToken, 
        uint256 preciousTokenId
    ) private view {
        if (!_isPreciousListCorrect(preciousToken, preciousTokenId)) {
            revert BadPreciousListError();
        }
    }

    /// @notice Check that the precious is within this contract or not
    function _checkHasPrecious(
        IERC721 preciousToken, 
        uint256 preciousTokenId
    ) private view {
        if(!_getHasPrecious(preciousToken, preciousTokenId)){
            revert PreciousNotWithinContract(preciousToken, preciousTokenId);
        }
    }

    /// @notice Generates the typehash for arbitraryCall typedData
    function _hashArbitraryCall(
        ArbitraryCall calldata call, 
        IERC721 preciousToken, 
        uint256 preciousTokenId
    ) 
        private 
        view 
        returns(bytes32) 
    {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EXECUTE_ARBITRARY_CALL_TYPEHASH,
                    call.target,
                    call.value,
                    keccak256(call.data),
                    call.expectedResultHash,
                    preciousToken, 
                    preciousTokenId, 
                    nonce
                )
            )
        );
    }

    // Check it first in every call
    function _isPreciousListCorrect(
        IERC721 preciousToken,
        uint256 preciousTokenId
    ) 
        private 
        view 
        returns(bool) 
    {
        return preciousNFTHash == _hashPreciousNFT(preciousToken, preciousTokenId);
    }

    // Do we possess the precious?
    function _getHasPrecious(
        IERC721 preciousToken,
        uint256 preciousTokenId
    ) 
        private 
        view 
        returns(bool hasPrecious) 
    {
        hasPrecious = preciousToken.safeOwnerOf(preciousTokenId) == address(this);
    }

    // To hash the precious NFT details
    function _hashPreciousNFT(
        IERC721 preciousToken,
        uint256 preciousTokenId
    ) 
        private 
        pure 
        returns(bytes32 h) 
    {
        h = keccak256(abi.encodePacked(preciousToken, preciousTokenId));
    }
}