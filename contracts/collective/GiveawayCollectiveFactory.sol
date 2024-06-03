// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../utils/Proxy.sol";
import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";

import "./GiveawayCollective.sol";

//Factory used to deploy new proxified `Giveaway Collective` instances.
contract GiveawayCollectiveFactory {
    /// @notice The `Globals` contract storing global configuration values. 
    /// This contract is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice Set the `Globals` contract address.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    event GiveawayCollectiveCreated(
        GiveawayCollective indexed gCollective,
        GiveawayCollective.GiveawayCollectiveOptions opts 
    );

    /// @notice Deploy a new giveaway collective instance. 
    /// @param opts Options used to initialize the giveaway collective. These are fixed
    ///             and cannot be changed.
    /// @return gCollective The newly created `Giveaway Collective` instance.
    function createGiveawayCollective(GiveawayCollective.GiveawayCollectiveOptions memory opts) 
        external returns(GiveawayCollective gCollective){
            gCollective = GiveawayCollective(
                payable(
                    new Proxy(
                        _GLOBALS.getImplementation(LibGlobals.GLOBAL_GIVEAWAY_COLLECTIVE_IMPL),
                        abi.encodeCall(GiveawayCollective.initializeGiveaway, (opts))
                    )
                )
            );
            emit GiveawayCollectiveCreated(gCollective, opts);
        }
}
