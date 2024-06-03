# ICollective
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/collective/ICollective.sol)


## Functions
### crowdfundAddress

The address of crowdfund


```solidity
function crowdfundAddress() external view returns (address);
```

### preciousNFTHash

NFT details, fixed from the inception of this collective. CANNOT be changed later so storing as hash


```solidity
function preciousNFTHash() external view returns (bytes32);
```

### nonce

This is used to execute proposals


```solidity
function nonce() external view returns (uint256);
```

### initialize

Initialize storage for proxy contracts


```solidity
function initialize(CollectiveInitData memory initData) external;
```

### getDistributionShareOf

Returns the total share of contributor in totalVotingPower according to his ethUsed


```solidity
function getDistributionShareOf(address contributor) external view returns (uint256 ethUsed);
```

### getTotalVotingPowerOfCollective

Returns the total voting power according to the price of nft bought


```solidity
function getTotalVotingPowerOfCollective() external view returns (uint96);
```

### getGovernanceValues

Returns the current governance values for proposals


```solidity
function getGovernanceValues() external view returns (GovernanceOpts memory gv);
```

### getClaimableAmountOfContributor

Returns the claimable earning of individual


```solidity
function getClaimableAmountOfContributor(address contributor) external view returns (uint128 claimableAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contributor`|`address`|The contributor whose earning is being fetched|


### createDistributionAndClaim

Create a ETH distribution if it is not created yet,
by moving the collective's entire balance
to the `Distributor` contract and immediately creating a
distribution governed by this collective.
Also claim all the earnings of caller from this collective
This function can be called by anyone externally or `batchClaim()` from Distributor contract


```solidity
function createDistributionAndClaim(address contributor) external returns (uint128 amountClaimed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contributor`|`address`|The contributor whose earning will be claimed|


### executeProposalListToOpensea

Lists the NFT on Opensea


```solidity
function executeProposalListToOpensea(ListingCall memory listingParams) external returns (bytes32 orderHash);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`listingParams`|`ListingCall`|All new listing params|


### executeProposalUpdateGovernanceValues

Update the governance values of this collective


```solidity
function executeProposalUpdateGovernanceValues(GovernanceOpts memory governanceValues, bytes calldata signature)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`governanceValues`|`GovernanceOpts`|New governanceValues for this collective.|
|`signature`|`bytes`|The signature to verify off-chain proposal|


### executeProposalArbitraryCalls

Arbitrary calls from this contract to other unknown contracts


```solidity
function executeProposalArbitraryCalls(
    ArbitraryCall[] calldata calls,
    IERC721 preciousToken,
    uint256 preciousTokenId,
    bytes calldata signature
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`calls`|`ArbitraryCall[]`|Calling to more than one arbitrary call in a single function call|
|`preciousToken`|`IERC721`|The token contract of nft held|
|`preciousTokenId`|`uint256`|The tokenId of nft held|
|`signature`|`bytes`|The signature to verify off-chain proposal|


## Events
### OpenseaOrderListed

```solidity
event OpenseaOrderListed(
    IOpenseaExchange.OrderParameters orderParams,
    bytes32 orderHash,
    IERC721 token,
    uint256 tokenId,
    uint256 sellingPrice,
    uint256 expiry
);
```

### OpenseaLastOrderCancelled

```solidity
event OpenseaLastOrderCancelled(bytes32 orderHash, IERC721 token, uint256 tokenId);
```

### GovernanceValuesUpdated

```solidity
event GovernanceValuesUpdated(GovernanceOpts newGovernanceValues);
```

### ArbitraryCallExecuted

```solidity
event ArbitraryCallExecuted(uint256 idx, uint256 count);
```

## Errors
### InvalidFeeRecipients

```solidity
error InvalidFeeRecipients();
```

### CannotClaimZeroEarnings

```solidity
error CannotClaimZeroEarnings(uint128 memberSupply);
```

### BadPreciousListError

```solidity
error BadPreciousListError();
```

### PreciousNotWithinContractError

```solidity
error PreciousNotWithinContractError(IERC721 token, uint256 tokenId);
```

## Structs
### GovernanceOpts

```solidity
struct GovernanceOpts {
    uint40 voteDuration;
    uint40 vetoDuration;
    uint16 passThresholdBps;
}
```

### CollectiveInitData

```solidity
struct CollectiveInitData {
    GovernanceOpts governanceOpts;
    uint96 totalVotingPower;
    IERC721 preciousToken;
    uint256 preciousTokenId;
    address crowdfundAddress;
}
```

### ListingCall

```solidity
struct ListingCall {
    IOpenseaConduitController conduitController;
    IOpenseaExchange seaport;
    uint256 sellingPrice;
    uint256 listPrice;
    uint256[] fees;
    address payable[] feeRecipients;
    IERC721 preciousToken;
    uint256 preciousTokenId;
    bytes signature;
}
```

### ArbitraryCall

```solidity
struct ArbitraryCall {
    address payable target;
    uint256 value;
    bytes data;
    bytes32 expectedResultHash;
}
```

