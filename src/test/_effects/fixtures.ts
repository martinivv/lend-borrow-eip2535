import hre from "hardhat"

export const fixture = (fixtureNames: string[]) => {
    beforeEach(async function () {
        const fixture = await hre.deployments.createFixture(async hre => {
            const result = await hre.deployments.fixture(fixtureNames)

            return {
                facets: result.Diamond ? result.Diamond.facets : [],
                deployer: hre.users.deployer.address,
                diamondAddr: hre.Diamond.target,
            }
        })()

        // 👇 gets the data sent on deployment
        this.facets = fixture.facets || []

        this.deployer = fixture.deployer
        this.diamondAddr = fixture.diamondAddr
    })
}
