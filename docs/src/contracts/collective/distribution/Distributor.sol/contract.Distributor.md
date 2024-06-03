# Distributor
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/collective/distribution/Distributor.sol)

**Inherits:**
[IDistributor](/contracts/collective/distribution/IDistributor.sol/interface.IDistributor.md), [ReentrancyGuard](/contracts/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)

Creates distributions for collectives.


## State Variables
### lastDistributionIdPerCollective
Last distribution ID for a collective.


```solidity
mapping(ICollective => uint256) public lastDistributionIdPerCollective;
```


### NATIVE_TOKEN_ADDRESS
Token address used to indicate a native distribution (i.e. distribution of ETH).


```solidity
address private constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


### _GLOBALS
The `Globals` contract storing global configuration values. This contract
is immutable and it’s address will never change.


```solidity
IGlobals private immutable _GLOBALS;
```


### _storedBalances
Last known balance of a token, identified by an ID derived from the token.
Gets lazily updated when creating and claiming a distribution (transfers).
Allows one to simply transfer and call `createDistribution()` without
fussing with allowances.


```solidity
mapping(bytes32 => uint256) private _storedBalances;
```


### _distributionStates
tokenDistributorCollective => distributionId => DistributionState


```solidity
mapping(ICollective => mapping(uint256 => DistributionState)) private _distributionStates;
```


## Functions
### constructor


```solidity
constructor(IGlobals globals);
```

### createNativeDistribution

Create a new distribution for an outstanding native token balance
governed by a collective.

*Native tokens should be transferred directly into this contract
immediately prior (same tx) to calling `createDistribution()` or
attached to the call itself.*


```solidity
function createNativeDistribution(ICollective collective) external payable returns (DistributionInfo memory info);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collective`|`ICollective`|The collective whose members can claim the distribution.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`info`|`DistributionInfo`|Information on the created distribution.|


### claim

Claim a portion of a distribution owed to a `contributorAddress` belonging
to the collective that created the distribution. The caller
must be the collective


```solidity
function claim(DistributionInfo calldata info, address contributor)
    external
    nonReentrant
    returns (uint128 amountClaimed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`info`|`DistributionInfo`|Information on the distribution being claimed.|
|`contributor`|`address`|The person who is claiming the earning|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountClaimed`|`uint128`|The amount of the distribution claimed.|


### batchClaim

Batch version of `claim()`.


```solidity
function batchClaim(ICollective[] memory collectiveAddresses) external returns (uint128[] memory amountsClaimed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collectiveAddresses`|`ICollective[]`|Collectives whose distributions are being claimed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountsClaimed`|`uint128[]`|The amounts of the distributions claimed by collectives|


### getClaimAmountOfContributorFromCollectives

Compute the amount of a distribution's token are owed to a collective
member, identified by the `contributorAddress`.


```solidity
function getClaimAmountOfContributorFromCollectives(
    ICollective[] memory collectiveAddresses,
    address contributorAddress
) external view returns (uint128 totalClaimableAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collectiveAddresses`|`ICollective[]`|Information on the distribution being claimed.|
|`contributorAddress`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalClaimableAmount`|`uint128`|The amount of the distribution owed to the collective member from all the given collectives.|


### hasCollectiveContributorClaimed

Check whether a `contributorAddress` has claimed their share of a distribution.


```solidity
function hasCollectiveContributorClaimed(ICollective collective, address contributorAddress, uint256 distributionId)
    external
    view
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collective`|`ICollective`|The collective to use for checking whether the `collectiveTokenId` has claimed.|
|`contributorAddress`|`address`|The address of the collective contributor to claim for.|
|`distributionId`|`uint256`|The ID of the distribution to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|hasClaimed Whether the `collectiveTokenId` has claimed.|


### getRemainingMemberSupply

Get how much unclaimed member tokens are left in a distribution.


```solidity
function getRemainingMemberSupply(ICollective collective, uint256 distributionId) external view returns (uint128);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collective`|`ICollective`|The collective to use for checking the unclaimed member tokens.|
|`distributionId`|`uint256`|The ID of the distribution to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint128`|remainingMemberSupply The amount of distribution supply remaining.|


### getClaimAmount

Compute the amount of a distribution's token are owed to a collective
member, identified by the `contributorAddress`.


```solidity
function getClaimAmount(DistributionInfo calldata info, address contributorAddress) public view returns (uint128);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`info`|`DistributionInfo`|Information on the distribution being claimed.|
|`contributorAddress`|`address`|The address of the collective contributor to claim for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint128`|claimAmount The amount of the distribution owed to the collective member.|


### _createDistribution


```solidity
function _createDistribution(CreateDistributionArgs memory args) private returns (DistributionInfo memory info);
```

### _transfer


```solidity
function _transfer(TokenType tokenType, address payable recipient, uint256 amount) private;
```

### _getDistributionHash


```solidity
function _getDistributionHash(DistributionInfo memory info) private pure returns (bytes32 hash);
```

### _getBalanceId


```solidity
function _getBalanceId(TokenType tokenType) private pure returns (bytes32 balanceId);
```

## Errors
### InvalidDistributionInfoError

```solidity
error InvalidDistributionInfoError(DistributionInfo info);
```

### DistributionAlreadyClaimedByCollectiveContributorError

```solidity
error DistributionAlreadyClaimedByCollectiveContributorError(uint256 distributionId, address contributorAddress);
```

### InvalidDistributionSupplyError

```solidity
error InvalidDistributionSupplyError(uint128 supply);
```

### OnlyCollectiveCanCall

```solidity
error OnlyCollectiveCanCall();
```

## Structs
### DistributionState

```solidity
struct DistributionState {
    bytes32 distributionHash;
    uint128 remainingMemberSupply;
    mapping(address => bool) hasCollectiveContributorClaimed;
}
```

### CreateDistributionArgs

```solidity
struct CreateDistributionArgs {
    ICollective collective;
    TokenType tokenType;
    address token;
    uint256 currentTokenBalance;
}
```

