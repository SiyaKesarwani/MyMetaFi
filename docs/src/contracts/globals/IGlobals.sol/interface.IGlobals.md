# IGlobals
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/globals/IGlobals.sol)


## Functions
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
function setBytes32(uint256 key, bytes32 value) external;
```

### setUint256


```solidity
function setUint256(uint256 key, uint256 value) external;
```

### setBool


```solidity
function setBool(uint256 key, bool value) external;
```

### setAddress


```solidity
function setAddress(uint256 key, address value) external;
```

### setIncludesBytes32


```solidity
function setIncludesBytes32(uint256 key, bytes32 value, bool isIncluded) external;
```

### setIncludesUint256


```solidity
function setIncludesUint256(uint256 key, uint256 value, bool isIncluded) external;
```

### setIncludesAddress


```solidity
function setIncludesAddress(uint256 key, address value, bool isIncluded) external;
```

