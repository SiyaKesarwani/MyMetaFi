# CollectiveCrowdfund
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/crowdfund/CollectiveCrowdfund.sol)

**Inherits:**
[ERC721Receiver](/contracts/tokens/ERC721Receiver.sol/abstract.ERC721Receiver.md), [Implementation](/contracts/utils/Implementation.sol/abstract.Implementation.md), [ICollectiveCrowdfund](/contracts/crowdfund/ICollectiveCrowdfund.sol/interface.ICollectiveCrowdfund.md), [ReentrancyGuard](/contracts/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)


## State Variables
### totalContributions
The total (recorded) ETH contributed to this crowdfund.


```solidity
uint96 public totalContributions;
```


### totalContributors
The total contributors to this crowdfund.


```solidity
uint256 public totalContributors;
```


### lowerLimitInvestment
Minimum limit of the investment set by the host


```solidity
uint96 public lowerLimitInvestment;
```


### fundraiseGoal
Minimum limit of the crowdfund amount to raise for buying a NFT


```solidity
uint96 public fundraiseGoal;
```


### factory
Store the address of Factory Contract through which this crowdfund is created.
To check it in `transferUnusedContribution()` function.


```solidity
address public factory;
```


### delegationsByContributor
Who a contributor last delegated to.


```solidity
mapping(address => address) public delegationsByContributor;
```


### successCollective
The Collective instance created by `_createCollectiveAndTransferNFT()`
to which NFT is sent on buying after a successful crowdfund.


```solidity
ICollective public successCollective;
```


### governanceOpts
Collective governance options passed into `initialize()`.


```solidity
GovernanceOpts public governanceOpts;
```


### _GLOBALS

```solidity
IGlobals internal immutable _GLOBALS;
```


### _contributionsByContributor
Array of contributions by a contributor.
One is created for every nonzero contribution made.
`private` for testing purposes only.


```solidity
mapping(address => Contribution[]) private _contributionsByContributor;
```


### _totalContributionsOfContributor
Total contributions made by a contributor until NFT is purchased
`private` for testing purposes only.


```solidity
mapping(address => uint96) private _totalContributionsOfContributor;
```


### _contributorHasClaimed
Contributor has claimed through `claimUnusedContribution()`
or `transferUnusedContribution()`.


```solidity
mapping(address => bool) private _contributorHasClaimed;
```


## Functions
### onlyCollectiveContributor


```solidity
modifier onlyCollectiveContributor();
```

### constructor


```solidity
constructor(IGlobals globals);
```

### contribute

Contribute to this crowdfund


```solidity
function contribute(address delegate) external payable onlyDelegateCall;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegate`|`address`|The address to which he is delegating his ownership.|


### updateOnlyDelegate

Updates only delegate address of a contributor

*This will only be called to update delegate address of contributor which internally calls `_updateDelegate()`*


```solidity
function updateOnlyDelegate(address newDelegate) external onlyDelegateCall onlyCollectiveContributor;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newDelegate`|`address`|The new delegate address to replace old one|


### acceptContributionFromCollective

Contribute to this crowdfund from another crowdfund


```solidity
function acceptContributionFromCollective(address contributor, address delegate) external payable onlyDelegateCall;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contributor`|`address`|The contributor who is transferring fund from expired collective.|
|`delegate`|`address`|The address to which he is delegating his ownership.|


### getContributorInfo

Retrieve info about a participant's contributions.

*This will only be called off-chain so doesn't have to be optimal.*


```solidity
function getContributorInfo(address contributor)
    public
    view
    returns (uint256 ethContributed, uint256 ethUsed, uint256 ethOwed, uint256 votingPower);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contributor`|`address`|The contributor to retrieve contributions for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ethContributed`|`uint256`|The total ETH contributed by `contributor`.|
|`ethUsed`|`uint256`|The total ETH used by `contributor` to acquire the NFT.|
|`ethOwed`|`uint256`|The total ETH refunded back to `contributor`.|
|`votingPower`|`uint256`|The intrinsic voting power of `contributor` equivalent to his contribution used.|


### getCrowdfundLifecycle

Get the current lifecycle of the crowdfund.


```solidity
function getCrowdfundLifecycle() public view virtual returns (CrowdfundLifecycle);
```

### claimUnusedContribution

Claim unused ETH back to wallet

*This will be called by contributors to claim all the unused amount of ETH*


```solidity
function claimUnusedContribution(address payable receiver)
    external
    onlyDelegateCall
    onlyCollectiveContributor
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address payable`|The address in which contributor want to receive the claim.|


### transferUnusedContribution

Transfer unused ETH to other collective

*This will be called by contributors to transfer all the unused amount of ETH to any Active Collective*


```solidity
function transferUnusedContribution(address payable collectiveCrowdfundAddress, address delegate)
    external
    onlyDelegateCall
    onlyCollectiveContributor
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collectiveCrowdfundAddress`|`address payable`|The address of another crowdfund collective|
|`delegate`|`address`|This is the delegate address set in the contribute function of another collective|


### _initialize


```solidity
function _initialize(CollectiveCrowdfundOptions memory opts) internal;
```

### _createCollectiveAndTransferNFT

Can be called after a collective crowdfunding becomes successful.
Deploys and initializes a `Collective` instance via the `CollectiveFactory`
and transfers the bought NFT to it.


```solidity
function _createCollectiveAndTransferNFT(IERC721 preciousToken, uint256 preciousTokenId)
    internal
    returns (ICollective collective_);
```

### _assertIsContributor


```solidity
function _assertIsContributor(address who) internal view returns (bool);
```

### _isEligibleToBuyNFT

Check if this crowdfund is eligible to buy NFT


```solidity
function _isEligibleToBuyNFT() internal view virtual returns (bool);
```

### _getFinalPrice

Get the final sale price of the bought assets.
This will also be the total voting power of the governance collective.


```solidity
function _getFinalPrice() internal view virtual returns (uint256);
```

### _transferContributionToCollective


```solidity
function _transferContributionToCollective(
    ICollectiveCrowdfund crowdfund,
    address contributor,
    address delegate,
    uint256 amount
) private;
```

### _contribute


```solidity
function _contribute(address contributor, uint96 amount, address delegate, uint96 previousTotalContributions) private;
```

### _claimLeftAmount


```solidity
function _claimLeftAmount(address contributor, address payable receiver, uint256 amount) private;
```

### _updateDelegate


```solidity
function _updateDelegate(address contributor, address newDelegate) private;
```

### _getFinalContribution


```solidity
function _getFinalContribution(address contributor)
    private
    view
    returns (uint256 ethUsed, uint256 ethOwed, uint256 votingPower);
```

### _getCollectiveFactory


```solidity
function _getCollectiveFactory() private view returns (ICollectiveFactory);
```

## Structs
### CollectiveCrowdfundOptions

```solidity
struct CollectiveCrowdfundOptions {
    string collectiveTitleName;
    IERC721 nftContractAddress;
    uint96 fundraiseGoal;
    uint40 crowdFundDuration;
    uint96 lowerLimitInvestment;
    address initialContributor;
    GovernanceOpts governanceOpts;
}
```

