# EIP165
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/utils/EIP165.sol)


## Functions
### supportsInterface

Query if a contract implements an interface.


```solidity
function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The interface identifier, as specified in ERC-165|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|`true` if the contract implements `interfaceId` and `interfaceId` is not 0xffffffff, `false` otherwise|


