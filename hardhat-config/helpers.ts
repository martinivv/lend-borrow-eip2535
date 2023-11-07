import { HardhatUserConfig, NetworksUserConfig, SolidityUserConfig } from "hardhat/types"

/* ==================== Users ============================================================== */

export const accounts = {
    deployer: {
        default: 0,
    },
    accOne: {
        default: 1,
    },
    accTwo: {
        default: 2,
    },
}

export const users: HardhatUserConfig["namedAccounts"] = accounts

/* ==================== Compilers ============================================================== */

export const compilers: SolidityUserConfig = {
    version: "0.8.20",
    settings: {
        metadata: {
            bytecodeHash: "none",
        },
        optimizer: {
            enabled: false,
            runs: 600,
        },
    },
}

/* ==================== Networks ============================================================== */

export const networks = (/* PRIVATE_KEY: string */): NetworksUserConfig => ({
    sepolia: {
        // 👇!
        url: "",
        chainId: 11155111,
        // accounts: [PRIVATE_KEY],
        live: true,
    },
})
