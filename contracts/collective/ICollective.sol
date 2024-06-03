// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../tokens/IERC721.sol";

import "./ICollectiveFactory.sol";
import "./distribution/IDistributor.sol";

import "../helper/Opensea/IOpenseaConduitController.sol";
import "../helper/Opensea/IOpenseaExchange.sol";

interface ICollective {
    /// @notice Arguments used to initialize the collective governance options
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

    /// @notice Arguments used to initialize the `CollectiveGovernanceNFT`.
    struct CollectiveInitData {
        GovernanceOpts governanceOpts;
        uint96 totalVotingPower;
        uint256 preciousTokenId;
        IERC721 preciousToken;
        address crowdfundAddress;
    }

    /// @notice Arguments used to list NFT on Opensea
    struct ListingCall {
        IOpenseaConduitController conduitController;
        IOpenseaExchange seaport;
        uint256 sellingPrice;
        uint256 listPrice;
        uint256 preciousTokenId;
        uint256[] fees;
        address payable[] feeRecipients;
        IERC721 preciousToken;
    }

    /// @notice Arguments used to call arbitrarily to other unknown contracts
    struct ArbitraryCall {
        // The call target.
        address payable target;
        // Amount of ETH to attach to the call.
        uint256 value;
        // Calldata.
        bytes data;
        // Hash of the successful return data of the call.
        // If 0x0, no return data checking will occur for this call.
        bytes32 expectedResultHash;
    }

    error InvalidFeeRecipients();
    error BadPreciousListError();
    error PreciousNotWithinContract(IERC721 token, uint256 tokenId);
    error SeaportNotMatchingGlobals(address globalsSeaportAddress, address givenSeaportAddress);

    event OpenseaOrderListed(
        IOpenseaExchange.OrderParameters orderParams,
        bytes32 orderHash,
        IERC721 token,
        uint256 tokenId,
        uint256 sellingPrice,
        uint256 expiry
    );
    event OpenseaLastOrderCancelled(
        bytes32 orderHash,
        IERC721 token,
        uint256 tokenId
    );
    event GovernanceValuesUpdated(GovernanceOpts newGovernanceValues);
    event ArbitraryCallExecuted(address payable callTarget, bytes callData);

    /// @notice The address of crowdfund
    function crowdfundAddress() external view returns (address);

    /// @notice NFT details, fixed from the inception of this collective. CANNOT be changed later so storing as hash
    function preciousNFTHash() external view returns (bytes32);

    /// @notice This is used to execute proposals
    function nonce() external view returns (uint256);

    /// @notice Initialize storage for proxy contracts
    function initialize(CollectiveInitData memory initData) external;

    /// @notice Returns the total share of contributor in totalVotingPower according to his ethUsed
    function getDistributionShareOf(
        address contributor
    ) external view returns (uint256 ethUsed);

    /// @notice Returns the total voting power according to the price of nft bought
    function getTotalVotingPowerOfCollective() external view returns (uint96);

    /// @notice Returns the current governance values for proposals
    function getGovernanceValues()
        external
        view
        returns (GovernanceOpts memory gv);

    // /// @notice Returns the claimable earning of individual
    // /// @param contributor The contributor whose earning is being fetched
    // function getClaimableAmountOfContributor(
    //     address contributor
    // ) external view returns (uint128 claimableAmount);

    // /// @notice Create a ETH distribution if it is not created yet,
    // ///         by moving the collective's entire balance
    // ///         to the `Distributor` contract and immediately creating a
    // ///        distribution governed by this collective.
    // ///         Also claim all the earnings of caller from this collective
    // ///        This function can be called by anyone externally or `batchClaim()` from Distributor contract
    // /// @param contributor The contributor whose earning will be claimed
    // function createDistributionAndClaim(
    //     address contributor
    // ) external;

    
    // function executeProposalListToOpensea(
    //     ListingCall memory listingParams
    // ) external returns (bytes32 orderHash);

    
    // function executeProposalUpdateGovernanceValues(
    //     GovernanceOpts memory governanceValues
    // ) external;

    /// @notice Arbitrary calls from this contract to other unknown contracts
    /// @param call Calling to more than one arbitrary call in a single function call
    /// @param preciousToken The token contract of nft held
    /// @param preciousTokenId The tokenId of nft held
    /// @param signature The signature to verify off-chain proposal
    function executeProposalArbitraryCall(
        ArbitraryCall calldata call,
        IERC721 preciousToken,
        uint256 preciousTokenId,
        bytes calldata signature
    ) external;
}
