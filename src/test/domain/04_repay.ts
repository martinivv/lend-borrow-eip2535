/* eslint-disable @typescript-eslint/no-floating-promises */
import { Contract, ContractTransactionResponse } from "ethers"
import hre from "hardhat"
import { IERC20 } from "../../../types/typechain"
import { fixture } from "../_effects/fixtures"
import { runRepayPreconditions } from "../_effects/run"
import { expect } from "../chai"

describe("Domain", () => {
    fixture(["all"])

    // r = repay
    let dToken: IERC20,
        bToken: IERC20,
        rWholeAmount: string,
        rPartialAmount: string,
        rFacet: Contract,
        tx: ContractTransactionResponse | undefined

    before(async function () {
        rFacet = await hre.get("RepayFacet")
    })

    /* =============================================================== METHODS =============================================================== */

    describe("#RepayFacet-Methods", () => {
        describe("#Whole-repay", () => {
            // ==================== Pre ===================================================
            beforeEach(async function () {
                ;({ dToken, bToken, rWholeAmount, tx } = await runRepayPreconditions())

                tx = await hre.Diamond.repay(dToken.target, bToken, 2)
            })

            // ==================== Conditions ===================================================
            it("emits event on repay", async function () {
                expect(tx).to.emit(rFacet, "Repay")
            })

            it("changes token balances", async function () {
                expect(tx).to.changeTokenBalances(
                    bToken,
                    [this.diamondAddr, this.deployer],
                    [rWholeAmount, -rWholeAmount],
                )
            })

            it("changes the parallel data structures", async function () {
                const borrowedTokenData = await hre.Diamond.getBorrowedTokens(this.deployer)
                const borrowedTokens = (await hre.Diamond.getAccountData(this.deployer)).borrowedTokens

                expect(borrowedTokenData).to.be.lengthOf(0)
                expect(borrowedTokens).to.be.lengthOf(0)
            })

            it("removes the address of the borrower from the `borrowers[]`", async function () {
                expect(await hre.Diamond.getAllBorrowers()).to.have.same.members([])
            })
        })

        describe("#Partial-repay", () => {
            // ==================== Pre ===================================================
            beforeEach(async function () {
                ;({ dToken, bToken, rPartialAmount, tx } = await runRepayPreconditions())

                tx = await hre.Diamond.repay(dToken.target, bToken, 1)
            })

            // ==================== Conditions ===================================================
            it("changes token balances", async function () {
                expect(tx).to.changeTokenBalances(
                    bToken,
                    [this.diamondAddr, this.deployer],
                    [rPartialAmount, -rPartialAmount],
                )
            })

            it("keeps the address in `borrowers[]`", async function () {
                const allBorrowers = [...(await hre.Diamond.getAllBorrowers())]

                expect(allBorrowers).to.have.same.members([this.deployer])
            })

            it("keeps correct state of the parallel data structures", async function () {
                const borrowedTokenData = await hre.Diamond.getBorrowedTokens(this.deployer)
                const borrowedTokens = [...(await hre.Diamond.getAccountData(this.deployer)).borrowedTokens]

                expect(borrowedTokenData).to.be.lengthOf(1)
                expect(borrowedTokens).to.have.same.members([bToken.target])
            })
        })
    })

    /* =============================================================== ATTACK =============================================================== */

    describe("#RepayFacet-Attack", () => {
        // ==================== Pre ===================================================
        beforeEach(async function () {
            ;({ dToken, bToken } = await runRepayPreconditions())
        })

        // ==================== Conditions ===================================================
        it("reverts if not the same collateral as on borrow is used", async function () {
            await expect(hre.Diamond.repay(bToken.target, bToken.target, 2)).to.be.revertedWithCustomError(
                rFacet,
                "CollateralMismatch",
            )
        })

        it("reverts if trying to repay a not borrowed token/not allowed token", async function () {
            await expect(hre.Diamond.repay(dToken.target, dToken.target, 2)).to.be.revertedWithCustomError(
                rFacet,
                "CollateralMismatch",
            )
        })

        it("reverts if the amount is not positive", async function () {
            await expect(hre.Diamond.repay(dToken.target, bToken.target, 0)).to.be.revertedWithCustomError(
                rFacet,
                "AmountShouldBePositive",
            )
        })

        it("reverts if the caller doesn't have enough funds", async function () {
            await bToken.transfer(hre.users.accOne.address, await bToken.balanceOf(this.deployer))

            await expect(hre.Diamond.repay(dToken.target, bToken.target, 2)).to.be.revertedWithCustomError(
                rFacet,
                "InsufficientTokenAmount",
            )
        })
    })
})
