// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../tokens/ERC721Receiver.sol";
import "../utils/LibSafeERC721.sol";
import "../utils/LibSafeCast.sol";
import "../utils/EIP712.sol";
import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";
import "../tokens/IERC20.sol";
import "../utils/LibERC20Compat.sol";
import "../utils/LibAddress.sol";

import "./ICollective.sol";

import "../crowdfund/ICollectiveCrowdfund.sol";

/// @notice The governance contract that also custodies the precious NFTs. This
///         is also the Governance NFT 721 contract.
contract Collective is ICollective, ERC721Receiver, Implementation, EIP712, ReentrancyGuard {
    using LibSafeCast for uint256;
    using LibSafeERC721 for IERC721;
    using LibERC20Compat for IERC20;
    using LibAddress for address payable;
    
    /// @inheritdoc ICollective
    uint256 public nonce;

    /// @inheritdoc ICollective
    address public crowdfundAddress;

    /// @inheritdoc ICollective
    bytes32 public preciousNFTHash;

    /// @notice typehash as per EIP712 standard
    bytes32 constant EXECUTE_ARBITRARY_CALL_TYPEHASH = keccak256(
        "ExecuteProposal(address target,uint256 value,bytes data,bytes32 expectedResultHash,address preciousToken,uint256 preciousTokenId,uint256 nonce)");

    /// @notice The order hash of listed NFT
    bytes32 private _orderHash;

    /// @notice The OrderComps after NFT is listed (to cancel the listing)
    IOpenseaExchange.OrderComponents[] private _orderCompsOfListedNFT;

    /// @notice Governance parameters, fixed from the inception of this collective. But CAN BE changed later on proposals.
    GovernanceOpts private _governanceValues;

    /// @notice Total voting power according to the price at which NFT is bought
    uint96 private _totalVotingPower;

    /// @notice This is createDistribution flag
    IDistributor.DistributionInfo private _distInfo;
    
    /// @notice The `Globals` contract storing global configuration values. 
    /// This contract is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    event DistributionCreated(
        IDistributor.TokenType tokenType,
        uint256 amount
    );

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
    error ZeroAmountDistribution();
    error InsufficientAmount(uint256 distributionAmount, uint256 amountAvailable);

    modifier onlyWhenNotGloballyDisabled() {
        if (_GLOBALS.getBool(LibGlobals.GLOBAL_DISABLE_MMF_ACTIONS)) {
            revert OnlyWhenEnabledError();
        }
        _;
    }

    /// @notice Set the `Globals` contract address.
    constructor(IGlobals globals) EIP712("Collective", "1") {
        _GLOBALS = globals;
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
        onlyConstructor 
    {
        // Set the governance parameters.
        _governanceValues = GovernanceOpts({
            voteDuration: initData.governanceOpts.voteDuration,
            vetoDuration: initData.governanceOpts.vetoDuration,
            passThresholdBps: initData.governanceOpts.passThresholdBps
        });

        // Set the totalVotingPower.
        _totalVotingPower = initData.totalVotingPower;

        // Set the precious nft details.
        _setPreciousNFT(initData.preciousToken, initData.preciousTokenId);

        // Set the address from which this collective is created.
        // Used further in Distribution of earnings
        crowdfundAddress = initData.crowdfundAddress;
    }

    /// @notice Create a token distribution
    ///         by moving the collective's entire balance
    ///         to the `Distributor` contract and immediately creating a
    ///        distribution governed by this collective.
    ///        This function can only be called by a collective contributor
    function executeProposalCreateDistribution(
        uint256 amount,
        IDistributor.TokenType tokenType,
        address token
    ) 
        external  
        returns (IDistributor.DistributionInfo memory distInfo)
    {
        _checkIfSelfCall();

        if(amount == 0){
            revert ZeroAmountDistribution();
        }

        // Get the address of the token distributor.
        IDistributor distributor = IDistributor(
            _GLOBALS.getAddress(LibGlobals.GLOBAL_DISTRIBUTOR)
        );

        address payable feeRecipient = payable(_GLOBALS.getAddress(LibGlobals.GLOBAL_FEE_RECIPIENT)); 
        uint256 distFeeBps = _GLOBALS.getUint256(LibGlobals.GLOBAL_DISTRIBUTOR_FEE_BPS);

        if (tokenType == IDistributor.TokenType.Native) {
            if(address(this).balance < amount){
                revert InsufficientAmount(amount, address(this).balance);
            }
            uint96 feeEth = (amount * distFeeBps / 1e4).safeCastUint256ToUint96();
            if(feeEth != 0){
                // Transfer the fee to the platform
                feeRecipient.transferEth(feeEth);
            }
            return
                distributor.createNativeDistribution{ value: amount - feeEth }(
                    ICollective(payable(address(this)))
                );
        }
        // Otherwise must be an ERC20 token distribution.
        assert(tokenType == IDistributor.TokenType.Erc20);
        uint256 contractBal = IERC20(token).balanceOf(address(this));
        if(contractBal < amount){
            revert InsufficientAmount(amount, contractBal);
        }
        uint96 feeToken = (amount * distFeeBps / 1e4).safeCastUint256ToUint96();
        if(feeToken != 0){
            // Transfer the fee to the platform
            IERC20(token).compatTransfer(address(feeRecipient), feeToken);
        }
        IERC20(token).compatTransfer(address(distributor), amount - feeToken);
        return
            distributor.createErc20Distribution(
                IERC20(token),
                ICollective(payable(address(this)))
            );
    }

    // /// @inheritdoc ICollective
    // function createDistributionAndClaim(
    //     address contributor
    // ) 
    //     external  
    //     onlyWhenNotGloballyDisabled
    //     onlyDelegateCall
    //     nonReentrant
    // {
    //     // Caller can be a person or Distributor contract
    //     // contributor must be a collective contributor.
        // uint256 callerEthUsedInCollective = getDistributionShareOf(contributor);
        // if(callerEthUsedInCollective < 1){
        //     revert ICollectiveCrowdfund.OnlyCollectiveContributor();
        // }

    //     // Get the address of the token distributor.
    //     IDistributor distributor = IDistributor(
    //         _GLOBALS.getAddress(LibGlobals.GLOBAL_DISTRIBUTOR)
    //     );

    //     // If distribution is not created yet,
    //     // then first create distribution and claim earning for the caller
    //     if(address(_distInfo.collective) != address(this)){
    //         // This should only be created if there is some member supply
    //         uint128 memberSupply = _getMemberSupplyOfCollective();
    //         if(memberSupply < 1){
    //             revert CannotClaimZeroEarnings(memberSupply);
    //         }
    //         _distInfo = _createDistribution(IDistributor.TokenType.Native, distributor, memberSupply);
    //     }
    //     else{
    //         if(distributor.hasCollectiveContributorClaimed(this, contributor, 1))
    //             return; 
    //     }
    //     // Claim earnings of the caller from this collective
    //     uint128 amountClaimed = distributor.claim(_distInfo, contributor);
    //     if(amountClaimed < 1) {
    //         revert CannotClaimZeroEarnings(amountClaimed);
    //     }
    // }

    /// @notice Lists the NFT on Opensea
    /// @param listingParams All new listing params. This should contain token info for the nft to be listed.
    ///                      Provided, it should be within contract to list.
    function executeProposalListToOpensea(
        ListingCall memory listingParams
    ) 
        external  
        returns(bytes32 orderHash) 
    {
        _checkIfSelfCall();

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

        // // Check that the precious list is valid.
        // _checkValidPreciousList(listingParams.preciousToken, listingParams.preciousTokenId);

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
        require(listingParams.preciousToken.getApproved(listingParams.preciousTokenId) == conduit, "Collective: NFT unpproved");
        
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

    /// @notice Update the governance values of this collective
    /// @param governanceValues New governanceValues for this collective.
    function executeProposalUpdateGovernanceValues(
        GovernanceOpts memory governanceValues
    ) 
        external
    {
        _checkIfSelfCall();
        // Check vote duration is within the limit (1 to 7 days only)
        // Check veto duration is within the limit (1 to 3 days only)
        // Check the pass threshold BPS is within limit or not (where 100% = 10,000 and 50% = 5000)
        if(governanceValues.voteDuration < 86400 || governanceValues.voteDuration > 604800 ||
            governanceValues.vetoDuration < 86400 || governanceValues.vetoDuration > 259200 ||
            governanceValues.passThresholdBps > 1e4 || governanceValues.passThresholdBps < 5e3){
                revert ICollectiveCrowdfund.WrongGovernanceValues();
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
        // Only collective contributor can call
        uint256 callerEthUsedInCollective = getDistributionShareOf(msg.sender);
        if(callerEthUsedInCollective < 1){
            revert ICollectiveCrowdfund.OnlyCollectiveContributor();
        }
        // Check that the precious list is valid.
        _checkValidPreciousList(preciousToken,preciousTokenId);

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

    // /// @inheritdoc ICollective
    // function getClaimableAmountOfContributor(
    //     address contributor
    // ) 
    //     external 
    //     view 
    //     returns(uint128 claimableAmount)
    // {
    //     IDistributor.DistributionInfo memory distInfo = _distInfo;
    //     // Get the address of the token distributor.
    //     IDistributor distributor = IDistributor(
    //         _GLOBALS.getAddress(LibGlobals.GLOBAL_DISTRIBUTOR)
    //     );

    //     uint128 currentMemberSupply;

    //     if(address(distInfo.collective) == address(this)){
    //         if(distributor.hasCollectiveContributorClaimed(this, contributor, 1)){
    //             return 0;
    //         }
    //         currentMemberSupply = distInfo.memberSupply;
    //     }
    //     else{
    //         currentMemberSupply = _getMemberSupplyOfCollective();
    //     }
    //     uint256 shareOfSupply = ((getDistributionShareOf(contributor)) * 1e30) / _totalVotingPower;
    //     claimableAmount = ((shareOfSupply * currentMemberSupply + (1e30 - 1)) / 1e30).safeCastUint256ToUint128();
    // }

    /// @inheritdoc ICollective
    function getTotalVotingPowerOfCollective() external view returns(uint96){
        return _totalVotingPower;
    }

    /// @inheritdoc ICollective
    function getGovernanceValues() external view returns(GovernanceOpts memory gv){
        return _governanceValues;
    }

    /// @inheritdoc ICollective
    function getDistributionShareOf(
        address contributor
    ) 
        public 
        view 
        onlyDelegateCall
        returns(uint256 ethUsed)
    {
        (, ethUsed, ,) = ICollectiveCrowdfund(crowdfundAddress).getContributorInfo(contributor);
    }
    
    // /// @notice Create a token distribution by moving the collective's entire balance
    // ///         to the `Distributor` contract and immediately creating a
    // ///         distribution governed by this collective.
    // /// @param tokenType The type of token to distribute.
    // /// @param distributor The distributor contract.
    // /// @param memberSupply The total balance of this collective.
    // /// @return distInfo The information about the created distribution.
    // function _createDistribution(
    //     IDistributor.TokenType tokenType,
    //     IDistributor distributor,
    //     uint256 memberSupply
    // ) 
    //     private 
    //     returns(IDistributor.DistributionInfo memory distInfo)
    // {
    //     emit DistributionCreated(tokenType, memberSupply);
    //     // Create a native token distribution.
    //     if (tokenType == IDistributor.TokenType.Native) {
    //         return distributor.createNativeDistribution
    //             { value: memberSupply }(ICollective(address(this)));
    //     }
    // }

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