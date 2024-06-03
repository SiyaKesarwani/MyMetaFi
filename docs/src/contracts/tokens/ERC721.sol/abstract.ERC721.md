# ERC721
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/tokens/ERC721.sol)

**Inherits:**
[IERC721](/contracts/tokens/IERC721.sol/interface.IERC721.md), [EIP165](/contracts/utils/EIP165.sol/abstract.EIP165.md)

**Author:**
Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)

Modern, minimalist, and gas efficient ERC-721 implementation.


## State Variables
### name

```solidity
string public name;
```


### symbol

```solidity
string public symbol;
```


### _ownerOf

```solidity
mapping(uint256 => address) internal _ownerOf;
```


### _balanceOf

```solidity
mapping(address => uint256) internal _balanceOf;
```


### getApproved

```solidity
mapping(uint256 => address) public getApproved;
```


### isApprovedForAll

```solidity
mapping(address => mapping(address => bool)) public isApprovedForAll;
```


## Functions
### tokenURI


```solidity
function tokenURI(uint256 id) public virtual returns (string memory);
```

### ownerOf


```solidity
function ownerOf(uint256 id) public view virtual returns (address owner);
```

### balanceOf


```solidity
function balanceOf(address owner) public view virtual returns (uint256);
```

### constructor


```solidity
constructor(string memory _name, string memory _symbol);
```

### approve


```solidity
function approve(address spender, uint256 id) public virtual;
```

### setApprovalForAll


```solidity
function setApprovalForAll(address operator, bool approved) public virtual;
```

### transferFrom


```solidity
function transferFrom(address from, address to, uint256 id) public virtual;
```

### safeTransferFrom


```solidity
function safeTransferFrom(address from, address to, uint256 id) public virtual;
```

### safeTransferFrom


```solidity
function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual;
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool);
```

### _mint


```solidity
function _mint(address to, uint256 id) internal virtual;
```

### _burn


```solidity
function _burn(uint256 id) internal virtual;
```

### _safeMint


```solidity
function _safeMint(address to, uint256 id) internal virtual;
```

### _safeMint


```solidity
function _safeMint(address to, uint256 id, bytes memory data) internal virtual;
```

