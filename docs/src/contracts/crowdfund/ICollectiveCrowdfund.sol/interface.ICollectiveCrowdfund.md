# ICollectiveCrowdfund
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/crowdfund/ICollectiveCrowdfund.sol)


## Functions
### factory

Store the address of Factory Contract through which this crowdfund is created.
To check it in `transferUnusedContribution()` function.


```solidity
function factory() external view returns (address);
```

### lowerLimitInvestment

Minimum limit of the investment set by the host


```solidity
function lowerLimitInvestment() external view returns (uint96);
```

### totalContributions

The total (recorded) ETH contributed to this crowdfund.


```solidity
function totalContributions() external returns (uint96);
```

### totalContributors

The total contributors to this crowdfund.


```solidity
function totalContributors() external returns (uint256);
```

### fundraiseGoal

Minimum limit of the crowdfund amount to raise for buying a NFT


```solidity
function fundraiseGoal() external returns (uint96);
```

### successCollective

The Collective instance created by `_createCollectiveAndTransferNFT()`
to which NFT is sent on buying after a successful crowdfund.


```solidity
function successCollective() external returns (ICollective);
```

### delegationsByContributor

Who a contributor last delegated to.


```solidity
function delegationsByContributor(address contributor) external returns (address delegate);
```

### getCrowdfundLifecycle

Get the current lifecycle of the crowdfund.


```solidity
function getCrowdfundLifecycle() external view returns (CrowdfundLifecycle);
```

### contribute

Contribute to this crowdfund


```solidity
function contribute(address delegate) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegate`|`address`|The address to which he is delegating his ownership.|


### acceptContributionFromCollective

Contribute to this crowdfund from another crowdfund


```solidity
function acceptContributionFromCollective(address contributor, address delegate) external payable;
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
    external
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


### updateOnlyDelegate

Updates only delegate address of a contributor

*This will only be called to update delegate address of contributor which internally calls `_updateDelegate()`*


```solidity
function updateOnlyDelegate(address newDelegate) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newDelegate`|`address`|The new delegate address to replace old one|


### transferUnusedContribution

Transfer unused ETH to other collective

*This will be called by contributors to transfer all the unused amount of ETH to any Active Collective*


```solidity
function transferUnusedContribution(address payable collectiveCrowdfundAddress, address delegate) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collectiveCrowdfundAddress`|`address payable`|The address of another crowdfund collective|
|`delegate`|`address`|This is the delegate address set in the contribute function of another collective|


### claimUnusedContribution

Claim unused ETH back to wallet

*This will be called by contributors to claim all the unused amount of ETH*


```solidity
function claimUnusedContribution(address payable receiver) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address payable`|The address in which contributor want to receive the claim.|


## Events
### DelegateUpdated

```solidity
event DelegateUpdated(address contributor, address delegate);
```

### Contributed

```solidity
event Contributed(address contributor, uint96 amount, address delegate, uint256 previousTotalContributions);
```

### ClaimedUnusedContribution

```solidity
event ClaimedUnusedContribution(address receiver, uint256 amount);
```

### TransferredToCollective

```solidity
event TransferredToCollective(ICollectiveCrowdfund crowdfund, uint256 amount);
```

### Successful

```solidity
event Successful(ICollective collective, IERC721 nftContract, uint256 nftTokenId, uint256 settledPrice);
```

### FeeTransferred

```solidity
event FeeTransferred(address feeRecipient, uint256 fee);
```

## Errors
### WrongLifecycleError

```solidity
error WrongLifecycleError(CrowdfundLifecycle lc);
```

### ContributionAmountShouldBeWithinLimit

```solidity
error ContributionAmountShouldBeWithinLimit(uint96 lowerLimitInvestment, uint96 upperLimitInvestment);
```

### InvalidDelegateError

```solidity
error InvalidDelegateError();
```

### NothingToClaimError

```solidity
error NothingToClaimError();
```

### ContributorHasAlreadyClaimedLeftAmount

```solidity
error ContributorHasAlreadyClaimedLeftAmount();
```

### NoSuccessCollectiveError

```solidity
error NoSuccessCollectiveError();
```

### TransferToCollectiveFailedError

```solidity
error TransferToCollectiveFailedError();
```

### FailedToBuyNFTError

```solidity
error FailedToBuyNFTError(IERC721 nftContract, uint256 nftTokenId);
```

### CallProhibitedError

```solidity
error CallProhibitedError(address target, bytes data);
```

### ExceedsTotalContributionsError

```solidity
error ExceedsTotalContributionsError(uint96 value, uint96 totalContributions);
```

### NotEligibleToBuy

```solidity
error NotEligibleToBuy();
```

### OnlyCollectiveContributorsError

```solidity
error OnlyCollectiveContributorsError();
```

### InvalidCrowdfundError

```solidity
error InvalidCrowdfundError(address crowdfund);
```

### InvalidContributorError

```solidity
error InvalidContributorError();
```

### WrongGovernanceValues

```solidity
error WrongGovernanceValues();
```

### CannotAcceptZeroContribution

```solidity
error CannotAcceptZeroContribution();
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

### Contribution

```solidity
struct Contribution {
    uint96 previousTotalContributions;
    uint96 amount;
}
```

## Enums
### CrowdfundLifecycle

```solidity
enum CrowdfundLifecycle {
    Invalid,
    Busy,
    Active,
    Expired,
    Successful
}
```

