// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// @title IDiamondLoupeFacet
interface IDiamondLoupeFacet {
    /// @notice Used with {facets} to return all facet addresses and their 4 byte function selectors
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facets and their selectors
    /// @return facets_ {Facet[]}
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific @param _facet
    /// @return facetFunctionSelectors_ {bytes4[]}
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Gets all facet addresses used by a diamond
    /// @return facetAddresses_ {address[]}
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the @return facetAddress_ that supports given @param _functionSelector
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
