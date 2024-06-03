# IOpenseaConduitController
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/helper/Opensea/IOpenseaConduitController.sol)


## Functions
### getKey


```solidity
function getKey(address conduit) external view returns (bytes32 conduitKey);
```

### getConduit


```solidity
function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);
```

