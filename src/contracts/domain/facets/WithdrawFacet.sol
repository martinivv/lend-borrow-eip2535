// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AssetsModifiers, a} from "../libraries/AssetsState.sol";
import {ProtocolModifiers, p} from "../libraries/ProtocolState.sol";
import {SafeERC20} from "../vendor/SafeERC20.sol";
import {IMToken} from "../interfaces/IMToken.sol";
import {DomainEvents} from "../../helpers/Events.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/// @title WithdrawFacet
/// @custom:version 0.0.1
contract WithdrawFacet is AssetsModifiers, ProtocolModifiers {
    using SafeERC20 for IERC20;

    /// @notice Withdraws @param _tokenAmount of @param tokenAddress
    /// @custom:advice Consider checking the balance of the interest-bearing token; if necessary
    /// @custom:advice Consider implementing event monitoring for the interest-bearing token
    /// @custom:exec Sanity checks -> calculation call -> burn -> records withdraw -> transfer
    function withdraw(
        address tokenAddress,
        uint256 _tokenAmount
    ) external notInUseCollateral(tokenAddress) positiveAmount(_tokenAmount) nonReentrant {
        (uint256 verifiedAmount, uint256 withdrawAmount, uint256 mTokensToBurn) = a().calculateWithdraw(
            tokenAddress,
            _tokenAmount
        );
        // The right decimals are applied
        IMToken(p().mTokenAddress).burn(msg.sender, mTokensToBurn);

        a().recordWithdraw(tokenAddress, verifiedAmount);

        emit DomainEvents.Withdraw(tokenAddress, withdrawAmount, msg.sender);
        IERC20(tokenAddress).safeTransfer(msg.sender, withdrawAmount);
    }
}
