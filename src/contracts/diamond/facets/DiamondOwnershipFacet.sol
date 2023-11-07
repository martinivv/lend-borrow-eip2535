// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {d} from "../libraries/DiamondState.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {DiamondErrors} from "../../helpers/Errors.sol";

/// @title DiamondOwnershipFacet
/// @notice Contract for managing the owner of the diamond
/// @custom:version 0.0.1
contract DiamondOwnershipFacet is IERC173 {
    /// @inheritdoc IERC173
    function transferOwnership(address _newOwner) external override {
        if (_newOwner == address(0)) revert DiamondErrors.NoZeroAddressOwner();

        d().enforceIsContractOwner();
        d().setContractOwner(_newOwner);
    }

    /// @inheritdoc IERC173
    function owner() external view override returns (address owner_) {
        owner_ = d().getContractOwner();
    }
}
