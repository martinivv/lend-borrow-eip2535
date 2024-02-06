/* solhint-disable state-visibility */

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {ERC20} from "../vendor/ERC20.sol";
import {IMToken} from "../interfaces/IMToken.sol";

/// @title MToken
/// @notice The interest-bearing token associated with the protocol
/// @custom:advice Consider implementing a more robust access control mechanism; like OZ's
/// @custom:version 0.0.1
contract MToken is ERC20, IMToken {
    /// @notice The address of the owner
    address public owner;
    /// @notice The address of the operator
    address public operator;
    /// @notice Initial supply amount
    uint256 constant SUPPLY = 10_000_000 * 1e18;

    /// @notice Emits when the owner address is changed
    event OwnerChanged(address indexed owner, address indexed _newOwner);

    /// @notice Triggers when the function is not called by the owner
    error NotOwner(address _caller);
    /// @notice Triggers when the function is not called by the protocol
    error NotOperator(address _caller);

    /// @notice Checks if the function is called by the owner of the token
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }

    /// @notice Checks if the function is called by the protocol
    modifier onlyOperator() {
        if (msg.sender != operator) revert NotOperator(msg.sender);
        _;
    }

    /* ======================= Methods ===================================================== */

    /// @notice Contract constructor
    constructor() ERC20("MToken", "MMM") {
        owner = msg.sender;
        emit OwnerChanged(address(0), owner);
        _mint(msg.sender, SUPPLY);
    }

    /// @notice Mints token @param _amount to @param _to address
    function mint(address _to, uint256 _amount) external onlyOwner {
        uint256 scaledAmount = _amount * 1e18;
        _mint(_to, scaledAmount);
    }

    /// @inheritdoc IMToken
    function burn(address _from, uint256 _amount) external onlyOperator {
        _burn(_from, _amount);
    }

    /// @notice Sets the token's owner to a new @param owner_ address
    function setOwner(address _owner) external onlyOwner {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @notice Sets the token's operator to @param _operator
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }
}
