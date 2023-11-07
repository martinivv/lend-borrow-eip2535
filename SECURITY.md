Most of the security considerations have been documented in the inline documentation. However, some trivial ones have not been documented.

## If futher developed, keep in mind:

1. Be cautious when adding tokens. A well-designed, secure transfer abstraction (for example) can be somewhat helpful. However, it's important to note that the existence of Tether Gold can make it challenging to handle return values for all tokens accurately.
2. The financial aspect of the protocol is not foolproof; it adheres only to common financial principles. Develop a solid, foolproof business model.
3. The interest-bearing token. It’s value is the intrinsic value of the protocol. Consider enabling more than just one interest-bearing token for various staked tokens, depending on different parameters such as risk and intrinsic value.
4. In the current version, the _owner_ represents a single point of failure.
5. Consider not using tokens with _fee-on-transfer_ (possibly in the future: USDT, USDC) or handle them correctly.
6. Be aware of the behavior of upgradable tokens when adding more allowed tokens.
7. Minting mTokens to the creator in the contract's constructor creates centralization risk; if related logic is created.
8. Non-standard ERC20 tokens can lead to inaccuracies, wrong calculations, loss of funds. Less than 6 decimals most of the
   times lead to a lot of troubles.
9. Include a protocol pause mechanism in case of exploit, crypto crash, or unexpected situation.
10. Implement more financial metrics for a robust financial aspect, better protocol health.
11. Consider adding a governance token.
12. Better token amount compatibility.
13. Better network managing/handling; remove the hardcoded values.
14. Implement better access control — roles.
15. Consider upgrading the mToken.
16. Integrate more data feed oracles.
17. Vault implementation (EIP-4626).
18. Pools.
19. Foundry.
20. Enhance the tests, include more edge cases.
21. And many more, the field for improvement is enormous.
