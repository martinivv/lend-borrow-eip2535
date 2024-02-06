/* eslint-disable @typescript-eslint/no-floating-promises */
import { Contract, ContractTransactionResponse } from "ethers"
import hre from "hardhat"
import { IERC20 } from "../../../types/typechain"
import { parseAmount } from "../../utils/deploy/config"
import { fixture } from "../_effects/fixtures"
import { runBorrowPreconditions } from "../_effects/run"
import { expect } from "../chai"

describe("Domain", () => {
    fixture(["all"])

    // b = borrow
    let dToken: IERC20,
        bToken: IERC20,
        tx: ContractTransactionResponse | undefined,
        bScaledAmount: bigint,
        bFacet: Contract

    before(async function () {
        bFacet = await hre.get("BorrowFacet")
    })

    /* =============================================================== METHODS =============================================================== */

    describe("#BorrowFacet-Methods", () => {
        // ==================== Pre ================================================
        beforeEach(async function () {
            ;({ bToken, bScaledAmount, tx } = await runBorrowPreconditions(true))
        })

        describe("#OnFirst-borrow", () => {
            // ==================== Conditions ================================================
            it("emits event on borrow", async function () {
                expect(tx).to.emit(bFacet, "Borrow")
            })

            it("changes token balances", async function () {
                expect(tx).to.changeTokenBalances(
                    bToken,
                    [this.deployer, this.diamondAddr],
                    [bScaledAmount, -bScaledAmount],
                )
            })

            it("changes the parallel data structures", async function () {
                const borrowedTokenData = await hre.Diamond.getBorrowedTokens(this.deployer)
                const borrowedTokens = [...(await hre.Diamond.getAccountData(this.deployer)).borrowedTokens]

                expect(borrowedTokenData).to.be.lengthOf(1)
                expect(borrowedTokens).to.have.same.members([bToken.target])
            })

            it("adds the borrower to `borrowers`", async function () {
                const allBorrowers = [...(await hre.Diamond.getAllBorrowers())]

                expect(allBorrowers).to.have.same.members([this.deployer])
            })
        })

        describe("#OnSecond-borrow", async function () {
            // ==================== Pre ================================================
            beforeEach(async function () {
                ;({ dToken, bToken } = await runBorrowPreconditions(false, false))
                await hre.Diamond.borrow(dToken.target, bToken.target, 2)
            })

            // ==================== Conditions ================================================
            it("adds the amount", async function () {
                const borrowedTokenData = [...(await hre.Diamond.getBorrowedTokens(this.deployer))]

                expect(borrowedTokenData[0].amountBorrowed).to.equal("4")
            })

            it("keeps correct state of the parallel data structures", async function () {
                const borrowedTokenData = await hre.Diamond.getBorrowedTokens(this.deployer)
                const borrowedTokens = [...(await hre.Diamond.getAccountData(this.deployer)).borrowedTokens]

                expect(borrowedTokenData).to.be.lengthOf(1)
                expect(borrowedTokens).to.have.same.members([bToken.target])
            })

            it("keeps correct state of `borrowers[]`", async function () {
                const allBorrowers = [...(await hre.Diamond.getAllBorrowers())]

                expect(allBorrowers).to.have.same.members([this.deployer])
            })
        })
    })

    /* =============================================================== ATTACK =============================================================== */

    describe("#BorrowFacet-Attack", () => {
        describe("#borrow", () => {
            let mock: Contract

            // ==================== Pre ================================================
            before(async function () {
                mock = await hre.getAt("MockV3Aggregator", hre.tokens.mocks.TokenA)
            })

            beforeEach(async function () {
                ;({ dToken, bToken } = await runBorrowPreconditions())
                await hre.Diamond.turnOnCollateral(dToken.target)
            })

            // ==================== Conditions ================================================
            it("reverts if the collateral is not activated/token is not staked", async function () {
                // It's activated in the `beforeEach` hook
                await hre.Diamond.turnOffCollateral(dToken)

                await expect(hre.Diamond.borrow(dToken.target, bToken.target, 2)).to.be.revertedWithCustomError(
                    bFacet,
                    "CollateralNotEnabled",
                )
            })

            it("reverts if the borrowed token is not allowed", async function () {
                await expect(hre.Diamond.borrow(dToken.target, hre.tokens.notAllowed, 2)).to.be.revertedWithCustomError(
                    bFacet,
                    "TokenNotAllowed",
                )
            })

            it("reverts if the amount is not positive", async function () {
                await expect(hre.Diamond.borrow(dToken.target, bToken.target, 0)).to.be.revertedWithCustomError(
                    bFacet,
                    "AmountShouldBePositive",
                )
            })

            it("reverts in case of crypto crash, dToken's value in USD = 0", async function () {
                await mock.updateAnswer(0)

                await expect(hre.Diamond.borrow(dToken.target, bToken.target, 2)).to.be.revertedWithCustomError(
                    bFacet,
                    "AnswerShouldBePositiveNum",
                )
            })

            it("reverts in case of zero timestamp oracle response", async function () {
                await mock.updateRoundData(0, parseAmount("1", await dToken.decimals()), 0, 0)

                await expect(hre.Diamond.borrow(dToken.target, bToken.target, 2)).to.be.revertedWithCustomError(
                    bFacet,
                    "InvalidTime",
                )
            })

            it("reverts in case of stale oracle answer, > `answerStalenessThreshold`", async function () {
                await mock.updateRoundData(0, parseAmount("1", await dToken.decimals()), 1, 1)

                await expect(hre.Diamond.borrow(dToken.target, bToken.target, 1)).to.be.revertedWithCustomError(
                    bFacet,
                    "StalePrice",
                )
            })

            it("reverts if the amount cannot be borrowed", async function () {
                await expect(hre.Diamond.borrow(dToken.target, bToken.target, 4)).to.be.revertedWithCustomError(
                    bFacet,
                    "CannotBorrowAmount",
                )
            })
        })
    })
})
