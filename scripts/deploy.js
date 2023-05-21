// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades, network } = require("hardhat");
const fs = require('fs');
const proxy_adresses =  {
  OCPP: null,
}


async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Network: ", network.name)
  console.log("Address: ",owner.address)

  balance = await ethers.provider.getBalance(owner.address)
  console.log("Balance: ",ethers.utils.formatEther( balance))

  const OCPP = await ethers.getContractFactory("OCPP");
  const ocpp = await upgrades.deployProxy(OCPP,[{
    country_code: 1,
    currency:1,
    owner: ethers.constants.AddressZero,
    price_components:[
        {
            price: ethers.utils.parseEther("0"),
            vat: 0,
            ctype:1, // by kwt
            step_size: 1,
            restrictions:{
                start_date: 0,
                end_date: 0,
                start_time:0,
                end_time: 0,
                min_wh:0,
                max_wh:0,
                min_duration:0,
                max_duration:0,
            } 
        },
        {
            price: ethers.utils.parseEther("0"),
            vat: 0,
            ctype:0, // flat
            step_size: 0,
            restrictions:{
                start_date: 0,
                end_date: 0,
                start_time:0,
                end_time: 0,
                min_wh:0,
                max_wh:0,
                min_duration:0,
                max_duration:0,
            } 
        },
        {
            price: ethers.utils.parseEther("0"),
            vat: 0,
            ctype:0,
            step_size: 0,
            restrictions:{
                start_date: 0,
                end_date: 0,
                start_time:0,
                end_time: 0,
                min_wh:0,
                max_wh:0,
                min_duration:0,
                max_duration:0
            } 
        }
    ]
}]);
  
  await ocpp.deployed();
  proxy_adresses.OCPP = ocpp.address;

  console.log(ocpp);

  fs.writeFile(__dirname+"/../"+network.name+"_proxy_adresses.json", JSON.stringify(proxy_adresses, null, "\t"), function (err) {
    if (err) return console.log(err);
    else console.log("Save to "+network.name+"_proxy_adresses.json")
  });

  console.log("OCPP deployed to:", ocpp.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
