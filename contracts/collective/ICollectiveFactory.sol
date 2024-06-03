// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../tokens/IERC721.sol";

import "./ICollective.sol";

/// @notice Creates generic Collective instances.
interface ICollectiveFactory {
    event CollectiveCreated(
        ICollective indexed collective,
        ICollective.GovernanceOpts opts,
        IERC721 preciousToken,
        uint256 preciousTokenId
    );

    /// @notice Deploy a new collective instance. 
    /// @param opts Options used to initialize the party. These are fixed
    ///             and can 
    /// @param preciousToken The token that is considered precious by the
    ///                       collective.These are protected assets and are subject
    ///                       to extra restrictions in proposals vs other
    ///                       assets.
    /// @param preciousTokenId The ID associated with token in `preciousToken`.
    /// @return collective The newly created `Collective` instance.
    function createCollective(
        ICollective.GovernanceOpts memory opts,
        uint96 totalVotingPower,
        IERC721 preciousToken,
        uint256 preciousTokenId,
        address crowdfundAddress
    ) 
        external 
        returns(ICollective collective);
}
