# LibSafeCast
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/utils/LibSafeCast.sol)


## Functions
### safeCastUint256ToUint96


```solidity
function safeCastUint256ToUint96(uint256 v) internal pure returns (uint96);
```

### safeCastUint256ToUint128


```solidity
function safeCastUint256ToUint128(uint256 v) internal pure returns (uint128);
```

### safeCastUint256ToInt192


```solidity
function safeCastUint256ToInt192(uint256 v) internal pure returns (int192);
```

### safeCastUint96ToInt192


```solidity
function safeCastUint96ToInt192(uint96 v) internal pure returns (int192);
```

### safeCastInt192ToUint96


```solidity
function safeCastInt192ToUint96(int192 i192) internal pure returns (uint96);
```

### safeCastUint256ToInt128


```solidity
function safeCastUint256ToInt128(uint256 x) internal pure returns (int128);
```

### safeCastUint256ToUint40


```solidity
function safeCastUint256ToUint40(uint256 x) internal pure returns (uint40);
```

## Errors
### Uint256ToUint96CastOutOfRange

```solidity
error Uint256ToUint96CastOutOfRange(uint256 v);
```

### Uint256ToInt192CastOutOfRange

```solidity
error Uint256ToInt192CastOutOfRange(uint256 v);
```

### Int192ToUint96CastOutOfRange

```solidity
error Int192ToUint96CastOutOfRange(int192 i192);
```

### Uint256ToInt128CastOutOfRangeError

```solidity
error Uint256ToInt128CastOutOfRangeError(uint256 u256);
```

### Uint256ToUint128CastOutOfRangeError

```solidity
error Uint256ToUint128CastOutOfRangeError(uint256 u256);
```

### Uint256ToUint40CastOutOfRangeError

```solidity
error Uint256ToUint40CastOutOfRangeError(uint256 u256);
```

