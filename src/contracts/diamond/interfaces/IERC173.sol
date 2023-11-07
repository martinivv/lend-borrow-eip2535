// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// @title IERC173
/// @notice The interface introduces contract ownership standard
/// @dev The ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
    /// @notice Sets the contract's owner to a @param _newOwner's address
    function transferOwnership(address _newOwner) external;

    /// @notice Gets the @return owner_'s address
    function owner() external view returns (address owner_);
}
