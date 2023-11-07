// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AllowedToken, a, AssetsState, StakedToken, BorrowedToken} from "../AssetsState.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {p} from "../ProtocolState.sol";
import {DomainErrors} from "../../../helpers/Errors.sol";
import {DomainConstants} from "../../../helpers/Constants.sol";

/// @title LibUI
/// @notice Methods that return requested data
library LibUI {
    /// @notice Returned as a data in {batchAllowedTokens}
    struct AllowedTokenData {
        address tokenAddress;
        uint16 stakeStableRate;
        uint16 borrowStableRate;
        uint16 ltv;
        uint16 liquidationThreshold;
        string name;
    }

    /// @notice Returned as a data in {batchStakedTokens}
    struct StakedTokenData {
        uint256 amountStaked;
        uint256 startAccumulatingDay;
        address tokenAddress;
        bool isCollateralOn;
        bool isCollateralInUse;
        string name;
    }

    /// @notice Returned as a data in {batchBorrowedTokens}
    struct BorrowedTokenData {
        uint256 amountBorrowed;
        uint256 startAccumulatingDay;
        string name;
        address tokenAddress;
        address collateralAddress;
        uint256 collateralAmount;
    }

    /// @notice Returned as a data in {accountData}
    struct AccountData {
        address[] stakedTokens;
        address[] borrowedTokens;
    }

    /* ======================================= Global ============================================================================================ */

    /// @notice Batches allowed tokens related info in @return data
    function batchAllowedTokens() internal view returns (AllowedTokenData[] memory data) {
        address[] memory tokens = a().allowedTokens;

        uint256 length = tokens.length;
        data = new AllowedTokenData[](length);

        for (uint256 i; i < length; i++) {
            address tokenAddr = tokens[i];
            AllowedToken memory token = a().allowedTokenData[tokenAddr];

            data[i] = AllowedTokenData({
                tokenAddress: tokenAddr,
                stakeStableRate: token.stakeStableRate,
                borrowStableRate: token.borrowStableRate,
                ltv: token.ltv,
                liquidationThreshold: token.liquidationThreshold,
                name: IERC20(tokenAddr).name()
            });
        }
    }

    /// @notice Returns the address of the interest-bearing token in @return data
    function mTokenAddress() internal view returns (address data) {
        data = p().mTokenAddress;
    }

    /* ======================================= User's ============================================================================================ */

    /// @notice Calculates the maximum amount in USD that can be borrowed based on @param _collateralAddress
    /// and @param _collateralAmount values
    /// @return value as a whole number
    function maxUsdToBorrow(
        address _collateralAddress,
        uint256 _collateralAmount
    ) internal view returns (uint256 value) {
        if (!a().allowedTokenData[_collateralAddress].isAllowed) {
            revert DomainErrors.UI__TokenNotAllowed(msg.sender, _collateralAddress);
        }

        uint256 collateralInUsd = a().getNormalizedUsdEquivalent(_collateralAddress, _collateralAmount);
        uint16 tokenLtv = a().allowedTokenData[_collateralAddress].ltv;

        // Calculates the result of the expression `collateralInUsd - (collateralInUsd * tokenLtv / BASIS_POINTS)`.
        // The calculation within the parentheses is rounded down
        uint256 denominator = DomainConstants.BASIS_POINTS;
        assembly {
            let z := mul(collateralInUsd, tokenLtv)

            if iszero(
                and(iszero(iszero(denominator)), or(iszero(collateralInUsd), eq(div(z, collateralInUsd), tokenLtv)))
            ) {
                revert(0, 0)
            }

            z := div(z, denominator)
            value := sub(collateralInUsd, z)
        }
    }

    /// @notice Batches related info for the staked tokens of @param _account and returns it in @return data
    function batchStakedTokens(address _account) internal view returns (StakedTokenData[] memory data) {
        address[] memory tokens = a().stakedTokens[_account];

        uint256 length = tokens.length;
        data = new StakedTokenData[](length);

        for (uint256 i; i < length; i++) {
            address tokenAddr = tokens[i];
            StakedToken memory token = a().stakedTokenData[_account][tokenAddr];

            data[i] = StakedTokenData({
                amountStaked: token.amountStaked,
                startAccumulatingDay: token.startAccumulatingDay,
                tokenAddress: tokenAddr,
                isCollateralOn: token.isCollateralOn,
                isCollateralInUse: token.isCollateralInUse,
                name: IERC20(tokenAddr).name()
            });
        }
    }

    /// @notice Batches related info for the borrowed tokens of @param _account and returns it in @return data
    function batchBorrowedTokens(address _account) internal view returns (BorrowedTokenData[] memory data) {
        address[] memory tokens = a().borrowedTokens[_account];

        uint256 length = tokens.length;
        data = new BorrowedTokenData[](length);

        for (uint256 i; i < length; i++) {
            address tokenAddr = tokens[i];
            BorrowedToken memory token = a().borrowedTokenData[_account][tokenAddr];

            data[i] = BorrowedTokenData({
                amountBorrowed: token.amountBorrowed,
                startAccumulatingDay: token.startAccumulatingDay,
                name: IERC20(tokenAddr).name(),
                tokenAddress: tokenAddr,
                collateralAddress: token.collateralAddress,
                collateralAmount: token.collateralAmount
            });
        }
    }

    /* ======================================= Keeper's ============================================================================================ */

    /// @notice Retrieve a list of all borrowers in the protocol as @return data
    function allBorrowers() internal view returns (address[] memory data) {
        address[] memory borrowers = a().borrowers;

        data = new address[](borrowers.length);
        data = borrowers;
    }

    /// @notice Batches relevant @param account data
    function batchAccountData(address _account) internal view returns (AccountData memory data) {
        data = AccountData({stakedTokens: a().stakedTokens[_account], borrowedTokens: a().borrowedTokens[_account]});
    }

    /// @notice Returns @return result indicating the outcome of the check
    /// @param _account The address of the account
    /// @param _collateralAddress The address of the collateral
    /// @param _borrowedTokenAddress The address of the borrowed token
    function isLiquidatable(
        address _account,
        address _collateralAddress,
        address _borrowedTokenAddress
    ) internal view returns (bool result) {
        AssetsState storage ast = a();

        // ========= Collateral ============================
        uint256 collateralAmount = ast.stakedTokenData[_account][_collateralAddress].amountStaked;
        uint256 collateralInUsd = ast.getNormalizedUsdEquivalent(_collateralAddress, collateralAmount);

        // ========= Borrowed token ============================
        uint256 borrowedAmount = ast.borrowedTokenData[_account][_borrowedTokenAddress].amountBorrowed;
        uint256 borrowedInUsd = ast.getNormalizedUsdEquivalent(_borrowedTokenAddress, borrowedAmount);

        // ========= Limit ============================
        uint256 threshold = ast.allowedTokenData[_collateralAddress].liquidationThreshold;
        uint256 limitInUsd = (threshold * collateralInUsd) / DomainConstants.BASIS_POINTS;

        result = borrowedInUsd > limitInUsd - 1 ? true : false;
    }
}
