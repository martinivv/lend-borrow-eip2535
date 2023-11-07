/* eslint-disable @typescript-eslint/no-floating-promises */
import { Contract, ContractTransactionResponse } from "ethers"
import hre from "hardhat"
import { IERC20 } from "../../../types/typechain"
import { fixture } from "../_effects/fixtures"
import { runLiquidationPreconditions } from "../_effects/run"
import { expect } from "../chai"

describe("Domain", () => {
    fixture(["all"])

    // l = liquidation
    let dToken: IERC20,
        lScaledAmount: bigint,
        tx: ContractTransactionResponse | undefined,
        mock: Contract,
        lFacet: Contract

    before(async function () {
        lFacet = await hre.get("LiquidationFacet")
    })

    /* ============================================= METHODS ======================================================================================= */

    describe("#LiquidationFacet-Methods", () => {
        describe("#liquidate", () => {
            // =================== Pre =============================================
            beforeEach(async function () {
                ;({ dToken, lScaledAmount, tx } = await runLiquidationPreconditions(true))
            })

            // =================== Conditions =============================================
            it("emits event on liquidation", async function () {
                expect(tx).to.emit(lFacet, "Liquidation")
            })

            it("changes token balances", async function () {
                expect(tx).to.changeTokenBalances(
                    dToken,
                    [this.diamondAddr, hre.users.accOne.address],
                    [-lScaledAmount, lScaledAmount],
                )
            })

            it("changes the parallel data structures", async function () {
                const stakedTokenData = await hre.Diamond.getStakedTokens(this.deployer)
                const stakedTokens = (await hre.Diamond.getAccountData(this.deployer)).stakedTokens

                expect(stakedTokenData).to.be.lengthOf(0)
                expect(stakedTokens).to.be.lengthOf(0)
            })
        })
    })

    /* ============================================= ATTACK ======================================================================================= */

    describe("#LiquidationFacet-Attack", () => {
        let bToken: IERC20

        // =================== Pre =============================================
        beforeEach(async function () {
            ;({ bToken, dToken, mock } = await runLiquidationPreconditions())
        })

        // =================== Conditions =============================================
        it("reverts if self-liquidation is attempted", async function () {
            await expect(hre.Diamond.liquidate(this.deployer, bToken.target)).to.be.revertedWithCustomError(
                lFacet,
                "SelfLiquidationNotAllowed",
            )
        })

        it("reverts if the token is not borrowed by the user", async function () {
            await expect(
                hre.Diamond.connect(hre.users.accOne).liquidate(this.deployer, dToken.target),
            ).to.be.revertedWithCustomError(lFacet, "TokenNotBorrowed")
        })

        it("reverts if the user is not liquidatable", async function () {
            mock.updateAnswer(11)

            await expect(
                hre.Diamond.connect(hre.users.accOne).liquidate(this.deployer, bToken.target),
            ).to.be.revertedWithCustomError(lFacet, "NotLiquidatable")
        })
    })
})
