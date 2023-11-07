import hre from "hardhat"
import { IDiamondLoupeFacet } from "../../../types/typechain"
import { fixture } from "../_effects/fixtures"
import { expect } from "../chai"

describe("Domain", () => {
    fixture(["all"])

    describe("#Initialization-Structure", () => {
        let facetsOnChain: IDiamondLoupeFacet.FacetStructOutput[]

        // ================= Preconditions =========================================
        beforeEach(async function () {
            facetsOnChain = [...(await hre.Diamond.facets())]
        })

        // ================= Conditions =========================================
        it("sets standard facet addresses", async function () {
            const facetAddressesOnChain = facetsOnChain.map(f => f.facetAddress)
            const facetAddressesOnArtifact = this.facets.map(f => f.facetAddress)

            expect(facetAddressesOnChain).to.have.same.members(facetAddressesOnArtifact)
        })

        it("sets selectors of standard facets", async function () {
            const facetSelectorsOnChain = facetsOnChain.flatMap(f => f.functionSelectors)
            const facetSelectorsOnArtifact = this.facets.flatMap(f => f.functionSelectors)

            expect(facetSelectorsOnChain).to.have.same.members(facetSelectorsOnArtifact)
        })
    })
})
