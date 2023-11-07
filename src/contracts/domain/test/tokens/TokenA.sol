// SPDX-License-Identifier: MIT
// solhint-disable state-visibility

pragma solidity =0.8.20;

import {ERC20} from "../../vendor/ERC20.sol";

/// @title TokenA
/// @notice Used as an allowed token when tested on a local network
contract TokenA is ERC20 {
    /// @notice Initial supply amount
    uint256 constant SUPPLY = 100_000_000 * 1e18;

    /// @notice Contract constructor
    constructor() ERC20("TokenA", "AAA") {
        _mint(msg.sender, SUPPLY);
    }
}
