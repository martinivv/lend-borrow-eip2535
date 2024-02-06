// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {LibDiamondCut} from "./logic/LibDiamondCut.sol";
import {LibDiamondOwnership} from "./logic/LibDiamondOwnership.sol";

using LibDiamondCut for DiamondState global;
using LibDiamondOwnership for DiamondState global;

/// @notice Struct defining the current diamond state
/// @custom:advice Always you can create a library with "generic" functions related to `DiamondState`
struct DiamondState {
    /// @notice Function selector -> address facet and selector positions
    mapping(bytes4 => bytes32) facets;
    /// @notice Array of slots of function selectors, each slot holds 8 function selectors
    mapping(uint256 => bytes32) selectorSlots;
    /// @notice The number of function selectors in `selectorSlots`
    uint16 selectorCount;
    /// @notice ERC-165 implementation; query if a contract implements an interface
    mapping(bytes4 => bool) supportedInterfaces;
    /// @notice The owner of the Diamond contract
    address contractOwner;
}

// ======================== Pointer ================================================================

bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("martinivv.diamond.storage");

/// @notice Used as a shared storage
/// @return ds Storage pointer to `DiamondState` struct
function d() pure returns (DiamondState storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
        ds.slot := position
    }
}
