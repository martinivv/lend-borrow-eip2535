// SPDX-License-Identifier: MIT
// solhint-disable one-contract-per-file

pragma solidity =0.8.20;

import {IDiamondCutFacet} from "../diamond/interfaces/IDiamondCutFacet.sol";

/// @title DiamondEvents
/// @notice Events used all around the Diamond logic
library DiamondEvents {
    /// @notice Emitted on a successful cut
    event DiamondCut(IDiamondCutFacet.FacetCut[] _diamondCut, address _init, bytes _calldata);
}

/// @title DomainEvents
/// @notice Events used all around the Domain logic
library DomainEvents {
    /// @notice Emitted on a successful deposit/stake in the protocol
    event Deposit(address _depositedToken, uint256 _depositedAmount, address indexed _depositor);
    /// @notice Emitted on a successful collateral activation
    event CollateralOn(address _tokenAddress, address _depositor);
    /// @notice Emitted on a successful collateral deactivation
    event CollateralOff(address _tokenAddress, address _depositor);
    /// @notice Emitted on a successful borrow from the protocol
    event Borrow(address borrowedToken, uint256 _borrowedAmount, address indexed _borrower);
    /// @notice Emitted on a successful repayment to the protocol
    event Repay(address borrowedToken, uint256 _repayedAmount, address indexed _borrower);
    /// @notice Emitted on a successful withdrawal from the protocol
    event Withdraw(address token, uint256 amount, address indexed _depositor);
    /// @notice Emitted on a successful liquidation
    event Liquidation(address indexed _borrower, address indexed borrowedToken, uint256 keeperReward, address _keeper);
}
