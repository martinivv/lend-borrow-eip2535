import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import type { HardhatRuntimeEnvironment } from "hardhat/types/runtime"
import type { NetworkInfoMap } from "../../types/global"

/* ========================= Users ============================================================================== */

export const getUsers = async function (hre?: HardhatRuntimeEnvironment): Promise<Record<string, SignerWithAddress>> {
    if (!hre) hre = require("hardhat")

    return hre!.ethers.getNamedSigners()
}

/* ========================= Networks ============================================================================== */

// Be cautious when using it on a network with a lot of block reorgs, as lower value can produce inaccuracies
export const BLOCK_CONFIRMATIONS = 4

// Consider removing the hardcoded values and implementing a better solution.
// The current demo version of the protocol will be deployed only on one testnet;
// this will work just fine
export const NETWORKS: NetworkInfoMap = {
    sepolia: {
        daiUsd: "0x0d79df66BE487753B02D015Fb622DED7f0E9798d",
        linkUsd: "0x48731cF7e84dc94C5f84577882c14Be11a5B7456",
        // Values can be obtained at: https://docs.aave.com/developers/deployed-contracts/v3-testnet-addresses
        dai: "0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357",
        link: "0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5",
    },
}
