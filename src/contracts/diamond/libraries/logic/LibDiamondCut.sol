// solhint-disable avoid-low-level-calls
// solhint-disable code-complexity
// solhint-disable custom-errors

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IDiamondCutFacet} from "../../interfaces/IDiamondCutFacet.sol";
import {DiamondState, d} from "../DiamondState.sol";
import {DiamondEvents} from "../../../helpers/Events.sol";
import {DiamondErrors} from "../../../helpers/Errors.sol";
import {DiamondConstants} from "../../../helpers/Constants.sol";

/// @notice See {diamondCut}'s @notice
function initializeDiamondCut(address _init, bytes memory _calldata) {
    if (_init == address(0)) return;

    LibDiamondCut.enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");

    (bool success, bytes memory error) = _init.delegatecall(_calldata);
    if (!success) {
        if (error.length > 0) {
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(error)
                revert(add(32, error), returndata_size)
            }
        } else {
            revert DiamondErrors.InitializationFunctionReverted(_init, _calldata);
        }
    }
}

/// @title LibDiamondCut
/// @notice Internal function versions of `DiamondCutFacet` ones
/// @dev This code is almost the same as the external `DiamondCutFacet` one,
/// except it is using `Facet[] memory _diamondCut` instead of
/// `Facet[] calldata _diamondCut`. The code is duplicated to prevent
/// copying calldata to memory which causes an error for a two dimensional array
library LibDiamondCut {
    /// @notice Adds/replaces/removes any number of functions and optionally executes
    /// a function with `delegatecall`
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute `_calldata`
    /// @param _calldata A function call, including function selector and arguments
    /// @dev Be aware that `_calldata` is executed with delegatecall on the `_init` contract
    function diamondCut(
        DiamondState storage self,
        IDiamondCutFacet.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        uint256 originalSelectorCount = self.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;

        if (selectorCount & 7 > 0) selectorSlot = self.selectorSlots[selectorCount >> 3];

        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
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

        if (selectorCount != originalSelectorCount) self.selectorCount = uint16(selectorCount);

        if (selectorCount & 7 > 0) self.selectorSlots[selectorCount >> 3] = selectorSlot;

        emit DiamondEvents.DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /// @notice See {diamondCut}'s @notice
    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCutFacet.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondState storage self = d();

        if (_selectors.length < 1) revert DiamondErrors.NoSelectorFound();

        if (_action == IDiamondCutFacet.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");

            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = self.facets[selector];

                if (address(bytes20(oldFacet)) != address(0)) revert DiamondErrors.FunctionAlreadyExists();

                self.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                _selectorSlot =
                    (_selectorSlot & ~(DiamondConstants.CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                if (selectorInSlotPosition == 224) {
                    self.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }

                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCutFacet.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");

            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = self.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                if (oldFacetAddress == address(this)) revert DiamondErrors.ImmutableFunctionDetected();

                if (oldFacetAddress == _newFacetAddress) revert DiamondErrors.CannotReplaceTheSameFunction();

                if (oldFacetAddress == address(0)) revert DiamondErrors.FunctionDoesNotExist();

                self.facets[selector] = (oldFacet & DiamondConstants.CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCutFacet.FacetCutAction.Remove) {
            if (_newFacetAddress != address(0)) revert DiamondErrors.MustBeZeroAddress(_newFacetAddress);

            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;

            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                if (_selectorSlot == 0) {
                    selectorSlotCount--;
                    _selectorSlot = self.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = self.facets[selector];
                    if (address(bytes20(oldFacet)) == address(0)) revert DiamondErrors.FunctionDoesNotExist();

                    if (address(bytes20(oldFacet)) == address(this)) revert DiamondErrors.ImmutableFunctionDetected();

                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));

                    if (lastSelector != selector) {
                        self.facets[lastSelector] =
                            (oldFacet & DiamondConstants.CLEAR_ADDRESS_MASK) |
                            bytes20(self.facets[lastSelector]);
                    }

                    delete self.facets[selector];

                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = self.selectorSlots[oldSelectorsSlotCount];

                    oldSelectorSlot =
                        (oldSelectorSlot & ~(DiamondConstants.CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    self.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    _selectorSlot =
                        (_selectorSlot & ~(DiamondConstants.CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete self.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }

            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert DiamondErrors.IncorrectFacetCutAction(uint8(_action));
        }

        return (_selectorCount, _selectorSlot);
    }

    /// @notice Ensures that the @param _contract has code, otherwise throws an @param _errorMessage
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;

        assembly {
            contractSize := extcodesize(_contract)
        }

        require(contractSize > 0, _errorMessage);
    }
}
