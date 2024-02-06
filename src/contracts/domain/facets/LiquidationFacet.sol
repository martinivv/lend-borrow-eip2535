// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AssetsModifiers, a} from "../libraries/AssetsState.sol";
import {ProtocolModifiers} from "../libraries/ProtocolState.sol";
import {SafeERC20} from "../vendor/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {DomainErrors} from "../../helpers/Errors.sol";
import {DomainEvents} from "../../helpers/Events.sol";

/// @title LiquidationFacet
/// @custom:version 0.0.1
contract LiquidationFacet is AssetsModifiers, ProtocolModifiers {
    using SafeERC20 for IERC20;

    /// @notice Implements an atypical and severe penalty when the borrower's collateral falls below
    /// a specified threshold value. In order to prioritize simplicity
    /// @param _borrower The address of the borrower
    /// @param borrowedToken The address of the borrowed token
    /// @custom:security Think of implementing a different reward system based on the business model
    /// @custom:exec Checks -> checks if it is liquidatable -> calculates the reward for the keeper ->
    /// internal changes -> transfer
    function liquidate(
        address _borrower,
        address borrowedToken
    ) external liquidatable(_borrower, borrowedToken) nonReentrant {
        (address collateralAddress, uint256 rewardInTokens) = a().manageLiquidation(_borrower, borrowedToken);

        a().recordLiquidation(_borrower, collateralAddress, borrowedToken);

        IERC20 collateral = IERC20(collateralAddress);
        if (collateral.balanceOf(address(this)) < rewardInTokens) revert DomainErrors.InsufficientProtocolFunds();
        emit DomainEvents.Liquidation(_borrower, borrowedToken, rewardInTokens, msg.sender);
        collateral.safeTransfer(msg.sender, rewardInTokens);
    }
}
