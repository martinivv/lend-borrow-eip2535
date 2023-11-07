import type { HardhatUserConfig } from "hardhat/config"

// ================= PLUGINS ===========================================================
// 👇 plugin should be placed before TypeChain
import "hardhat-diamond-abi"
import "@nomicfoundation/hardhat-toolbox"
import "@nomiclabs/hardhat-ethers"
import "hardhat-deploy"

// ================= DOTENV ===========================================================
import { config as dotenvConfig } from "dotenv"
dotenvConfig({ path: __dirname + "/.env" })

// const PRIVATE_KEY = process.env.PRIVATE_KEY
// if (!PRIVATE_KEY) throw new Error("The private key isn't set.")

// ================= EXTENSIONS ===========================================================
import "./hardhat-config/extensions"

// ================= HELPERS ===========================================================
import { compilers, networks, users } from "./hardhat-config/helpers"

// ================= CONFIGURATION ===========================================================
const outDir = "types/typechain"

const config: HardhatUserConfig = {
    solidity: compilers,
    networks: networks(/* PRIVATE_KEY */),
    namedAccounts: users,
    paths: {
        sources: "./src/contracts",
        deploy: "src/deploy",
        deployments: "deployments",
        tests: "./src/test",
        cache: "./build/cache",
        artifacts: "./build/artifacts",
    },
    diamondAbi: {
        name: "Martin",
        include: ["facets/*"],
        exclude: ["interfaces/*", "test/*", "vendor"],
        strict: false,
    },
    typechain: {
        outDir,
        target: "ethers-v6",
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
}

export default config
