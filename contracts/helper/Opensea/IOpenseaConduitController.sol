// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IOpenseaConduitController {
    function getKey(address conduit) external view returns (bytes32 conduitKey);

    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);
}
