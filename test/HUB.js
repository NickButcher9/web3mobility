const { expect }   =   require('chai');
const { ethers, upgrades} = require("hardhat");
const {
    GetEventArgumentsByNameAsync
} = require("../utils/IFBUtils");

before(async function() {

    accounts = await ethers.getSigners();

    this.owner = accounts[0].address;
    this.anotherUser = accounts[1]

    const HUB = await ethers.getContractFactory("HUB");

    console.log("Deploying Contracts...");
    
    const HUBDeploy = await upgrades.deployProxy(HUB);
    this.HUB = await HUBDeploy.deployed()
    console.log("HUB deployed to:", HUBDeploy.address);



})


describe("Hub", function(){
    it("Add partner", async function(){
        
        let log = await this.HUB.addPartner({
            country_code: ethers.utils.toUtf8Bytes( "RU"),
            party_id:ethers.utils.toUtf8Bytes("PRT"),
            name: ethers.utils.toUtf8Bytes("PortalEnergy"),
            role:[1,2], //CPO
            status:3,
            owner_address: this.owner,
            last_updated: (Date.now()/1000).toFixed(0)
        })        

        let tx = await log.wait()

    })

    it("getMe", async function(){
        const me = await this.HUB.me();

        expect(me.owner_address).to.equal(this.owner)
    })

    it("getPartners", async function(){
        const partners = await this.HUB.getPartners()

        expect(partners.length).to.equal(1)
    })
})
