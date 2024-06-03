# Strings
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/utils/EIP712.sol)

*String operations.*


## State Variables
### _HEX_SYMBOLS

```solidity
bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
```


## Functions
### toString

*Converts a `uint256` to its ASCII `string` decimal representation.*


```solidity
function toString(uint256 value) internal pure returns (string memory);
```

### toHexString

*Converts a `uint256` to its ASCII `string` hexadecimal representation.*


```solidity
function toHexString(uint256 value) internal pure returns (string memory);
```

### toHexString

*Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.*


```solidity
function toHexString(uint256 value, uint256 length) internal pure returns (string memory);
```

