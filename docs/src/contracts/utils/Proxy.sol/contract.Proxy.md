# Proxy
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/utils/Proxy.sol)

Base class for all proxy contracts.


## State Variables
### IMPL
The address of the implementation contract used by this proxy.


```solidity
Implementation public immutable IMPL;
```


## Functions
### constructor


```solidity
constructor(Implementation impl, bytes memory initCallData) payable;
```

### fallback


```solidity
fallback() external payable;
```

