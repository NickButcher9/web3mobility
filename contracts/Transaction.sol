// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./Payment.sol";
import "./Station.sol";

import "hardhat/console.sol";

library TransactionStruct {

    struct Fields {
        uint256 Id;
        address Initiator;
        uint256 TotalPrice;
        uint256 TotalImportRegisterWh;
        string Idtag;
        uint256 MeterStart;
        uint256 LastMeter;
        uint256 MeterStop;
        uint256 DateStart;
        uint256 DateStop;
        uint256 Tariff;
        uint256 Invoice;
        uint256 StationId;
        int ConnectorId;
        int State;        
    }

    struct FieldsLocal {
        string Id;
        uint256 TotalImportRegisterWh;
        uint256 MeterStart;
        uint256 MeterStop;
        uint256 DateStart;
        uint256 DateStop;
        uint256 StationId;
        int ConnectorId;       
    }



    struct MeterValue {
        uint256 TransactionId;
        int ConnectorId;
        uint256 EnergyActiveImportRegister_Wh;
        int CurrentImport_A;
        int CurrentOffered_A;
        int PowerActiveImport_W;
        int Voltage_V;
        int Percent;
    }

    // For Fields.State
    int constant New = 1;
    int constant Preparing = 2;
    int constant Charging = 3;
    int constant Finished = 4;
    int constant Error = 5;
    int constant Cancelled = 6;

    
}


contract Transaction is Initializable {

    uint256 transactionIdcounter;

    string version;

    Station _station;
    Payment _payment;
    string[] _localTransactions;
    mapping (uint256 => TransactionStruct.Fields) Transactions;
    mapping (string => TransactionStruct.FieldsLocal) LocalTransactions;
    mapping (string => uint256) UserToTransaction;

    mapping (uint256 => TransactionStruct.MeterValue[]) MeterValuesData;
    mapping (address => mapping(address => bool)) CreateTransactionAccess;


    event StartTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId, uint256 dateStart, uint256 meterStart);
    event StopTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId, uint256 dateStop, uint256 meterStop);
    event CancelTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId);
    
    event RemoteStartTransaction(uint256 indexed stationId, string clientUrl, int connectorId, string idtag, uint256 indexed transactionId);
    event MeterValues(uint256 indexed stationId, string clientUrl, int connectorId, uint256 indexed transactionId, TransactionStruct.MeterValue  meterValue );
    event RemoteStopTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId, int connectorId, string idtag);
    event RejectTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId);
    // Events for log only
    event StartTransactionLocal(uint256 indexed stationId, string clientUrl, string indexed transactionId, int connectorId,  uint256 dateStart, uint256 meterStart);
    event StopTransactionLocal(uint256 indexed stationId, string clientUrl, string indexed transactionId, uint256 dateStop, uint256 meterStop);

    function initialize(address stationContractAddress, address paymentContractAddress ) public initializer {

        version = "1.0";

        _station = Station(stationContractAddress);
        _payment = Payment(paymentContractAddress);


    }

    function getVersion() public view returns(string memory){
        return version;
    }

    function addPartnerWhoCanCreateTransaction(address addPartner) public {
        CreateTransactionAccess[msg.sender][addPartner] = true;
    }   

    function partnerCanCreateTransaction(address stationOwner, address partner) public view returns(bool) {
        return CreateTransactionAccess[stationOwner][partner];
    }

    function deletePartnerWhoCanCreateTransaction(address deletePartner) public {
        CreateTransactionAccess[msg.sender][deletePartner] = false;
    }


    function getTransactionsCount() public view  returns(uint256){
        return transactionIdcounter;
    }


    function remoteStartTransaction(string memory clientUrl, int connectorId, string memory idtag) public  {
        
        uint256 stationId = _station.getStationIdByUrl(clientUrl);              

        StationStruct.Connectors memory connector  = _station.getConnector(stationId, connectorId);
        StationStruct.Fields memory station = _station.getStation(stationId);

        if(!partnerCanCreateTransaction(station.Owner, msg.sender) ){
            revert("access_denied");
        }   
        
        if(  (connector.Status == StationStruct.Available || connector.Status == StationStruct.SuspendedEVSE || connector.Status == StationStruct.Preparing ) && station.State == StationStruct.Active && UserToTransaction[idtag] == 0 ) {
            
            transactionIdcounter++;

            UserToTransaction[idtag] = transactionIdcounter;

            Transactions[transactionIdcounter] = TransactionStruct.Fields({
                Id: transactionIdcounter,
                Initiator: msg.sender,
                TotalPrice: 0,
                TotalImportRegisterWh: 0,
                Idtag:idtag,
                MeterStart:0,
                MeterStop:0,
                LastMeter:0,
                DateStart:0,
                DateStop:0,
                Tariff:connector.Tariff,
                StationId:stationId,
                ConnectorId:connectorId,
                State: TransactionStruct.New,
                Invoice: 0
            });

            emit RemoteStartTransaction(stationId, clientUrl, connectorId, idtag, transactionIdcounter);

        }else{
            revert("cannot_start_transaction");
        }

    }

    function getUserTransaction(string memory idtag) public view  returns(uint256){
        return UserToTransaction[idtag];
    }

    function rejectTransaction(uint256 transactionId) public   {
        StationStruct.Fields memory station = _station.getStation(Transactions[transactionId].StationId);
        
        if(station.Owner == msg.sender){
            Transactions[transactionId].State = TransactionStruct.Error;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;
            emit RejectTransaction(Transactions[transactionId].StationId, station.ClientUrl, transactionId);                        
        }else{
            revert("access_denied");
        }
            
    }

    function cancelTransaction(string memory clientUrl, uint256 transactionId) public  {
        uint256 stationId = _station.getStationIdByUrl(clientUrl);
        StationStruct.Fields memory station = _station.getStation(stationId);

        if( Transactions[transactionId].Initiator == msg.sender || station.Owner == msg.sender ){
            Transactions[transactionId].State = TransactionStruct.Cancelled;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;
            emit CancelTransaction(stationId, clientUrl, transactionId);
        }else{
            revert("access_denied");
        }
    } 

    function remoteStopTransaction(string memory clientUrl, string memory idtag) public   {
        uint256 stationId = _station.getStationIdByUrl(clientUrl);
        StationStruct.Fields memory station = _station.getStation(stationId);
        uint256 transactionId = UserToTransaction[idtag];

        StationStruct.Connectors memory connector  = _station.getConnector(stationId, Transactions[transactionId].ConnectorId);

        if(  
            (connector.Status == StationStruct.Charging || connector.Status == StationStruct.Preparing) 
            && station.State == StationStruct.Active 
            && (Transactions[transactionId].Initiator == msg.sender || station.Owner == msg.sender
        ) ) {
            emit RemoteStopTransaction(stationId, clientUrl, transactionId, Transactions[transactionId].ConnectorId, idtag);
        }
        
    }

    function getTransaction(uint256 id) public view  returns(TransactionStruct.Fields memory){
        return Transactions[id];
    }

    function getTransactionLocal(string memory transactionId,string memory clientUrl) public view  returns(TransactionStruct.FieldsLocal memory){
        string memory transactionidlocal = string.concat(transactionId,clientUrl);
        return LocalTransactions[transactionidlocal];
    }


    function getTransactionByIdtag(string memory tagId) public view returns(uint256){
        uint256 transactionId =  UserToTransaction[tagId];
        return transactionId;
    }


    function getTransactionsLocal() public view  returns(string[] memory){
        return _localTransactions;
    }    


    function startTransaction(string memory clientUrl, string memory tagId, uint256 dateStart, uint256 meterStart) public  {
        
        uint256  transactionId =  UserToTransaction[tagId];
        StationStruct.Fields memory station = _station.getStation(Transactions[transactionId].StationId);

        if( Transactions[transactionId].Initiator == address(0))
            revert("transaction_not_found");

        if(station.Owner != msg.sender)
            revert("access_denied");

        Transactions[transactionId].MeterStart = meterStart;
        Transactions[transactionId].DateStart = dateStart;
        Transactions[transactionId].State = TransactionStruct.Charging;
        emit StartTransaction(Transactions[transactionId].StationId, clientUrl, transactionId,  dateStart, meterStart);
    }


    function meterValues(string memory clientUrl, int connectorId,uint256 transactionId, TransactionStruct.MeterValue memory meterValue ) public {
        uint256 stationId = _station.getStationIdByUrl(clientUrl);
        StationStruct.Fields memory station = _station.getStation(stationId);
        StationStruct.Connectors memory connector  = _station.getConnector(stationId, connectorId);
        
        if( Transactions[transactionId].Initiator == address(0))
            revert("transaction_not_found");

        if(station.Owner != msg.sender)
            revert("access_denied");

        if( station.Owner == msg.sender && connector.Status == StationStruct.Charging){
            
            //_station.heartbeat( clientUrl, block.timestamp);
            Transactions[transactionId].LastMeter =  meterValue.EnergyActiveImportRegister_Wh;
            MeterValuesData[transactionId].push(meterValue);
            emit MeterValues(stationId, clientUrl, connectorId, transactionId,  meterValue );
        }

    }

    function getMeterValues(uint256 transactionId) public view  returns(TransactionStruct.MeterValue[] memory){
        return MeterValuesData[transactionId];
    }

    function stopTransaction(string memory clientUrl, uint256 transactionId, uint256 dateStop, uint256 meterStop) public  {
        uint256 stationId = _station.getStationIdByUrl(clientUrl);
        StationStruct.Fields memory station = _station.getStation(stationId);
        
        if( station.Owner == msg.sender ){
            Transactions[transactionId].MeterStop = meterStop;
            Transactions[transactionId].TotalImportRegisterWh = Transactions[transactionId].MeterStop-Transactions[transactionId].MeterStart;
            Transactions[transactionId].DateStop = dateStop;
            Transactions[transactionId].State = TransactionStruct.Finished;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;

            (uint256 invoiceid, uint256 amount) = _payment.createInvoice(Transactions[transactionId], station.Owner, transactionId);
            Transactions[transactionId].Invoice = invoiceid;
            Transactions[transactionId].TotalPrice = amount;

            emit StopTransaction(stationId, clientUrl, transactionId, dateStop, meterStop);
        }else{
            revert("access_denied");
        }
    }



    /* Events For Local transaction logs */
   // start transaction Local Event
   // stop transaction Local event
   // meterValue local event

   function startTransactionLocal(string memory clientUrl, string memory transactionId, int connectorId, uint256 dateStart, uint256 meterStart) public   {
        uint256 stationId = _station.getStationIdByUrl(clientUrl);
        StationStruct.Fields memory station = _station.getStation(stationId);
        
        if( station.Owner == msg.sender ){
            string memory transactionidlocal = string.concat(transactionId,clientUrl);
            
            _localTransactions.push(transactionidlocal);

            LocalTransactions[transactionidlocal] = TransactionStruct.FieldsLocal({
                Id: transactionidlocal,
                TotalImportRegisterWh: 0,
                MeterStart:meterStart,
                MeterStop:0,
                DateStart:dateStart,
                DateStop:0,
                StationId:stationId,
                ConnectorId:connectorId
            });
            emit StartTransactionLocal(stationId, clientUrl, transactionidlocal, connectorId, dateStart, meterStart);
        }else{
            revert("access_denied");
        }
   }

   function stopTransactionLocal(string memory clientUrl, string memory transactionId, uint256 dateStop, uint256 meterStop) public {
        uint256 stationId = _station.getStationIdByUrl(clientUrl);
        StationStruct.Fields memory station = _station.getStation(stationId);
        
        if( station.Owner == msg.sender ){
            string memory transactionidlocal = string.concat(transactionId,clientUrl);
            LocalTransactions[transactionidlocal].TotalImportRegisterWh = meterStop-LocalTransactions[transactionidlocal].MeterStart;
            LocalTransactions[transactionidlocal].MeterStop = meterStop;
            LocalTransactions[transactionidlocal].DateStop = dateStop;
            emit StopTransactionLocal(stationId, clientUrl, transactionidlocal,  dateStop, meterStop);
        }else{
            revert("access_denied");
        }
   }

}
