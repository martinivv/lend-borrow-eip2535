// SPDX-License-Identifier: MIT
// solhint-disable state-visibility

pragma solidity =0.8.20;

import {ERC20} from "../../vendor/ERC20.sol";

/// @title TokenB
/// @notice Used as an allowed token when tested on a local network
contract TokenB is ERC20 {
    /// @notice Initial supply amount
    uint256 constant SUPPLY = 100_000_000 * 1e18;

    constructor() ERC20("TokenB", "BBB") {
        _mint(msg.sender, SUPPLY);
    }
}
