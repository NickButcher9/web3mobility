require("@nomicfoundation/hardhat-toolbox");

const { task } = require("hardhat/config");
const fs = require('fs');
const mnemonic = fs.readFileSync('.mnemonic', 'utf8');
const contractsAddress = JSON.parse( fs.readFileSync('proxy_adresses.json', 'utf8'))

const ABI = require('./artifacts/contracts/OCPP.sol/OCPP.json');

task("addStation", "Distribute ETH", async () => {

  try {

  
    const accounts = await ethers.getSigners();
    
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let log = await contract.addStation({
      ClientUrl: "/CB00001",
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


task("getStation", "Distribute ETH", async () => {

  try {

  
    const accounts = await ethers.getSigners();
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let log = await contract.getStation("/demo")
    console.log(log)
  } catch (error) {
    console.log(error)
  }

})



task("startTransaction", "Distribute ETH", async () => {

  try {

  
    const accounts = await ethers.getSigners();
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let log = await contract.remoteStartTransaction("/CB00001", 1, 12);

    console.log(log)
  } catch (error) {
    console.log(error)
  }

})

task("stopTransaction", "Distribute ETH", async () => {

  try {

  
    const accounts = await ethers.getSigners();
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let log = await contract.remoteStopTransaction("/CB00001", 12);
    
    console.log(log)
  } catch (error) {
    console.log(error)
  }

})

task("getTransaction", "Distribute ETH", async () => {

  try {

  
    const accounts = await ethers.getSigners();
    const contract = new ethers.Contract(contractsAddress.Station, ABI.abi, accounts[0]);
    
    let log = await contract.getTransaction(5);
    
    console.log(log)
  } catch (error) {
    console.log(error)
  }

})





/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "authority",
  networks: {
    hardhat: {
    },
    authority: {
      url: "http://rrbp.portalenergy.tech:80",
      gasPrice: 2000,
      skipDryRun: true,
      //timeout:10000000,
      networkid:18021982,
      confirmations:2,
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