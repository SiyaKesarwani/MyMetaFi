# Collective
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/collective/Collective.sol)

**Inherits:**
[ICollective](/contracts/collective/ICollective.sol/interface.ICollective.md), [ERC721Receiver](/contracts/tokens/ERC721Receiver.sol/abstract.ERC721Receiver.md), [Implementation](/contracts/utils/Implementation.sol/abstract.Implementation.md), [ReadOnlyDelegateCall](/contracts/utils/ReadOnlyDelegateCall.sol/abstract.ReadOnlyDelegateCall.md), [EIP712](/contracts/utils/EIP712.sol/abstract.EIP712.md)

The governance contract that also custodies the precious NFTs. This
is also the Governance NFT 721 contract.


## State Variables
### nonce
This is used to execute proposals


```solidity
uint256 public nonce;
```


### crowdfundAddress
The address of crowdfund


```solidity
address public crowdfundAddress;
```


### preciousNFTHash
NFT details, fixed from the inception of this collective. CANNOT be changed later so storing as hash


```solidity
bytes32 public preciousNFTHash;
```


### SELLING_TYPEHASH

```solidity
bytes32 constant SELLING_TYPEHASH = keccak256(
    "ExecuteProposal(address conduitController,address seaport,uint256 sellingPrice,uint256 listPrice,uint256[] fees,address[] feeRecipients,address preciousToken,uint256 preciousTokenId,uint256 nonce)"
);
```


### GOVERNANCE_TYPEHASH

```solidity
bytes32 constant GOVERNANCE_TYPEHASH =
    keccak256("ExecuteGoverningProposal(uint40 voteDuration,uint40 vetoDuration,uint16 passThresholdBps,uint256 nonce)");
```


### EXECUTE_ARBITRARY_CALL_TYPEHASH

```solidity
bytes32 constant EXECUTE_ARBITRARY_CALL_TYPEHASH = keccak256(
    "ExecuteArbitraryCall(ArbitraryCall[] call,address preciousToken,uint256 preciousTokenId,uint256 nonce)ArbitraryCall(address target,uint256 value,bytes data,bytes32 expectedResultHash)"
);
```


### _orderHash
The order hash of listed NFT


```solidity
bytes32 private _orderHash;
```


### _orderCompsOfListedNFT
The OrderComps after NFT is listed (to cancel the listing)


```solidity
IOpenseaExchange.OrderComponents[] private _orderCompsOfListedNFT;
```


### _governanceValues

```solidity
GovernanceOpts private _governanceValues;
```


### _totalVotingPower

```solidity
uint96 private _totalVotingPower;
```


### _distInfo
This is createDistribution flag


```solidity
IDistributor.DistributionInfo private _distInfo;
```


### _GLOBALS

```solidity
IGlobals private immutable _GLOBALS;
```


## Functions
### constructor


```solidity
constructor(IGlobals globals) EIP712("Collective", "1");
```

### receive


```solidity
receive() external payable;
```

### initialize

Initialize storage for proxy contracts


```solidity
function initialize(CollectiveInitData memory initData) external onlyConstructor;
```

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


### getClaimableAmountOfContributor

Returns the claimable earning of individual


```solidity
function getClaimableAmountOfContributor(address contributor) external view returns (uint128 claimableAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contributor`|`address`|The contributor whose earning is being fetched|


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

### getDistributionShareOf

Returns the total share of contributor in totalVotingPower according to his ethUsed


```solidity
function getDistributionShareOf(address contributor) public view returns (uint256 ethUsed);
```

### _createDistribution

Create a token distribution by moving the collective's entire balance
to the `Distributor` contract and immediately creating a
distribution governed by this collective.


```solidity
function _createDistribution(IDistributor.TokenType tokenType, IDistributor distributor, uint256 memberSupply)
    private
    returns (IDistributor.DistributionInfo memory distInfo);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenType`|`IDistributor.TokenType`|The type of token to distribute.|
|`distributor`|`IDistributor`|The distributor contract.|
|`memberSupply`|`uint256`|The total balance of this collective.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`distInfo`|`IDistributor.DistributionInfo`|The information about the created distribution.|


### _getOrderHash

*`getOrderHash()` wants an `OrderComponents` struct, which is an `OrderParameters`
struct but with the last field (`totalOriginalConsiderationItems`)
replaced with the maker's nonce. Since we (the maker) never increment
our seaport nonce, it is always 0.
So we temporarily set the `totalOriginalConsiderationItems` field to 0,
force cast the `OrderParameters` into a `OrderComponents` type, call
`getOrderHash()`, and then restore the `totalOriginalConsiderationItems`
field's value before returning.*


```solidity
function _getOrderHash(IOpenseaExchange.OrderParameters memory orderParams, IOpenseaExchange seaport)
    private
    returns (bytes32 orderHash);
```

### _setPreciousNFT


```solidity
function _setPreciousNFT(IERC721 preciousToken, uint256 preciousTokenId) private;
```

### _executeSingleArbitraryCall


```solidity
function _executeSingleArbitraryCall(uint256 idx, ArbitraryCall[] memory calls) private;
```

### _getMemberSupplyOfCollective

To check if this collective is eligible to create distribution or not


```solidity
function _getMemberSupplyOfCollective() private view returns (uint128 memberSupply);
```

### _hash

Generates the typehash for selling typedData


```solidity
function _hash(
    address conduitController,
    address seaport,
    uint256 sellingPrice,
    uint256 listPrice,
    uint256[] memory fees,
    address payable[] memory feeRecipients,
    address preciousToken,
    uint256 preciousTokenId
) private view returns (bytes32);
```

### _hashArbitraryCalls

Generates the typehash for arbitraryCall typedData


```solidity
function _hashArbitraryCalls(ArbitraryCall[] calldata calls, IERC721 preciousToken, uint256 preciousTokenId)
    private
    view
    returns (bytes32);
```

### _hashGovernanceValues

Generates the typehash for governance typedData


```solidity
function _hashGovernanceValues(uint40 voteDuration, uint40 vetoDuration, uint16 passThresholdBps)
    private
    view
    returns (bytes32);
```

### _isPreciousListCorrect


```solidity
function _isPreciousListCorrect(IERC721 preciousToken, uint256 preciousTokenId) private view returns (bool);
```

### _getHasPrecious


```solidity
function _getHasPrecious(IERC721 preciousToken, uint256 preciousTokenId) private view returns (bool hasPrecious);
```

### _hashPreciousNFT


```solidity
function _hashPreciousNFT(IERC721 preciousToken, uint256 preciousTokenId) private pure returns (bytes32 h);
```

## Events
### DistributionCreated

```solidity
event DistributionCreated(IDistributor.TokenType tokenType, uint256 amount);
```

## Errors
### ArbitraryCallFailedError

```solidity
error ArbitraryCallFailedError(bytes revertData);
```

### UnexpectedCallResultHashError

```solidity
error UnexpectedCallResultHashError(uint256 idx, bytes32 resultHash, bytes32 expectedResultHash);
```

### NotEnoughEthError

```solidity
error NotEnoughEthError(uint256 callValue, uint256 ethAvailable);
```

