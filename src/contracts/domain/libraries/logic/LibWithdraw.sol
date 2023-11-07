// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Array} from "./utils/Array.sol";
import {AssetsState, StakedToken} from "../AssetsState.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {DomainErrors} from "../../../helpers/Errors.sol";
import {DomainConstants} from "../../../helpers/Constants.sol";

/// @title LibWithdraw
library LibWithdraw {
    using Array for address[];

    /// @notice Records the withdraw, applying the changes to the internal state
    /// @param _tokenAddress The address of the withdrawn token
    /// @param _verifiedAmount The verified amount of the withdrawn token
    /// @custom:security When you're managing parallel data structures, it's crucial to ensure they are always synchronized.
    /// Otherwise, it can result in a critical bug. Make sure they're always managed together
    /// @custom:security Can't occur the mapping/array vulnerability where the mapping/array remains accessible
    /// even after deletion, because in this case it's not nested
    function recordWithdraw(AssetsState storage self, address _tokenAddress, uint256 _verifiedAmount) internal {
        StakedToken storage stakedToken = self.stakedTokenData[msg.sender][_tokenAddress];

        uint256 currentAmount = stakedToken.amountStaked;

        if (_verifiedAmount == currentAmount) {
            // Always manage together!
            delete self.stakedTokenData[msg.sender][_tokenAddress];
            self.stakedTokens[msg.sender].remove(_tokenAddress);
            // =======
        } else {
            stakedToken.amountStaked -= _verifiedAmount;
        }
    }

    /// @notice Calculates @return withdrawAmount and @return mTokensToBurn. @return verifiedAmount ensures
    /// correct state changes in {recordWithdraw}
    /// @param _tokenAddress The address of the token to be withdrawn
    /// @param _tokenAmount The amount of the token to be withdrawn
    /// @custom:security The integral business model is not considered; wrong calculations and loss of funds may occur.
    /// Calculations are only used for demo purposes
    /// @custom:security If `startAccumulatingDay` is in the current day, `verifiedNumDays` will receive a value of
    /// 1 (day) to ensure proper calculations in the current version, thereby preventing a critical vulnerability
    /// @custom:security Performs calculations with a different bit size than `(uint)256`. Should be
    /// closely/further monitored
    function calculateWithdraw(
        AssetsState storage self,
        address _tokenAddress,
        uint256 _tokenAmount
    ) internal view returns (uint256 verifiedAmount, uint256 withdrawAmount, uint256 mTokensToBurn) {
        /* ========================== Setup ======================================================================== */

        StakedToken memory stakedToken = self.stakedTokenData[msg.sender][_tokenAddress];

        uint256 stakedAmount = stakedToken.amountStaked;

        IERC20 token = IERC20(_tokenAddress);
        uint8 decimals = token.decimals();

        // In order to burn the correct amount
        verifiedAmount = (_tokenAmount > stakedAmount ? stakedAmount : _tokenAmount);
        uint256 scaledWithdraw = verifiedAmount * 10 ** decimals;

        /* ========================== Interest, withdrawable amount ======================================================================== */

        if (!stakedToken.isCollateralOn) {
            uint32 tokenStakeStableRate = self.allowedTokenData[_tokenAddress].stakeStableRate;

            uint256 numDays = (block.timestamp - stakedToken.startAccumulatingDay) / DomainConstants.SECONDS_PER_DAY;

            uint256 verifiedNumDays = numDays > 0 ? numDays : 1;
            // For example. `100e18 * 1000 / 10_000` equals to `10e18`
            uint256 dailyInterestInTokens = (scaledWithdraw * tokenStakeStableRate) / DomainConstants.BASIS_POINTS;
            // `15 * 10e18 / 365` equals to `(0.)410958904109589041`
            uint256 accumulatedInterestInTokens = (verifiedNumDays * dailyInterestInTokens) /
                DomainConstants.DAYS_PER_YEAR;

            // `100e18 += 410958904109589041` equals to `100410958904109589041`
            withdrawAmount = accumulatedInterestInTokens;
        }

        withdrawAmount += scaledWithdraw;
        if (token.balanceOf(address(this)) < withdrawAmount) revert DomainErrors.InsufficientProtocolFunds();

        /* ========================== mTokens ======================================================================== */

        mTokensToBurn = (self.getNormalizedUsdEquivalent(_tokenAddress, verifiedAmount)) * 10 ** decimals;
    }
}
