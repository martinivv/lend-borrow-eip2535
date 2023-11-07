// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// @title IMToken
/// @notice Interface for the interest-bearing token *mToken*
interface IMToken {
    /// @notice Burns @param _amount of tokens from @param _from
    function burn(address _from, uint256 _amount) external;
}
