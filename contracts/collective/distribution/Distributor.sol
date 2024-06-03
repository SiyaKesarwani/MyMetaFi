// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../globals/IGlobals.sol";
import "../../globals/LibGlobals.sol";
import "../../utils/LibAddress.sol";
import "../../utils/LibRawResult.sol";
import "../../utils/LibSafeCast.sol";
import "../../utils/LibERC20Compat.sol";

import "./IDistributor.sol";

/// @notice Creates distributions for collectives.
contract Distributor is IDistributor, ReentrancyGuard{ 
    using LibAddress for address payable;
    using LibRawResult for bytes;
    using LibSafeCast for uint256;
    using LibERC20Compat for IERC20;

    /// @notice State of the distribution of a Collective
    struct DistributionState {
        // The hash of the `DistributionInfo`.
        bytes32 distributionHash;
        // The remaining member supply.
        uint128 remainingMemberSupply;
        // Whether a governance token has claimed its distribution share.
        mapping(address => bool) hasCollectiveContributorClaimed;
    }

    /// @notice Arguments for `_createDistribution()`.
    struct CreateDistributionArgs {
        ICollective collective;
        TokenType tokenType;
        address token;
        uint256 currentTokenBalance;
    }

    error InvalidDistributionInfo(
        DistributionInfo info
    );
    error DistributionAlreadyClaimed(
        uint256 distributionId, 
        address contributorAddress
    );
    error InvalidDistributionSupply(
        uint128 supply
    );
    error OnlyCollective();
    error OnlyCollectiveContributor();

    /// @notice Last distribution ID for a collective.
    mapping(ICollective => uint256) public lastDistributionIdPerCollective;

    /// @notice Token address used to indicate a native distribution (i.e. distribution of ETH).
    address private constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice The `Globals` contract storing global configuration values. This contract
    ///         is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice Last known balance of a token, identified by an ID derived from the token.
    ///         Gets lazily updated when creating and claiming a distribution (transfers).
    ///         Allows one to simply transfer and call `createDistribution()` without
    ///         fussing with allowances.
    mapping(bytes32 => uint256) private _storedBalances;

    /// @notice tokenDistributorCollective => distributionId => DistributionState
    mapping(ICollective => mapping(uint256 => DistributionState)) private _distributionStates;

    /// @notice Set the `Globals` contract address.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    /// @inheritdoc IDistributor
    function createNativeDistribution(
        ICollective collective
    ) 
        external 
        payable 
        returns(DistributionInfo memory info) 
    {
        if(msg.sender != address(collective)){
            revert OnlyCollective();
        }
        info = _createDistribution(
            CreateDistributionArgs({
                collective: collective,
                tokenType: TokenType.Native,
                token: NATIVE_TOKEN_ADDRESS,
                currentTokenBalance: address(this).balance
            })
        );
    }

    /// @inheritdoc IDistributor
    function createErc20Distribution(
        IERC20 token,
        ICollective collective
    ) external returns (DistributionInfo memory info) {
        if(msg.sender != address(collective)){
            revert OnlyCollective();
        }
        info = _createDistribution(
            CreateDistributionArgs({
                collective: collective,
                tokenType: TokenType.Erc20,
                token: address(token),
                currentTokenBalance: token.balanceOf(address(this))
            })
        );
    }

    /// @inheritdoc IDistributor
    function claim(
        DistributionInfo calldata info
    ) 
        public 
        nonReentrant 
        returns(uint128 amountClaimed) 
    {
        // Only collective contributor can call
        uint256 callerEthUsedInCollective = info.collective.getDistributionShareOf(msg.sender);
        if(callerEthUsedInCollective < 1){
            revert OnlyCollectiveContributor();
        }
        // DistributionInfo must be correct for this distribution ID.
        DistributionState storage state = _distributionStates[info.collective][info.distributionId];
        if (state.distributionHash != _getDistributionHash(info)) {
            revert InvalidDistributionInfo(info);
        }
        // The msg.sender must not have claimed its distribution yet.
        if (state.hasCollectiveContributorClaimed[msg.sender]) {
            revert DistributionAlreadyClaimed(info.distributionId, msg.sender);
        }

        // Compute amount owed to msg.sender.
        amountClaimed = getClaimAmount(info, msg.sender);

        // // Compute amount owed to msg.sender.
        // amountClaimed = info.collective.getClaimableAmountOfContributor(msg.sender);
        
        // Mark the msg.sender as having claimed their distribution.
        state.hasCollectiveContributorClaimed[msg.sender] = true;

        // Cap at the remaining member supply. Otherwise a malicious
        // collective could drain more than the distribution supply.
        uint128 remainingMemberSupply = state.remainingMemberSupply;
        amountClaimed = amountClaimed > remainingMemberSupply
            ? remainingMemberSupply
            : amountClaimed;
        state.remainingMemberSupply = remainingMemberSupply - amountClaimed;

        // Transfer tokens owed.
        _transfer(info.tokenType, info.token, payable(msg.sender), amountClaimed);
        emit DistributionClaimedByCollectiveContributor(
            info.collective,
            msg.sender,
            info.tokenType,
            info.token,
            amountClaimed
        );
    }

    /// @inheritdoc IDistributor
    function batchClaim(
        DistributionInfo[] calldata infos
    ) external returns (uint128[] memory amountsClaimed) {
        amountsClaimed = new uint128[](infos.length);
        for (uint256 i = 0; i < infos.length; ++i) {
            amountsClaimed[i] = claim(infos[i]);
        }
    }

    // /// @inheritdoc IDistributor
    // function batchClaim(
    //     ICollective[] memory collectiveAddresses
    // ) 
    //     external 
    // {
    //     for (uint256 i = 0; i < collectiveAddresses.length; ++i) {
    //         collectiveAddresses[i].createDistributionAndClaim(msg.sender);
    //     }
    // }

    /// @inheritdoc IDistributor
    function getClaimAmount(
        DistributionInfo calldata info,
        address contributorAddress
    ) public view returns (uint128) {
        uint256 shareOfSupply = ((info.collective.getDistributionShareOf(contributorAddress)) * 1e30) /
            info.totalShares;

        return
            // We round up here to prevent dust amounts getting trapped in this contract.
            ((shareOfSupply * info.memberSupply + (1e30 - 1)) / 1e30)
                .safeCastUint256ToUint128();
    }

    // /// @inheritdoc IDistributor
    // function getClaimAmountOfContributorFromCollectives(
    //     ICollective[] memory collectiveAddresses,
    //     address contributorAddress
    // ) 
    //     external 
    //     view 
    //     returns(uint128 totalClaimableAmount) 
    // {
    //     totalClaimableAmount = 0;
    //     for(uint256 i = 0; i < collectiveAddresses.length; i++){
    //         ICollective collective = collectiveAddresses[i];
    //         totalClaimableAmount += collective.getClaimableAmountOfContributor(contributorAddress);
    //     }
    // }

    /// @inheritdoc IDistributor
    function hasCollectiveContributorClaimed(
        ICollective collective,
        address contributorAddress,
        uint256 distributionId
    ) 
        external 
        view 
        returns(bool) 
    {
        return _distributionStates[collective][distributionId].hasCollectiveContributorClaimed[contributorAddress];
    }

    /// @inheritdoc IDistributor
    function getRemainingMemberSupply(
        ICollective collective,
        uint256 distributionId
    ) 
        external 
        view 
        returns(uint128) 
    {
        return _distributionStates[collective][distributionId].remainingMemberSupply;
    }

    // Private function for creating distribution
    function _createDistribution(
        CreateDistributionArgs memory args
    ) 
        private 
        returns(DistributionInfo memory info) 
    {
        uint128 supply;
        {
            bytes32 balanceId = _getBalanceId(args.tokenType, args.token);
            supply = (args.currentTokenBalance - _storedBalances[balanceId])
                .safeCastUint256ToUint128();
            // Supply must be nonzero.
            if (supply == 0) {
                revert InvalidDistributionSupply(supply);
            }
            // Update stored balance.
            _storedBalances[balanceId] = args.currentTokenBalance;
        }
        // Create a distribution.
        info = DistributionInfo({
            tokenType: args.tokenType,
            distributionId: ++lastDistributionIdPerCollective[args.collective],
            token: args.token,
            collective: args.collective,
            memberSupply: supply,
            totalShares: args.collective.getTotalVotingPowerOfCollective()
        });
        (
            _distributionStates[args.collective][info.distributionId].distributionHash,
            _distributionStates[args.collective][info.distributionId].remainingMemberSupply
        ) = (_getDistributionHash(info), supply);
        emit DistributionCreated(args.collective, info);
    }

    // Private transfer function
    function _transfer(
        TokenType tokenType,
        address token,
        address payable recipient,
        uint256 amount
    ) 
        private 
    {
        bytes32 balanceId = _getBalanceId(tokenType, token);
        // Reduce stored token balance.
        uint256 storedBalance = _storedBalances[balanceId] - amount;
        // Temporarily set to max as a reentrancy guard. An interesing attack
        // could occur if we didn't do this where an attacker could `claim()` and
        // reenter upon transfer (e.g. in the `tokensToSend` hook of an ERC777) to
        // `createERC20Distribution()`. Since the `balanceOf(address(this))`
        // would not of been updated yet, the supply would be miscalculated and
        // the attacker would create a distribution that essentially steals from
        // the last distribution they were claiming from. Here, we prevent that
        // by causing an arithmetic underflow with the supply calculation if
        // this were to be attempted.
        _storedBalances[balanceId] = type(uint256).max;
        if (tokenType == TokenType.Native) {
            recipient.transferEth(amount);
        } else {
            assert(tokenType == TokenType.Erc20);
            IERC20(token).compatTransfer(recipient, amount);
        }
        _storedBalances[balanceId] = storedBalance;
    }

    // Private function to calculate hash of distribution
    function _getDistributionHash(
        DistributionInfo memory info
    ) 
        private 
        pure 
        returns(bytes32 hash) 
    {
        assembly {
            hash := keccak256(info, 0x100)
        }
    }

    // Private function to get balanceId
    function _getBalanceId(
        TokenType tokenType,
        address token
    ) 
        private 
        pure 
        returns(bytes32 balanceId) 
    {
        if (tokenType == TokenType.Native) {
            return bytes32(uint256(uint160(NATIVE_TOKEN_ADDRESS)));
        }
        assert(tokenType == TokenType.Erc20);
        return bytes32(uint256(uint160(token)));
    }
}