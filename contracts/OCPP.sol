// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library TransactionStruct {

    struct Fields {
        address initiator;
        uint256 totalPrice;
        uint256 totalImportRegisterWh;
        bool isPaidToOwner;
        uint256 idtag;
        uint256 MeterStart;
        uint256 LastMeter;
        uint256 MeterStop;
        uint256 DateStart;
        uint256 DateStop;
        uint256 ConnectorPrice;
        uint256 StationId;
        int ConnectorId;
        int State;
        int ConnectorPriceFor;
        
    }

    struct MeterValue {
        uint256 TransactionId;
        int ConnectorId;
        uint256 EnergyActiveImportRegister_Wh;
        int CurrentImport_A;
        int CurrentOffered_A;
        int PowerActiveImport_W;
        int Voltage_V;
    }

    // For Fields.State
    int constant New = 1;
    int constant Preparing = 2;
    int constant Charging = 3;
    int constant Finished = 4;
    int constant Error = 5;

    // For Fields.ConnectorPriceFor
    int constant Kw = 1;
    int constant Time = 2;
    
}


library StationStruct {

    struct Connectors {
        uint256 Price;        
        int ConnectorId;
        int connectorType; //
        int PriceFor;
        int Status; // 1 - avaliable, 2 - preparing, 3 - charging, 4 - finished, 5 - error
        int ErrorCode;
        bool IsHaveLock;
    }

    int constant Type1 = 1;
    int constant Type2 = 2;
    int constant Chademo = 3;
    int constant CCS1 = 4;
    int constant CCS2 = 5;
    int constant GBTDC = 6;
    int constant GBTAC = 7;

    int constant ConnectorLockFailure = 1;
    int constant EVCommunicationError = 2;
    int constant GroundFailure = 3;
    int constant HighTemperature = 4;
    int constant InternalError = 5;
    int constant LocalListConflict = 6;
    int constant NoError = 7;
    int constant OtherError = 8;
    int constant OverCurrentFailure = 9;
    int constant PowerMeterFailure = 10;
    int constant PowerSwitchFailure = 11;
    int constant ReaderFailure = 12;
    int constant ResetFailure = 13;
    int constant UnderVoltage = 14;
    int constant OverVoltage = 15;
    int constant WeakSignalint = 16;


    int constant Available =  1;
    int constant Preparing = 2;
    int constant Charging = 3;
    int constant SuspendedEVSE = 4;
    int constant SuspendedEV = 5;
    int constant Finishing = 6;
    int constant Reserved = 7;
    int constant Unavailable = 8;
    int constant Faulted = 9;


    bool constant Active = true;
    bool constant InActive = false;

    struct Fields {
        string ClientUrl;
        address Owner;
        string Name;
        string LocationLat;
        string LocationLon;
        string Address;
        string Time;
        string ChargePointModel;
        string ChargePointVendor;
        string ChargeBoxSerialNumber;
        string FirmwareVersion;
        bool IsActive;
        bool State; 
        string Url;
        int Type;
        uint256 OcppInterval;
        uint256 Heartbeat;
        Connectors[] Connectors;
    }
}


contract OCPP {

    uint256 transactionIdcounter;
    uint256 stationIndex;

    mapping (uint256 => TransactionStruct.Fields) Transactions;
    mapping (uint256 => uint256) UserToTransaction;
    mapping (uint256 => StationStruct.Fields)  Stations;
    mapping (string => uint256) ClientUrlById;
    mapping (uint256 => TransactionStruct.MeterValue[]) MeterValuesData;
    

    event BootNotification(uint256 indexed stationId, string clientUrl, uint256 timestamp);
    event StatusNotification(uint256 indexed stationId, string clientUrl, int connectorId, int status, int errorCode );
    event Heartbeat(string clientUrl, uint256 timestamp);
    event StartTransaction(string clientUrl, uint256 indexed transactionId, uint256 dateStart, uint256 meterStart);
    event StopTransaction(string clientUrl, uint256 indexed transactionId, uint256 dateStop, uint256 meterStop);
    event ChangeStateStation(uint256 indexed stationId, string clientUrl, bool state);
    event RemoteStartTransaction(string clientUrl, int connectorId, uint256 idtag, uint256 indexed transactionId);
    event MeterValues(string clientUrl, int connectorId, uint256 indexed transactionId, TransactionStruct.MeterValue  meterValue );
    event RemoteStopTransaction(string clientUrl, uint256 indexed transactionId, int connectorId);
    event RejectTransaction(uint256 indexed transactionId, string reason);

    constructor() {
        stationIndex = 0;
        transactionIdcounter = 0;
    }

    function addStation(StationStruct.Fields calldata station) public returns(uint256){

        require(station.Owner == msg.sender, "Station.Owner must much with msg.sender");

        stationIndex++;
        Stations[stationIndex] = station;
        
        ClientUrlById[station.ClientUrl] = stationIndex;
        return stationIndex;
    }

    function getStation(uint256 stationId) public view returns(StationStruct.Fields memory){
        StationStruct.Fields memory station = Stations[stationId];
        return station;
    }


    function getStationByUrl(string memory clientUrl) public view returns(StationStruct.Fields memory){
        uint256 stationId = ClientUrlById[clientUrl];
        StationStruct.Fields memory station = Stations[stationId];
        return station;
    }


    function setState(string memory clientUrl, bool state) public {
        uint256 stationId = ClientUrlById[clientUrl];
        Stations[stationId].State = state;
        emit ChangeStateStation(stationId, clientUrl, state);
    }


    function getConnector(uint256 stationId, int connectorId) public view returns(StationStruct.Connectors memory connector){
        StationStruct.Fields memory station = Stations[stationId];

        for (uint256 index = 0; index < station.Connectors.length; index++) {
            StationStruct.Connectors memory c = station.Connectors[index];

            if (c.ConnectorId == connectorId) {
                return c;
            }
        }
    }

    function bootNotification(string memory clientUrl) public {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if(Stations[stationId].IsActive){
           Stations[stationId].Heartbeat = block.timestamp; 
           emit BootNotification(stationId, clientUrl, block.timestamp);
        }
    }

    function statusNotification(string memory clientUrl, int connectorId, int status, int errorCode) public {
        uint256 stationId = ClientUrlById[clientUrl];

        StationStruct.Fields memory station = Stations[stationId];

        for (uint256 index = 0; index < station.Connectors.length; index++) {

            StationStruct.Connectors memory c = station.Connectors[index];

            if (c.ConnectorId == connectorId) {
                Stations[stationId].Connectors[index].Status = status;
                Stations[stationId].Connectors[index].ErrorCode = errorCode;
                Stations[stationId].Heartbeat = block.timestamp;

                statusNotificationTriggers(Stations[stationId].Connectors[index], stationId);
                
                emit StatusNotification(stationId, clientUrl, connectorId, status, errorCode );
            }
        }        
    }

    function heartbeat(string memory clientUrl) public {
        uint256 stationId = ClientUrlById[clientUrl];
        Stations[stationId].Heartbeat = block.timestamp;
        emit Heartbeat(clientUrl, block.timestamp);
    }

    function statusNotificationTriggers(StationStruct.Connectors memory connector, uint256 stationId) private {

    }



    function remoteStartTransaction(string memory clientUrl, int connectorId, uint256 idtag) public returns(uint256) {
        uint256 stationId = ClientUrlById[clientUrl];
        StationStruct.Connectors memory connector  = getConnector(stationId, connectorId);
        
        if(  (connector.Status == StationStruct.Available || connector.Status == StationStruct.SuspendedEVSE || connector.Status == StationStruct.Preparing ) && Stations[stationId].State == StationStruct.Active ) {
            
            transactionIdcounter++;

            UserToTransaction[idtag] = transactionIdcounter;

            Transactions[transactionIdcounter] = TransactionStruct.Fields({
                initiator: msg.sender,
                totalPrice: 0,
                totalImportRegisterWh: 0,
                isPaidToOwner: false,
                idtag:idtag,
                MeterStart:0,
                MeterStop:0,
                LastMeter:0,
                DateStart:0,
                DateStop:0,
                ConnectorPrice:connector.Price,
                StationId:stationId,
                ConnectorId:connectorId,
                State: TransactionStruct.New,
                ConnectorPriceFor: TransactionStruct.Kw     
            });

            emit RemoteStartTransaction(clientUrl, connectorId, idtag, transactionIdcounter);

            return transactionIdcounter;
        }

        return 0;
    }

    function rejectTransaction(uint256 transactionId) public {
        Transactions[transactionId].State = TransactionStruct.Error;
        UserToTransaction[Transactions[transactionId].idtag] = 0;

        if(Transactions[transactionId].initiator == msg.sender)
            emit RejectTransaction(transactionId, "Rejected");
    }

    function remoteStopTransaction(string memory clientUrl, uint256 idtag) public {
        uint256 stationId = ClientUrlById[clientUrl];
        uint256 transactionId = UserToTransaction[idtag];

        StationStruct.Connectors memory connector  = getConnector(stationId, Transactions[transactionId].ConnectorId);

        if(  connector.Status == StationStruct.Charging && Stations[stationId].State == StationStruct.Active && Transactions[transactionId].initiator == msg.sender) {
            emit RemoteStopTransaction(clientUrl, transactionId, Transactions[transactionId].ConnectorId);
        }
        
    }

    function getTransaction(uint256 id) public view returns(TransactionStruct.Fields memory){
        return Transactions[id];
    }

    function getTransactionByIdtag(uint256 tagId) public view returns(uint256){
        uint256 transactionId =  UserToTransaction[tagId];
        return transactionId;
    }

    function startTransaction(string memory clientUrl, uint256 tagId, uint256 dateStart, uint256 meterStart) public {
        uint256  transactionId =  UserToTransaction[tagId];
        Transactions[transactionId].MeterStart = meterStart;
        Transactions[transactionId].DateStart = dateStart;
        Transactions[transactionId].State = TransactionStruct.Preparing;
        emit StartTransaction(clientUrl, transactionId, meterStart, dateStart);
    }


    function meterValues(string memory clientUrl, int connectorId,uint256 transactionId, TransactionStruct.MeterValue memory meterValue ) public {

        if( Transactions[transactionId].initiator == msg.sender){
            uint256 stationId = ClientUrlById[clientUrl];
            Stations[stationId].Heartbeat = block.timestamp;
            Transactions[transactionId].State = TransactionStruct.Charging;
            Transactions[transactionId].LastMeter =  meterValue.EnergyActiveImportRegister_Wh;
            MeterValuesData[transactionId].push(meterValue);
            emit MeterValues(clientUrl, connectorId, transactionId,  meterValue );
        }

    }

    function stopTransaction(string memory clientUrl, uint256 transactionId, uint256 dateStop, uint256 meterStop) public {
        if( Transactions[transactionId].initiator == msg.sender ){
            Transactions[transactionId].MeterStop = meterStop;
            Transactions[transactionId].totalImportRegisterWh = Transactions[transactionId].MeterStop-Transactions[transactionId].MeterStart;
            Transactions[transactionId].DateStop = dateStop;
            Transactions[transactionId].State = TransactionStruct.Finished;
            UserToTransaction[Transactions[transactionId].idtag] = 0;

            if(  Transactions[transactionId].ConnectorPriceFor == TransactionStruct.Kw){
                Transactions[transactionId].totalPrice = (Transactions[transactionId].totalImportRegisterWh/1000)*Transactions[transactionId].ConnectorPrice;
            }
            

            emit StopTransaction(clientUrl, transactionId, meterStop, dateStop);
        }
    }
}
