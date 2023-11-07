// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// @title IERC165
/// @notice The interface introduces support of contract interfaces, which can then be queried
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
