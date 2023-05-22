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
    const Payment = await ethers.getContractFactory("Payment");
    const Station = await ethers.getContractFactory("Station");
    const Transaction = await ethers.getContractFactory("Transaction");

    console.log("Deploying Contracts...");

    this.tariff = {
        country_code: 1,
        currency:1,
        owner: ethers.constants.AddressZero,
        price_components:[
            {
                price: ethers.utils.parseEther("15"),
                vat: 20,
                ctype:1, // by kwt
                step_size: 1,
                restrictions:{
                    start_date: 0,
                    end_date: 0,
                    start_time:0,
                    end_time: 0,
                    min_wh:ethers.utils.parseEther("1000"),
                    max_wh:ethers.utils.parseEther("200000"),
                    min_duration:0,
                    max_duration:0,
                } 
            },
            {
                price: ethers.utils.parseEther("150"),
                vat: 20,
                ctype:2, // flat
                step_size: 1,
                restrictions:{
                    start_date: 0,
                    end_date: 0,
                    start_time:0,
                    end_time: 0,
                    min_wh:0,
                    max_wh:0,
                    min_duration:1,
                    max_duration:100,
                } 
            },
            {
                price: ethers.utils.parseEther("5"),
                vat: 20,
                ctype:3,
                step_size: 1,
                restrictions:{
                    start_date: 0,
                    end_date: 0,
                    start_time:9,
                    end_time: 20,
                    min_wh:0,
                    max_wh:0,
                    min_duration:0,
                    max_duration:0
                } 
            }
        ]
    };
    this.stationData = {
        ClientUrl: "CB00001",
        Owner: this.owner,
        Name: "demo",
        Description: "Demo desc",
        Power: 31,
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
            Tariff:1,
            Power:20,
            ConnectorId: 1,
            connectorType: 1,
            Status: 2,
            ErrorCode:0,
            IsHaveLock: true,
          },
          {
            Tariff:1,
            Power:20,
            ConnectorId: 2,
            connectorType: 1,
            Status: 2,
            ErrorCode:0,
            IsHaveLock: true,
          }
        ]
    };
    
    const HUBDeploy = await upgrades.deployProxy(HUB);
    this.HUB = await HUBDeploy.deployed()
    console.log("HUB deployed to:", HUBDeploy.address);

    const PaymentDeploy = await upgrades.deployProxy(Payment,[this.tariff,HUBDeploy.address]);
    this.Payment = await PaymentDeploy.deployed()
    console.log("Payment deployed to:", PaymentDeploy.address);

    const StationDeploy = await upgrades.deployProxy(Station,[HUBDeploy.address]);
    this.Station = await StationDeploy.deployed()
    console.log("Station deployed to:", StationDeploy.address);

    const TransactionDeploy = await upgrades.deployProxy(Transaction,[StationDeploy.address,PaymentDeploy.address]);
    this.Transaction = await TransactionDeploy.deployed()
    console.log("Transaction deployed to:", TransactionDeploy.address);



})


describe("Station", function(){

    it("Add Station", async function(){
        let log = await this.Station.addStation(this.stationData)
        let wait = await log.wait()

    })

    it("Add existed station", async function(){
        await expect(this.Station.addStation(this.stationData)).to.be.revertedWith('already_exist');
    })

    it("getStation", async function() {
        const station = await this.Station.getStation(1);
        expect(station.Owner).to.equal(this.owner);
    })

    it("getStations", async function() {
        const stations = await this.Station.getStations();
        expect(stations.length).to.be.equal(1)
    })

    it("getStationNotFound", async function() {
        await expect(this.Station.getStation(2)).to.be.revertedWith('station_not_found');
    })

    it("getStationByUrl", async function() {
        const station = await this.Station.getStationByUrl("CB00001");
        expect(station.Owner).to.equal(this.owner);
    })

    it("getStationByUrlNotFound", async function() {
        await expect(this.Station.getStationByUrl("SOMESTATION")).to.be.revertedWith('station_not_found');
    })


    it("station.setState", async function() {
        let log = await this.Station.setState("CB00001", true)
        await log.wait()

        station = await this.Station.getStationByUrl("CB00001");

        expect(station.State).to.equal(true);

    })

    it("station.setState station_not_found", async function(){
        await expect(this.Station.setState("SOMESTATION", true)).to.be.revertedWith('station_not_found');
    })

    it("station.setState access_denied", async function(){
        await expect(this.Station.connect(this.anotherUser).setState("CB00001", true)).to.be.revertedWith('access_denied');
    })

    it("station.getConnector", async function(){
        const conn = await this.Station.getConnector(1, 1);
        expect(conn.ConnectorId.toString()).to.equal("1");
    })

    it("station.getConnector not_found", async function(){
        await expect(this.Station.getConnector(1, 3)).to.be.revertedWith('not_found');
    })

    it("bootNotification", async function(){
        const transaction = await this.Station.bootNotification("CB00001");
        const { clientUrl } = await GetEventArgumentsByNameAsync(transaction, "BootNotification");
        expect(clientUrl).to.equal("CB00001");
    })

    it("statusNotification Conn 1", async function(){
        const transaction = await this.Station.statusNotification("CB00001", 1, 1, 7);
        const { status } = await GetEventArgumentsByNameAsync(transaction, "StatusNotification");
        expect(status.toString()).to.equal("1");
        const conn = await this.Station.getConnector(1, 1);
        expect(conn.Status.toString()).to.equal("1");
        
    })

    it("statusNotification Conn 2", async function(){
        const transaction = await this.Station.statusNotification("CB00001", 2, 1, 7);
        const { status } = await GetEventArgumentsByNameAsync(transaction, "StatusNotification");
        expect(status.toString()).to.equal("1");
        const conn = await this.Station.getConnector(1, 2);
        expect(conn.Status.toString()).to.equal("1");
        
    })
    
    it("heartbeat", async function(){
        const transaction = await this.Station.heartbeat("CB00001", Date.now());
        const { clientUrl } = await GetEventArgumentsByNameAsync(transaction, "Heartbeat");
        expect(clientUrl).to.equal("CB00001");        
    })
    
})



describe("CreateTransactionAccess", function(){

    it("Add partner to create transaction", async function(){
        await this.Transaction.addPartnerWhoCanCreateTransaction(this.anotherUser.address);

        const whoCanCreateTransaction = await this.Transaction.partnerCanCreateTransaction(this.owner, this.anotherUser.address);

        expect(whoCanCreateTransaction).to.equal(true);
        
    })

    it("Delete partner to create transaction", async function(){
        await this.Transaction.deletePartnerWhoCanCreateTransaction(this.anotherUser.address)
        const whoCanCreateTransaction = await this.Transaction.partnerCanCreateTransaction(this.owner, this.anotherUser.address);

        expect(whoCanCreateTransaction).to.equal(false);
        
    })

    it("Add access to create transaction myself", async function(){
        await this.Transaction.addPartnerWhoCanCreateTransaction(this.owner);

        const whoCanCreateTransaction = await this.Transaction.partnerCanCreateTransaction(this.owner, this.owner);

        expect(whoCanCreateTransaction).to.equal(true);
        
    })
})

describe("Failed transaction", function(){
    it("RemoteStartTransaction ID 1", async function(){
        const transaction = await this.Transaction.remoteStartTransaction("CB00001", 1, "123");
        const {clientUrl, connectorId, idtag, transactionId} = await GetEventArgumentsByNameAsync(transaction, "RemoteStartTransaction");
        expect(clientUrl).to.equal("CB00001");             
        expect(connectorId.toString()).to.equal("1");             
        expect(idtag.toString()).to.equal("123");    
        expect(transactionId.toString()).to.equal("1");   
    })

    it("RejectTransaction ID 1", async function(){
        const transaction = await this.Transaction.rejectTransaction(1)
        const {transactionId} = await GetEventArgumentsByNameAsync(transaction, "RejectTransaction");
        expect(transactionId.toString()).to.equal("1");
    })

    it("getTransaction ID 1", async function(){
        const {Initiator, State} = await this.Transaction.getTransaction(1)

        expect(Initiator).to.equal(this.owner);
        expect(State.toString()).to.equal("5");
    })
})

describe("Success transaction", function(){

    var meter = 0;

    it("RemoteStartTransaction ID 2", async function(){
        const transaction = await this.Transaction.remoteStartTransaction("CB00001", 1, "123");
        const {clientUrl, connectorId, idtag, transactionId} = await GetEventArgumentsByNameAsync(transaction, "RemoteStartTransaction");
        expect(clientUrl).to.equal("CB00001");             
        expect(connectorId.toString()).to.equal("1");             
        expect(idtag.toString()).to.equal("123");    
        expect(transactionId.toString()).to.equal("2");   
    })

    it("startTransaction ID 2", async function(){
        const time = Math.floor(new Date().getTime() / 1000)
        const transaction = await this.Transaction.startTransaction("CB00001", "123", time, 0)
        const {clientUrl, transactionId, meterStart, dateStart} = await GetEventArgumentsByNameAsync(transaction, "StartTransaction");
        expect(transactionId.toString()).to.equal("2");
        expect(meterStart.toString()).to.equal("0");
        expect(dateStart.toString()).to.equal(time.toString());
        expect(clientUrl).to.equal("CB00001")
    })

    it("StatusNotification:Charging ID 2", async function(){
        
        const transactionStatus = await this.Station.statusNotification("CB00001", 1, 3, 7);
        const { status } = await GetEventArgumentsByNameAsync(transactionStatus, "StatusNotification");
        expect(status.toString()).to.equal("3");
        const conn = await this.Station.getConnector(1, 1);
        expect(conn.Status.toString()).to.equal("3");
    })

    it("getTransaction ID 2", async function(){
        const {Initiator, State, Idtag, MeterStart, ConnectorPrice, StationId, ConnectorId} = await this.Transaction.getTransaction(2)

        expect(Initiator).to.equal(this.owner);
        expect(State.toString()).to.equal("3");
        expect(Idtag.toString()).to.equal("123")
        expect(MeterStart.toString()).to.equal("0")
        expect(StationId.toString()).to.equal("1")
        expect(ConnectorId.toString()).to.equal("1")

    })

    it("MeterValues ID 2", async function(){


        for (let index = 0; index < 100; index++) {
            meter += 300;

            let data = {
                TransactionId: 2,
                ConnectorId: 1,
                EnergyActiveImportRegister_Wh:ethers.utils.parseEther( meter.toString()),
                CurrentImport_A:38,
                CurrentOffered_A:40,
                PowerActiveImport_W:9000,
                Voltage_V:220,
                Percent:10,              
            }

            const transactionMeterValues = await this.Transaction.meterValues("CB00001", 1, 2, data)            
            const { meterValue } = await GetEventArgumentsByNameAsync(transactionMeterValues, "MeterValues");

            expect(data.TransactionId.toString()).to.equal(meterValue.TransactionId.toString())
            expect(data.ConnectorId.toString()).to.equal(meterValue.ConnectorId.toString())
            expect(data.EnergyActiveImportRegister_Wh.toString()).to.equal(meterValue.EnergyActiveImportRegister_Wh.toString())
            expect(data.CurrentImport_A.toString()).to.equal(meterValue.CurrentImport_A.toString())
            expect(data.CurrentOffered_A.toString()).to.equal(meterValue.CurrentOffered_A.toString())
            expect(data.PowerActiveImport_W.toString()).to.equal(meterValue.PowerActiveImport_W.toString())
            expect(data.Voltage_V.toString()).to.equal(meterValue.Voltage_V.toString())
            expect(data.Percent.toString()).to.equal(meterValue.Percent.toString())
        }

        const meterValues = await this.Transaction.getMeterValues(2);

        expect(meterValues.length).to.equal(100);
    })

    it("RemoteStopTransaction ID 2", async function(){
        const transaction = await this.Transaction.remoteStopTransaction("CB00001", "123");
        const {clientUrl, connectorId, idtag, transactionId} = await GetEventArgumentsByNameAsync(transaction, "RemoteStopTransaction");
        expect(clientUrl).to.equal("CB00001");         
        expect(transactionId.toString()).to.equal("2");      
        expect(connectorId.toString()).to.equal("1");             
        expect(idtag.toString()).to.equal("123");    
    })

    it("StopTransaction ID 2", async function(){
        const time = Math.floor(new Date().getTime() / 1000)+60;

        meter += 300
        const transaction = await this.Transaction.stopTransaction("CB00001", 2, time, ethers.utils.parseEther( meter.toString() ) )
        const {clientUrl, transactionId, meterStop, dateStop} = await GetEventArgumentsByNameAsync(transaction, "StopTransaction");
        const existUserTransaction = await this.Transaction.getUserTransaction("123")
        expect(existUserTransaction.toString(), "existUserTransaction").to.equal("0")
        expect(transactionId.toString(), "Transaction ID").to.equal("2");
        expect(meterStop.toString(), "MeterStop").to.equal( ethers.utils.parseEther( meter.toString()));
        expect(dateStop.toString(), "DateStop").to.equal(time.toString());
        expect(clientUrl, "clientUrl").to.equal("CB00001")
    })

    it("StatusNotification:Preparing ID 2", async function(){
        
        const transactionStatus = await this.Station.statusNotification("CB00001", 1, 2, 7);
        const { status } = await GetEventArgumentsByNameAsync(transactionStatus, "StatusNotification");
        expect(status.toString()).to.equal("2");
        const conn = await this.Station.getConnector(1, 1);
        expect(conn.Status.toString()).to.equal("2");
    })    

    it("Check Transaction data ID 2", async function(){
        const {Initiator, State, Idtag, MeterStart, MeterStop, TotalImportRegisterWh, TotalPrice, StationId, ConnectorId, Invoice} = await this.Transaction.getTransaction(2)

        let TotalImportRegisterWhCalc =  Number(ethers.utils.formatEther( MeterStop).toString())-Number(ethers.utils.formatEther(MeterStart).toString())


        //const invoice = await this.OCPP.getInvoice(Invoice)
        //console.log(invoice);
        expect(Initiator, "Initiator").to.equal(this.owner);
        expect(State.toString(), "State").to.equal("4");
        expect(Idtag.toString(), "Idtag").to.equal("123")
        expect(MeterStart.toString(), "MeterStart").to.equal("0")
        expect(StationId.toString(), "StationId").to.equal("1")
        expect(ConnectorId.toString(), "ConnectorId").to.equal("1")
        expect(MeterStop.toString(), "MeterStop").to.equal(ethers.utils.parseEther( meter.toString()))
        expect(Invoice.toString(), "Invoice").to.equal("1")

        expect(ethers.utils.formatEther(TotalImportRegisterWh).toString(), "TotalImportRegisterWh").to.equal(TotalImportRegisterWhCalc.toString()+".0")

        expect(ethers.utils.formatEther(TotalPrice).toString(), "TotalPrice").to.equal("600.0")
    })

    // TODO write checks all invoice data

})

describe("Cancell transaction", function(){
    it("RemoteStartTransaction ID 3", async function(){
        const transaction = await this.Transaction.remoteStartTransaction("CB00001", 1, "123");
        const {clientUrl, connectorId, idtag, transactionId} = await GetEventArgumentsByNameAsync(transaction, "RemoteStartTransaction");
        expect(clientUrl).to.equal("CB00001");             
        expect(connectorId.toString()).to.equal("1");             
        expect(idtag.toString()).to.equal("123");    
        expect(transactionId.toString()).to.equal("3");   
    })

    it("CancellTransaction ID 3", async function(){
        const transaction = await this.Transaction.cancelTransaction("CB00001", 3);
        const {clientUrl, transactionId} = await GetEventArgumentsByNameAsync(transaction, "CancelTransaction");
        expect(transactionId.toString()).to.equal("3");  
        expect(clientUrl).to.equal("CB00001"); 
    })

    it("CheckStatus cancelled transaction ID 3", async function(){
        const {State} = await this.Transaction.getTransaction(3)
        const existUserTransaction = await this.Transaction.getUserTransaction("123")
        expect(State.toString(), "State").to.equal("6")
        expect(existUserTransaction.toString(), "existUserTransaction").to.equal("0")
    })
})

describe("Total data", function(){

    var countStations = 30;

    it("Add "+countStations+" stations", async function(){
        for (let index = 0; index < countStations; index++) {
            this.stationData.ClientUrl = "CB10000"+index
            this.stationData.State = true;
            let log = await this.Station.addStation(this.stationData)
            await log.wait()
        }
    })

    it("Generate "+countStations+" transactions", async function(){
        for (let index = 0; index < countStations; index++) {
            const startTransaction = await this.Transaction.remoteStartTransaction("CB10000"+index, 1, "123"+index);
            await startTransaction.wait()
        }
        
    })

    it("Stations count", async function(){
        const count = await this.Station.getStationsCount()
        const stations = await this.Station.getStations()
        expect(count.toString()).to.equal((countStations+1).toString())
        expect(stations.length).to.equal((countStations+1))
    })

    it("Transactions count", async function(){
        const count = await this.Transaction.getTransactionsCount()
        const transactions = await this.Transaction.getTransactions()
        expect(count.toString()).to.equal((countStations+3).toString())
        expect(transactions.length).to.equal((countStations+3))
    })

})


describe("Tariff", function(){
    it("Check default tariff", async function(){
        const tariff = await this.Payment.getTariff(1)
        //console.log(tariff, tariff.price_components, tariff.price_components[0].restrictions)
    })
})