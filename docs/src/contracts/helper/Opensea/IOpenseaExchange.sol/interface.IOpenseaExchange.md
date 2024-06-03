# IOpenseaExchange
[Git Source](https://appinvent.in/http://gitlab.rohit.sethi/mmf-contracts/blob/4564a0ed4c805ab4153b1500269975d2eef1570d/contracts/helper/Opensea/IOpenseaExchange.sol)


## Functions
### cancel


```solidity
function cancel(OrderComponents[] calldata orders) external returns (bool cancelled);
```

### validate


```solidity
function validate(Order[] calldata orders) external returns (bool validated);
```

### fulfillBasicOrder


```solidity
function fulfillBasicOrder(BasicOrderParameters calldata parameters) external payable returns (bool fulfilled);
```

### fulfillOrder


```solidity
function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey) external payable returns (bool fulfilled);
```

### fulfillBasicOrder_efficient_6GL6yc


```solidity
function fulfillBasicOrder_efficient_6GL6yc(BasicOrderParameters calldata parameters)
    external
    payable
    returns (bool fulfilled);
```

### getOrderStatus


```solidity
function getOrderStatus(bytes32 orderHash)
    external
    view
    returns (bool isValidated, bool isCancelled, uint256 totalFilled, uint256 totalSize);
```

### getOrderHash


```solidity
function getOrderHash(OrderComponents calldata order) external view returns (bytes32 orderHash);
```

### getNonce


```solidity
function getNonce(address offerer) external view returns (uint256 nonce);
```

## Errors
### InvalidTime

```solidity
error InvalidTime();
```

## Structs
### OfferItem

```solidity
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}
```

### ConsiderationItem

```solidity
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}
```

### OrderParameters

```solidity
struct OrderParameters {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 totalOriginalConsiderationItems;
}
```

### Order

```solidity
struct Order {
    OrderParameters parameters;
    bytes signature;
}
```

### OrderComponents

```solidity
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}
```

### AdditionalRecipient

```solidity
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}
```

### BasicOrderParameters

```solidity
struct BasicOrderParameters {
    address considerationToken;
    uint256 considerationIdentifier;
    uint256 considerationAmount;
    address payable offerer;
    address zone;
    address offerToken;
    uint256 offerIdentifier;
    uint256 offerAmount;
    BasicOrderType basicOrderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 offererConduitKey;
    bytes32 fulfillerConduitKey;
    uint256 totalOriginalAdditionalRecipients;
    AdditionalRecipient[] additionalRecipients;
    bytes signature;
}
```

## Enums
### OrderType

```solidity
enum OrderType {
    FULL_OPEN,
    PARTIAL_OPEN,
    FULL_RESTRICTED,
    PARTIAL_RESTRICTED
}
```

### ItemType

```solidity
enum ItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155,
    ERC721_WITH_CRITERIA,
    ERC1155_WITH_CRITERIA
}
```

### BasicOrderType

```solidity
enum BasicOrderType {
    ETH_TO_ERC721_FULL_OPEN,
    ETH_TO_ERC721_PARTIAL_OPEN,
    ETH_TO_ERC721_FULL_RESTRICTED,
    ETH_TO_ERC721_PARTIAL_RESTRICTED,
    ETH_TO_ERC1155_FULL_OPEN,
    ETH_TO_ERC1155_PARTIAL_OPEN,
    ETH_TO_ERC1155_FULL_RESTRICTED,
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,
    ERC20_TO_ERC721_FULL_OPEN,
    ERC20_TO_ERC721_PARTIAL_OPEN,
    ERC20_TO_ERC721_FULL_RESTRICTED,
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,
    ERC20_TO_ERC1155_FULL_OPEN,
    ERC20_TO_ERC1155_PARTIAL_OPEN,
    ERC20_TO_ERC1155_FULL_RESTRICTED,
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,
    ERC721_TO_ERC20_FULL_OPEN,
    ERC721_TO_ERC20_PARTIAL_OPEN,
    ERC721_TO_ERC20_FULL_RESTRICTED,
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,
    ERC1155_TO_ERC20_FULL_OPEN,
    ERC1155_TO_ERC20_PARTIAL_OPEN,
    ERC1155_TO_ERC20_FULL_RESTRICTED,
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}
```

