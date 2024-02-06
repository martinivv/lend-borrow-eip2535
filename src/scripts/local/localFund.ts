import hre from "hardhat"
import { IERC20 } from "../../../types/typechain"
import { parseAmount } from "../../utils/deploy/config"
import { addFund } from "../../utils/scripts/addLog"

export const localFund = async function () {
    if (hre.network.live) throw new Error("Trying to use a local script on a live network.")

    /* ========================================== ALLOWED TOKENS FUND ========================================= */

    const tokenA: IERC20 = await hre.get("TokenA")
    const tokenB: IERC20 = await hre.get("TokenB")
    const tokenContracts = [tokenA, tokenB]

    hre.log("Transfering allowed tokens to the protocol...")

    for (let i = 0; i < tokenContracts.length; i++) {
        const sentAmount = parseAmount("10000", await tokenContracts[i].decimals())

        tokenContracts[i].transfer(hre.Diamond.target, sentAmount).then(async function (result) {
            const receipt = await result.wait()

            if (!receipt?.status) throw new Error(`Transfer failed: ${result.hash}`)

            const balanceAfter = await tokenContracts[i].balanceOf(hre.Diamond.target)
            await addFund(await tokenContracts[i].name(), result.hash, sentAmount, balanceAfter)
        })
    }

    hre.log("Success.")

    /* ============================================== MTOKEN FUND ============================================= */

    const mToken: IERC20 = await hre.get("MToken")
    const sentAmount = parseAmount("10000", await mToken.decimals())

    hre.log("Transfering MTokens to the protocol...")

    mToken.transfer(hre.Diamond.target, sentAmount).then(async function (result) {
        const receipt = await result.wait()

        if (!receipt?.status) throw new Error(`Transfer failed: ${result.hash}`)

        const balanceAfter = await mToken.balanceOf(hre.Diamond.target)
        await addFund("MToken", result.hash, sentAmount, balanceAfter)
    })
}
