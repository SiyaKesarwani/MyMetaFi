# IERC721
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/tokens/IERC721.sol)


## Functions
### transferFrom


```solidity
function transferFrom(address from, address to, uint256 tokenId) external;
```

### safeTransferFrom


```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
```

### safeTransferFrom


```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) external;
```

### approve


```solidity
function approve(address operator, uint256 tokenId) external;
```

### setApprovalForAll


```solidity
function setApprovalForAll(address operator, bool isApproved) external;
```

### name


```solidity
function name() external view returns (string memory);
```

### symbol


```solidity
function symbol() external view returns (string memory);
```

### getApproved


```solidity
function getApproved(uint256 tokenId) external view returns (address);
```

### isApprovedForAll


```solidity
function isApprovedForAll(address owner, address operator) external view returns (bool);
```

### ownerOf


```solidity
function ownerOf(uint256 tokenId) external view returns (address);
```

### balanceOf


```solidity
function balanceOf(address owner) external view returns (uint256);
```

## Events
### Transfer

```solidity
event Transfer(address indexed owner, address indexed to, uint256 indexed tokenId);
```

### Approval

```solidity
event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);
```

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
```

