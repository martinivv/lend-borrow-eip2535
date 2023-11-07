## Depositing

To stake tokens, ensure:

1. `tokenAddress` is an address of allowed ERC20 token.
2. `tokenAmount` is greater than zero.
3. Having a sufficient balance.

In return, you will receive an interest-bearing token (mToken) amount equivalent to the value of the staked
tokens in USD. For example, staking 10 DAI tokens (1 DAI = 1 $) will yield you 10 mTokens.

## After Depositing

The staked token's property `isCollateralOn` is set to `false`, allowing you to start earning interest on your deposit. If you wish to enable collateral for a token, you should call the `turnOnCollateral` function. To turn off (after repaying all debts, if any), you should call the `turnOffCollateral` function.

## Keep in mind

If a token is already staked, attempting to stake an additional amount will reset the `startAccumulatingDay` property.
