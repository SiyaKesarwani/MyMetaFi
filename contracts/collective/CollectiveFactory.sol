// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../utils/Proxy.sol";
import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";

import "./ICollectiveFactory.sol";

//Factory used to deploy new proxified `Collective` instances.
contract CollectiveFactory is ICollectiveFactory { 
    
    /// @notice The `Globals` contract storing global configuration values. 
    /// This contract is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice Set the `Globals` contract address.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    /// @inheritdoc ICollectiveFactory
    function createCollective(
        ICollective.GovernanceOpts memory opts,
        uint96 totalVotingPower,
        IERC721 preciousToken,
        uint256 preciousTokenId,
        address crowdfundAddress
    ) 
        external 
        returns(ICollective collective) 
    {
        // Deploy a new proxified `Collective` instance.
        ICollective.CollectiveInitData memory initData = ICollective.CollectiveInitData({  
            governanceOpts: opts,
            totalVotingPower: totalVotingPower,
            preciousToken: preciousToken,
            preciousTokenId: preciousTokenId,
            crowdfundAddress: crowdfundAddress
        });
        collective = ICollective(
            payable(
                new Proxy(
                    _GLOBALS.getImplementation(LibGlobals.GLOBAL_COLLECTIVE_IMPL),
                    abi.encodeCall(ICollective.initialize, (initData))
                )
            )
        );
        emit CollectiveCreated(collective, opts, preciousToken, preciousTokenId);
    }
}
