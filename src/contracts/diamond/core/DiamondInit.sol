// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {ProtocolModifiers, ProtocolState, p} from "../../domain/libraries/ProtocolState.sol";
import {AllowedToken} from "../../domain/libraries/AssetsState.sol";
import {DiamondState, d} from "../libraries/DiamondState.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IDiamondCutFacet} from "../interfaces/IDiamondCutFacet.sol";
import {IDiamondLoupeFacet} from "../interfaces/IDiamondLoupeFacet.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibOwner} from "../../domain/libraries/logic/LibOwner.sol";

/// @title DiamondInit
/// @notice Contract for setting state variables in the diamond during deployment or an upgrade
/// @custom:security It is only called once in the diamond constructor and is not saved as a facet within the diamond
/// @custom:version 0.0.1
contract DiamondInit is ProtocolModifiers {
    struct DiamondInitArgs {
        address mTokenAddress;
        AllowedToken[] allowedTokens;
    }

    /// @notice Sets state variables
    /// @param _args Initial arguments
    function init(DiamondInitArgs calldata _args) external {
        /* ======================= DIAMOND INITIALIZATION ======================= */
        DiamondState storage ds = d();

        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCutFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupeFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        /* ======================= PROTOCOL&ASSETS INITIALIZATION ======================= */
        ProtocolState storage ps = p();

        _initReentrancyGuard();
        ps.mTokenAddress = _args.mTokenAddress;
        ps.answerStalenessThreshold = 1 days;

        LibOwner.setTokens(_args.allowedTokens);
    }
}
