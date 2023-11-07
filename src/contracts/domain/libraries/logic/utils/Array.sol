// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

// Consider adding remappings
import {DomainErrors} from "../../../../helpers/Errors.sol";

/// @title Array
/// @notice Array helper utils
library Array {
    /// @notice Removes @param _address from @param _arr
    /// @custom:exec Gets the index of `tokenAddress` -> moves the element in the last index, if
    /// it's not already there -> removes the last index
    function remove(address[] storage _arr, address _address) internal {
        uint256 index = _indexOf(_arr, _address);
        if (index == 404) revert DomainErrors.Error404();

        uint256 lastIndex = _arr.length - 1;

        if (index != lastIndex) _arr[index] = _arr[lastIndex];

        _arr.pop();
    }

    /// @notice Pushes @param _address in @param _arr, if doesn't occur
    function safePush(address[] storage _arr, address _address) internal {
        uint256 index = _indexOf(_arr, _address);

        if (index == 404) {
            _arr.push(_address);
        } else {
            revert DomainErrors.TokenAlreadyThere();
        }
    }

    /// @notice Returns the index of @param _address in @param _arr
    /// @return i The index of the token's address, otherwise `404`, referencing the popular *Error404*
    /// @custom:security Security measures taken for the *for* loop:
    /// 1. The array is cached outside, making it gas-optimized;
    /// 2. There is no storage array that can grow infinitely;
    /// 3. There are no external calls within the loop, potentially preventing a DoS attack
    function _indexOf(address[] memory _arr, address _address) private pure returns (uint256 i) {
        uint256 length = _arr.length;

        for (i; i < length; i++) {
            if (_arr[i] == _address) return i;
        }

        i = 404;
    }
}
