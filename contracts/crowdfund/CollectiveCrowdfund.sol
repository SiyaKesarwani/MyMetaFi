// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "../utils/LibAddress.sol";
import "../utils/LibRawResult.sol";
import "../utils/LibSafeCast.sol";
import "../utils/ReentrancyGuard.sol";
import "../tokens/ERC721Receiver.sol";
import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";
import "../utils/LibSafeERC721.sol";

import "./ICollectiveCrowdfund.sol";
import "../collective/ICollectiveFactory.sol";

// Base contract for SingleNFTCrowdfundWithToken/CollectionNFTCrowdfundWithToken.
// Holds post-AcceptingFund/Expired logic.
abstract contract CollectiveCrowdfund is ERC721Receiver, Implementation, ICollectiveCrowdfund, ReentrancyGuard {
    using LibSafeERC721 for IERC721;
    using LibRawResult for bytes;
    using LibSafeCast for uint256;
    using LibAddress for address payable;

    // Options to be passed into `_initialize()` when the crowdfund is created.
    struct CollectiveCrowdfundOptions {
        string collectiveTitleName;
        IERC721 nftContractAddress;
        uint96 fundraiseGoal;
        uint40 crowdFundDuration;
        uint96 lowerLimitInvestment;
        address initialContributor;
        GovernanceOpts governanceOpts;
    }    

    /// @inheritdoc ICollectiveCrowdfund
    uint96 public totalContributions;

    /// @inheritdoc ICollectiveCrowdfund
    uint256 public totalContributors;

    /// @inheritdoc ICollectiveCrowdfund
    uint96 public lowerLimitInvestment;

    /// @inheritdoc ICollectiveCrowdfund
    uint96 public fundraiseGoal;

    /// @inheritdoc ICollectiveCrowdfund
    address public factory;

    /// @inheritdoc ICollectiveCrowdfund
    mapping(address => address) public delegationsByContributor;

    /// @inheritdoc ICollectiveCrowdfund
    ICollective public successCollective;

    /// @notice Collective governance options passed into `initialize()`.
    GovernanceOpts public governanceOpts;

    /// @notice The NFT contract to buy.
    IERC721 public nftContract;

    /// @notice When this crowdfund expires.
    uint40 public expiry;

    /// @notice What the NFT was actually bought for.
    uint96 public settledPrice;

    /// @notice Was this NFT gifted or bought for free.
    bool public isGiftedNFT;

    /// @notice The `Globals` contract storing global configuration values. 
    /// This contract is immutable and it’s address will never change.
    IGlobals internal immutable _GLOBALS;

    /// @notice Array of contributions by a contributor.
    ///         One is created for every nonzero contribution made.
    ///         `private` for testing purposes only.
    mapping(address => Contribution[]) private _contributionsByContributor;

    /// @notice Total contributions made by a contributor until NFT is purchased
    ///         `private` for testing purposes only.
    mapping(address => uint96) private _totalContributionsOfContributor;

    /// @notice Contributor has claimed through `claimUnusedContribution()` 
    ///         or `transferUnusedContribution()`.
    mapping(address => bool) private _contributorHasClaimed;
    
    /// @notice Reverts if the current function caller is not a contributor
    modifier onlyCollectiveContributor() {
        if(!_assertIsContributor(msg.sender)){
            revert OnlyCollectiveContributor();
        }
        _;
    }

    /// @notice Set the `Globals` contract address.
    constructor(IGlobals globals) { 
        _GLOBALS = globals;
    }

    /// @inheritdoc ICollectiveCrowdfund
    function contribute(
        address delegate
    ) 
        external 
        payable 
        onlyDelegateCall 
    {
        _contribute(
            msg.sender,
            msg.value.safeCastUint256ToUint96(),
            delegate,
            totalContributions
        );
    }

    /// @inheritdoc ICollectiveCrowdfund
    function updateOnlyDelegate(
        address newDelegate
    ) 
        external 
        onlyDelegateCall 
        onlyCollectiveContributor 
    {
        _updateDelegate(msg.sender, newDelegate);
    }

    /// @inheritdoc ICollectiveCrowdfund
    function acceptContributionFromCollective(
        address contributor, 
        address delegate
    ) 
        external 
        payable 
        onlyDelegateCall 
    {
        // Can only be called from a crowdfund collective
        ICollectiveCrowdfund crowdfund = ICollectiveCrowdfund(msg.sender);

        _checkFactory(crowdfund);

        // Can only accept funds from an Expired/Successful crowdfund.
        if(crowdfund.getCrowdfundLifecycle() == CrowdfundLifecycle.Active){
            revert InvalidCrowdfund(address(crowdfund));
        }

        _contribute(
            contributor,
            msg.value.safeCastUint256ToUint96(),
            delegate,
            totalContributions
        );
    }

    /// @inheritdoc ICollectiveCrowdfund
    function getContributorInfo(
        address contributor
    ) 
        public 
        view 
        returns(uint256 ethContributed, uint256 ethUsed, uint256 ethOwed, uint256 votingPower) 
    {
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc == CrowdfundLifecycle.Successful || lc == CrowdfundLifecycle.Expired) {
            (ethUsed, ethOwed, votingPower) = _getFinalContribution(contributor);
            ethContributed = ethUsed + ethOwed;
            address delegate = delegationsByContributor[contributor];
            if(delegate != contributor){
                    votingPower = 0;
                }
        } else {
            ethContributed = _totalContributionsOfContributor[contributor];
        }
    }

    /// @inheritdoc ICollectiveCrowdfund
    function getCrowdfundLifecycle() public view returns (CrowdfundLifecycle){
        // If there is a settled price then we tried to buy the NFT.
        if (settledPrice != 0) {
            return
                address(successCollective) != address(0)
                    ? CrowdfundLifecycle.Successful // If we have a collective, then we succeeded buying the NFT.
                    : CrowdfundLifecycle.Busy; // Otherwise we're in the middle of the `buy()`.
        }
        if (block.timestamp >= expiry && settledPrice == 0) {
            // Expired, but nothing to do so skip straight to lost, or NFT was
            // acquired for free so refund contributors and trigger lost.
            return CrowdfundLifecycle.Expired;
        }
        return CrowdfundLifecycle.Active;
    }

    /// @inheritdoc ICollectiveCrowdfund
    function claimUnusedContribution(
        address payable receiver
    ) 
        external 
        onlyDelegateCall 
        onlyCollectiveContributor 
        nonReentrant 
    {
        // Can only be called When contributor's money was not used in buying NFT if Successful |OR| Crowdfund has Expired.
        CrowdfundLifecycle lc = getCrowdfundLifecycle();

        _checkSuccessfulOrExpired(lc);

        _checkHasNotClaimed(msg.sender);

        (, uint256 ethOwed,) = _getFinalContribution(msg.sender);
        // ethOwed should be greater than 0 to claim
        if(ethOwed == 0){
            revert NothingToClaim();
        }
        // transfer the whole amount directly to the receiver account (contributor can give any address he wants the refund to be received)
        _contributorHasClaimed[msg.sender] = true;
        receiver.transferEth(ethOwed);
        emit ClaimedUnusedContribution(receiver, ethOwed);
    }

    /// @inheritdoc ICollectiveCrowdfund
    function transferUnusedContribution(
        address payable collectiveCrowdfundAddress, 
        address delegate
    ) 
        external 
        onlyDelegateCall 
        onlyCollectiveContributor 
        nonReentrant 
    {
        // Can only be called When contributor's money was not used in buying NFT if Successful |OR| Crowdfund has Expired.
        CrowdfundLifecycle lc = getCrowdfundLifecycle();

        _checkSuccessfulOrExpired(lc);

        // Can only transfer to an existing crowdfund.
        ICollectiveCrowdfund crowdfund = ICollectiveCrowdfund(collectiveCrowdfundAddress);
        
        _checkFactory(crowdfund);

        // Can only transfer to an Active crowdfund.
        if(crowdfund.getCrowdfundLifecycle() != CrowdfundLifecycle.Active){
            revert InvalidCrowdfund(address(crowdfund));
        }

        _checkHasNotClaimed(msg.sender);

        (, uint256 ethOwed,) = _getFinalContribution(msg.sender);

        // If called by someone whose all contribution is used in buying the NFT
        if(ethOwed == 0){
            revert NothingToClaim();
        }
        
        (uint256 ethContributed, , ,) = crowdfund.getContributorInfo(msg.sender);
        uint96 upperLimitOfCrowdfund = 20 * crowdfund.fundraiseGoal() / 100;
        // Eligibility of contributor to contribute in new Crowdfund
        uint256 amountEligibleToBeContributed = upperLimitOfCrowdfund - ethContributed;

        // If he is eligible to contribute
        if(amountEligibleToBeContributed > 0 ) {
            // If he has never contributed then he should 
            // contribute more than or equal to `lowerLimitInvestment`
            if( ethOwed < crowdfund.lowerLimitInvestment() && ethContributed == 0) {
                revert TransferToCollectiveFailed();
            }
            // If he is already a contributor to next crowdfund but has more capacity
            // Set to true
            _contributorHasClaimed[msg.sender] = true;
            // If he has greater amount to transfer than his limit left in next crowdfund
            if(ethOwed > amountEligibleToBeContributed) {
                _transferContributionToCollective(crowdfund, msg.sender, delegate, amountEligibleToBeContributed);
                // transfer rest of the amount to contributor's account
                _claimLeftAmount(payable(msg.sender), ethOwed - amountEligibleToBeContributed);
            }
            // If he has lesser or equal amount to transfer than his limit left in next crowdfund
            else {   
                // Transfer all amount he owes
                _transferContributionToCollective(crowdfund, msg.sender, delegate, ethOwed);
            }
        }
        // If he is already a contributor to next crowdfund but has contributed maximum
        else{
            revert TransferToCollectiveFailed();
        }
    }

    // Initialize storage for proxy contracts, credit initial contribution
    function _initialize(
        CollectiveCrowdfundOptions memory opts
    ) 
        internal 
    {
        // Check vote duration is within the limit (1 to 7 days only)
        // Check veto duration is within the limit (1 to 3 days only)
        // Check the pass threshold BPS is within limit or not (where 100% = 10,000 and 50% = 5000)
        if(opts.governanceOpts.voteDuration < 86400 || opts.governanceOpts.voteDuration > 604800 ||
            opts.governanceOpts.vetoDuration < 86400 || opts.governanceOpts.vetoDuration > 259200 ||
            opts.governanceOpts.passThresholdBps > 1e4 || opts.governanceOpts.passThresholdBps < 5e3){
                revert WrongGovernanceValues();
            }
        factory = msg.sender;
        lowerLimitInvestment = opts.lowerLimitInvestment;
        // If the deployer passed in some ETH during deployment, credit them
        // for the initial contribution. This should be minimum 25 dollars or more than equal to lowerLimitInvestment
        if(msg.value < opts.lowerLimitInvestment) {
            revert ContributionNotWithinLimit(opts.lowerLimitInvestment, (20*opts.fundraiseGoal)/100);
        }
        fundraiseGoal = opts.fundraiseGoal;
        governanceOpts = opts.governanceOpts;
        // The host cannot delegate votes while creating the collective
        _contribute(opts.initialContributor, msg.value.safeCastUint256ToUint96(), opts.initialContributor, 0);
    }

    /// @notice Execute arbitrary calldata to perform a buy using Opensea Seaport Contract
    function _buyFromOpensea(
        uint256 _nftTokenId,
        address payable callTarget,
        uint96 callValue,
        uint96 fee,
        bytes memory callData
    ) 
        internal 
        returns(ICollective collective_)
    {
        // Execute the call to buy the NFT, but only if we have a nonzero callValue
        // because a zero callValue will cause the CF to lose anyawy.
        (bool s, bytes memory r) = callTarget.call{ value: callValue }(callData);
        if (!s) {
            r.rawRevert();
        }
        // Make sure we acquired the NFT we want.
        if (nftContract.safeOwnerOf(_nftTokenId) == address(this)) { 
            if (callValue != 0) {
                // This is to ensure the total amount spent(price+fee) in buying NFT 
                // but on frontend we'll show only nft price
                settledPrice = callValue + fee; 
                // Transfer the fees owed to feeRecipient
                address payable feeRecipient = payable(_GLOBALS.getAddress(LibGlobals.GLOBAL_FEE_RECIPIENT)); 
                feeRecipient.transferEth(fee);
                emit Successful(
                    // Create a collective around the newly bought NFT.
                    collective_ = _createCollectiveAndTransferNFT(
                        // host,
                        nftContract,
                        _nftTokenId
                    ),
                    nftContract,
                    _nftTokenId,
                    callValue   // Need to fix this
                );
                emit FeeTransferred(feeRecipient, fee);
            }
            // If the NFT was purchased for free or "gifted" to us.
            // Set this crowdfund as Expired and set settledPrice 0.
            // This crowdfund can claim their contributions now
            else{
                settledPrice = 0;
                isGiftedNFT = true;
                expiry = uint40(block.timestamp);
                emit crowdfundExpired(); 
            }
        }
        else{
            revert FailedToBuyNFT(nftContract, _nftTokenId);
        }
    }

    /// @notice Can be called after a collective crowdfunding becomes successful.
    ///         Deploys and initializes a `Collective` instance via the `CollectiveFactory`
    ///         and transfers the bought NFT to it.
    function _createCollectiveAndTransferNFT(
        // address host,
        IERC721 preciousToken,
        uint256 preciousTokenId
    ) 
        internal 
        returns(ICollective collective_) 
    {
        successCollective = collective_ = _getCollectiveFactory().createCollective( 
            ICollective.GovernanceOpts({
                // host: host,
                voteDuration: governanceOpts.voteDuration,
                vetoDuration: governanceOpts.vetoDuration,
                passThresholdBps: governanceOpts.passThresholdBps
            }),
            _getFinalPrice().safeCastUint256ToUint96(),
            preciousToken,
            preciousTokenId,
            address(this)
        );
        preciousToken.safeTransferFrom(address(this), address(collective_), preciousTokenId);
    }

    // Assert that `who` is a contributor to the crowdfund.
    function _assertIsContributor(
        address who
    ) 
        internal 
        view 
        returns(bool)
    {
        return (_contributionsByContributor[who].length != 0);
    }
    
    /// @notice Checks that the NFT bought is not allowed to be moved out of the crowdfund contract.
    function _isCallAllowed(
        address payable callTarget
    ) 
        internal 
        view 
        returns(bool isAllowed) 
    {
        // Ensure the call target isn't trying to reenter
        // Ensure the call is only for Seaport contract
        if (callTarget != address(_GLOBALS.getAddress(LibGlobals.GLOBAL_OPENSEA_SEAPORT))) {
                return false;
        }
        // Not Required since we are checking the Seaport Contract Address
        // if (callTarget == address(nftContract) && callData.length >= 4) {
        //     // Get the function selector of the call (first 4 bytes of calldata).
        //     bytes4 selector;
        //     assembly {
        //         selector := and(
        //             mload(add(callData, 32)),
        //             0xffffffff00000000000000000000000000000000000000000000000000000000
        //         )
        //     }
        //     // Prevent approving the NFT to be transferred out from the crowdfund.
        //     if (
        //         selector == IERC721.approve.selector ||
        //         selector == IERC721.setApprovalForAll.selector
        //     ) {
        //         return false;
        //     }
        // }
        // All other calls are allowed.
        return true;
    }

    /// @notice Check if this crowdfund is eligible to buy NFT
    function _isEligibleToBuyNFT() internal view returns (bool){
        if (
                getCrowdfundLifecycle() == CrowdfundLifecycle.Active && 
                totalContributions>=fundraiseGoal
            )
            return true;
        // Wait for 14 days more after expiry time to buy 
        else if(
                    getCrowdfundLifecycle() == CrowdfundLifecycle.Expired && 
                    totalContributions>=fundraiseGoal && 
                    block.timestamp <= (expiry + 1209600) &&
                    !isGiftedNFT
                )
            return true;
        else 
            return false;
    }
    
    /// @notice Get the final sale price of the bought assets. 
    ///         This will also be the total voting power of the governance collective.
    function _getFinalPrice() internal view returns (uint256){
        return settledPrice;
    }

    // Called from `transferUnusedContribution()` on different conditions
    function _transferContributionToCollective(
        ICollectiveCrowdfund crowdfund, 
        address contributor, 
        address delegate, 
        uint256 amount
    ) 
        private 
    {
        crowdfund.acceptContributionFromCollective{value : amount}(contributor, delegate);
        (uint256 ethContributed, , ,) = crowdfund.getContributorInfo(contributor);
        require(ethContributed >= amount);
        emit TransferredToCollective(crowdfund, amount);
    }

    // Common function called from `_initialize()`, `contribute()`, `acceptContributionFromCollective()`
    function _contribute(
        address contributor,
        uint96 amount,
        address delegate,
        uint96 previousTotalContributions
    ) 
        private 
    {
        // Cannot contribute 0 amount
        if(amount == 0){
            revert CannotAcceptZeroContribution();
        }

        // address(0) and address(this) cannot be a contributor
        if (contributor == address(this) || contributor == address(0)) {
            revert InvalidContributor();
        }
        
        // Only allow contributions while the crowdfund is active.
        {
            CrowdfundLifecycle lc = getCrowdfundLifecycle();
            if (lc != CrowdfundLifecycle.Active) {
                revert WrongLifecycle(lc);
            }
        }
        
        // Increase total contributions.
        totalContributions += amount;

        // Max possible contribution
        uint96 maxPossibleContribution = (20 * fundraiseGoal) / 100;
        
        // Create contributions entry for this contributor.
        Contribution[] storage contributions = _contributionsByContributor[contributor];
        uint256 numContributions = contributions.length;
        uint256 contributionsTillNow = _totalContributionsOfContributor[contributor];
        if ((contributionsTillNow + amount) > maxPossibleContribution) {
            revert ContributionNotWithinLimit(lowerLimitInvestment, maxPossibleContribution);
        }

        _totalContributionsOfContributor[contributor] += amount;
        emit Contributed(contributor, amount, delegate, previousTotalContributions);

        // Update delegate.
        _updateDelegate(contributor, delegate);

        if (numContributions > 0) {
            uint lastIndex;
            unchecked {
                lastIndex = numContributions - 1;
            }
            Contribution memory lastContribution = contributions[lastIndex];
            // If no one else (other than this contributor) has contributed since,
            // we can just reuse this contributor's last entry.
            uint256 totalContributionsAmountForReuse = 
                lastContribution.previousTotalContributions + lastContribution.amount;
            if (totalContributionsAmountForReuse == previousTotalContributions) {
                lastContribution.amount += amount;
                contributions[lastIndex] = lastContribution;
                return;
            }
        }
        // If contributor is new, then add new contributor to totalContributors
        else {
            if (amount < lowerLimitInvestment || amount > maxPossibleContribution){
                revert ContributionNotWithinLimit(lowerLimitInvestment, maxPossibleContribution);
            }
            totalContributors += 1;
        }
        // Add a new contribution entry.
        contributions.push(
            Contribution({
                previousTotalContributions: previousTotalContributions,
                amount: amount
            })
        );
    }

    // Called from `transferUnusedContribution()` on different conditions
    function _claimLeftAmount(
        address payable receiver, 
        uint256 amount
    ) 
        private 
    {
        receiver.transferEth(amount);
        emit ClaimedUnusedContribution(receiver, amount);
    }

    // Common function for updating delegate from `updateOnlyDelegate()` and `_contribute()`
    function _updateDelegate(
        address contributor, 
        address newDelegate
    ) 
        private 
    {
        // Check the delegated Address should be either a Contributor or Himself and Non-Null
        if((!_assertIsContributor(newDelegate) && newDelegate != contributor)){
            revert InvalidDelegate();
        }

        // Get the old delegate to avoid updating if it is same as new
        address oldDelegate = delegationsByContributor[contributor];

        // If the delegate is same as older delegate
        if((oldDelegate == newDelegate)){
            return;
        }

        // Update delegate.
        delegationsByContributor[contributor] = newDelegate;
        emit DelegateUpdated(contributor, newDelegate);
    }

    /// @notice Check the factory of the crowdfund is same as this crowdfund factory
    function _checkFactory(
        ICollectiveCrowdfund crowdfund
    ) private view{
        if(crowdfund.factory() != factory){
            revert InvalidCrowdfund(address(crowdfund));
        }
    }

    /// @notice Check the crowdfund must be Expired or Successul.
    function _checkSuccessfulOrExpired(
        CrowdfundLifecycle lc
    ) private view{
        if (lc == CrowdfundLifecycle.Successful && successCollective == ICollective(payable(0))) {
            revert NoSuccessCollective();
        }
        else if (lc != CrowdfundLifecycle.Successful && lc != CrowdfundLifecycle.Expired) {
            revert WrongLifecycle(lc);
        }
    }

    /// @notice Check the collector has not alreafy claimed unused funds.
    function _checkHasNotClaimed(
        address contributor
    ) private view {
        if(_contributorHasClaimed[contributor]){
            revert UnusedFundAlreadyClaimed();
        }
    }

    // Called from `getContributorInfo()`, `claimUnusedContribution()`, `transferUnusedContribution()`
    function _getFinalContribution(
        address contributor
    ) 
        private 
        view 
        returns(uint256 ethUsed, uint256 ethOwed, uint256 votingPower) 
    {
        uint256 totalEthUsed = _getFinalPrice();
        {
            Contribution[] memory contributions = _contributionsByContributor[contributor];
            uint256 numContributions = contributions.length;
            for (uint256 i = 0; i < numContributions; ++i) {
                Contribution memory c = contributions[i];
                if (c.previousTotalContributions >= totalEthUsed) {
                    // This entire contribution was not used.
                    ethOwed += c.amount;
                } else if (c.previousTotalContributions + c.amount <= totalEthUsed) {
                    // This entire contribution was used.
                    ethUsed += c.amount;
                } else {
                    // This contribution was partially used.
                    uint256 partialEthUsed;
                    unchecked {
                        partialEthUsed = totalEthUsed - c.previousTotalContributions;
                        ethOwed = c.amount - partialEthUsed;
                    }
                    ethUsed += partialEthUsed; 
                }
            }
        }
        // Voting power should be equivalent to the EthUsed in buying the NFT if not delegated to anyone else
        votingPower = ethUsed;
    }

    // Function to get collective factory address
    function _getCollectiveFactory() private view returns (ICollectiveFactory) {
        return ICollectiveFactory(_GLOBALS.getAddress(LibGlobals.GLOBAL_COLLECTIVE_FACTORY));
    }
}