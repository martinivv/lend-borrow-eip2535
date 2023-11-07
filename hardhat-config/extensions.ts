import { extendEnvironment } from "hardhat/config"
import { BLOCK_CONFIRMATIONS, getUsers } from "../src/utils/global"

extendEnvironment(async function (hre) {
    hre.users = await getUsers(hre)

    hre.log = (...args) => hre.deployments.log(...args)
    hre.get = async function (name, signer?) {
        return hre.ethers.getContract(name, signer)
    }
    hre.getAt = async function (nameOrAbi, address, signer?) {
        return hre.ethers.getContractAt(nameOrAbi, address, signer)
    }
    hre.deploy = async function (name, options) {
        const blockConfirmations = hre.network.live ? BLOCK_CONFIRMATIONS : 1

        const options_ = options
            ? {
                  from: options.from || hre.users.deployer.address,
                  waitConfirmations: options.waitConfirmations || blockConfirmations,
                  ...options,
              }
            : {
                  from: hre.users.deployer.address,
                  waitConfirmations: blockConfirmations,
              }

        const deployment = await hre.deployments.deploy(name, options_)

        return deployment
    }
})
