// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../tokens/IERC721.sol";
import "../collective/ICollective.sol";

interface ICollectiveCrowdfund {
    
    /// @notice Lifecycle of a crowdfund
    enum CrowdfundLifecycle {
        Invalid,
        Busy, // Temporary. mid-settlement state
        Active,
        Expired,
        Successful
    }

    /// @notice Collective Governance options that must be known at crowdfund creation and can be changed later on proposals.
    struct GovernanceOpts {
        // How long people can vote on a proposal.
        uint40 voteDuration;
        // How long to wait after a proposal passes before it can be
        // executed.
        uint40 vetoDuration;
        // Minimum ratio of accept votes to consider a proposal passed,
        // in bps, where 10,000 == 100%.
        uint16 passThresholdBps;
    }                                                                                                                                                                                           

    /// @notice A record of a single contribution made by a user.
    /// Stored in `_contributionsByContributor`.
    struct Contribution {
        // The value of `Crowdfund.totalContributions` when this contribution was made.
        uint96 previousTotalContributions;
        // How much was this contribution.
        uint96 amount;
    }

    event DelegateUpdated(address contributor, address delegate);
    event Contributed(
        address contributor,
        uint96 amount,
        address delegate,
        uint256 previousTotalContributions
    );
    event ClaimedUnusedContribution(address receiver, uint256 amount);
    event TransferredToCollective(ICollectiveCrowdfund crowdfund, uint256 amount);
    event Successful(
        ICollective collective, 
        IERC721 nftContract, 
        uint256 nftTokenId, 
        uint256 settledPrice
    );
    event FeeTransferred(
        address feeRecipient,
        uint256 fee
    );
    event crowdfundExpired();

    error WrongLifecycle(CrowdfundLifecycle lc);
    error ContributionNotWithinLimit(uint96 lowerLimitInvestment, uint96 upperLimitInvestment);
    error InvalidDelegate();
    error NothingToClaim();
    error UnusedFundAlreadyClaimed();
    error NoSuccessCollective();
    error TransferToCollectiveFailed();
    error FailedToBuyNFT(IERC721 nftContract, uint256 nftTokenId);
    error CallProhibited(address target, bytes data);
    error ExceedsTotalContributions(uint96 value, uint96 totalContributions);
    error NotEligibleToBuy();
    error OnlyCollectiveContributor();
    error InvalidCrowdfund(address crowdfund);
    error InvalidContributor();
    error WrongGovernanceValues();
    error CannotAcceptZeroContribution();

    /// @notice Store the address of Factory Contract through which this crowdfund is created. 
    ///         To check it in `transferUnusedContribution()` function.
    function factory() external view returns(address);

    /// @notice Minimum limit of the investment set by the host
    function lowerLimitInvestment() external view returns(uint96);

    /// @notice The total (recorded) ETH contributed to this crowdfund.
    function totalContributions() external returns (uint96);

    /// @notice The total contributors to this crowdfund.
    function totalContributors() external returns (uint256);

    /// @notice Minimum limit of the crowdfund amount to raise for buying a NFT
    function fundraiseGoal() external returns(uint96);

    /// @notice The Collective instance created by `_createCollectiveAndTransferNFT()` 
    ///         to which NFT is sent on buying after a successful crowdfund.
    function successCollective() external returns(ICollective);

    /// @notice Who a contributor last delegated to.
    function delegationsByContributor(address contributor) external returns(address delegate);

    /// @notice Get the current lifecycle of the crowdfund.
    function getCrowdfundLifecycle() external view returns (CrowdfundLifecycle);

    /// @notice Contribute to this crowdfund 
    /// @param delegate The address to which he is delegating his ownership.
    function contribute(address delegate) external payable;

    /// @notice Contribute to this crowdfund from another crowdfund
    /// @param contributor The contributor who is transferring fund from expired collective.
    /// @param delegate The address to which he is delegating his ownership.
    function acceptContributionFromCollective(address contributor, address delegate) external payable;

    /// @notice Retrieve info about a participant's contributions.
    /// @dev This will only be called off-chain so doesn't have to be optimal.
    /// @param contributor The contributor to retrieve contributions for.
    /// @return ethContributed The total ETH contributed by `contributor`.
    /// @return ethUsed The total ETH used by `contributor` to acquire the NFT.
    /// @return ethOwed The total ETH refunded back to `contributor`.
    /// @return votingPower The intrinsic voting power of `contributor` equivalent to his contribution used.
    function getContributorInfo(
        address contributor
    ) 
        external 
        view 
        returns(uint256 ethContributed, uint256 ethUsed, uint256 ethOwed, uint256 votingPower);

    /// @notice Updates only delegate address of a contributor
    /// @dev This will only be called to update delegate address of contributor which internally calls `_updateDelegate()`
    /// @param newDelegate The new delegate address to replace old one
    function updateOnlyDelegate(address newDelegate) external;

    /// @notice Transfer unused ETH to other collective
    /// @dev This will be called by contributors to transfer all the unused amount of ETH to any Active Collective
    /// @param collectiveCrowdfundAddress The address of another crowdfund collective
    /// @param delegate This is the delegate address set in the contribute function of another collective
    function transferUnusedContribution(address payable collectiveCrowdfundAddress, address delegate) external;

    /// @notice Claim unused ETH back to wallet
    /// @dev This will be called by contributors to claim all the unused amount of ETH
    /// @param receiver The address in which contributor want to receive the claim.
    function claimUnusedContribution(address payable receiver) external;
}
