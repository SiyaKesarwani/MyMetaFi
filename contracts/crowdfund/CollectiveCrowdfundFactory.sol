// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "../utils/LibRawResult.sol";
import "../utils/Proxy.sol";
import "../globals/IGlobals.sol";

import "./SingleNFTCrowdfund.sol";
import "./CollectionNFTCrowdfund.sol";

contract CollectiveCrowdfundFactory{
    using LibRawResult for bytes;

    event SingleNFTCrowdfundCreated(SingleNFTCrowdfund crowdfund, SingleNFTCrowdfund.SingleNFTCrowdfundOptions opts);
    event CollectionNFTCrowdfundCreated(CollectionNFTCrowdfund crowdfund, CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions opts);

    /// @notice The `Globals` contract storing global configuration values. 
    /// This contract is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice Set the `Globals` contract address.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    /// @notice Create a new crowdfund to purchase a specific NFT (i.e., with a
    ///         known token ID) listing for a known price.
    /// @param opts Options used to initialize the crowdfund. These are not fixed
    ///             and can be changed later using update() function.
    function createSingleNFTCrowdfund(
        SingleNFTCrowdfund.SingleNFTCrowdfundOptions memory opts
    ) public payable returns (SingleNFTCrowdfund inst) {
        inst = SingleNFTCrowdfund(
            payable(
                new Proxy{ value: msg.value }(
                     _GLOBALS.getImplementation(LibGlobals.GLOBAL_SINGLE_BUY_CF_IMPL),
                    abi.encodeCall(SingleNFTCrowdfund.initialize, (opts))
                )
            )
        );
        emit SingleNFTCrowdfundCreated(inst, opts);
    }

    /// @notice Create a new crowdfund to purchase any NFT from a collection
    ///         (i.e. any token ID) from a collection for a known price.
    /// @param opts Options used to initialize the crowdfund. These are not fixed
    ///             and can be changed later using update() function.
    function createCollectionNFTCrowdfund(
        CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts
    ) public payable returns (CollectionNFTCrowdfund inst) {
        inst = CollectionNFTCrowdfund(
            payable(
                new Proxy{ value: msg.value }(
                     _GLOBALS.getImplementation(LibGlobals.GLOBAL_COLLECTION_BUY_CF_IMPL),
                    abi.encodeCall(CollectionNFTCrowdfund.initialize, (opts))
                )
            )
        );
        emit CollectionNFTCrowdfundCreated(inst, opts);
    }
}