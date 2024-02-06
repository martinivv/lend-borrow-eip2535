// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {DiamondState} from "../DiamondState.sol";
import {DiamondErrors} from "../../../helpers/Errors.sol";

/// @title LibDiamondOwnership
/// @notice Library collection of diamond ownership functions
library LibDiamondOwnership {
    /// @notice Emitted when the diamond owner is updated
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Updates the diamond owner to @param _newOwner's address
    function setContractOwner(DiamondState storage self, address _newOwner) internal {
        address previousOwner = self.contractOwner;
        self.contractOwner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @notice Returns the diamond @return contractOwner_'s address
    function getContractOwner(DiamondState storage self) internal view returns (address contractOwner_) {
        contractOwner_ = self.contractOwner;
    }

    /// @notice Checks if the `msg.sender` is the diamond owner
    function enforceIsContractOwner(DiamondState storage self) internal view {
        if (msg.sender != self.contractOwner) revert DiamondErrors.MustBeDiamondOwner(msg.sender);
    }
}
