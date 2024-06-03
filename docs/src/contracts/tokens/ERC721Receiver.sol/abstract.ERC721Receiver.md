# ERC721Receiver
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/tokens/ERC721Receiver.sol)

**Inherits:**
[IERC721Receiver](/contracts/tokens/IERC721Receiver.sol/interface.IERC721Receiver.md), [EIP165](/contracts/utils/EIP165.sol/abstract.EIP165.md), [ERC721TokenReceiver](/contracts/tokens/ERC721.sol/abstract.ERC721TokenReceiver.md)

Mixin for contracts that want to receive ERC721 tokens.

*Use this instead of solmate's ERC721TokenReceiver because the
compiler has issues when overriding EIP165/IERC721Receiver functions.*


## Functions
### onERC721Received


```solidity
function onERC721Received(address, address, uint256, bytes memory)
    public
    virtual
    override(IERC721Receiver, ERC721TokenReceiver)
    returns (bytes4);
```

### supportsInterface

Query if a contract implements an interface.


```solidity
function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The interface identifier, as specified in ERC-165|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|`true` if the contract implements `interfaceId` and `interfaceId` is not 0xffffffff, `false` otherwise|


