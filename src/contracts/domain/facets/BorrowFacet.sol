// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AssetsModifiers, a} from "../libraries/AssetsState.sol";
import {ProtocolModifiers} from "../libraries/ProtocolState.sol";
import {SafeERC20} from "../vendor/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {DomainEvents} from "../../helpers/Events.sol";

/// @title BorrowFacet
/// @dev Keep in mind that *most* of the functions should be symmetric with `RepayFacet` ones
/// @custom:version 0.0.1
contract BorrowFacet is AssetsModifiers, ProtocolModifiers {
    using SafeERC20 for IERC20;

    /// @notice Borrows a token amount
    /// @param _collateralAddress The address of the token which is going to be used as a collateral
    /// @param tokenAddress The address of the wanted token
    /// @param _tokenAmount The amount of tokens to borrow
    /// @custom:exec Sanity checks -> internal state changes, returns the scaled amount (currently) -> transfer
    function borrow(
        address _collateralAddress,
        address tokenAddress,
        uint256 _tokenAmount
    ) external enabledCollateral(_collateralAddress) allowed(tokenAddress, _tokenAmount) nonReentrant {
        uint256 scaledAmount = a().verifyAndRecordBorrow(_collateralAddress, tokenAddress, _tokenAmount);

        emit DomainEvents.Borrow(tokenAddress, _tokenAmount, msg.sender);
        IERC20(tokenAddress).safeTransfer(msg.sender, scaledAmount);
    }
}
