// solhint-disable one-contract-per-file
// solhint-disable state-visibility

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// @title DiamondConstants
/// @notice Constants used all around the Diamond logic
library DiamondConstants {
    /// @notice Diamond's property
    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    /// @notice Diamond's property
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));
}

/// @title DomainConstants
/// @notice Constants used all around the Domain logic
library DomainConstants {
    /// @notice Used for handling calculations with basis points
    uint256 constant BASIS_POINTS = 10_000;
    /// @notice One day in seconds
    uint256 constant SECONDS_PER_DAY = 1 days;
    /// @notice Days in a year. Yeap years are ignored
    uint256 constant DAYS_PER_YEAR = 365;
    /// @notice ReentrancyGuard's property
    uint256 constant _NOT_ENTERED = 1;
    /// @notice ReentrancyGuard's property
    uint256 constant _ENTERED = 2;
}
