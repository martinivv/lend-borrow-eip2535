// solhint-disable no-complex-fallback

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {d} from "../libraries/DiamondState.sol";
import {IDiamondCutFacet} from "../interfaces/IDiamondCutFacet.sol";
import {DiamondErrors} from "../../helpers/Errors.sol";

/// @title Diamond
/// @author Forked implementation with some modifications
/// @notice Diamond proxy contract. Serves as the primary entry point for the protocol
/// @custom:advice Consider adding events and more parameters to the custom errors throughout the Diamond contracts
/// @custom:version 0.0.1
contract Diamond {
    struct DiamondArgs {
        address owner;
        address diamondInit;
        bytes data;
    }

    /// @notice Sets the diamond owner, cuts the @param _diamondCutFacet address, and then calls the `DiamondInit`
    /// contract with `data`
    /// @param _args Initial arguments
    /// @dev Be aware that `data` is executed with `delegatecall` on the `DiamondInit` contract
    constructor(DiamondArgs memory _args, address _diamondCutFacet) {
        d().setContractOwner(_args.owner);

        IDiamondCutFacet.FacetCut[] memory cut = new IDiamondCutFacet.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCutFacet.diamondCut.selector;
        cut[0] = IDiamondCutFacet.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCutFacet.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        d().diamondCut(cut, _args.diamondInit, _args.data);
    }

    receive() external payable {}

    /// @notice Finds the facet for the function that is called and executes the function if the facet is found
    fallback() external payable {
        address facet = address(bytes20(d().facets[msg.sig]));
        if (facet == address(0)) revert DiamondErrors.FunctionDoesNotExist();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @notice A rescue function for missent/donated *msg.value*
    function rescue() external {
        if (msg.sender != d().contractOwner) revert DiamondErrors.MustBeDiamondOwner(msg.sender);

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert DiamondErrors.TransferFailed();
    }
}
