// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {LibDeposit} from "./logic/LibDeposit.sol";
import {LibBorrow} from "./logic/LibBorrow.sol";
import {LibRepay} from "./logic/LibRepay.sol";
import {LibWithdraw} from "./logic/LibWithdraw.sol";
import {LibLiquidation} from "./logic/LibLiquidation.sol";
import {LibCalculator} from "./logic/LibCalculator.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";
import {DomainErrors} from "../../helpers/Errors.sol";

using LibDeposit for AssetsState global;
using LibBorrow for AssetsState global;
using LibRepay for AssetsState global;
using LibWithdraw for AssetsState global;
using LibLiquidation for AssetsState global;
using LibCalculator for AssetsState global;

/// @notice Defines the properties for an allowed token
/// @dev Parameters used for calculations are present in basis points. For example,
/// 1000 basis points = a 10 % staking stable rate
struct AllowedToken {
    /// @notice Used as a parameter (on withdrawing) for calculating the daily interest (in tokens)
    /// for *solely* staking the token
    uint16 stakeStableRate;
    /// @notice Used as a parameter (on repaying) for calculating the daily interest (in tokens) to
    /// be paid back for a borrowed token
    uint16 borrowStableRate;
    /// @notice The token's LTV ratio. Higher value — higher risk for the protocol's health
    uint16 ltv;
    /// @notice The token's liquidation threshold. If the borrowed amount in USD surpasses
    /// this limit, the borrower should be liquidated
    /// @dev 8_000 BPs = 80 % of the collateral
    uint16 liquidationThreshold;
    /// @notice Returns `true` if the token is allowed, otherwise `false`
    bool isAllowed;
    /// @notice The address of the token used for setting up the protocol's allowed tokens
    address tokenAddress;
    /// @notice The address of the Chainlink data feed
    IAggregatorV3 dataFeed;
}

/// @notice Defines the properties for a staked token
struct StakedToken {
    /// @notice The staked amount
    uint256 amountStaked;
    /// @notice Marks the start of the staking period, measured in seconds since the Unix epoch (block.timestamp)
    uint256 startAccumulatingDay;
    /// @notice Returns `true` if the token is staked, otherwise `false`
    bool isStaked;
    /// @notice Returns `true` if the token can be used as collateral for borrowing
    bool isCollateralOn;
    /// @notice Returns `true` if the token is currently used as collateral for a borrowed token
    bool isCollateralInUse;
}

/// @notice Defines the properties for a borrowed token
struct BorrowedToken {
    /// @notice The borrowed amount
    uint256 amountBorrowed;
    /// @notice Marks the start of the borrowing period, measured in seconds since the Unix epoch (block.timestamp)
    uint256 startAccumulatingDay;
    /// @notice Returns `true` if the token is borrowed, otherwise `false`
    bool isBorrowed;
    /// @notice The address of the used collateral
    address collateralAddress;
    /// @notice The amount tokens used for the borrow
    uint256 collateralAmount;
}

/// @notice Struct defining the current assets state
/// @custom:advice Consider creating a library with "generic" functions related to `AssetsState`
struct AssetsState {
    /// @notice Protocol's allowed tokens data. Token address -> token data
    mapping(address => AllowedToken) allowedTokenData;
    /// @notice Protocol's allowed tokens
    address[] allowedTokens;
    // ======================= STAKE ===========================================================
    /// @notice Account -> token address -> staking data
    mapping(address => mapping(address => StakedToken)) stakedTokenData;
    /// @notice Account -> array of staked token addresses
    mapping(address => address[]) stakedTokens;
    // ======================= BORROW ===========================================================
    /// @notice Account -> token address -> borrowing data
    mapping(address => mapping(address => BorrowedToken)) borrowedTokenData;
    /// @notice Account -> array of borrowed token addressess
    mapping(address => address[]) borrowedTokens;
    /// @notice Protocol's borrowers
    address[] borrowers;
}

/* ======================================================= POINTER ======================================================= */

bytes32 constant ASSETS_STORAGE_POSITION = keccak256("martinivv.assets.storage");

/// @notice Used as a shared storage
/// @return ast Storage pointer to `AssetsState` struct
/// @dev Any operation involving `ast` will read from or write to **storage**
function a() pure returns (AssetsState storage ast) {
    bytes32 position = ASSETS_STORAGE_POSITION;

    assembly {
        ast.slot := position
    }
}

/* ======================================================= MODIFIERS ======================================================= */

/// @notice Includes modifiers shared across protocol's contracts
abstract contract AssetsModifiers {
    /* =========================================== DEPOSIT & BORROW =========================================== */

    /// @notice Checks if @param _tokenAddress is allowed and @param _tokenAmount is greater than 0
    /// @custom:security Zero value ERC20 transfers are terminated in the protocol
    modifier allowed(address _tokenAddress, uint256 _tokenAmount) {
        if (!a().allowedTokenData[_tokenAddress].isAllowed) {
            revert DomainErrors.TokenNotAllowed(msg.sender, _tokenAddress);
        }
        if (_tokenAmount == 0) revert DomainErrors.AmountShouldBePositive(msg.sender);
        _;
    }

    /// @notice Looks the @param _tokenAddress's collateral option to be enabled
    /// @custom:security When enabled, it is checked whether it is staked or not
    modifier enabledCollateral(address _tokenAddress) {
        if (!a().stakedTokenData[msg.sender][_tokenAddress].isCollateralOn) {
            revert DomainErrors.CollateralNotEnabled(msg.sender, _tokenAddress);
        }
        _;
    }

    /// @notice Looks the @param _collateralAddress to not be currently in use
    /// @custom:security The property `isCollateralInUse` is controlled in `BorrowFacet` and
    /// `RepayFacet`, the necessary checks are made
    modifier notInUseCollateral(address _collateralAddress) {
        if (!a().stakedTokenData[msg.sender][_collateralAddress].isStaked) {
            revert DomainErrors.TokenNotStaked(msg.sender, _collateralAddress);
        }
        if (a().stakedTokenData[msg.sender][_collateralAddress].isCollateralInUse) {
            revert DomainErrors.CollateralCurrentlyInUse();
        }
        _;
    }

    /* ================================================= REPAY ================================================ */

    /// @notice Looks @param _collateralAddress and @param _borrowedToken to be repayable
    /// @custom:security Checking the validity of the `_collateralAddress` is crucial for the
    /// protocol security, otherwise could lead to critical vulnerability
    modifier repayableCollateral(address _collateralAddress, address _borrowedToken) {
        if (a().borrowedTokenData[msg.sender][_borrowedToken].collateralAddress != _collateralAddress) {
            revert DomainErrors.CollateralMismatch();
        }
        if (!a().stakedTokenData[msg.sender][_collateralAddress].isCollateralInUse) {
            revert DomainErrors.CollateralNotInUse();
        }
        _;
    }

    /* ============================================== LIQUIDATION ============================================= */

    /// @notice Looks @param _borrower and @param _borrowedToken to be liquidatable
    modifier liquidatable(address _borrower, address _borrowedToken) {
        if (msg.sender == _borrower) revert DomainErrors.SelfLiquidationNotAllowed();
        if (!a().borrowedTokenData[_borrower][_borrowedToken].isBorrowed) {
            revert DomainErrors.TokenNotBorrowed(msg.sender, _borrowedToken);
        }
        _;
    }

    /* ================================================ GLOBAL ================================================ */

    /// @notice Looks @param _tokenAmount to be positive
    modifier positiveAmount(uint256 _tokenAmount) {
        if (_tokenAmount == 0) revert DomainErrors.AmountShouldBePositive(msg.sender);
        _;
    }
}
