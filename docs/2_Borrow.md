## Before Borrowing

Make sure that you can borrow the desired amount of tokens. The `getMaxUsdToBorrow` function (or a related one in the future) will be in help.

## Borrowing

To borrow tokens, ensure:

1. The collateral property for `_collateralAddress` is enabled.
2. `tokenAddress` is the address of an allowed ERC20 token.
3. `_tokenAmount` is greater than zero and falls within the appropriate range.

## After Borrowing

1. The collateral will be _locked_ and won't be withdrawable.
2. You can be subject to liquidation.

## Keep in mind

If a token is borrowed multiple times beyond the first, the originally used collateral should remain unchanged; the `startAccumulatingDay` property won't be reset.
