// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../ICollective.sol";
import "../../tokens/IERC20.sol";
import "../../utils/ReentrancyGuard.sol";

/// @notice Creates distribution for collectives.
interface IDistributor {
    // Types of tokens
    enum TokenType {
        Native,
        Erc20
    }

    /// @notice Info on a distribution, created by createDistribution().
    struct DistributionInfo {
        // Type of distribution/token.
        TokenType tokenType;
        // ID of the distribution. Assigned by createDistribution().
        uint256 distributionId;
        // The collective whose members can claim the distribution.
        ICollective collective;
        // The token being distributed.
        address token;
        // Total amount of `token` that can be claimed by collective members.
        uint128 memberSupply;
        // Total shares at time distribution was created.
        uint96 totalShares;
    }
    
    event DistributionCreated(ICollective indexed collective, DistributionInfo info);
    event DistributionFeeClaimed(
        ICollective indexed collective,
        address indexed feeRecipient,
        TokenType tokenType,
        address token,
        uint256 amount
    );
    event DistributionClaimedByCollectiveContributor(
        ICollective indexed collective,
        address indexed contributorAddress,
        TokenType tokenType,
        address token,
        uint256 amountClaimed
    );

    /// @notice Create a new distribution for an outstanding native token balance
    ///         governed by a collective.
    /// @dev Native tokens should be transferred directly into this contract
    ///      immediately prior (same tx) to calling `createDistribution()` or
    ///      attached to the call itself.
    /// @param collective The collective whose members can claim the distribution.
    /// @return info Information on the created distribution.
    function createNativeDistribution(
        ICollective collective
    ) 
        external 
        payable 
        returns(DistributionInfo memory info);

    /// @notice Create a new distribution for an outstanding ERC20 token balance
    ///         governed by a collective.
    /// @dev ERC20 tokens should be transferred directly into this contract
    ///      immediately prior (same tx) to calling `createDistribution()` or
    ///      attached to the call itself.
    /// @param token The ERC20 token to distribute.
    /// @param collective The collective whose members can claim the distribution.
    /// @return info Information on the created distribution.
    function createErc20Distribution(
        IERC20 token,
        ICollective collective
    ) external returns (DistributionInfo memory info);

    /// @notice Claim a portion of a distribution owed to a `contributorAddress` belonging
    ///         to the collective that created the distribution. The caller
    ///         must be the collective
    /// @param info Information on the distribution being claimed.
    /// @return amountClaimed The amount of the distribution claimed.
    function claim(
        DistributionInfo calldata info
    ) 
        external 
        returns(uint128 amountClaimed);

    /// @notice Batch version of `claim()`. The caller can claim any no. of distributions
    /// from any number of collectives he want.
    /// @param infos Information on the distributions being claimed.
    /// @return amountsClaimed The amount of the distributions claimed.
    function batchClaim(
        DistributionInfo[] calldata infos
    ) external returns (uint128[] memory amountsClaimed);


    // /// @notice Batch version of `claim()`.
    // /// @param collectiveAddresses Collectives whose distributions are being claimed.
    // function batchClaim(
    //     ICollective[] memory collectiveAddresses
    // ) 
    //     external;

    /// @notice Compute the amount of a distribution's token are owed to a collective
    ///         member, identified by the `collectiveTokenId`.
    /// @param info Information on the distribution being claimed.
    /// @param contributorAddress The person who is claiming the earning
    /// @return claimAmount The amount of the distribution owed to the collective member.
    function getClaimAmount(
        DistributionInfo calldata info,
        address contributorAddress
    ) external view returns (uint128);

    // /// @notice Compute the amount of a distribution's token are owed to a collective
    // ///         member, identified by the `contributorAddress`.
    // /// @param collectiveAddresses Information on the distribution being claimed.
    // /// @return totalClaimableAmount The amount of the distribution owed to the collective member from all the given collectives.
    // function getClaimAmountOfContributorFromCollectives(
    //     ICollective[] memory collectiveAddresses,
    //     address contributorAddress
    // ) 
    //     external 
    //     view 
    //     returns(uint128 totalClaimableAmount);

    /// @notice Check whether a `contributorAddress` has claimed their share of a distribution.
    /// @param collective The collective to use for checking whether the `collectiveTokenId` has claimed.
    /// @param contributorAddress The address of the collective contributor to claim for.
    /// @param distributionId The ID of the distribution to check.
    /// @return hasClaimed Whether the `collectiveTokenId` has claimed.
    function hasCollectiveContributorClaimed(
        ICollective collective,
        address contributorAddress,
        uint256 distributionId
    ) 
        external 
        view 
        returns(bool hasClaimed);

    /// @notice Get how much unclaimed member tokens are left in a distribution.
    /// @param collective The collective to use for checking the unclaimed member tokens.
    /// @param distributionId The ID of the distribution to check.
    /// @return remainingMemberSupply The amount of distribution supply remaining.
    function getRemainingMemberSupply(
        ICollective collective,
        uint256 distributionId
    ) 
        external 
        view 
        returns(uint128 remainingMemberSupply);
}