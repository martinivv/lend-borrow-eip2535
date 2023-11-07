import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
// Many conflicts occurred when a relative path was used. Intentionally are not
// added to prevent a potential error during compilation
import { Martin } from "../../types/typechain"
import { runDiamondCutting, runDiamondSetup } from "../utils/deploy/run"
import { updateDeploymentLogs, updateDiamond, verify } from "../utils/logHelpers"

const exec: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    hre.log("\n#1.")
    /* ============================ SETUP =================================================================================== */

    const { mTokenAddress, allowedTokens } = await runDiamondSetup(hre)

    /* ============================ DEPLOYMENT =================================================================================== */

    const diamondInit = await hre.get("DiamondInit")
    const calldata = diamondInit.interface.encodeFunctionData("init", [
        {
            mTokenAddress,
            allowedTokens,
        },
    ])
    const diamondCutFacet = await hre.get("DiamondCutFacet")

    const deployment = await hre.deploy("Diamond", {
        args: [
            { owner: hre.users.deployer.address, diamondInit: diamondInit.target, data: calldata },
            diamondCutFacet.target,
        ],
    })

    const isVerified = await verify(hre, "Diamond", {
        address: deployment.address,
        args: [
            { owner: hre.users.deployer.address, diamondInit: diamondInit.target, data: calldata },
            diamondCutFacet.target,
        ],
    })
    await updateDeploymentLogs("Diamond", deployment, isVerified)
    await updateDiamond(["DiamondCutFacet"])

    // Setting the operator
    await hre.getAt("MToken", mTokenAddress).then(async result => await result.setOperator(deployment.address))

    // Saving for later use
    hre.DiamondDeployment = deployment
    // 👇 is for getting data on-chain
    hre.Diamond = (await hre.getAt("Martin", deployment.address)) as unknown as Martin

    /* ============================ CUT =================================================================================== */

    await runDiamondCutting(hre)

    hre.log("🟢 | The Diamond base process was successfully completed.\n")
}

exec.tags = ["diamond-base"]
export default exec
