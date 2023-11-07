// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Array} from "./utils/Array.sol";
import {AssetsState, BorrowedToken} from "../AssetsState.sol";
import {DomainConstants} from "../../../helpers/Constants.sol";
import {DomainErrors} from "../../../helpers/Errors.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

/// @title LibLiquidation
library LibLiquidation {
    using Array for address[];

    /// @notice Returns keeper's @return rewardInTokens, otherwise, if the @param _borrower is not
    /// for liquidation, reverts
    /// @param _borrowedToken The address of the borrowed token
    /// @dev Calculations once again are in basis points. 8_000 BPs = 80 %
    /// @custom:advice Consider adding another mechanism instead of reverting; if needed
    /// @custom:security Performs calculations with a different bit size than `(uint)256`. Should be
    /// closely/further monitored
    /// @custom:security Gives 50 % (5_000 BPs) of the reward to the keeper to establish some form
    /// of equilibrium in the protocol (pays interest to the supporters). Don't forget that this
    /// is a DEFI protocol
    function manageLiquidation(
        AssetsState storage self,
        address _borrower,
        address _borrowedToken
    ) internal view returns (address collateralAddress, uint256 rewardInTokens) {
        BorrowedToken memory borrowedToken = self.borrowedTokenData[_borrower][_borrowedToken];

        /* ==================================== Is liquidatable? =========================================================================== */

        // ========== Collateral in USD ==============================
        collateralAddress = borrowedToken.collateralAddress;
        uint256 collateralAmount = self.stakedTokenData[_borrower][collateralAddress].amountStaked;
        uint256 collateralInUsd = self.getNormalizedUsdEquivalent(collateralAddress, collateralAmount);

        // ========== Borrowed in USD ==============================
        uint256 borrowedAmount = borrowedToken.amountBorrowed;
        uint256 borrowedInUsd = self.getNormalizedUsdEquivalent(_borrowedToken, borrowedAmount);

        // ========== Finding the limit ==============================
        uint16 collateralThreshold = self.allowedTokenData[collateralAddress].liquidationThreshold;
        // For example. `8_000 * 1000 / 10_000` equals to `800`
        uint256 limitInUsd = (collateralThreshold * collateralInUsd) / DomainConstants.BASIS_POINTS;
        if (borrowedInUsd < limitInUsd) revert DomainErrors.NotLiquidatable(msg.sender);

        /* =============================== Calculating the keeper reward ========================================================================== */

        // `(5_000 * (2400 - 2000)) / 10_000` equals to `200`
        uint256 rewardInUsd = (5_000 * (borrowedInUsd - limitInUsd)) / DomainConstants.BASIS_POINTS;
        uint256 singleTokenPrice = rewardInUsd / borrowedAmount;
        uint8 decimals = IERC20(_borrowedToken).decimals();
        rewardInTokens = (rewardInUsd * 10 ** decimals) / singleTokenPrice;
    }

    /// @notice Records the liquidation into the internal state
    /// @param _borrower The address of the borrower
    /// @param _collateralAddress The address of the used collateral token
    /// @param _borrowedToken The address of the borrowed token
    /// @custom:security When you're managing parallel data structures, it's crucial to ensure they are always synchronized.
    /// Otherwise, it can result in a critical bug. Make sure they're always managed together
    function recordLiquidation(
        AssetsState storage self,
        address _borrower,
        address _collateralAddress,
        address _borrowedToken
    ) internal {
        delete self.stakedTokenData[_borrower][_collateralAddress];
        self.stakedTokens[_borrower].remove(_collateralAddress);

        delete self.borrowedTokenData[_borrower][_borrowedToken];
        self.borrowedTokens[_borrower].remove(_borrowedToken);
    }
}
