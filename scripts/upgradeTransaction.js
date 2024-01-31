// scripts/deploy_upgradeable_box.js
const { ethers, upgrades, network } = require("hardhat");

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("Network: ", network.name)
    console.log("Address: ", owner.address)

    const cfg = require("../"+network.name+"_proxy_adresses.json");

    const Transaction = await ethers.getContractFactory("Transaction");

    console.log("Upgrading Transaction...");
    await upgrades.upgradeProxy( cfg.Transaction, Transaction);
    console.log("Transaction upgraded sucessfuly!");

}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});
