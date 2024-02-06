import hre from "hardhat"
import { IERC20 } from "../../types/typechain"
import { parseAmount } from "../utils/deploy/config"
import { addFund } from "../utils/scripts/addLog"

const fundMToken = async function () {
    const diamondDeployment = await hre.deployments.getOrNull("Diamond")
    if (!diamondDeployment) throw new Error(`No Diamond has been deployed on the ${hre.network.name} network.`)

    const mToken: IERC20 = await hre.ethers.getContract("MToken")
    const sentAmount = parseAmount("10000000", await mToken.decimals())

    console.log("Transfering MTokens to the protocol...")

    mToken.transfer(diamondDeployment.address, sentAmount).then(async function (result) {
        const receipt = await result.wait()

        if (!receipt?.status) throw new Error(`Transfer failed: ${result.hash}`)

        const balanceAfter = await mToken.balanceOf(diamondDeployment.address)
        await addFund("MToken", result.hash, sentAmount, balanceAfter)
    })
}

fundMToken()
    .then(() => {
        console.log("Success.")
        process.exit(0)
    })
    .catch(e => {
        console.log("Failed.")
        console.error(e)
        process.exit(1)
    })
