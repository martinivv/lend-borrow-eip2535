/* eslint-disable @typescript-eslint/no-floating-promises */
import hre from "hardhat"
import { DeployResult } from "hardhat-deploy/types"
import { MToken } from "../../../types/typechain"
import { expect } from "../chai"

describe("MToken", () => {
    let tx: DeployResult, mToken: MToken

    beforeEach(async function () {
        tx = await hre.deploy("MToken")
        mToken = await hre.get("MToken")
    })

    describe("#Initialization-State", () => {
        it("sets correct owner", async function () {
            expect(await mToken.owner()).to.equal(hre.users.deployer.address)
        })

        it("emits `OwnerChanged` event", async function () {
            expect(tx).to.emit(mToken, "OwnerChanged")
        })

        it("mints tokens to the deployer", async function () {
            expect(tx).to.changeTokenBalance(mToken, hre.users.deployer.address, "10000000")
        })
    })
})
