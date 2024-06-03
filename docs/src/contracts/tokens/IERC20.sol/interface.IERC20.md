# IERC20
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/tokens/IERC20.sol)


## Functions
### transfer


```solidity
function transfer(address to, uint256 amount) external returns (bool);
```

### transferFrom


```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool);
```

### approve


```solidity
function approve(address spender, uint256 allowance) external returns (bool);
```

### allowance


```solidity
function allowance(address owner, address spender) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address owner) external view returns (uint256);
```

## Events
### Transfer

```solidity
event Transfer(address indexed owner, address indexed to, uint256 amount);
```

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 allowance);
```

