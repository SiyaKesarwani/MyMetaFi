# Implementation
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/utils/Implementation.sol)


## State Variables
### IMPL

```solidity
address public immutable IMPL;
```


## Functions
### constructor


```solidity
constructor();
```

### onlyDelegateCall


```solidity
modifier onlyDelegateCall() virtual;
```

### onlyConstructor


```solidity
modifier onlyConstructor();
```

## Errors
### OnlyDelegateCallError

```solidity
error OnlyDelegateCallError();
```

### OnlyConstructorError

```solidity
error OnlyConstructorError();
```

