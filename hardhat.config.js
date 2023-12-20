require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-contract-sizer');
const { task } = require("hardhat/config");

const fs = require('fs');

const mnemonic = fs.readFileSync('.mnemonic', 'utf8');
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}


async function loadContract(){
  const {network, ethers} = require("hardhat");

  const contractsAddress = JSON.parse( fs.readFileSync(network.name+'_proxy_adresses.json', 'utf8'))

  const HUB = require('./artifacts/contracts/HUB.sol/HUB.json');
  const Transaction = require('./artifacts/contracts/Transaction.sol/Transaction.json');
  const Station = require('./artifacts/contracts/Station.sol/Station.json');
  const Payment = require('./artifacts/contracts/Payment.sol/Payment.json');
  
  const accounts = await ethers.getSigners();

  const contract = {
    Transaction: new ethers.Contract(contractsAddress.Transaction, Transaction.abi, accounts[0]),
    HUB: new ethers.Contract(contractsAddress.HUB, HUB.abi, accounts[0]),
    Station: new ethers.Contract(contractsAddress.Station, Station.abi, accounts[0]),
    Payment: new ethers.Contract(contractsAddress.Payment, Payment.abi, accounts[0])
  }

  return {accounts, contract, ethers}

}

task("getBalance", "get address balance")
.addParam("address")
.setAction(async (args) => {
  const {ethers} = await loadContract()

  const balance = await ethers.provider.getBalance(args.address)

  console.log("Balance:", ethers.utils.formatEther(balance))
})

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



/* 

    const tariff = {
        country_code: 1,
        currency:1,
        owner: Blockchain.signer.address,
        price_components:[
            {
                price: ethers.utils.parseEther(station.tariff.tariff.toString()),
                vat: 20,
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
      };

*/

task("addTariff", "to hub")
.setAction(async (args) => {
  const {contract,accounts} = await loadContract()
  const tariff = {
    country_code: 1,
    currency:1,
    owner: accounts[0].address,
    SyncId:10,
    price_components:[
        {
            price: ethers.utils.parseEther("10"),
            vat: 20,
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
  };
  
  const transaction = await contract.Payment.addTariff(tariff,{gasPrice:0})
  console.log(transaction)
  let result = await transaction.wait()

  console.log(result)


})



task("updateStationType")
.setAction(async () => {
  const {contract, accounts} = await loadContract()

  const stations = await contract.Station.getStations()


  for (let index = 0; index < stations.length; index++) {
    const station = stations[index];

    if(station.Owner == accounts[0].address){
      var type = 1;

      for (let index = 0; index < station.Connectors.length; index++) {
        const connector = station.Connectors[index];

        if(connector.connectorType != 1 && connector.connectorType != 2){
          type = 2;
          break;
        }
        
      }

      const updateStationType = await contract.Station.updateStationType(index+1, type);
    }
    
  }

})

task("addPartner", "to hub")
.addParam("address")
.addParam("name")
.setAction(async (args) => {
  const {contract} = await loadContract()
  try{

  const transaction = await contract.HUB.addPartner(args.address,args.name)
  transaction.wait()

  const partner = await contract.HUB.getPartner(args.address);

  if(partner.name)
    console.log("Partner add succesfuly!", partner)
  else
    console.log("Something wrong")
  }catch(e){
   console.log(e)
  }
})


task("transferETH", "Send ETH from zero account to address")
.addParam("address")
.addParam("amount")
.setAction(async (args) => {
  const accounts = await ethers.getSigners();
  // Create a transaction object
  let txData = {
      to: args.address,
      value: ethers.utils.parseEther(args.amount.toString()),
  }

  let tx = await accounts[0].sendTransaction(txData);
  console.log(tx)
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

  
    const {contract,accounts} = await loadContract()

//    let addmyself = await contract.Transaction.addPartnerWhoCanCreateTransaction(accounts[0].address)
//    await addmyself.wait()

    let log = await contract.Transaction.remoteStartTransaction(arg.stationurl, arg.connectorid, arg.idtag);
    let result = await log.wait()
    console.log("Success! Tx: ", result)
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


task("updateData", "")
.setAction( async () => {

  try {
    const {contract} = await loadContract()
    
    let result = await contract.Station.updateStationIndexClientUrl();

    console.log(result)
  } catch (error) {
    console.error("ERROR:", error.reason)
  }

})

task("isactive","")
.setAction(async () => {
  const {contract} = await loadContract()
  const stations = await contract.Station.getPartnersStationIds("0x602A44E855777E8b15597F0cDf476BEbB7aa70dE")

  for (let index = 0; index < stations.length; index++) {
    const clientUrl = stations[index];
    const stataion = await contract.Station.getStation(clientUrl)
    console.log(stataion);
    await contract.Station.updateIsActive(stataion.ClientUrl,true)
    await sleep(5000)
  }
})



/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "authorityLocal",
  networks: {
    hardhat: {
      //allowUnlimitedContractSize: true
    },
    authorityDev: {
      url: "http://77.222.43.227:8545",// "http://rrbp.portalenergy.tech/rpc",
      gasPrice: 20,
      skipDryRun: true,
      timeout:10000000,
      networkid:18021982,
      //confirmations:2,
      gas: 9000000,
      accounts: {mnemonic: mnemonic}
    },
    authorityProduction: {
      url: "http://77.222.43.227:8545",// "http://rrbp.portalenergy.tech/rpc",
      gasPrice: 200,
      skipDryRun: true,
      timeout:10000000,
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
