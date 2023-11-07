// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AllowedToken, AssetsState, a} from "../AssetsState.sol";
import {DomainErrors} from "../../../helpers/Errors.sol";

/// @title LibOwner
library LibOwner {
    /// @notice Sets the allowed tokens for the protocol
    /// @param _tokens Tokens to be allowed
    /// @custom:security Security measures taken for the *for* loop:
    /// 1. The array is cached outside, making it gas-optimized;
    /// 2. There is no storage array that can grow infinitely;
    /// 3. There are no external calls within the loop, potentially preventing a DoS attack
    /// @custom:security When you're managing parallel data structures, it's crucial to ensure they are always synchronized.
    /// Otherwise, it can result in a critical bug. Make sure they're always managed together
    function setTokens(AllowedToken[] calldata _tokens) internal {
        AssetsState storage ast = a();

        uint256 length = _tokens.length;
        if (length == 0) revert DomainErrors.NoTokensFound();

        for (uint256 i; i < length; ) {
            address tokenAddress = _tokens[i].tokenAddress;

            bool isAdded = ast.allowedTokenData[tokenAddress].isAllowed;
            if (!isAdded) {
                // Always manage together!
                ast.allowedTokenData[tokenAddress] = _tokens[i];
                ast.allowedTokens.push(tokenAddress);
            }

            unchecked {
                i++;
            }
        }
    }
}
