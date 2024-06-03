// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../utils/LibRawResult.sol";

abstract contract Multicall {
    using LibRawResult for bytes;

    /// @notice Perform multiple delegatecalls on ourselves.
    function multicall(bytes[] calldata multicallData) external {
        for (uint256 i = 0; i < multicallData.length; ++i) {
            (bool s, bytes memory r) = address(this).delegatecall(multicallData[i]);
            if (!s) {
                r.rawRevert();
            }
        }
    }
}
