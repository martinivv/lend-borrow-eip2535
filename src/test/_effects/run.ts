import { ContractTransactionResponse } from "ethers"
import hre from "hardhat"
import { IERC20 } from "../../../types/typechain"
import { parseAmount } from "../../utils/deploy/config"

/* ======================================= PARAMETERS =================================================================================== */

let tx: ContractTransactionResponse

const dScaledAmount = parseAmount("22", 18)
const bScaledAmount = parseAmount("2", 18)

// After calculating, based on the token and the formula in `LibRepay`:
const rWholeAmount = "2000547945205479452"
const rPartialAmount = "1000273972602739726"

const wWholeAmount = parseAmount("22", 18)
const wPartialAmount = parseAmount("11", 18)

const lScaledAmount = parseAmount("1", 18)

/* ======================================= RUN =================================================================================== */

const fund = async function (fund: boolean = true) {
    if (fund) {
        await hre
            .getAt("MToken", hre.tokens.MToken)
            .then(async result => result.transfer(hre.Diamond.target, parseAmount("10000000", await result.decimals())))

        await hre
            .getAt("TokenA", hre.tokens.allowedTokens.TokenA)
            .then(async result => result.transfer(hre.Diamond.target, parseAmount("1000", await result.decimals())))

        await hre
            .getAt("TokenB", hre.tokens.allowedTokens.TokenB)
            .then(async result => result.transfer(hre.Diamond.target, parseAmount("1000", await result.decimals())))
    }
}

// ============================== DEPOSIT ==========================================================

export const runDepositPreconditions = async function (callFund?: boolean) {
    const dToken: IERC20 = await hre.get("TokenA")

    await fund(callFund)
    await dToken.approve(hre.Diamond.target, dScaledAmount)
    const tx = await hre.Diamond.deposit(dToken.target, 22)

    return { dToken, dScaledAmount, tx }
}

// ============================== BORROW ==========================================================

export const runBorrowPreconditions = async function (callBorrow: boolean = false, callFund?: boolean) {
    const bToken: IERC20 = await hre.get("TokenB")

    const { dToken } = await runDepositPreconditions(callFund)
    if (callBorrow) {
        await hre.Diamond.turnOnCollateral(dToken.target)
        tx = await hre.Diamond.borrow(dToken.target, bToken.target, 2)
    }

    return { bToken, bScaledAmount, dToken, tx }
}

// ============================== REPAY ==========================================================

export const runRepayPreconditions = async function (callRepay: boolean = false, callFund?: boolean) {
    const bToken: IERC20 = await hre.get("TokenB")

    const { dToken } = await runBorrowPreconditions(true, callFund)
    await bToken.approve(hre.Diamond.target, dScaledAmount)
    if (callRepay) tx = await hre.Diamond.repay(dToken.target, bToken, 2)

    return { bToken, dToken, rWholeAmount, rPartialAmount, tx }
}

// ============================== WITHDRAW ==========================================================

export const runWithdrawPreconditions = async function (callWithdraw: boolean = false, callFund?: boolean) {
    const dToken: IERC20 = await hre.get("TokenA")

    await runDepositPreconditions(callFund)
    if (callWithdraw) tx = await hre.Diamond.withdraw(dToken, 22)

    return { dToken, wWholeAmount, wPartialAmount, tx }
}

// ============================== LIQUIDATION ==========================================================

export const runLiquidationPreconditions = async function (callLiquidate: boolean = false) {
    const mock = await hre.getAt("MockV3Aggregator", hre.tokens.mocks.TokenB)

    const { dToken, bToken } = await runBorrowPreconditions(true)
    await mock.updateAnswer(15 * 1e8)
    if (callLiquidate) {
        tx = await hre.Diamond.connect(hre.users.accOne).liquidate(hre.users.deployer.address, bToken.target)
    }

    return { dToken, tx, lScaledAmount, bToken, mock }
}
