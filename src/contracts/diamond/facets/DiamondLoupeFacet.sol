// solhint-disable code-complexity

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IDiamondLoupeFacet} from "../interfaces/IDiamondLoupeFacet.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {DiamondState, d} from "../libraries/DiamondState.sol";
import {DiamondErrors} from "../../helpers/Errors.sol";

/// @title DiamondLoupeFacet
/// @notice Declares related functions that tell you what functions and facets are provided by the diamond
/// @custom:version 0.0.1
contract DiamondLoupeFacet is IDiamondLoupeFacet, IERC165 {
    /// @inheritdoc IDiamondLoupeFacet
    function facets() external view override returns (Facet[] memory facets_) {
        DiamondState storage ds = d();

        facets_ = new Facet[](ds.selectorCount);
        uint16[] memory numFacetSelectors = new uint16[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];

            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) break;

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facets_[facetIndex].facetAddress == facetAddress_) {
                        facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;

                        if (numFacetSelectors[facetIndex] > 254) revert DiamondErrors.TooManyFunctionsInAFacet();

                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) continue;

                facets_[numFacets].facetAddress = facetAddress_;
                facets_[numFacets].functionSelectors = new bytes4[](ds.selectorCount);
                facets_[numFacets].functionSelectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }

        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;

            assembly {
                mstore(selectors, numSelectors)
            }
        }

        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @inheritdoc IDiamondLoupeFacet
    function facetFunctionSelectors(
        address _facet
    ) external view override returns (bytes4[] memory _facetFunctionSelectors) {
        DiamondState storage ds = d();

        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;

        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) break;

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(ds.facets[selector]));
                if (_facet == facet) {
                    _facetFunctionSelectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }

        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @inheritdoc IDiamondLoupeFacet
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        DiamondState storage ds = d();

        facetAddresses_ = new address[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];

            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) break;

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facetAddress_ == facetAddresses_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) continue;

                facetAddresses_[numFacets] = facetAddress_;
                numFacets++;
            }
        }

        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @inheritdoc IDiamondLoupeFacet
    /// @custom:advice Consider implementing better error handling if the facet is not found
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        facetAddress_ = address(bytes20(d().facets[_functionSelector]));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        return d().supportedInterfaces[_interfaceId];
    }
}
