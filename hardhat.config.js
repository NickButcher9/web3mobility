require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-contract-sizer');
const { task } = require("hardhat/config");

const fs = require('fs');
const { utils } = require("ethers");
const mnemonic = fs.readFileSync('.mnemonic', 'utf8');


async function loadContract(){
  const {network, ethers} = require("hardhat");

  const contractsAddress = JSON.parse( fs.readFileSync(network.name+'_proxy_adresses.json', 'utf8'))

  const HUB = require('./artifacts/contracts/HUB.sol/HUB.json');
  const Transaction = require('./artifacts/contracts/Transaction.sol/Transaction.json');
  const Station = require('./artifacts/contracts/Station.sol/Station.json');
  const Payment = require('./artifacts/contracts/Payment.sol/Payment.json');
  
  const accounts = await ethers.getSigners();

  const contract = {
    Transaction: new ethers.Contract(contractsAddress.Transaction, Transaction.abi, accounts[1]),
    HUB: new ethers.Contract(contractsAddress.HUB, HUB.abi, accounts[1]),
    Station: new ethers.Contract(contractsAddress.Station, Station.abi, accounts[1]),
    Payment: new ethers.Contract(contractsAddress.Payment, Payment.abi, accounts[1])
  }

  return {accounts, contract, ethers}

}

task("getAddresses", "Account list", async () => {
  const accounts = await ethers.getSigners();
  for (let index = 0; index < accounts.length; index++) {
    const account = accounts[index];
    let balance = await account.getBalance()
    console.log(index+"|", account.address, "|", ethers.utils.formatEther(balance))
    
  }
})

task("getTransactionsLocal", "List ids local transactions", async () => {
  const {contract} = await loadContract()
  const transactions = await contract.Transaction.getTransactionsLocal()
  console.log(transactions);
} )

task("getTransactionLocal", "List ids local transactions")
.addParam("clienturl")
.addParam("transactionid")
.setAction( async (args) => {
  const {contract} = await loadContract()
  
  const transaction = await contract.Transaction.getTransactionLocal(args.transactionid.toString(), args.clienturl)
  console.log(transaction);
} )


task("transferETH", "Send ETH from zero account to address")
.addParam("address")
.addParam("amount")
.setAction(async (args) => {
  const accounts = await ethers.getSigners();
  // Create a transaction object
  let txData = {
      to: args.address,
      value: ethers.utils.parseEther(args.amount.toString())
  }

  let tx = await accounts[0].sendTransaction(txData);
  await tx.wait();



})



task("addStation", "Distribute ETH", async (args) => {
  
  try {

    const {accounts, contract} = await loadContract()

    let log = await contract.Station.addStation({
      ClientUrl: "CB00001",
      Owner: accounts[0].address,
      Name: "demo",
      Description: "test",
      Power: 30,
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
          Tariff: 1,
          ConnectorId: 1,
          connectorType: 1,
          Status: 1,
          ErrorCode:0,
          IsHaveLock: true,
        },
        {
          Tariff: 1,
          ConnectorId: 2,
          connectorType: 1,
          Status: 1,
          ErrorCode:0,
          IsHaveLock: true,
        }
      ]
    })
    await log.wait()
    console.log(log)
  } catch (error) {
    console.log(error.reason)
  }

})


task("getStation", "Get station full data")
  .addOptionalParam("stationurl")
  .addOptionalParam("stationid")
  .setAction( async (args) => {
    try {  
      
      const {contract} = await loadContract()
      
      if(args.stationurl){
        let station = await contract.Station.getStationByUrl(args.stationurl)
        console.log(station)
      }
      if(args.stationid){
        let station = await contract.Station.getStation(args.stationid)
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

  
    const {contract} = await loadContract()
    let log = await contract.Transaction.remoteStartTransaction(arg.stationurl, arg.connectorid, arg.idtag, {gasLimit:1000000,gasPrice:21000});
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

  
    const {contract} = await loadContract()
    
    let log = await contract.Transaction.remoteStopTransaction(args.stationurl, args.idtag);
    
    console.log("Success! Tx: ", log.hash)
  } catch (error) {
    console.log(error)
  }

})

task("getTransaction", "")
.addParam("id")
.setAction( async (arg) => {

  try {
    const {contract} = await loadContract()
    
    let result = await contract.Transaction.getTransaction(arg.id);

    console.log(result)
  } catch (error) {
    console.error("ERROR:", error.reason)
  }

})



/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "authorityLocal",
  networks: {
    hardhat: {
      //allowUnlimitedContractSize: true
    },
    authorityLocal: {
      url: "http://localhost:8545",
      gasPrice: 2000,
      networkid:18021982,
      confirmations:2,
      gas: 12000000,
      accounts: {mnemonic: mnemonic}
    },
    authorityProduction: {
      url: "http://77.222.55.129:8545",// "http://rrbp.portalenergy.tech/rpc",
      gasPrice: 1,
      skipDryRun: true,
      //timeout:10000000,
      networkid:18021982,
      //confirmations:2,
      gas: 12000000,
      accounts: {mnemonic: mnemonic}
    }
  },
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 100000
  }
}
