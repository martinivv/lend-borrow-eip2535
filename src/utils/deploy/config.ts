import { Addressable, BigNumberish, Numeric } from "ethers"
import hre from "hardhat"
import { NETWORKS } from "../../utils/global"

export const diamondBase = ["DiamondInit", "DiamondCutFacet", "DiamondLoupeFacet", "DiamondOwnershipFacet", "MToken"]

export const facets = [
    "DepositFacet",
    "BorrowFacet",
    "RepayFacet",
    "WithdrawFacet",
    "LiquidationFacet",
    "OwnerFacet",
    "UIDataFacet",
]

export const getAllowedTokensHre = async function () {
    const { network } = hre

    let tokens
    if (!network.live) {
        const tokenA = await hre.deploy("TokenA")
        const mockA = await hre.deploy("MockV3Aggregator", { args: [8, 1 * 1e8] })
        const tokenB = await hre.deploy("TokenB")
        const mockB = await hre.deploy("MockV3Aggregator", { args: [8, 10 * 1e8] })

        hre.log("> All mocks have been successfully deployed.")

        tokens = [
            createConfig(toBPs(10), toBPs(5), toBPs(5), toBPs(90), true, tokenA.address, mockA.address, "TokenA"),
            createConfig(toBPs(15), toBPs(10), toBPs(15), toBPs(80), true, tokenB.address, mockB.address, "TokenB"),
        ]
    } else {
        tokens = [
            createConfig(
                toBPs(10),
                toBPs(5),
                toBPs(5),
                toBPs(90),
                true,
                NETWORKS[network.name].dai,
                NETWORKS[network.name].daiUsd,
                "DAI",
            ),
            createConfig(
                toBPs(15),
                toBPs(10),
                toBPs(15),
                toBPs(80),
                true,
                NETWORKS[network.name].link,
                NETWORKS[network.name].linkUsd,
                "LINK",
            ),
        ]
    }

    return tokens
}

/* ======================================================= BUILDERS ======================================================= */

export const createConfig = (
    stakeStableRate: BigNumberish,
    borrowStableRate: BigNumberish,
    ltv: BigNumberish,
    liquidationThreshold: BigNumberish,
    isAllowed: boolean,
    tokenAddress: string | Addressable,
    dataFeed: string | Addressable,
    symbol: string,
) => {
    return {
        stakeStableRate,
        borrowStableRate,
        ltv,
        liquidationThreshold,
        isAllowed,
        tokenAddress,
        dataFeed,
        symbol,
    }
}

// Converts percentage to Basis Points. 1000 basis points = 10 %
export const toBPs = (percentage: number) => percentage * 100

export const parseAmount = (value: string, unit: string | Numeric | undefined) => hre.ethers.parseUnits(value, unit)
