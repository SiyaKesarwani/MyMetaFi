// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

// Valid keys in `IGlobals`. Append-only.
library LibGlobals {
    uint256 internal constant GLOBAL_SINGLE_BUY_CF_IMPL = 1;
    uint256 internal constant GLOBAL_COLLECTION_BUY_CF_IMPL = 2;
    uint256 internal constant GLOBAL_FEE_RECIPIENT = 3;
    uint256 internal constant GLOBAL_OPENSEA_CONDUIT_KEY = 4;
    uint256 internal constant GLOBAL_OPENSEA_ZONE = 5;
    uint256 internal constant GLOBAL_COLLECTIVE_FACTORY = 6;
    uint256 internal constant GLOBAL_COLLECTIVE_IMPL = 7;
    uint256 internal constant GLOBAL_DISTRIBUTOR = 8;
    uint256 internal constant GLOBAL_VALIDSIGNER = 9;
    uint256 internal constant GLOBAL_FEE_BPS = 10;
    uint256 internal constant GLOBAL_OPENSEA_SEAPORT = 11;
    uint256 internal constant GLOBAL_DISABLE_MMF_ACTIONS = 12;
    uint256 internal constant GLOBAL_GIVEAWAY_COLLECTIVE_FACTORY = 13;
    uint256 internal constant GLOBAL_GIVEAWAY_COLLECTIVE_IMPL = 14;
    uint256 internal constant GLOBAL_DISTRIBUTOR_FEE_BPS = 15;
}
