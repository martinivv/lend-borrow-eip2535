import fs from "fs"
import hre from "hardhat"
import { DeployResult } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { ContractAddressMap, IDiamondFile, ILogFile } from "../../types/global"

const { network, ethers, artifacts } = hre

/* ======================== Properties ================================================================ */

const isProduction = process.env.PRODUCTION?.toLowerCase() === "true"

const addressesFile = isProduction
    ? `deployments/_deployment_logs/${network.name}_addresses.json`
    : `deployments/_deployment_logs/${network.name}_staging_addresses.json`

export const diamondFile = isProduction
    ? `deployments/_deployment_logs/${network.name}_diamond.json`
    : `deployments/_deployment_logs/${network.name}_staging_diamond.json`

/* =================================== Methods =================================================================================== */

export const updateDeploymentLogs = async function (name: string, deployResult: DeployResult, isVerified?: boolean) {
    const path = (await artifacts.readArtifact(name)).sourceName

    const version = getContractVersion(path)

    updateAddress(name, deployResult.address)
    updateLog(name, version, {
        ADDRESS: deployResult.address,
        OPTIMIZER_RUNS: "600",
        TIMESTAMP: new Date(
            (await ethers.provider.getBlock(deployResult?.receipt?.blockNumber || "latest"))!.timestamp * 1000,
        )
            .toISOString()
            .replace("T", " ")
            .split(".")[0],
        CONSTRUCTOR_ARGS: (await ethers.getContractFactory(name)).interface.encodeDeploy(deployResult.args),
        VERIFIED: (isVerified || false).toString(),
    })
}

export const updateLog = (name: string, version: string, info: any) => {
    let data: ILogFile = {}
    try {
        data = JSON.parse(fs.readFileSync("deployments/_deployment_logs/deployment_details.json", "utf8")) as ILogFile
    } catch {}

    const type = isProduction ? "production" : "staging"

    if (!data[name]) {
        data[name] = {}
    }
    if (!data[name][network.name]) {
        data[name][network.name] = {}
    }
    if (!data[name][network.name][type]) {
        data[name][network.name][type] = {}
    }
    if (!data[name][network.name][type][version]) {
        data[name][network.name][type][version] = []
    }

    data[name][network.name][type][version].push(info)

    fs.writeFileSync("deployments/_deployment_logs/deployment_details.json", JSON.stringify(data, null, 2))
}

export const updateDiamond = async function (name: string[]) {
    for (let i = 0; i < name.length; i++) {
        const address = (await hre.get(name[i])).target
        const path = (await artifacts.readArtifact(name[i])).sourceName

        const version = getContractVersion(path)

        let data: IDiamondFile = {}
        try {
            data = JSON.parse(fs.readFileSync(diamondFile, "utf8")) as IDiamondFile
        } catch {}

        if (!data["Diamond"]) {
            data["Diamond"] = {
                Facets: {},
                InitialFund: {},
            }
        }

        data["Diamond"].Facets![name[i]] = {
            Address: address.toString(),
            Version: version || "",
        }

        fs.writeFileSync(diamondFile, JSON.stringify(data, null, 3))
    }
}

export const getContractVersion = (path: string): string => {
    const code = fs.readFileSync(path, "utf8")
    return code.split("@custom:version")[1].split("\n")[0].trim()
}

export const verify = async function (
    hre: HardhatRuntimeEnvironment,
    name: string,
    options?: { address?: string; args?: any[] },
) {
    if (network.live && process.env.ETHERSCAN_API_KEY) {
        console.log("\nInitializing the verification process...")

        try {
            await hre.run("verify:verify", {
                address: options?.address,
                constructorArguments: options?.args || [],
            })

            return true
        } catch (e: any) {
            if (e.toString().includes("already verified")) return true

            console.log(`> Failed to verify ${name} contract: ${e}`)
            return false
        }
    } else {
        return false
    }
}

const updateAddress = (name: string, address: string) => {
    let data: ContractAddressMap = {}
    try {
        data = JSON.parse(fs.readFileSync(addressesFile, "utf8")) as ContractAddressMap
    } catch {}

    data[name] = address

    fs.writeFileSync(addressesFile, JSON.stringify(data, null, 3))
}
