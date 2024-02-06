import { BaseContract } from "ethers"
import hre from "hardhat"
import { fixture } from "../_effects/fixtures"
import { expect } from "../chai"

describe("Diamond", () => {
    fixture(["diamond-base"])

    let facet: BaseContract

    before(async function () {
        facet = await hre.get("DiamondOwnershipFacet")
    })

    /* =========================================================== METHODS =========================================================== */

    describe("#OwnershipFacet", () => {
        it("sets a new owner", async function () {
            const newOwner = hre.users.accOne.address

            await hre.Diamond.transferOwnership(newOwner)

            expect(await hre.Diamond.owner()).to.equal(newOwner)
        })
    })

    /* =========================================================== ATTACK =========================================================== */

    describe("#OwnershipFacet-Attack", () => {
        it("reverts if the address of the new owner is the zero address", async function () {
            await expect(hre.Diamond.transferOwnership(hre.ethers.ZeroAddress)).to.be.revertedWithCustomError(
                facet,
                "NoZeroAddressOwner",
            )
        })

        it("reverts if someone other than the owner calls it", async function () {
            await expect(
                hre.Diamond.connect(hre.users.accOne).transferOwnership(hre.users.accTwo.address),
            ).to.be.revertedWithCustomError(facet, "MustBeDiamondOwner")
        })
    })
})
