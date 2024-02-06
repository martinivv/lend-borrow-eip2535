import hre from "hardhat"
import { MToken } from "../../../types/typechain"
import { expect } from "../chai"

describe("MToken", () => {
    const random = hre.users.accOne.address

    let mToken: MToken

    beforeEach(async function () {
        await hre.deploy("MToken")
        mToken = await hre.get("MToken")
    })

    /* ================================================================= ATTACK ================================================================= */

    describe("#MToken-Attack", () => {
        describe("#mint", () => {
            it("reverts if someone other than the owner calls it", async function () {
                await expect(mToken.connect(hre.users.accOne).mint(random, 1)).to.be.revertedWithCustomError(
                    mToken,
                    "NotOwner",
                )
            })
        })

        describe("#burn", () => {
            it("reverts if someone other than the operator calls it", async function () {
                await expect(mToken.burn(random, 1)).to.be.revertedWithCustomError(mToken, "NotOperator")
            })
        })

        describe("#setOwner", () => {
            it("reverts if someone other than the owner calls it", async function () {
                await expect(mToken.connect(hre.users.accOne).setOwner(random)).to.be.revertedWithCustomError(
                    mToken,
                    "NotOwner",
                )
            })
        })

        describe("#setOperator", () => {
            it("reverts if someone other than the owner calls it", async function () {
                await expect(mToken.connect(hre.users.accOne).setOperator(random)).to.be.revertedWithCustomError(
                    mToken,
                    "NotOwner",
                )
            })
        })
    })
})
