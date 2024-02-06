// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {DomainConstants} from "../../helpers/Constants.sol";
import {DomainErrors} from "../../helpers/Errors.sol";
import {d} from "../../diamond/libraries/DiamondState.sol";

/// @notice Struct defining the current protocol state
/// @custom:advice Consider creating a library with "generic" functions related to `ProtocolState`
struct ProtocolState {
    /// @notice Reentrancy guard's property
    uint256 reentrancyStatus;
    /// @notice The address of the interest-bearing token
    address mTokenAddress;
    /// @notice Staleness prevention for the Chainlink oracle response
    uint32 answerStalenessThreshold;
}

/* ====================================================== POINTER ====================================================== */

bytes32 constant PROTOCOL_STORAGE_POSITION = keccak256("martinivv.protocol.storage");

/// @notice Used as a shared storage among libraries
/// @return ps Storage pointer to `DiamondState` struct
/// @dev Any operation involving `ps` will read from or write to **storage**
function p() pure returns (ProtocolState storage ps) {
    bytes32 position = PROTOCOL_STORAGE_POSITION;

    assembly {
        ps.slot := position
    }
}

/* ====================================================== MODIFIERS ====================================================== */

/// @notice Includes modifiers shared across protocol's contracts
/// @custom:advice Consider adding more robust access control management
abstract contract ProtocolModifiers {
    /// @notice Prevents a contract from calling itself, over and over, directly or indirectly
    /// @dev Forked OZ implementation. Avoids state storage collision within diamond
    /// @dev By storing the original value once again at the end, a refund is triggered (see
    /// https://eips.ethereum.org/EIPS/eip-2200)
    modifier nonReentrant() {
        if (p().reentrancyStatus == DomainConstants._ENTERED) revert DomainErrors.ReentrantCall();

        p().reentrancyStatus = DomainConstants._ENTERED;
        _;

        p().reentrancyStatus = DomainConstants._NOT_ENTERED;
    }

    /// @notice Access control modifier. Ensures that the method is called only by the diamond owner
    modifier onlyOwner() {
        d().enforceIsContractOwner();
        _;
    }

    /// @notice Initializes reentrancy guard on diamond deployment
    function _initReentrancyGuard() internal {
        p().reentrancyStatus = DomainConstants._NOT_ENTERED;
    }
}
