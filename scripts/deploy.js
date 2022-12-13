// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const fs = require('fs');
const proxy_adresses =  {
  Station: null,
}


async function main() {
  const [owner] = await ethers.getSigners();
  console.log(owner.address)

  balance = await ethers.provider.getBalance(owner.address)
  console.log(balance)

  const Station = await hre.ethers.getContractFactory("OCPP");
  const station = await Station.deploy();
  
  await station.deployed();
  proxy_adresses.Station = station.address;

  fs.writeFile(__dirname+"/../proxy_adresses.json", JSON.stringify(proxy_adresses, null, "\t"), function (err) {
    if (err) return console.log(err);
    else console.log("Save to proxy_adresses.json")
  });

  console.log("Station deployed to:", station.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
