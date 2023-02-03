const { expect }   =   require('chai');
const { ethers, upgrades} = require("hardhat");
const {
    GetEventArgumentsByNameAsync
} = require("../utils/IFBUtils");

before(async function() {

    accounts = await ethers.getSigners();

    this.owner = accounts[0].address;
    this.anotherUser = accounts[1]

    const OCPP = await ethers.getContractFactory("OCPP");

    console.log("Deploying OCPP...");
    const OCPPDeploy = await upgrades.deployProxy(OCPP);

    this.OCPP = await OCPPDeploy.deployed()
    console.log("OCPP deployed to:", OCPPDeploy.address);

    this.stationData = {
        ClientUrl: "CB00001",
        Owner: this.owner,
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
            Status: 2,
            ErrorCode:0,
            IsHaveLock: true,
          },
          {
            Price: ethers.utils.parseEther("10"),
            ConnectorId: 2,
            connectorType: 1,
            PriceFor: 1,
            Status: 2,
            ErrorCode:0,
            IsHaveLock: true,
          }
        ]
    };

})


describe("Station", function(){

    it("Add Station", async function(){
        let log = await this.OCPP.addStation(this.stationData)
        let wait = await log.wait()

    })

    it("Add existed station", async function(){
        await expect(this.OCPP.addStation(this.stationData)).to.be.revertedWith('already_exist');
    })

    it("getStation", async function() {
        const station = await this.OCPP.getStation(1);
        expect(station.Owner).to.equal(this.owner);
    })

    it("getStationNotFound", async function() {
        await expect(this.OCPP.getStation(2)).to.be.revertedWith('station_not_found');
    })

    it("getStationByUrl", async function() {
        const station = await this.OCPP.getStationByUrl("CB00001");
        expect(station.Owner).to.equal(this.owner);
    })

    it("getStationByUrlNotFound", async function() {
        await expect(this.OCPP.getStationByUrl("SOMESTATION")).to.be.revertedWith('station_not_found');
    })


    it("station.setState", async function() {
        let log = await this.OCPP.setState("CB00001", true)
        await log.wait()

        station = await this.OCPP.getStationByUrl("CB00001");

        expect(station.State).to.equal(true);

    })

    it("station.setState station_not_found", async function(){
        await expect(this.OCPP.setState("SOMESTATION", true)).to.be.revertedWith('station_not_found');
    })

    it("station.setState access_denied", async function(){
        await expect(this.OCPP.connect(this.anotherUser).setState("CB00001", true)).to.be.revertedWith('access_denied');
    })

    it("station.getConnector", async function(){
        const conn = await this.OCPP.getConnector(1, 1);
        expect(conn.ConnectorId.toString()).to.equal("1");
    })

    it("station.getConnector not_found", async function(){
        await expect(this.OCPP.getConnector(1, 3)).to.be.revertedWith('not_found');
    })

    it("bootNotification", async function(){
        const transaction = await this.OCPP.bootNotification("CB00001");
        const { clientUrl } = await GetEventArgumentsByNameAsync(transaction, "BootNotification");
        expect(clientUrl).to.equal("CB00001");
    })

    it("statusNotification Conn 1", async function(){
        const transaction = await this.OCPP.statusNotification("CB00001", 1, 1, 7);
        const { status } = await GetEventArgumentsByNameAsync(transaction, "StatusNotification");
        expect(status.toString()).to.equal("1");
        const conn = await this.OCPP.getConnector(1, 1);
        expect(conn.Status.toString()).to.equal("1");
        
    })

    it("statusNotification Conn 2", async function(){
        const transaction = await this.OCPP.statusNotification("CB00001", 2, 1, 7);
        const { status } = await GetEventArgumentsByNameAsync(transaction, "StatusNotification");
        expect(status.toString()).to.equal("1");
        const conn = await this.OCPP.getConnector(1, 2);
        expect(conn.Status.toString()).to.equal("1");
        
    })
    
    it("heartbeat", async function(){
        const transaction = await this.OCPP.heartbeat("CB00001");
        const { clientUrl } = await GetEventArgumentsByNameAsync(transaction, "Heartbeat");
        expect(clientUrl).to.equal("CB00001");        
    })
    
})

describe("Failed transaction", function(){
    it("RemoteStartTransaction ID 1", async function(){
        const transaction = await this.OCPP.remoteStartTransaction("CB00001", 1, 123);
        const {clientUrl, connectorId, idtag, transactionId} = await GetEventArgumentsByNameAsync(transaction, "RemoteStartTransaction");
        expect(clientUrl).to.equal("CB00001");             
        expect(connectorId.toString()).to.equal("1");             
        expect(idtag.toString()).to.equal("123");    
        expect(transactionId.toString()).to.equal("1");   
    })

    it("RejectTransaction ID 1", async function(){
        const transaction = await this.OCPP.rejectTransaction(1)
        const {transactionId} = await GetEventArgumentsByNameAsync(transaction, "RejectTransaction");
        expect(transactionId.toString()).to.equal("1");
    })

    it("getTransaction ID 1", async function(){
        const {Initiator, State} = await this.OCPP.getTransaction(1)

        expect(Initiator).to.equal(this.owner);
        expect(State.toString()).to.equal("5");
    })
})

describe("Success transaction", function(){

    var meter = 0;

    it("RemoteStartTransaction ID 2", async function(){
        const transaction = await this.OCPP.remoteStartTransaction("CB00001", 1, 123);
        const {clientUrl, connectorId, idtag, transactionId} = await GetEventArgumentsByNameAsync(transaction, "RemoteStartTransaction");
        expect(clientUrl).to.equal("CB00001");             
        expect(connectorId.toString()).to.equal("1");             
        expect(idtag.toString()).to.equal("123");    
        expect(transactionId.toString()).to.equal("2");   
    })

    it("startTransaction ID 2", async function(){
        const time = Date.now()
        const transaction = await this.OCPP.startTransaction("CB00001", 123, time, 0)
        const {clientUrl, transactionId, meterStart, dateStart} = await GetEventArgumentsByNameAsync(transaction, "StartTransaction");
        expect(transactionId.toString()).to.equal("2");
        expect(meterStart.toString()).to.equal("0");
        expect(dateStart.toString()).to.equal(time.toString());
        expect(clientUrl).to.equal("CB00001")
    })

    it("StatusNotification:Charging ID 2", async function(){
        // send StatusNotification with status Charging before send meterValues
        const transactionStatus = await this.OCPP.statusNotification("CB00001", 1, 3, 7);
        const { status } = await GetEventArgumentsByNameAsync(transactionStatus, "StatusNotification");
        expect(status.toString()).to.equal("3");
        const conn = await this.OCPP.getConnector(1, 1);
        expect(conn.Status.toString()).to.equal("3");
    })

    it("getTransaction ID 2", async function(){
        const {Initiator, State, Idtag, MeterStart, ConnectorPrice, StationId, ConnectorId} = await this.OCPP.getTransaction(2)

        expect(Initiator).to.equal(this.owner);
        expect(State.toString()).to.equal("2");
        expect(Idtag.toString()).to.equal("123")
        expect(MeterStart.toString()).to.equal("0")
        expect(ethers.utils.formatEther(ConnectorPrice.toString()) ).to.equal("5.0")
        expect(StationId.toString()).to.equal("1")
        expect(ConnectorId.toString()).to.equal("1")

    })

    it("MeterValues ID 2", async function(){


        for (let index = 0; index < 100; index++) {
            meter += 300;

            let data = {
                TransactionId: 2,
                ConnectorId: 1,
                EnergyActiveImportRegister_Wh:meter,
                CurrentImport_A:38,
                CurrentOffered_A:40,
                PowerActiveImport_W:9000,
                Voltage_V:220                  
            }

            const transactionMeterValues = await this.OCPP.meterValues("CB00001", 1, 2, data)            
            const { meterValue } = await GetEventArgumentsByNameAsync(transactionMeterValues, "MeterValues");

            expect(data.TransactionId.toString()).to.equal(meterValue.TransactionId.toString())
            expect(data.ConnectorId.toString()).to.equal(meterValue.ConnectorId.toString())
            expect(data.EnergyActiveImportRegister_Wh.toString()).to.equal(meterValue.EnergyActiveImportRegister_Wh.toString())
            expect(data.CurrentImport_A.toString()).to.equal(meterValue.CurrentImport_A.toString())
            expect(data.CurrentOffered_A.toString()).to.equal(meterValue.CurrentOffered_A.toString())
            expect(data.PowerActiveImport_W.toString()).to.equal(meterValue.PowerActiveImport_W.toString())
            expect(data.Voltage_V.toString()).to.equal(meterValue.Voltage_V.toString())
        }
    })

    it("RemoteStopTransaction ID 2", async function(){
        const transaction = await this.OCPP.remoteStopTransaction("CB00001", 123);
        const {clientUrl, connectorId, idtag, transactionId} = await GetEventArgumentsByNameAsync(transaction, "RemoteStopTransaction");
        expect(clientUrl).to.equal("CB00001");         
        expect(transactionId.toString()).to.equal("2");      
        expect(connectorId.toString()).to.equal("1");             
        expect(idtag.toString()).to.equal("123");    
    })

    it("StopTransaction ID 2", async function(){
        const time = Date.now()
        meter += 300
        const transaction = await this.OCPP.stopTransaction("CB00001", 2, time, meter)
        const {clientUrl, transactionId, meterStop, dateStop} = await GetEventArgumentsByNameAsync(transaction, "StopTransaction");
        expect(transactionId.toString(), "Transaction ID").to.equal("2");
        expect(meterStop.toString(), "MeterStop").to.equal(meter.toString());
        expect(dateStop.toString(), "DateStop").to.equal(time.toString());
        expect(clientUrl, "clientUrl").to.equal("CB00001")
    })

})