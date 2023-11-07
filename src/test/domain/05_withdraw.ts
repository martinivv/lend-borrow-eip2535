/* eslint-disable @typescript-eslint/no-floating-promises */
import { Contract, ContractTransactionResponse } from "ethers"
import hre from "hardhat"
import { IERC20 } from "../../../types/typechain"
import { fixture } from "../_effects/fixtures"
import { runWithdrawPreconditions } from "../_effects/run"
import { expect } from "../chai"

describe("Domain", () => {
    fixture(["all"])

    // w = withdraw
    let dToken: IERC20,
        wWholeAmount: bigint,
        tx: ContractTransactionResponse | undefined,
        mToken: Contract,
        wFacet: Contract

    before(async function () {
        wFacet = await hre.get("WithdrawFacet")
        mToken = await hre.get("MToken")
    })

    /* =============================================== METHODS ====================================================================================== */

    describe("#WithdrawFacet-Methods", () => {
        describe("#Whole-withdraw", () => {
            // ================= Pre ================================================
            beforeEach(async function () {
                ;({ dToken, wWholeAmount, tx } = await runWithdrawPreconditions())

                tx = await hre.Diamond.withdraw(dToken, 22)
            })

            // ================= Conditions ================================================
            it("emits event on withdraw", async function () {
                expect(tx).to.emit(wFacet, "Withdraw")
            })

            it("changes token balances", async function () {
                expect(tx).to.changeTokenBalances(
                    dToken,
                    [this.deployer, this.diamondAddr],
                    [wWholeAmount, -wWholeAmount],
                )
            })

            it("changes the parallel data structures", async function () {
                const stakedTokenData = await hre.Diamond.getStakedTokens(this.deployer)
                const stakedTokens = (await hre.Diamond.getAccountData(this.deployer)).stakedTokens

                expect(stakedTokenData).to.be.lengthOf(0)
                expect(stakedTokens).to.be.lengthOf(0)
            })

            it("burns MTokens", async function () {
                expect(tx).to.changeTokenBalances(
                    mToken,
                    [this.deployer, hre.ethers.ZeroAddress],
                    [-wWholeAmount, wWholeAmount],
                )
            })
        })

        describe("#Partial-withdraw", () => {
            let wPartialAmount: bigint

            // ================= Pre ================================================
            beforeEach(async function () {
                ;({ dToken, wPartialAmount, tx } = await runWithdrawPreconditions())

                tx = await hre.Diamond.withdraw(dToken, 11)
            })

            // ================= Conditions ================================================
            it("changes token balances", async function () {
                expect(tx).to.changeTokenBalances(
                    dToken,
                    [this.diamondAddr, this.deployer],
                    [-wPartialAmount, wPartialAmount],
                )
            })

            it("changes correctly the amount", async function () {
                const amountOnChain = [...(await hre.Diamond.getStakedTokens(this.deployer))][0].amountStaked

                expect(amountOnChain).to.be.equal("11")
            })

            it("keeps correct state of the parallel data structures", async function () {
                const stakedTokenData = await hre.Diamond.getStakedTokens(this.deployer)
                const stakedTokens = [...(await hre.Diamond.getAccountData(this.deployer)).stakedTokens]

                expect(stakedTokenData).to.be.lengthOf(1)
                expect(stakedTokens).to.have.same.members([dToken.target])
            })

            it("burns MTokens", async function () {
                expect(tx).to.changeTokenBalances(
                    mToken,
                    [this.deployer, hre.ethers.ZeroAddress],
                    [-wPartialAmount, wPartialAmount],
                )
            })
        })
    })

    /* =============================================== ATTACK ====================================================================================== */

    describe("#Withdraw-Attack", () => {
        describe("#withdraw", () => {
            // ================= Pre ================================================
            beforeEach(async function () {
                ;({ dToken } = await runWithdrawPreconditions())
            })

            // ================= Conditions ================================================
            it("reverts if the token is not staked", async function () {
                await expect(hre.Diamond.connect(hre.users.accOne).withdraw(dToken, 100)).to.be.revertedWithCustomError(
                    wFacet,
                    "TokenNotStaked",
                )
            })

            it("reverts if the token is in use", async function () {
                await hre.Diamond.turnOnCollateral(dToken.target)
                await hre.Diamond.borrow(dToken.target, dToken.target, 2)

                await expect(hre.Diamond.withdraw(dToken.target, 22)).to.be.revertedWithCustomError(
                    wFacet,
                    "CollateralCurrentlyInUse",
                )
            })

            it("reverts if the amount is not positive", async function () {
                await expect(hre.Diamond.withdraw(dToken.target, 0)).to.be.revertedWithCustomError(
                    wFacet,
                    "AmountShouldBePositive",
                )
            })

            it("executes with the correct amount if much larger amount is provided", async function () {
                tx = await hre.Diamond.withdraw(dToken.target, 10_000)
                const stakedTokenData = await hre.Diamond.getStakedTokens(this.deployer)
                const stakedTokens = (await hre.Diamond.getAccountData(this.deployer)).stakedTokens

                expect(tx).to.changeTokenBalances(
                    dToken,
                    [this.deployer, this.diamondAddr],
                    [wWholeAmount, -wWholeAmount],
                )
                expect(tx).to.changeTokenBalances(
                    mToken,
                    [this.deployer, hre.ethers.ZeroAddress],
                    [-wWholeAmount, wWholeAmount],
                )
                expect(stakedTokenData).to.be.lengthOf(0)
                expect(stakedTokens).to.be.lengthOf(0)
            })
        })
    })
})
