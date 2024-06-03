# LibERC20Compat
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/utils/LibERC20Compat.sol)


## Functions
### compatTransfer


```solidity
function compatTransfer(IERC20 token, address to, uint256 amount) internal;
```

### compatTransferFrom


```solidity
function compatTransferFrom(IERC20 token, address from, address to, uint256 amount) internal;
```

## Errors
### NotATokenError

```solidity
error NotATokenError(IERC20 token);
```

### TokenTransferFailedError

```solidity
error TokenTransferFailedError(IERC20 token, address to, uint256 amount);
```

### FromTokenTransferFailedError

```solidity
error FromTokenTransferFailedError(IERC20 token, address from, address to, uint256 amount);
```

