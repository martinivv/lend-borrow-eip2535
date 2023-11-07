// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {LibUI} from "../libraries/logic/LibUI.sol";

/// @title UIDataFacet
/// @notice UI aggregated data
/// @dev Make changes depending on the front-end model. This implementation is conceptual
/// @custom:version 0.0.1
contract UIDataFacet {
    /* =================================== Global ============================================================================================ */

    /// @notice Gets global-related data of the protocol
    /// @notice Aggregated view of the allowed tokens in @return allowedTokensBatch; in @return mTokenAddress — the address of the
    /// interest-bearing token
    function getProtocolTokens()
        external
        view
        returns (LibUI.AllowedTokenData[] memory allowedTokensBatch, address mTokenAddress)
    {
        allowedTokensBatch = LibUI.batchAllowedTokens();
        mTokenAddress = LibUI.mTokenAddress();
    }

    /* =================================== User's ============================================================================================ */

    /// @notice Returns the maximum amount in USD that can be borrowed based on @param _collateralAddress
    /// and @param _collateralAmount values
    /// @dev `_collateralAmount` must be a whole number
    function getMaxUsdToBorrow(
        address _collateralAddress,
        uint256 _collateralAmount
    ) external view returns (uint256 maxUsdToBorrow) {
        maxUsdToBorrow = LibUI.maxUsdToBorrow(_collateralAddress, _collateralAmount);
    }

    /// @notice Aggregated view of @param _account's staked tokens in @return stakedTokensBatch
    function getStakedTokens(
        address _account
    ) external view returns (LibUI.StakedTokenData[] memory stakedTokensBatch) {
        stakedTokensBatch = LibUI.batchStakedTokens(_account);
    }

    /// @notice Aggregated view of @param _account's borrowed tokens in @return borrowedTokensBatch
    function getBorrowedTokens(
        address _account
    ) external view returns (LibUI.BorrowedTokenData[] memory borrowedTokensBatch) {
        borrowedTokensBatch = LibUI.batchBorrowedTokens(_account);
    }

    /* =================================== Keeper's ============================================================================================ */

    /// @notice Returns all borrowers in the protocol as @return allBorrowers
    function getAllBorrowers() external view returns (address[] memory allBorrowers) {
        allBorrowers = LibUI.allBorrowers();
    }

    /// @notice Gets relevant @param _account information. Returns it as @return data
    function getAccountData(address _accountAddress) external view returns (LibUI.AccountData memory accountData) {
        accountData = LibUI.batchAccountData(_accountAddress);
    }

    /// @notice Checks if the @param _account is liquidatable based on @param _collateralAddress and @param _borrowedTokenAddress.
    /// @return result `true` if it is, otherwise `false`
    function isLiquidatable(
        address _account,
        address _collateralAddress,
        address _borrowedTokenAddress
    ) external view returns (bool result) {
        result = LibUI.isLiquidatable(_account, _collateralAddress, _borrowedTokenAddress);
    }
}
