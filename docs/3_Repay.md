## Repaying

To repay tokens, ensure:

1. Using the same `_collateralAddress` as you did when borrowing.
2. `tokenAddress` is the borrowed token and that you want to repay.
3. `_tokenAmount` is greater than 0.
4. You have sufficient funds to cover the interest for borrowing: **days being borrowed × (amount × token’s borrow stable rate) / days per year**.

## After Repaying

By doing so, you will reduce your debt and lower the risk of liquidation (if not completely).

## Keep in mind

If the `startAccumulatingDay` property for the borrowed token is set to the current day, it will automatically be considered as 1 day for the repayment calculations.
