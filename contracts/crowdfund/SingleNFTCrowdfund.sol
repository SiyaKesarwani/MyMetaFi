// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "./CollectiveCrowdfund.sol";

contract SingleNFTCrowdfund is CollectiveCrowdfund {  
    using LibRawResult for bytes;
    using LibSafeCast for uint256;
    using LibAddress for address payable;

    struct SingleNFTCrowdfundOptions {
        // The name of the crowdfund.
        // This will also carry over to the governance collective.
        string collectiveTitleName;
        // The ERC721 contract of the NFT being bought.
        IERC721 nftContractAddress;
        // ID of the NFT being bought.
        uint256 nftTokenId;
        // Minimum limit of the crowdfund amount to raise for buying a NFT
        uint96 fundraiseGoal;
        // How long this crowdfund has to take contributions and buy NFT, in seconds.
        uint40 crowdFundDuration;
        // Maximum investment made at a time for all the contributors
        uint96 lowerLimitInvestment;
        // If ETH is attached during deployment, it will be interpreted
        // as a contribution. This is who gets credit for that contribution.
        address initialContributor;
        // Governance options.
        GovernanceOpts governanceOpts;
    }

    /// @notice The NFT token ID to buy.
    uint256 public nftTokenId;

    /// @notice Set the `Globals` contract address.
    constructor(IGlobals globals) CollectiveCrowdfund(globals) {}

    function initialize(
        SingleNFTCrowdfundOptions memory opts
    ) 
        external 
        payable 
        onlyConstructor 
    {
        // host = opts.initialContributor;
        expiry = uint40(opts.crowdFundDuration + block.timestamp);
        CollectiveCrowdfund._initialize(
            CollectiveCrowdfundOptions({
                collectiveTitleName: opts.collectiveTitleName,
                nftContractAddress: opts.nftContractAddress,
                fundraiseGoal: opts.fundraiseGoal,
                crowdFundDuration: opts.crowdFundDuration,
                lowerLimitInvestment: opts.lowerLimitInvestment,
                initialContributor: opts.initialContributor,
                governanceOpts: opts.governanceOpts 
            })
        );
        nftTokenId = opts.nftTokenId;
        nftContract = opts.nftContractAddress;
    }

    /// @notice Execute arbitrary calldata to perform a buy, transfer fees to recipient on buy price 
    /// creating a collective if it successfully buys the NFT.
    /// @param callTarget The target contract to call to buy the NFT.
    /// @param callValue The amount of ETH to send with the call.
    /// @param callData The calldata to execute.
    /// @return collective_ Address of the `Collective` instance created after its bought.
    function buy(
        address payable callTarget,
        uint96 callValue,
        bytes memory callData
    ) 
        external 
        onlyDelegateCall 
        onlyCollectiveContributor 
        returns(ICollective collective_) 
    {
        // Check that the call is not prohibited.
        if (!_isCallAllowed(callTarget)) {
            revert CallProhibited(callTarget, callData);
        }
        // Should be eligible to buy
        if(!_isEligibleToBuyNFT()){
            revert NotEligibleToBuy();
        }

        uint96 fee = (callValue * _GLOBALS.getUint256(LibGlobals.GLOBAL_FEE_BPS) / 1e4).safeCastUint256ToUint96();

        // Prevent unaccounted ETH from being used to inflate the price and
        // create "ghost shares" in voting power.
        {
            if (callValue + fee > totalContributions) {
                revert ExceedsTotalContributions(callValue+fee, totalContributions);
            }
        }
        // Temporarily set to non-zero as a reentrancy guard.
        settledPrice = type(uint96).max;
        return
        _buyFromOpensea(  
            nftTokenId,
            callTarget,
            callValue,
            fee,
            callData
        );
    }
}
