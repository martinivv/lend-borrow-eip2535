/* eslint-disable @typescript-eslint/no-unused-vars */

import { HardhatRuntimeEnvironment } from "hardhat/types"
import type { TokenAddressMap } from "../../../types/global"
import { AllowedTokenStruct } from "../../../types/typechain/hardhat-diamond-abi/HardhatDiamondABI.sol/Martin"
import { addFacets, addOrReplaceFacets } from "../diamondHelpers"
import { updateDeploymentLogs, updateDiamond, verify } from "../logHelpers"
import { diamondBase, getAllowedTokensHre } from "./config"

export const runDiamondSetup = async function (hre: HardhatRuntimeEnvironment) {
    // ======================= Deployment =============================================
    for (const facetName of diamondBase) {
        const facet = await hre.deploy(facetName)
        const isVerified = await verify(hre, facetName, { address: facet.address })
        await updateDeploymentLogs(facetName, facet, isVerified)
    }

    // ======================= Tokens =============================================
    const mTokenAddress = (await hre.get("MToken")).target

    const allowedTokensHre = await getAllowedTokensHre()
    // Saving for later use
    hre.tokens = {
        MToken: mTokenAddress,
        allowedTokens: allowedTokensHre.reduce((acc: TokenAddressMap, t) => {
            acc[t.symbol] = t.tokenAddress
            return acc
        }, {}),
        notAllowed: "0x152649eA73beAb28c5b49B26eb48f7EAD6d4c898",
        mocks: allowedTokensHre.reduce((acc: TokenAddressMap, t) => {
            acc[t.symbol] = t.dataFeed
            return acc
        }, {}),
    }
    const allowedTokens = allowedTokensHre.map(({ symbol, ...rest }) => rest) as AllowedTokenStruct[]

    return { mTokenAddress, allowedTokens }
}

export const runDiamondCutting = async function (hre: HardhatRuntimeEnvironment) {
    const loupeFacet = await hre.get("DiamondLoupeFacet")
    const ownershipFacet = await hre.get("DiamondOwnershipFacet")

    try {
        await hre.Diamond.facets()
    } catch (e) {
        await addFacets([loupeFacet], hre.Diamond.target)
    }

    await addOrReplaceFacets([loupeFacet, ownershipFacet], hre.Diamond.target)
    await updateDiamond(["DiamondLoupeFacet", "DiamondOwnershipFacet"])

    // Saving... For getting artifact data
    hre.DiamondDeployment.facets = (await hre.Diamond.facets()).map(f => ({
        facetAddress: f.facetAddress,
        functionSelectors: f.functionSelectors,
    }))
    await hre.deployments.save("Diamond", hre.DiamondDeployment)
}
