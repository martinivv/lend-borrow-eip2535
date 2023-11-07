// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {SafeERC20} from "../../vendor/SafeERC20.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {AssetsState, StakedToken} from "../AssetsState.sol";
import {p} from "../ProtocolState.sol";
import {DomainErrors} from "../../../helpers/Errors.sol";
import {DomainEvents} from "../../../helpers/Events.sol";

/// @title LibDeposit
library LibDeposit {
    using SafeERC20 for IERC20;

    /// @notice Manages the deposit by changing the internal protocol state. Then sends mTokens
    /// @param _tokenAddress The deposited token address
    /// @param _tokenAmount The token amount without decimals
    /// @custom:security When you're managing parallel data structures, it's crucial to ensure they are always synchronized.
    /// Otherwise, it can result in a critical bug. Make sure they're always managed together
    function manageDeposit(AssetsState storage self, address _tokenAddress, uint256 _tokenAmount) internal {
        StakedToken storage stakedToken = self.stakedTokenData[msg.sender][_tokenAddress];

        bool isTokenStaked = stakedToken.isStaked;

        if (isTokenStaked) {
            stakedToken.amountStaked += _tokenAmount;
            stakedToken.startAccumulatingDay = block.timestamp;
        } else {
            StakedToken memory currentToken = StakedToken({
                amountStaked: _tokenAmount,
                startAccumulatingDay: block.timestamp,
                isStaked: true,
                isCollateralOn: false,
                isCollateralInUse: false
            });

            // Always manage together!
            self.stakedTokenData[msg.sender][_tokenAddress] = currentToken;
            self.stakedTokens[msg.sender].push(_tokenAddress);
            // =======
        }

        _sendMTokens(self, _tokenAddress, _tokenAmount);
    }

    /// @notice Sends mTokens; the interest-bearing token back for a deposited token
    /// @param _tokenAddress The deposited token's address
    /// @param _tokenAmount The deposited token's amount
    /// @custom:security Ensure you're using the right decimals, otherwise this can lead
    /// to wrong calculations, misleading errors, loss of funds
    /// @custom:advice Consider implementing event monitoring for the interest-bearing token
    function _sendMTokens(AssetsState storage state, address _tokenAddress, uint256 _tokenAmount) private {
        // The price of the token amount without decimals
        uint256 sendAmount = state.getNormalizedUsdEquivalent(_tokenAddress, _tokenAmount);

        IERC20 mToken = IERC20(p().mTokenAddress);
        uint8 decimals = mToken.decimals();

        uint256 scaledAmount = sendAmount * 10 ** decimals;
        if (scaledAmount > mToken.balanceOf(address(this))) revert DomainErrors.NotEnoughTokensInExistence();

        emit DomainEvents.Deposit(_tokenAddress, _tokenAmount, msg.sender);
        mToken.safeTransfer(msg.sender, scaledAmount);
    }
}
