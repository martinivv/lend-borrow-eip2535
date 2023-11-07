import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { facets } from "../utils/deploy/config"
import { addOrReplaceFacets } from "../utils/diamondHelpers"
import { updateDeploymentLogs, updateDiamond, verify } from "../utils/logHelpers"

const exec: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    hre.log("#2.")
    /* =============================== Deployment ================================================================= */

    const contracts = []
    for (const facetName of facets) {
        const facet = await hre.deploy(facetName)
        contracts.push(await hre.get(facetName))

        const isVerified = await verify(hre, facetName, { address: facet.address })
        await updateDeploymentLogs(facetName, facet, isVerified)
    }

    /* =============================== Cut ================================================================= */

    await addOrReplaceFacets(contracts, hre.Diamond.target)

    // Saving for later use
    hre.DiamondDeployment.facets = (await hre.Diamond.facets()).map(f => ({
        facetAddress: f.facetAddress,
        functionSelectors: f.functionSelectors,
    }))
    await hre.deployments.save("Diamond", hre.DiamondDeployment)

    await updateDiamond(facets)

    hre.log("🟢 | Remaining facets were successfully deployed and cut into the diamond.\n")
}

exec.tags = ["all"]
exec.dependencies = ["diamond-base"]
export default exec
