# CollectiveFactory
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/collective/CollectiveFactory.sol)

**Inherits:**
[ICollectiveFactory](/contracts/collective/ICollectiveFactory.sol/interface.ICollectiveFactory.md)

Factory used to deploy new proxified `Collective` instances.


## State Variables
### _GLOBALS
The `Globals` contract storing global configuration values. This contract
is immutable and it’s address will never change.


```solidity
IGlobals private immutable _GLOBALS;
```


## Functions
### constructor


```solidity
constructor(IGlobals globals);
```

### createCollective

Deploy a new collective instance.


```solidity
function createCollective(
    ICollective.GovernanceOpts memory opts,
    uint96 totalVotingPower,
    IERC721 preciousToken,
    uint256 preciousTokenId,
    address crowdfundAddress
) external returns (ICollective collective);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`opts`|`ICollective.GovernanceOpts`|Options used to initialize the party. These are fixed and can|
|`totalVotingPower`|`uint96`||
|`preciousToken`|`IERC721`|The token that is considered precious by the collective.These are protected assets and are subject to extra restrictions in proposals vs other assets.|
|`preciousTokenId`|`uint256`|The ID associated with token in `preciousToken`.|
|`crowdfundAddress`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collective`|`ICollective`|The newly created `Collective` instance.|


