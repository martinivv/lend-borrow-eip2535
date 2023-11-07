// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Array} from "./utils/Array.sol";
import {AssetsState, BorrowedToken} from "../AssetsState.sol";
import {DomainConstants} from "../../../helpers/Constants.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {DomainErrors} from "../../../helpers/Errors.sol";

/// @title LibRepay
library LibRepay {
    using Array for address[];

    /// @notice Makes internal changes
    /// @param _collateralAddress The address of the used collateral token
    /// @param _tokenAddress The address of the repaid token
    /// @param _verifiedAmount The verified amount of the repaid token
    /// @custom:security When you're managing parallel data structures, it's crucial to ensure they are always synchronized.
    /// Otherwise, it can result in a critical bug. Make sure they're always managed together
    /// @custom:security Can't occur the mapping/array vulnerability where the mapping/array remains accessible
    /// even after deletion, because in this case it's not nested
    function recordRepay(
        AssetsState storage self,
        address _collateralAddress,
        address _tokenAddress,
        uint256 _verifiedAmount
    ) internal {
        BorrowedToken storage borrowedToken = self.borrowedTokenData[msg.sender][_tokenAddress];

        // Still hasn't been updated
        uint256 currentAmount = borrowedToken.amountBorrowed;

        if (_verifiedAmount == currentAmount) {
            // Always manage together!
            delete self.borrowedTokenData[msg.sender][_tokenAddress];
            self.borrowedTokens[msg.sender].remove(_tokenAddress);
            // =======
            if (self.borrowedTokens[msg.sender].length == 0) self.borrowers.remove(msg.sender);

            // Managing the collateral token
            self.stakedTokenData[msg.sender][_collateralAddress].isCollateralInUse = false;
        } else {
            borrowedToken.amountBorrowed -= _verifiedAmount;
        }
    }

    /// @notice Calculates the amount to be repaid
    /// @param _tokenAddress The borrowed token
    /// @param _tokenAmount The borrowed amount
    /// @return verifiedAmount Ensures correct state changes in {recordRepay}
    /// @return totalToRepay The amount with the right token decimals
    /// @custom:security The integral business model is not considered; wrong calculations and loss of funds may occur.
    /// Calculations are only used for demo purposes
    /// @custom:security If `startAccumulatingDay` is in the current day, `verifiedNumDays` will receive a value of
    /// 1 (day) to ensure proper calculations in the current version, thereby preventing a critical vulnerability
    /// @custom:security Performs calculations with a different bit size than `(uint)256`. Should be
    /// closely/further monitored
    function calculateAmountToRepay(
        AssetsState storage self,
        address _tokenAddress,
        uint256 _tokenAmount
    ) internal view returns (uint256 verifiedAmount, uint256 totalToRepay) {
        /* ============================== Setup =========================================================================== */

        BorrowedToken memory borrowedToken = self.borrowedTokenData[msg.sender][_tokenAddress];

        uint256 borrowedAmount = borrowedToken.amountBorrowed;

        IERC20 token = IERC20(_tokenAddress);
        uint8 decimals = token.decimals();

        verifiedAmount = (_tokenAmount > borrowedAmount ? borrowedAmount : _tokenAmount);
        uint256 scaledAmount = verifiedAmount * 10 ** decimals;

        /* ============================== Interest =========================================================================== */

        uint256 startAccumulatingDay = borrowedToken.startAccumulatingDay;
        uint16 tokenBorrowStableRate = self.allowedTokenData[_tokenAddress].borrowStableRate;

        uint256 numDays = (block.timestamp - startAccumulatingDay) / DomainConstants.SECONDS_PER_DAY;

        uint256 verifiedNumDays = numDays > 0 ? numDays : 1;
        // For example. `100e18 * 500 / 10_000` equals to `5e18`
        uint256 dailyInterestInTokens = (scaledAmount * tokenBorrowStableRate) / DomainConstants.BASIS_POINTS;
        // `15 * 5e18 / 365` equals to `(0.)205479452054794520`
        uint256 accumulatedInterestInTokens = (verifiedNumDays * dailyInterestInTokens) / DomainConstants.DAYS_PER_YEAR;

        /* ============================== Finalization =========================================================================== */

        // `100e18 + 205479452054794520` equals to `100205479452054794520`
        totalToRepay = scaledAmount + accumulatedInterestInTokens;

        if (token.balanceOf(msg.sender) < totalToRepay) revert DomainErrors.InsufficientTokenAmount();
    }
}
