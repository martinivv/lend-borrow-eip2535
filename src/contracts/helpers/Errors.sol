// solhint-disable one-contract-per-file

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IAggregatorV3} from "../domain/interfaces/IAggregatorV3.sol";

/// @title DiamondErrors
/// @notice Errors used all around the Diamond logic
library DiamondErrors {
    error FunctionDoesNotExist();
    error TooManyFunctionsInAFacet();
    error NoZeroAddressOwner();
    error NoSelectorFound();
    error FunctionAlreadyExists();
    error ImmutableFunctionDetected();
    error CannotReplaceTheSameFunction();
    error MustBeZeroAddress(address _newFacetAddress);
    error IncorrectFacetCutAction(uint8 _actionNum);
    error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);
    error MustBeDiamondOwner(address _caller);
    error TransferFailed();
}

/// @title DomainErrors
/// @notice Errors used all around the Domain logic
/// @custom:advice Use distinct naming for the errors if your error monitoring model requires it
library DomainErrors {
    // =============== Protocol ========================================
    error ReentrantCall();
    // =============== Deposit ========================================
    error TokenNotAllowed(address _caller, address _tokenAddress);
    error AmountShouldBePositive(address _caller);
    error NotEnoughTokensInExistence();
    error TokenNotStaked(address _caller, address _tokenAddress);
    error CollateralAlreadyOn();
    error CollateralNotEnabled(address _caller, address _tokenAddress);
    error CollateralCurrentlyInUse();
    // =============== Borrow ========================================
    error NoAmountAvailable();
    error CannotBorrowAmount(address _caller, uint256 maxAmountToBorrowInUsd, uint256 amountToBeBorrowedInUsd);
    error InsufficientProtocolFunds();
    error CollateralMismatch();
    // =============== Repay ========================================
    error TokenNotBorrowed(address _caller, address _tokenAddress);
    error CollateralNotInUse();
    error InsufficientTokenAmount();
    error Error404();
    error TokenAlreadyThere();
    error NoTokensFound();
    // =============== Liquidation ========================================
    error SelfLiquidationNotAllowed();
    error NotLiquidatable(address _caller);
    // =============== LibCalculator ========================================
    error AnswerShouldBePositiveNum(uint80 roundId, int256 answer);
    error InvalidTime(uint80 roundId, uint256 updatedAt);
    error StalePrice(uint80 roundId);
    error OracleNotAvailable(IAggregatorV3 dataFeed);
    // =============== UI ========================================
    error UI__TokenNotAllowed(address _caller, address _tokenAddress);
}
