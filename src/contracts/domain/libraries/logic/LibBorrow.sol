// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Array} from "./utils/Array.sol";
import {AssetsState, BorrowedToken} from "../AssetsState.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {DomainErrors} from "../../../helpers/Errors.sol";

/// @title LibBorrow
library LibBorrow {
    using Array for address[];

    /// @notice Verifies the truth of account parameters and records the borrow
    /// @param _collateralAddress The address of the token used as collateral for the borrow
    /// @param _tokenAddress The address of the borrowed token
    /// @param _tokenAmount The amount to be borrowed
    /// @custom:security When you're managing parallel data structures, it's crucial to ensure they are always synchronized.
    /// Otherwise, it can result in a critical bug. Make sure they're always managed together
    /// @custom:advice If `_tokenAmount` cannot be borrowed, consider implementing logic where
    /// the maximum available token amount is passed to the `BorrowFacet`
    /// @custom:exec Sanity checks (internal calls to `LibCalculator`) -> internal state updates
    function verifyAndRecordBorrow(
        AssetsState storage self,
        address _collateralAddress,
        address _tokenAddress,
        uint256 _tokenAmount
    ) internal returns (uint256 scaledAmount) {
        /* ========================= Sanity checks ======================================================================== */

        (uint256 collateralAmount, uint256 maxToBorrowInUsd) = self.getMaxAmountToBorrowInUsd(_collateralAddress);
        uint256 amountToBeBorrowedInUsd = self.getNormalizedUsdEquivalent(_tokenAddress, _tokenAmount);

        if (amountToBeBorrowedInUsd > maxToBorrowInUsd) {
            revert DomainErrors.CannotBorrowAmount(msg.sender, maxToBorrowInUsd, amountToBeBorrowedInUsd);
        }

        IERC20 token = IERC20(_tokenAddress);
        uint8 decimals = token.decimals();
        scaledAmount = _tokenAmount * 10 ** decimals;

        if (token.balanceOf(address(this)) < scaledAmount) revert DomainErrors.InsufficientProtocolFunds();

        /* ========================= Updating internal state ======================================================================== */

        BorrowedToken storage borrowedToken = self.borrowedTokenData[msg.sender][_tokenAddress];

        bool isTokenBorrowed = borrowedToken.isBorrowed;

        if (isTokenBorrowed) {
            address collateralInUse = borrowedToken.collateralAddress;
            if (_collateralAddress != collateralInUse) revert DomainErrors.CollateralMismatch();

            borrowedToken.amountBorrowed += _tokenAmount;
        } else {
            BorrowedToken memory currentToken = BorrowedToken({
                amountBorrowed: _tokenAmount,
                startAccumulatingDay: block.timestamp,
                isBorrowed: true,
                collateralAddress: _collateralAddress,
                collateralAmount: collateralAmount
            });

            // Always manage together!
            self.borrowedTokenData[msg.sender][_tokenAddress] = currentToken;
            self.borrowedTokens[msg.sender].push(_tokenAddress);
            // =======
            self.borrowers.safePush(msg.sender);

            self.stakedTokenData[msg.sender][_collateralAddress].isCollateralInUse = true;
        }
    }
}
