// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// @title IAggregatorV3
/// @notice This interface enables utilization of Chainlink data feeds
interface IAggregatorV3 {
    /// @notice Returns the number of decimals in the response
    /// @return {uint8}
    function decimals() external view returns (uint8);

    /// @notice Gets data from the latest round
    /// @return roundId The round ID
    /// @return answer The data that this specific feed provides
    /// @return startedAt Timestamp of when the round started
    /// @return updatedAt Timestamp of when the round was updated
    /// @return answeredInRound Deprecated. Previously used when answers could take multiple rounds to be computed
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
