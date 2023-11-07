// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AssetsModifiers, StakedToken, a} from "../libraries/AssetsState.sol";
import {ProtocolModifiers} from "../libraries/ProtocolState.sol";
import {SafeERC20} from "../vendor/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {DomainEvents} from "../../helpers/Events.sol";
import {DomainErrors} from "../../helpers/Errors.sol";

/// @title DepositFacet
/// @dev Keep in mind that *most* of the functions should be symmetric with `WithdrawFacet` ones
/// @custom:advice Consider adding more events, better monitoring
/// @custom:version 0.0.1
contract DepositFacet is AssetsModifiers, ProtocolModifiers {
    using SafeERC20 for IERC20;

    /// @notice Deposits tokens
    /// @param tokenAddress The address of token you want to stake
    /// @param tokenAmount The amount of the token
    /// @dev In the front-end — ensure correct allowance handling
    /// @custom:security Transfers tokens before any state changes as an additional re-entrancy safeguard
    /// @custom:security For the simplicity of this version, `tokenAmount` will represent a whole number (ofc)
    /// of tokens without decimal places
    /// @custom:security Be aware of `safeTransferFrom` and all attack vectors associated with it
    /// @custom:security By using `safeTransferFrom`, it will not be neccessary to check if the transaction
    /// is succesful (including non-standard ERC20 tokens)
    /// @custom:security The right business model is crucial for the health of the protocol. If needed,
    /// consider applying a timed locking mechanism, adjusting the interest rate appropriately, or something else
    /// @custom:exec Sanity modifier -> deposit -> internal state changes -> sends mTokens
    function deposit(
        address tokenAddress,
        uint256 tokenAmount
    ) external allowed(tokenAddress, tokenAmount) nonReentrant {
        IERC20 token = IERC20(tokenAddress);

        uint256 decimals = token.decimals();
        uint256 scaledAmount = tokenAmount * 10 ** decimals;
        // If the depositer doesn't have enough tokens, the transfer will fail
        token.safeTransferFrom(msg.sender, address(this), scaledAmount);

        a().manageDeposit(tokenAddress, tokenAmount);
    }

    /// @notice Turns on the collateral for a staked token
    /// @dev Should be symmetric with {turnOffCollateral}
    function turnOnCollateral(address _tokenAddress) external nonReentrant {
        StakedToken storage stakedToken = a().stakedTokenData[msg.sender][_tokenAddress];

        if (!stakedToken.isStaked) revert DomainErrors.TokenNotStaked(msg.sender, _tokenAddress);
        if (stakedToken.isCollateralOn) revert DomainErrors.CollateralAlreadyOn();

        emit DomainEvents.CollateralOn(_tokenAddress, msg.sender);
        // This property is currently not utilized on tokens used as collateral, which is why it's `0`
        stakedToken.startAccumulatingDay = 0;
        stakedToken.isCollateralOn = true;
    }

    /// @notice Turns off the collateral for a staked token
    /// @dev Should be symmetric with {turnOnCollateral}
    function turnOffCollateral(
        address _tokenAddress
    ) external enabledCollateral(_tokenAddress) notInUseCollateral(_tokenAddress) nonReentrant {
        StakedToken storage stakedToken = a().stakedTokenData[msg.sender][_tokenAddress];

        emit DomainEvents.CollateralOff(_tokenAddress, msg.sender);
        stakedToken.startAccumulatingDay = block.timestamp;
        stakedToken.isCollateralOn = false;
    }
}
