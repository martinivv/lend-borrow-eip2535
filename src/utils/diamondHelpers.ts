import { Addressable, BaseContract, Contract, FunctionFragment, Interface, ZeroAddress } from "ethers"
// Many conflicts occurred when a relative path was used. Intentionally are not
// added to prevent a potential error during compilation
import { FacetCutAction, IFacetCut } from "../../types/global"
import hre from "hardhat"
import { IDiamondCutFacet } from "../../types/typechain"

const { ethers } = hre

export default class Selectors {
    selectors: string[]
    contract: Contract

    constructor(selectors: string[], contract: Contract) {
        this.selectors = selectors
        this.contract = contract
    }

    // Gets the function selectors from the ABI
    static getSelectors(contractInterface: Interface): string[] {
        const selectors: string[] = []
        contractInterface.fragments.forEach(fragment => {
            if (fragment.type === "function") {
                const funcFragment = fragment as FunctionFragment

                if (funcFragment.format("sighash") !== "init(bytes)") selectors.push(funcFragment.selector)
            }
        })
        return selectors
    }

    // Gets the function selector from the function signature
    static getSelector(func: string) {
        return ethers.FunctionFragment.from(func).selector
    }

    // Removes selectors using an array of signatures
    static removeSelectors(selectors: string[], signatures: string[]): string[] {
        const removeSelectors = signatures.map(v => Selectors.getSelector(v))
        selectors = selectors.filter(v => !removeSelectors.includes(v))
        return selectors
    }

    // Finds a specific address position within the return value of {DiamondLoupeFacet-facets}
    static findAddressPositionInFacets(facetAddress: string, facets: IFacetCut[]) {
        for (let i = 0; i < facets.length; i++) {
            if (facets[i].facetAddress === facetAddress) return i
        }
    }
}

export const addOrReplaceFacets = async function (
    facets: BaseContract[],
    diamondAddress: string | Addressable,
    initContract: string = ZeroAddress,
    initData = "0x",
): Promise<void> {
    const { log } = hre.deployments

    const loupe = await hre.getAt("IDiamondLoupeFacet", diamondAddress)
    const cut = []

    for (const f of facets) {
        const replaceSelectors = []
        const addSelectors = []

        const selectors = Selectors.getSelectors(f.interface)

        for (const s of selectors) {
            const addr = await loupe.facetAddress(s)

            if (addr === ZeroAddress) {
                addSelectors.push(s)
                continue
            }

            if (addr.toLowerCase() !== f.target.toString().toLowerCase()) replaceSelectors.push(s)
        }

        if (replaceSelectors.length) {
            cut.push({
                facetAddress: f.target,
                action: FacetCutAction.Replace,
                functionSelectors: replaceSelectors,
            })
        }
        if (addSelectors.length) {
            cut.push({
                facetAddress: f.target,
                action: FacetCutAction.Add,
                functionSelectors: addSelectors,
            })
        }
    }

    if (!cut.length) {
        log("> No facets to add or replace.")
        return
    }

    log("Adding/Replacing facet(s)...")
    await doCut(diamondAddress, cut, initContract, initData)

    log("Success.")
}

export const addFacets = async function (
    facets: BaseContract[],
    diamondAddress: string | Addressable,
    initContract: string = ZeroAddress,
    initData = "0x",
): Promise<void> {
    const { log } = hre.deployments

    const cut = []

    for (const f of facets) {
        const selectors = Selectors.getSelectors(f.interface)

        cut.push({
            facetAddress: f.target,
            action: FacetCutAction.Add,
            functionSelectors: selectors,
        })
    }

    if (!cut.length) {
        log("> No facets to add or replace.")
        return
    }

    log("Adding facet(s)...")
    await doCut(diamondAddress, cut, initContract, initData)

    log("Success.")
}

export const removeFacet = async function (selectors: string[], diamondAddress: string): Promise<void> {
    const { log } = hre.deployments

    const cut = [
        {
            facetAddress: ZeroAddress,
            action: FacetCutAction.Remove,
            functionSelectors: selectors,
        },
    ]

    log("Removing facet...")
    await doCut(diamondAddress, cut, ZeroAddress, "0x")

    log("Success.")
}

export const replaceFacet = async function (
    facet: BaseContract,
    diamondAddress: string,
    initContract: string = ZeroAddress,
    initData = "0x",
): Promise<void> {
    const { log } = hre.deployments

    const selectors = Selectors.getSelectors(facet.interface)
    const cut = [
        {
            facetAddress: facet.target,
            action: FacetCutAction.Replace,
            functionSelectors: selectors,
        },
    ]

    log("Replacing facet...")
    await doCut(diamondAddress, cut, initContract, initData)

    log("Success.")
}

const doCut = async function (
    diamondAddress: string | Addressable,
    cut: IDiamondCutFacet.FacetCutStruct[],
    initContract: string,
    initData: string,
): Promise<void> {
    const cutter = await hre.getAt("IDiamondCutFacet", diamondAddress)

    await cutter.diamondCut(cut, initContract, initData).then(async function (result) {
        hre.deployments.log("> Diamond cut tx:", result.hash)

        const receipt = await result.wait()
        if (!receipt?.status) throw new Error(`Diamond upgrade failed: ${result.hash}`)
    })
}
