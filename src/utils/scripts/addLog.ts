import fs from "fs"
import hre from "hardhat"
import { IDiamondFile } from "../../../types/global"
import { diamondFile, getContractVersion } from "../logHelpers"

export const addFund = async function (name: string, hash: string, sentAmount: bigint, balanceAfter: bigint) {
    let data: IDiamondFile = {}
    try {
        data = JSON.parse(fs.readFileSync(diamondFile, "utf8")) as IDiamondFile
    } catch {}

    const path = (await hre.artifacts.readArtifact(name)).sourceName
    const version = getContractVersion(path)

    data["Diamond"].InitialFund![name] = {
        SentAmount: sentAmount.toString(),
        BalanceAfter: balanceAfter.toString(),
        Version: version,
        TxHash: hash,
    }

    fs.writeFileSync(diamondFile, JSON.stringify(data, null, 3))
}
