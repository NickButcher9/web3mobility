// scripts/deploy_upgradeable_box.js
const { ethers, upgrades, network } = require("hardhat");

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("Network: ", network.name)
    console.log("Address: ", owner.address)

    const cfg = require("../"+network.name+"_proxy_adresses.json");

    const Station = await ethers.getContractFactory("Station");

    console.log("Upgrading Station...");
    await upgrades.upgradeProxy( cfg.Station, Station);
    console.log("Station upgraded sucessfuly!");

}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});
