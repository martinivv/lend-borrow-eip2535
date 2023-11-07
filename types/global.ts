import { Addressable } from "ethers";

export type TokenAddressMap = Record<string, string | Addressable>;

export type ContractAddressMap = Record<string, string>;

export type NetworkInfoMap = Record<string, TokenAddressMap>;

export interface IFacetCut {
    facetAddress: string
    action: FacetCutAction
    functionSelectors: string[]
}


export interface IDiamondFile {
    [diamond: string]: {
        Facets: {
            [contract: string]: {
                Address: string
                Version: string
            }
        }
        InitialFund: {
            [contract: string]: {
                SentAmount: string
                BalanceAfter: string
                Version: string
                TxHash: string
            }
        }
    }
}

export interface ILogFile {
    [contract: string]: {
        [network: string]: {
            [productOrStaging: string]: {
                [version: string]: {
                    ADDRESS: string
                    OPTIMIZER_RUNS: string
                    TIMESTAMP: string
                    CONSTRUCTOR_ARGS: string
                    VERIFIED: string
                }[]
            }
        }
    }
}

export enum FacetCutAction {
    Add = 0,
    Replace = 1,
    Remove = 2,
}
