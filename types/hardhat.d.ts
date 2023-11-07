import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { Addressable, BaseContract, Contract, Signer } from "ethers"
import { DeployOptions, DeployResult, Facet } from "hardhat-deploy/types"
import "hardhat/types/runtime"
import "mocha"
import { accounts } from "../hardhat-config/helpers"
import type { TokenAddressMap } from "./global"
import { Martin } from "./typechain"

/* ========================= Augmentations ============================================================================ */

declare module "hardhat/types/runtime" {
    export type HardhatUsers<T> = {
        [key in keyof typeof accounts]: T
    }

    interface HardhatRuntimeEnvironment {
        users: Record<string, SignerWithAddress>
        log(...args: any[]): void
        get<ContractType extends BaseContract = BaseContract>(name: string, signer?: string): Promise<ContractType>
        getAt: (nameOrAbi: string | any[], address: string | Addressable, signer?: Signer) => Promise<Contract>;
        deploy(
            name: string,
            options?: Omit<DeployOptions, "from" | "waitConfirmations"> & {
                from?: string,
                waitConfirmations?: number
            }
        ): Promise<DeployResult>;
            
        tokens: {
            MToken: string | Addressable,
            allowedTokens: TokenAddressMap
            notAllowed: string | Addressable,
            mocks: TokenAddressMap
        }
        DiamondDeployment: DeployResult
        Diamond: Martin
    }
}

declare module "mocha" {
    export interface Context {
        facets: Facet[];
    }
}
