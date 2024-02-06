// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AssetsModifiers, a} from "../libraries/AssetsState.sol";
import {ProtocolModifiers} from "../libraries/ProtocolState.sol";
import {SafeERC20} from "../vendor/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {DomainEvents} from "../../helpers/Events.sol";

/// @title RepayFacet
/// @custom:version 0.0.1
contract RepayFacet is AssetsModifiers, ProtocolModifiers {
    using SafeERC20 for IERC20;

    /// @notice Repays a borrow
    /// @param _collateralAddress The address of the used collateral token
    /// @param tokenAddress The borrowed token address
    /// @param _tokenAmount The borrowed amount
    /// @dev Ensure correct allowance handling
    /// @custom:exec Checks -> calculation library call -> transfer -> internal state changes
    function repay(
        address _collateralAddress,
        address tokenAddress,
        uint256 _tokenAmount
    ) external repayableCollateral(_collateralAddress, tokenAddress) positiveAmount(_tokenAmount) nonReentrant {
        // The right decimals are set
        (uint256 verifiedAmount, uint256 totalToRepay) = a().calculateAmountToRepay(tokenAddress, _tokenAmount);
        // Before any state changes as an additional re-entrancy metric
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), totalToRepay);
        emit DomainEvents.Repay(tokenAddress, totalToRepay, msg.sender);

        a().recordRepay(_collateralAddress, tokenAddress, verifiedAmount);
    }
}
