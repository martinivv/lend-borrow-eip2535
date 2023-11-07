// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {ProtocolModifiers} from "../libraries/ProtocolState.sol";
import {AllowedToken} from "../libraries/AssetsState.sol";
import {LibOwner} from "../libraries/logic/LibOwner.sol";

/// @title OwnerFacet
/// @custom:security Be aware of the single point of failure vulnerability
/// @custom:version 0.0.1
contract OwnerFacet is ProtocolModifiers {
    /// @notice End-owner functionality for setting the allowed tokens during initialization or upgrade
    /// @param _tokens {AllowedToken[]}
    function setAllowedTokens(AllowedToken[] calldata _tokens) external onlyOwner {
        LibOwner.setTokens(_tokens);
    }
}
