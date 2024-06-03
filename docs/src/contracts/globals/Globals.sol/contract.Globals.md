# Globals
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/globals/Globals.sol)

**Inherits:**
[IGlobals](/contracts/globals/IGlobals.sol/interface.IGlobals.md), [Multicall](/contracts/utils/Multicall.sol/abstract.Multicall.md)

Contract storing global configuration values.


## State Variables
### multiSig

```solidity
address public multiSig;
```


### pendingMultiSig

```solidity
address public pendingMultiSig;
```


### _wordValues

```solidity
mapping(uint256 => bytes32) private _wordValues;
```


### _includedWordValues

```solidity
mapping(uint256 => mapping(bytes32 => bool)) private _includedWordValues;
```


## Functions
### onlyMultisig


```solidity
modifier onlyMultisig();
```

### onlyPendingMultisig


```solidity
modifier onlyPendingMultisig();
```

### constructor


```solidity
constructor(address multiSig_);
```

### transferMultiSig


```solidity
function transferMultiSig(address newMultiSig) external onlyMultisig;
```

### acceptMultiSig


```solidity
function acceptMultiSig() external onlyPendingMultisig;
```

### getBytes32


```solidity
function getBytes32(uint256 key) external view returns (bytes32);
```

### getUint256


```solidity
function getUint256(uint256 key) external view returns (uint256);
```

### getBool


```solidity
function getBool(uint256 key) external view returns (bool);
```

### getAddress


```solidity
function getAddress(uint256 key) external view returns (address);
```

### getImplementation


```solidity
function getImplementation(uint256 key) external view returns (Implementation);
```

### getIncludesBytes32


```solidity
function getIncludesBytes32(uint256 key, bytes32 value) external view returns (bool);
```

### getIncludesUint256


```solidity
function getIncludesUint256(uint256 key, uint256 value) external view returns (bool);
```

### getIncludesAddress


```solidity
function getIncludesAddress(uint256 key, address value) external view returns (bool);
```

### setBytes32


```solidity
function setBytes32(uint256 key, bytes32 value) external onlyMultisig;
```

### setUint256


```solidity
function setUint256(uint256 key, uint256 value) external onlyMultisig;
```

### setBool


```solidity
function setBool(uint256 key, bool value) external onlyMultisig;
```

### setAddress


```solidity
function setAddress(uint256 key, address value) external onlyMultisig;
```

### setIncludesBytes32


```solidity
function setIncludesBytes32(uint256 key, bytes32 value, bool isIncluded) external onlyMultisig;
```

### setIncludesUint256


```solidity
function setIncludesUint256(uint256 key, uint256 value, bool isIncluded) external onlyMultisig;
```

### setIncludesAddress


```solidity
function setIncludesAddress(uint256 key, address value, bool isIncluded) external onlyMultisig;
```

## Errors
### OnlyMultiSigError

```solidity
error OnlyMultiSigError();
```

### OnlyPendingMultiSigError

```solidity
error OnlyPendingMultiSigError();
```

### InvalidBooleanValueError

```solidity
error InvalidBooleanValueError(uint256 key, uint256 value);
```

