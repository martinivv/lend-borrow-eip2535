// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IDiamondCutFacet} from "../interfaces/IDiamondCutFacet.sol";
import {DiamondState, d} from "../libraries/DiamondState.sol";
import {initializeDiamondCut, LibDiamondCut} from "../libraries/logic/LibDiamondCut.sol";

/// @title DiamondCutFacet
/// @notice Declares related functions for executing a diamond cut
/// @custom:version 0.0.1
contract DiamondCutFacet is IDiamondCutFacet {
    /// @inheritdoc IDiamondCutFacet
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {
        DiamondState storage ds = d();

        ds.enforceIsContractOwner();

        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        if (selectorCount & 7 > 0) selectorSlot = ds.selectorSlots[selectorCount >> 3];

        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            // Calling it in the typical for the protocol way will result in *Stack too deep* error.
            // Consider creating better version of the Diamond implementation
            (selectorCount, selectorSlot) = LibDiamondCut.addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) ds.selectorCount = uint16(selectorCount);

        if (selectorCount & 7 > 0) ds.selectorSlots[selectorCount >> 3] = selectorSlot;

        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }
}
