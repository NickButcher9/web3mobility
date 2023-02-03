require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
const { task } = require("hardhat/config");
const fs = require('fs');
const mnemonic = fs.readFileSync('.mnemonic', 'utf8');
const contractsAddress = JSON.parse( fs.readFileSync('proxy_adresses.json', 'utf8'))

//const ABI = require('./artifacts/contracts/OCPP.sol/OCPP.json');

task("addStation", "Distribute ETH", async () => {

  try {

  
    const accounts = await ethers.getSigners();
    
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let log = await contract.addStation({
      ClientUrl: "CB00001",
      Owner: accounts[0].address,
      Name: "demo",
      LocationLat: "56.666",
      LocationLon: "35.56",
      Address: "Demo fucker",
      Time: "24 hours",
      ChargePointModel: "Demo",
      ChargePointVendor: "Demo",
      ChargeBoxSerialNumber: "Demo",
      FirmwareVersion: "1.3.4",
      IsActive: true,
      State: false,
      Url: "https://portalenergy.tech",
      Type: 1,
      OcppInterval: ethers.utils.parseEther("5"),
      Heartbeat: ethers.utils.parseEther("1"),
      Connectors: [
        {
          Price: ethers.utils.parseEther("5"),
          ConnectorId: 1,
          connectorType: 1,
          PriceFor: 1,
          Status: 1,
          ErrorCode:0,
          IsHaveLock: true,
        },
        {
          Price: ethers.utils.parseEther("10"),
          ConnectorId: 2,
          connectorType: 1,
          PriceFor: 1,
          Status: 1,
          ErrorCode:0,
          IsHaveLock: true,
        }
      ]
    })
    await log.wait()
    console.log(log)
  } catch (error) {
    console.log(error)
  }

})

task("updateStation", "Distribute ETH", async () => {

  try {

  
    const accounts = await ethers.getSigners();
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let log = await contract.updateStation({
      Id: 1,
      ClientUrl: "/CB00001",
      Name: "demo",
      LocationLat: "56.666",
      LocationLon: "35.56",
      Address: "Demo sucker",
      Time: "24 hours",
      ChargePointModel: "Demo",
      ChargePointVendor: "Demo",
      ChargeBoxSerialNumber: "Demo",
      FirmwareVersion: "1.3.4",
      IsActive: true,
      State: "active",
      Url: "https://portalenergy.tech",
      Type: "control",
      OcppInterval: ethers.utils.parseEther("5"),
      heartbeat: ethers.utils.parseEther("1"),
      Connectors: [
        {
          ConnectorId:1,
          connectorType: "type1",
          Price: ethers.utils.parseEther("5"),
          PriceFor: "kw",
          Status: "Avaliable",
          IsHaveLock: true,
        }
      ]
    })
    console.log(log)
  } catch (error) {
    console.log(error)
  }

})


task("getStation", "Get station full data")
  .addOptionalParam("stationurl")
  .addOptionalParam("stationid")
  .setAction( async (args) => {
    try {  
      
      const accounts = await ethers.getSigners();
      const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
      
      if(args.stationurl){
        let station = await contract.getStationByUrl(args.stationurl)
        console.log(station)
      }
      if(args.stationid){
        let station = await contract.getStation(args.stationid)
        console.log(station)
      }


    } catch (error) {
      console.error("ERROR:", error.reason)
    }
})



task("startTransaction", "Start charging transaction")
.addParam("stationurl")
.addParam("idtag")
.addParam("connectorid")
.setAction( async (arg) => {

  try {

  
    const accounts = await ethers.getSigners();
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    let log = await contract.remoteStartTransaction(arg.stationurl, arg.connectorid, arg.idtag, {gasLimit:1000000,gasPrice:21000});
    await log.wait()
    console.log("Success! Tx: ", log)
  } catch (error) {
    console.log("ERROR:", error.reason)
  }

})

task("stopTransaction", "Stop charging transaction")
.addParam("stationurl")
.addParam("idtag")
.setAction( async (args) => {

  try {

  
    const accounts = await ethers.getSigners();
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let log = await contract.remoteStopTransaction(args.stationurl, args.idtag);
    
    console.log("Success! Tx: ", log.hash)
  } catch (error) {
    console.log(error)
  }

})

task("getTransaction", "Distribute ETH")
.addParam("id")
.setAction( async (arg) => {

  try {
    const accounts = await ethers.getSigners();
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let result = await contract.getTransaction(arg.id);
    
    console.log(result)
  } catch (error) {
    console.error("ERROR:", error.reason)
  }

})



/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "authority",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
    },
    authority: {
      url: "http://localhost:8545",
      //url: "http://rrbp.portalenergy.tech:80",
      gasPrice: 2000,
      //skipDryRun: true,
      //timeout:10000000,
      networkid:18021982,
      confirmations:2,
      gas: 12000000,
      accounts: {mnemonic: mnemonic}
    }
  },
  solidity: "0.8.9",
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
}
