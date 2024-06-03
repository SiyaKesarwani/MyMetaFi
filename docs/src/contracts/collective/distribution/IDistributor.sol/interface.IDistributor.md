# IDistributor
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/collective/distribution/IDistributor.sol)

Creates distribution for collectives.


## Functions
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
function claim(DistributionInfo calldata info, address contributor) external returns (uint128 amountClaimed);
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


### getClaimAmount

Compute the amount of a distribution's token are owed to a collective
member, identified by the `contributorAddress`.


```solidity
function getClaimAmount(DistributionInfo calldata info, address contributorAddress)
    external
    view
    returns (uint128 claimAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`info`|`DistributionInfo`|Information on the distribution being claimed.|
|`contributorAddress`|`address`|The address of the collective contributor to claim for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`claimAmount`|`uint128`|The amount of the distribution owed to the collective member.|


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
    returns (bool hasClaimed);
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
|`hasClaimed`|`bool`|Whether the `collectiveTokenId` has claimed.|


### getRemainingMemberSupply

Get how much unclaimed member tokens are left in a distribution.


```solidity
function getRemainingMemberSupply(ICollective collective, uint256 distributionId)
    external
    view
    returns (uint128 remainingMemberSupply);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collective`|`ICollective`|The collective to use for checking the unclaimed member tokens.|
|`distributionId`|`uint256`|The ID of the distribution to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`remainingMemberSupply`|`uint128`|The amount of distribution supply remaining.|


## Events
### DistributionClaimedByCollectiveContributor

```solidity
event DistributionClaimedByCollectiveContributor(
    ICollective indexed collective,
    address indexed contributorAddress,
    TokenType tokenType,
    address token,
    uint256 amountClaimed
);
```

## Structs
### DistributionInfo

```solidity
struct DistributionInfo {
    TokenType tokenType;
    uint256 distributionId;
    ICollective collective;
    address token;
    uint128 memberSupply;
    uint96 totalShares;
}
```

## Enums
### TokenType

```solidity
enum TokenType {
    Native,
    Erc20
}
```

