// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AssetsState} from "../AssetsState.sol";
// Add remappings
import {DomainConstants} from "../../../helpers/Constants.sol";
import {p} from "../ProtocolState.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";
import {DomainErrors} from "../../../helpers/Errors.sol";

/// @title LibCalculator
/// @custom:advice If needed, implement max ratio constant
library LibCalculator {
    /// @notice Gets the borrowing power in USD
    /// @param _collateralAddress The address of the used collateral for the borrow
    /// @return collateralAmount The amount of the used collateral
    /// @return maxToBorrowInUsd The maximum USD amount you can borrow
    /// @dev LTV ratio is represented in basis points, 500 basis points = 5 %
    /// @custom:security Reverts if the extraction in `value` results in a negative value
    /// @custom:security The integral business model is not considered, may occur wrong calculations, loss of funds.
    /// It's a demo version
    /// @custom:security Performs calculations with a different bit size than `(uint)256`. Should be
    /// closely/further monitored
    /// @custom:exec Gets the USD equivalent of the collateral amount -> calculates the
    /// max borrowing amount in USD
    function getMaxAmountToBorrowInUsd(
        AssetsState storage self,
        address _collateralAddress
    ) internal view returns (uint256 collateralAmount, uint256 maxToBorrowInUsd) {
        collateralAmount = self.stakedTokenData[msg.sender][_collateralAddress].amountStaked;
        uint256 collateralInUsd = getNormalizedUsdEquivalent(self, _collateralAddress, collateralAmount);
        uint16 tokenLtv = self.allowedTokenData[_collateralAddress].ltv;

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
            maxToBorrowInUsd := sub(collateralInUsd, z)
        }
    }

    /// @notice Calculates the USD equivalent value of a token amount
    /// @param _tokenAddress The token's address
    /// @param _tokenAmount The token amount
    /// @return value The normalized USD value obtained by `tokenAmount *
    /// the token's USD price / decimals to be removed`
    function getNormalizedUsdEquivalent(
        AssetsState storage self,
        address _tokenAddress,
        uint256 _tokenAmount
    ) internal view returns (uint256 value) {
        (uint256 oracleResponse, uint8 decimals) = _getTokenPriceInUsd(self, _tokenAddress);

        value = (_tokenAmount * oracleResponse) / (10 ** decimals);
    }

    /// @notice Gets the raw price and decimals of an allowed token
    /// @param _tokenAddress The allowed token
    /// @return oracleResponse Returns the raw price with `decimals`, not divided by a decimal point
    /// @return decimals *Typically* comes with a value of 8
    /// @custom:security Consider implementing backup oracle(-s) logic in case of failure;
    /// TWAP or other verifiably secure options are recommended
    function _getTokenPriceInUsd(
        AssetsState storage state,
        address _tokenAddress
    ) private view returns (uint256 oracleResponse, uint8 decimals) {
        IAggregatorV3 dataFeed = state.allowedTokenData[_tokenAddress].dataFeed;

        try dataFeed.latestRoundData() returns (uint80 roundId, int256 answer, uint256, uint256 updatedAt, uint80) {
            if (answer < 1) revert DomainErrors.AnswerShouldBePositiveNum(roundId, answer);

            if (updatedAt == 0) revert DomainErrors.InvalidTime(roundId, updatedAt);

            if (block.timestamp - updatedAt > p().answerStalenessThreshold) {
                revert DomainErrors.StalePrice(roundId);
            }

            oracleResponse = uint256(answer);
        } catch {
            revert DomainErrors.OracleNotAvailable(dataFeed);
        }

        decimals = dataFeed.decimals();
    }
}
