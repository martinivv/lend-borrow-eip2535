/* eslint-disable @typescript-eslint/no-floating-promises */
import { Contract, ContractTransactionResponse } from "ethers"
import hre from "hardhat"
import { IERC20 } from "../../../types/typechain"
import { fixture } from "../_effects/fixtures"
import { runDepositPreconditions } from "../_effects/run"
import { expect } from "../chai"

describe("Domain", () => {
    fixture(["all"])

    // d = deposit
    let dToken: IERC20,
        dScaledAmount: bigint,
        tx: ContractTransactionResponse | undefined,
        dFacet: Contract,
        mToken: Contract

    before(async function () {
        dFacet = await hre.get("DepositFacet")
        mToken = await hre.get("MToken")
    })

    /* ============================================= METHODS ====================================================================================== */

    describe("#DepositFacet-Methods", () => {
        // =================== Pre ===============================================
        beforeEach(async function () {
            ;({ dToken, dScaledAmount, tx } = await runDepositPreconditions())
        })

        // =================== Conditions ===============================================
        describe("#OnFirst-deposit", () => {
            it("emits event on deposit", async function () {
                expect(tx).to.emit(dFacet, "Deposit")
            })

            it("changes token balances", async function () {
                expect(tx).to.changeTokenBalances(
                    dToken,
                    [this.deployer, this.diamondAddr],
                    [-dScaledAmount, dScaledAmount],
                )
            })

            it("changes the parallel data structures", async function () {
                const stakedTokenData = await hre.Diamond.getStakedTokens(this.deployer)
                const stakedTokens = [...(await hre.Diamond.getAccountData(this.deployer)).stakedTokens]

                expect(stakedTokenData).to.be.lengthOf(1)
                expect(stakedTokens).to.have.same.members([dToken.target])
            })

            it("sends MTokens", async function () {
                expect(tx).to.changeTokenBalances(
                    mToken,
                    [this.diamondAddr, this.deployer],
                    [-dScaledAmount, dScaledAmount],
                )
            })
        })

        describe("#OnSecond-deposit", () => {
            // =================== Pre ===============================================
            beforeEach(async function () {
                ;({ dToken, dScaledAmount, tx } = await runDepositPreconditions(false))
            })

            // =================== Conditions ===============================================
            it("changes the deposited amount", async function () {
                const amountOnChain = Array.from(await hre.Diamond.getStakedTokens(this.deployer))[0].amountStaked

                expect(amountOnChain).to.equal("44")
            })

            it("keeps correct state of the parallel data structures", async function () {
                const stakedTokenData = await hre.Diamond.getStakedTokens(this.deployer)
                const stakedTokens = [...(await hre.Diamond.getAccountData(this.deployer)).stakedTokens]

                expect(stakedTokenData).to.be.lengthOf(1)
                expect(stakedTokens).to.have.same.members([dToken.target])
            })

            it("sends MTokens", async function () {
                expect(tx).to.changeTokenBalances(
                    mToken,
                    [this.diamondAddr, this.deployer],
                    [-dScaledAmount, dScaledAmount],
                )
            })
        })

        describe("#turnOnCollateral", () => {
            // =================== Pre ===============================================
            beforeEach(async function () {
                tx = await hre.Diamond.turnOnCollateral(dToken.target)
            })

            // =================== Conditions ===============================================
            it("emits event on activation", async function () {
                expect(tx).to.emit(dFacet, "CollateralOn")
            })

            it("changes token's property `isCollateralOn` to `true`", async function () {
                const onChainResult = Array.from(await hre.Diamond.getStakedTokens(this.deployer))[0].isCollateralOn

                expect(onChainResult).to.be.true
            })
        })

        describe("#turnOffCollateral", () => {
            // =================== Pre ===============================================
            beforeEach(async function () {
                await hre.Diamond.turnOnCollateral(dToken.target)
                tx = await hre.Diamond.turnOffCollateral(dToken.target)
            })

            // =================== Conditions ===============================================
            it("emits event on deactivation", async function () {
                expect(tx).to.emit(dFacet, "CollateralOff")
            })

            it("changes token's property `isCollateralOn` to `false`", async function () {
                const onChainResult = Array.from(await hre.Diamond.getStakedTokens(this.deployer))[0].isCollateralOn

                expect(onChainResult).to.be.false
            })
        })
    })

    /* ============================================= ATTACK ====================================================================================== */

    describe("#DepositFacet-Attack", () => {
        // =================== Pre ===============================================
        beforeEach(async function () {
            dToken = await hre.get("TokenA")
        })

        // =================== Conditions ===============================================
        describe("#deposit", () => {
            it("reverts on a not allowed token", async function () {
                await expect(hre.Diamond.deposit(hre.tokens.notAllowed, 11)).to.be.revertedWithCustomError(
                    dFacet,
                    "TokenNotAllowed",
                )
            })

            it("reverts on a not positive amount", async function () {
                await expect(hre.Diamond.deposit(hre.tokens.allowedTokens.TokenA, 0)).to.be.revertedWithCustomError(
                    dFacet,
                    "AmountShouldBePositive",
                )
            })

            it("reverts if the caller doesn't have enough funds", async function () {
                await dToken.connect(hre.users.accOne).approve(this.diamondAddr, dScaledAmount)

                await expect(hre.Diamond.connect(hre.users.accOne).deposit(dToken.target, 11)).to.be.reverted
            })

            it("reverts if there are not enough MTokens in the protocol", async function () {
                await dToken.approve(this.diamondAddr, dScaledAmount)

                await expect(hre.Diamond.deposit(dToken.target, 11)).to.be.revertedWithCustomError(
                    dFacet,
                    "NotEnoughTokensInExistence",
                )
            })
        })

        describe("#turnOnCollateral", () => {
            it("reverts if the token is not staked", async function () {
                await expect(hre.Diamond.turnOnCollateral(dToken.target)).to.be.revertedWithCustomError(
                    dFacet,
                    "TokenNotStaked",
                )
            })

            it("reverts if the token is already with activated collateral", async function () {
                await runDepositPreconditions()
                await hre.Diamond.turnOnCollateral(dToken.target)

                await expect(hre.Diamond.turnOnCollateral(dToken.target)).to.be.revertedWithCustomError(
                    dFacet,
                    "CollateralAlreadyOn",
                )
            })
        })

        describe("#turnOffCollateral", () => {
            // =================== Pre ===============================================
            beforeEach(async function () {
                await runDepositPreconditions()
            })

            // =================== Conditions ===============================================
            it("reverts if the token is not staked", async function () {
                await expect(hre.Diamond.turnOffCollateral(dToken.target)).to.be.revertedWithCustomError(
                    dFacet,
                    "CollateralNotEnabled",
                )
            })

            it("reverts if the token is not with activated collateral", async function () {
                await expect(hre.Diamond.turnOffCollateral(dToken.target)).to.be.revertedWithCustomError(
                    dFacet,
                    "CollateralNotEnabled",
                )
            })

            it("reverts if the collateral is in use", async function () {
                await hre.Diamond.turnOnCollateral(dToken.target)
                await hre.Diamond.borrow(dToken.target, (await hre.get("TokenB")).target, 2)

                await expect(hre.Diamond.turnOffCollateral(dToken.target)).to.be.revertedWithCustomError(
                    dFacet,
                    "CollateralCurrentlyInUse",
                )
            })
        })
    })
})
