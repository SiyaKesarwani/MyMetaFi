# CollectionNFTCrowdfund
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/crowdfund/CollectionNFTCrowdfund.sol)

**Inherits:**
[CollectiveCrowdfund](/contracts/crowdfund/CollectiveCrowdfund.sol/abstract.CollectiveCrowdfund.md)


## State Variables
### host
This is the host of this crowdfund instance


```solidity
address public host;
```


### nftContract
The NFT contract to buy.


```solidity
IERC721 public nftContract;
```


### expiry
When this crowdfund expires.


```solidity
uint40 public expiry;
```


### settledPrice
What the NFT was actually bought for.


```solidity
uint96 public settledPrice;
```


## Functions
### constructor


```solidity
constructor(IGlobals globals) CollectiveCrowdfund(globals);
```

### initialize


```solidity
function initialize(CollectionNFTCrowdfundOptions memory opts) external payable onlyConstructor;
```

### buy

Execute arbitrary calldata to perform a buy, creating a collective
if it successfully buys the NFT.


```solidity
function buy(uint256 nftTokenId, address payable callTarget, uint96 callValue, bytes memory callData)
    external
    onlyDelegateCall
    returns (ICollective collective_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftTokenId`|`uint256`||
|`callTarget`|`address payable`|The target contract to call to buy the NFT.|
|`callValue`|`uint96`|The amount of ETH to send with the call.|
|`callData`|`bytes`|The calldata to execute.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collective_`|`ICollective`|Address of the `Collective` instance created after its bought.|


### getCrowdfundLifecycle


```solidity
function getCrowdfundLifecycle() public view override returns (CrowdfundLifecycle);
```

### _isEligibleToBuyNFT

If there is a settled price then we tried to buy the NFT.


```solidity
function _isEligibleToBuyNFT() internal view override returns (bool);
```

### _getFinalPrice

Get the final sale price of the bought assets.
This will also be the total voting power of the governance collective.


```solidity
function _getFinalPrice() internal view override returns (uint256);
```

### _buyFromOpensea


```solidity
function _buyFromOpensea(
    uint256 nftTokenId,
    address payable callTarget,
    uint96 callValue,
    uint96 fee,
    bytes memory callData
) private returns (ICollective collective_);
```

### _isCallAllowed


```solidity
function _isCallAllowed(address payable callTarget, bytes memory callData) private view returns (bool isAllowed);
```

## Errors
### OnlyCollectiveHostError

```solidity
error OnlyCollectiveHostError();
```

## Structs
### CollectionNFTCrowdfundOptions

```solidity
struct CollectionNFTCrowdfundOptions {
    string collectiveTitleName;
    IERC721 nftContractAddress;
    uint96 fundraiseGoal;
    uint40 crowdFundDuration;
    uint96 lowerLimitInvestment;
    address initialContributor;
    GovernanceOpts governanceOpts;
}
```

