# CollectiveCrowdfundFactory
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/crowdfund/CollectiveCrowdfundFactory.sol)


## State Variables
### _GLOBALS

```solidity
IGlobals private immutable _GLOBALS;
```


## Functions
### constructor


```solidity
constructor(IGlobals globals);
```

### createSingleNFTCrowdfund

Create a new crowdfund to purchase a specific NFT (i.e., with a
known token ID) listing for a known price.


```solidity
function createSingleNFTCrowdfund(SingleNFTCrowdfund.SingleNFTCrowdfundOptions memory opts)
    public
    payable
    returns (SingleNFTCrowdfund inst);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`opts`|`SingleNFTCrowdfund.SingleNFTCrowdfundOptions`|Options used to initialize the crowdfund. These are not fixed and can be changed later using update() function.|


### createCollectionNFTCrowdfund

Create a new crowdfund to purchase any NFT from a collection
(i.e. any token ID) from a collection for a known price.


```solidity
function createCollectionNFTCrowdfund(CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions memory opts)
    public
    payable
    returns (CollectionNFTCrowdfund inst);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`opts`|`CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions`|Options used to initialize the crowdfund. These are not fixed and can be changed later using update() function.|


## Events
### SingleNFTCrowdfundCreated

```solidity
event SingleNFTCrowdfundCreated(SingleNFTCrowdfund crowdfund, SingleNFTCrowdfund.SingleNFTCrowdfundOptions opts);
```

### CollectionNFTCrowdfundCreated

```solidity
event CollectionNFTCrowdfundCreated(
    CollectionNFTCrowdfund crowdfund, CollectionNFTCrowdfund.CollectionNFTCrowdfundOptions opts
);
```

