# ReentrancyGuard
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/utils/ReentrancyGuard.sol)

*Contract module that helps prevent reentrant calls to a function.
Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
available, which can be applied to functions to make sure there are no nested
(reentrant) calls to them.
Note that because there is a single `nonReentrant` guard, functions marked as
`nonReentrant` may not call one another. This can be worked around by making
those functions `private`, and then adding `external` `nonReentrant` entry
points to them.
TIP: If you would like to learn more about reentrancy and alternative ways
to protect against it, check out our blog post
https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].*


## State Variables
### _NOT_ENTERED

```solidity
uint256 private constant _NOT_ENTERED = 1;
```


### _ENTERED

```solidity
uint256 private constant _ENTERED = 2;
```


### _status

```solidity
uint256 private _status;
```


## Functions
### constructor


```solidity
constructor();
```

### nonReentrant

*Prevents a contract from calling itself, directly or indirectly.
Calling a `nonReentrant` function from another `nonReentrant`
function is not supported. It is possible to prevent this from happening
by making the `nonReentrant` function external, and making it call a
`private` function that does the actual work.*


```solidity
modifier nonReentrant();
```

### _nonReentrantBefore


```solidity
function _nonReentrantBefore() private;
```

### _nonReentrantAfter


```solidity
function _nonReentrantAfter() private;
```

### _reentrancyGuardEntered

*Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
`nonReentrant` function in the call stack.*


```solidity
function _reentrancyGuardEntered() internal view returns (bool);
```

## Errors
### ReentrancyGuardReentrantCall
*Unauthorized reentrant call.*


```solidity
error ReentrancyGuardReentrantCall();
```

