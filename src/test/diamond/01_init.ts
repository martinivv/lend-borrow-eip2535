import hre from "hardhat"
import { IDiamondLoupeFacet } from "../../../types/typechain"
import { addOrReplaceFacets } from "../../utils/diamondHelpers"
import { fixture } from "../_effects/fixtures"
import { expect } from "../chai"

describe("Diamond", () => {
    fixture(["diamond-base"])

    /* ======================================================== STRUCTURE ======================================================== */

    describe("#Initialization-Structure", () => {
        let facetsOnChain: IDiamondLoupeFacet.FacetStructOutput[]

        // ================ Preconditions ======================================
        beforeEach(async function () {
            facetsOnChain = [...(await hre.Diamond.facets())]
        })

        // ================ Conditions ======================================
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

    /* ======================================================== STATE ======================================================== */

    describe("#Initialization-State", () => {
        let tokensOnChain: any

        // ================ Pre ======================================
        beforeEach(async function () {
            await hre.deploy("UIDataFacet")
            await addOrReplaceFacets([await hre.get("UIDataFacet")], this.diamondAddr)

            tokensOnChain = await hre.Diamond.getProtocolTokens()
        })

        // ================ Conditions ======================================
        it("sets correct owner", async function () {
            expect(await hre.Diamond.owner()).to.be.equal(this.deployer)
        })

        it("sets standard MToken address", async function () {
            expect(tokensOnChain.mTokenAddress).to.equal(hre.tokens.MToken)
        })

        it("sets standard allowed token addresses", async function () {
            const allowedTokensOnChain = [...tokensOnChain.allowedTokensBatch].flatMap(t => t.tokenAddress)
            const tokensOnArtifact = Object.values(hre.tokens.allowedTokens)

            expect(allowedTokensOnChain).to.have.same.members(tokensOnArtifact)
        })
    })
})
