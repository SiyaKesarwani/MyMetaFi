# SingleNFTCrowdfund
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/crowdfund/SingleNFTCrowdfund.sol)

**Inherits:**
[CollectiveCrowdfund](/contracts/crowdfund/CollectiveCrowdfund.sol/abstract.CollectiveCrowdfund.md)


## State Variables
### nftTokenId
The NFT token ID to buy.


```solidity
uint256 public nftTokenId;
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
function initialize(SingleNFTCrowdfundOptions memory opts) external payable onlyConstructor;
```

### buy

Execute arbitrary calldata to perform a buy, transfer fees to recipient on buy price
creating a collective if it successfully buys the NFT.


```solidity
function buy(address payable callTarget, uint96 callValue, bytes memory callData)
    external
    onlyDelegateCall
    onlyCollectiveContributor
    returns (ICollective collective_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
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

Check if this crowdfund is eligible to buy NFT


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
function _buyFromOpensea(address payable callTarget, uint96 callValue, uint96 fee, bytes memory callData)
    private
    returns (ICollective collective_);
```

### _isCallAllowed


```solidity
function _isCallAllowed(address payable callTarget, bytes memory callData) private view returns (bool isAllowed);
```

## Structs
### SingleNFTCrowdfundOptions

```solidity
struct SingleNFTCrowdfundOptions {
    string collectiveTitleName;
    IERC721 nftContractAddress;
    uint256 nftTokenId;
    uint96 fundraiseGoal;
    uint40 crowdFundDuration;
    uint96 lowerLimitInvestment;
    address initialContributor;
    GovernanceOpts governanceOpts;
}
```

