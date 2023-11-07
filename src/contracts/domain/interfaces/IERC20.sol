// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// @title IERC20
/// @notice Interface for standard ERC20 implementation
interface IERC20 {
    /// @notice Emmited when @param value tokens are moved @param from to @param to account
    /// @dev `value` may be zero
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when the allowance of a @param spender for an @param owner is
    /// set by a call to {approve}. @param value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the name of the token
    /// @return {string}
    function name() external view returns (string memory);

    /// @notice Returns the decimals places of the token
    /// @return {uint8}
    function decimals() external view returns (uint8);

    /// @notice Returns the value of tokens in existence
    /// @return {uint256}
    function totalSupply() external view returns (uint256);

    /// @notice Returns the value of tokens owned by @param _owner
    /// @return {uint256}
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Moves a @param _value amount of tokens from the caller's account to @param _to
    /// @return Returns a boolean value indicating whether the operation succeeded
    /// @dev Emits a {Transfer} event
    function transfer(address _to, uint256 _value) external returns (bool);

    /// @notice Moves a @param _value amount of tokens from @param _from to @param _to using the
    /// allowance mechanism. @param _value is then deducted from the caller's allowance
    /// @return Returns a boolean value indicating whether the operation succeeded
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    /// @notice Sets a @param _value amount of tokens as the allowance of @param _spender over the
    /// caller's tokens
    /// @return Returns a boolean value indicating whether the operation succeeded
    /// @custom:security Beware that changing an allowance with this method brings the risk
    /// that someone may use both the old and the new allowance by unfortunate transaction ordering.
    /// One possible solution to mitigate this race condition is to first reduce the spender's
    /// allowance to 0 and set the desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender) external view returns (uint256);
}
