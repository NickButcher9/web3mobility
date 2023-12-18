// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./Payment.sol";
import "./Station.sol";

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
        string LocalId;       
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
    uint256 _LocalTotalImportRegisterWh;
    uint256 _TotalImportRegisterWh;
    mapping(string => uint256) TotalImportRegisterWhByStation;
    mapping(string => uint256) CountBadTransaction;
    mapping(address => uint256) CountBadTransactionByOwner;

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
    event AddTransactionLocal(uint256 indexed stationId, string clientUrl, string indexed transactionId, int connectorId,  uint256 dateStart, uint256 dateStop, uint256 meterStart, uint256 meterStop);

    function initialize(address stationContractAddress, address paymentContractAddress ) public initializer {

        version = "1.0";

        _station = Station(stationContractAddress);
        _payment = Payment(paymentContractAddress);


    }

    function getVersion() public view returns(string memory){
        return version;
    }
    // TODO check is partner in hub contract
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

    function cancelTransaction(uint256 transactionId) public  {
        StationStruct.Fields memory station = _station.getStation(Transactions[transactionId].StationId);

        if( Transactions[transactionId].Initiator == msg.sender || station.Owner == msg.sender ){
            Transactions[transactionId].State = TransactionStruct.Cancelled;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;
            emit CancelTransaction(Transactions[transactionId].StationId, station.ClientUrl, transactionId);
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

    function getTransactionLocal(string memory transactionId) public view  returns(TransactionStruct.FieldsLocal memory){
        return LocalTransactions[transactionId];
    }


    function getTransactions(uint offset, uint limit) public view  returns(TransactionStruct.Fields[] memory){
        TransactionStruct.Fields[] memory ret = new TransactionStruct.Fields[](offset+limit);
        for (uint i = offset; i < offset+limit; i++) {
            if(i == transactionIdcounter)
                break;

            ret[i] = Transactions[i+1];
        }

        return ret;
    }

    function getTransactionsLocal(uint offset, uint limit) public view returns(TransactionStruct.FieldsLocal[] memory){
        TransactionStruct.FieldsLocal[] memory ret = new TransactionStruct.FieldsLocal[](limit+2);
        uint b = 0;
        for (uint i = offset; i < offset+limit; i++) {

            if(i == _localTransactions.length)
                break;
                
            ret[b] = LocalTransactions[_localTransactions[i]];
            b++;
        }

        return ret;
    }


    function getTransactionsLocalCount() public view  returns(uint256){
        return _localTransactions.length;
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

            if(Transactions[transactionId].DateStart == 0){
                revert("transaction_not_started");
            }

            if(Transactions[transactionId].DateStop > 0){
                revert("transaction_already_stoped");
            }


            Transactions[transactionId].MeterStop = meterStop;
            Transactions[transactionId].TotalImportRegisterWh = Transactions[transactionId].MeterStop-Transactions[transactionId].MeterStart;

            uint256 alertTransaction = 1*(10**18);

            if(Transactions[transactionId].TotalImportRegisterWh < alertTransaction){
                CountBadTransaction[clientUrl] += 1;
                CountBadTransactionByOwner[station.Owner] +=1;
            }

            _TotalImportRegisterWh += Transactions[transactionId].TotalImportRegisterWh;
            TotalImportRegisterWhByStation[clientUrl] += Transactions[transactionId].TotalImportRegisterWh;
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
            string memory transactionidlocal = string.concat(transactionId,"-",clientUrl);

            if(LocalTransactions[transactionidlocal].DateStart > 0){
                revert("already_exist");
            }

            
            _localTransactions.push(transactionidlocal);

            LocalTransactions[transactionidlocal] = TransactionStruct.FieldsLocal({
                Id: transactionidlocal,
                TotalImportRegisterWh: 0,
                MeterStart:meterStart,
                MeterStop:0,
                DateStart:dateStart,
                DateStop:0,
                StationId:stationId,
                ConnectorId:connectorId,
                LocalId:transactionId
            });
            emit StartTransactionLocal(stationId, clientUrl, transactionidlocal, connectorId, dateStart, meterStart);
        }else{
            revert("access_denied");
        }
   }

   function addTransactionLocal(string memory clientUrl, string memory transactionId, int connectorId, uint256 dateStart, uint256 dateStop, uint256 meterStart, uint256 meterStop) public   {
    uint256 stationId = _station.getStationIdByUrl(clientUrl);
    StationStruct.Fields memory station = _station.getStation(stationId);
    
    if( station.Owner == msg.sender ){
        string memory transactionidlocal = string.concat(transactionId,"-",clientUrl);

        if(LocalTransactions[transactionidlocal].DateStart > 0){
            revert("already_exist");
        }

        
        _localTransactions.push(transactionidlocal);

        LocalTransactions[transactionidlocal] = TransactionStruct.FieldsLocal({
            Id: transactionidlocal,
            TotalImportRegisterWh: meterStop-meterStart,
            MeterStart:meterStart,
            MeterStop:meterStop,
            DateStart:dateStart,
            DateStop:dateStop,
            StationId:stationId,
            ConnectorId:connectorId,
            LocalId:transactionId
        });

        _LocalTotalImportRegisterWh += LocalTransactions[transactionidlocal].TotalImportRegisterWh;
        TotalImportRegisterWhByStation[clientUrl] += LocalTransactions[transactionidlocal].TotalImportRegisterWh;

        emit AddTransactionLocal(stationId, clientUrl, transactionidlocal, connectorId, dateStart, dateStop, meterStart, meterStop);
    }else{
        revert("access_denied");
    }
}

   function stopTransactionLocal(string memory clientUrl, string memory transactionId, uint256 dateStop, uint256 meterStop) public {
        uint256 stationId = _station.getStationIdByUrl(clientUrl);
        StationStruct.Fields memory station = _station.getStation(stationId);
        
        

        if( station.Owner == msg.sender ){
            string memory transactionidlocal = string.concat(transactionId,"-",clientUrl);

            if(LocalTransactions[transactionidlocal].DateStart > 0){

                if(LocalTransactions[transactionidlocal].DateStop == 0){
                    LocalTransactions[transactionidlocal].TotalImportRegisterWh = meterStop-LocalTransactions[transactionidlocal].MeterStart;

                    uint256 alertTransaction = 1*(10**18);
        
                    if(LocalTransactions[transactionidlocal].TotalImportRegisterWh < alertTransaction){
                        CountBadTransaction[clientUrl] +=1;
                        CountBadTransactionByOwner[station.Owner] +=1;
                    }
        
                    _LocalTotalImportRegisterWh += LocalTransactions[transactionidlocal].TotalImportRegisterWh;
                    TotalImportRegisterWhByStation[clientUrl] += LocalTransactions[transactionidlocal].TotalImportRegisterWh;
                    LocalTransactions[transactionidlocal].MeterStop = meterStop;
                    LocalTransactions[transactionidlocal].DateStop = dateStop;
                    emit StopTransactionLocal(stationId, clientUrl, transactionidlocal,  dateStop, meterStop);
                }else{
                    revert("already_stoped");
                }


            }else{
                revert("local_transaction_not_found");
            }

        }else{
            revert("access_denied");
        }
   }


    function brandRate() public view returns(string[] memory, uint256[] memory,string[] memory, address[] memory){
        string[] memory StationIndexClientUrl =  _station.getStationIndexClientUrl();
        
        uint256[] memory values = new uint256[](StationIndexClientUrl.length);
        string[] memory vendor = new string[](StationIndexClientUrl.length);
        address[] memory partner = new address[](StationIndexClientUrl.length);


        for (uint i = 0; i < StationIndexClientUrl.length; i++) {
            StationStruct.Fields memory station = _station.getStationByUrl(StationIndexClientUrl[i]);
            values[i] = CountBadTransaction[StationIndexClientUrl[i]];
            vendor[i] = station.ChargePointVendor;
            partner[i] = station.Owner;
        }

        return (StationIndexClientUrl, values,vendor,partner);
    }


    function getTotalImportRegisterWhByStations() public view returns(string[] memory, uint256[] memory, string[] memory,address[] memory){
        string[] memory StationIndexClientUrl =  _station.getStationIndexClientUrl();
        
        uint256[] memory values = new uint256[](StationIndexClientUrl.length);
        string[] memory names = new string[](StationIndexClientUrl.length);
        address[] memory partner = new address[](StationIndexClientUrl.length);

        for (uint i = 0; i < StationIndexClientUrl.length; i++) {
            StationStruct.Fields memory station = _station.getStationByUrl(StationIndexClientUrl[i]);

            values[i] = TotalImportRegisterWhByStation[StationIndexClientUrl[i]];

            names[i] = string.concat(station.Name, " ", station.ChargePointVendor);
            partner[i] = station.Owner;
        }

        return (StationIndexClientUrl, values,names,partner);
    }    
    function getTotalImportRegisterWhByStation(string memory clientUrl) public view returns(uint256){
        return TotalImportRegisterWhByStation[clientUrl];
    }

    function getCountBadTransactionByOwner(address owner) public view returns(uint256){
        return CountBadTransactionByOwner[owner];
    }

    function getLocalTotalImportRegisterWh() public view returns(uint256){
        return _LocalTotalImportRegisterWh;
    }

    function getTotalImportRegisterWh() public view returns(uint256){
        return _TotalImportRegisterWh;
    }

   

}
