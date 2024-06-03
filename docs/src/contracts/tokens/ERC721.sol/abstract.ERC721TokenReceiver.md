# ERC721TokenReceiver
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/tokens/ERC721.sol)

**Author:**
Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)

A generic interface for a contract which properly accepts ERC721 tokens.


## Functions
### onERC721Received


```solidity
function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4);
```

