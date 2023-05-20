// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./OCPPStructs.sol";
import "./Payment.sol";

contract OCPP is Initializable, AccessControlUpgradeable, Payment {

    uint256 transactionIdcounter;
    uint256 stationIndex;
    string version;

    bytes32 public constant MANAGESTATION = keccak256("MANAGESTATION");
    bytes32 public constant PARTNER = keccak256("PARTNER");
    bytes32 public constant VIEW = keccak256("VIEW");

    mapping (uint256 => TransactionStruct.Fields) Transactions;
    mapping (string => uint256) UserToTransaction;
    mapping (uint256 => StationStruct.Fields)  Stations;
    mapping (string => uint256) ClientUrlById;
    mapping (uint256 => TransactionStruct.MeterValue[]) MeterValuesData;
    mapping (address => mapping(address => bool)) CreateTransactionAccess;

    event BootNotification(uint256 indexed stationId, string clientUrl, uint256 timestamp);
    event StatusNotification(uint256 indexed stationId, string clientUrl, int connectorId, int status, int errorCode );
    event Heartbeat(uint256 indexed stationId, string clientUrl, uint256 timestamp);
    event StartTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId, uint256 dateStart, uint256 meterStart);
    event StopTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId, uint256 dateStop, uint256 meterStop);
    event CancelTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId);
    event ChangeStateStation(uint256 indexed stationId, string clientUrl, bool state);
    event RemoteStartTransaction(uint256 indexed stationId, string clientUrl, int connectorId, string idtag, uint256 indexed transactionId);
    event MeterValues(uint256 indexed stationId, string clientUrl, int connectorId, uint256 indexed transactionId, TransactionStruct.MeterValue  meterValue );
    event RemoteStopTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId, int connectorId, string idtag);
    event RejectTransaction(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId);
    // Events for log only
    event StartTransactionLocal(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId,  uint256 dateStart, uint256 meterStart, string tagId);
    event StopTransactionLocal(uint256 indexed stationId, string clientUrl, uint256 indexed transactionId, uint256 dateStop, uint256 meterStop);
    event MeterValuesLocal(uint256 indexed stationId, string clientUrl, int connectorId, uint256 indexed transactionId, TransactionStruct.MeterValue  meterValue );

    function initialize(Tariff calldata _tariff) public initializer {

        transactionIdcounter = 0;
        stationIndex = 0;
        version = "1.0";

        __Tariffs_init(_tariff);
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGESTATION, msg.sender);
        _grantRole(PARTNER, msg.sender);
        _grantRole(VIEW, msg.sender);
    }

    function addPartnerWhoCanCreateTransaction(address addPartner) public onlyRole(MANAGESTATION) {
        CreateTransactionAccess[msg.sender][addPartner] = true;
    }   

    function partnerCanCreateTransaction(address stationOwner, address partner) public view returns(bool) {
        return CreateTransactionAccess[stationOwner][partner];
    }

    function deletePartnerWhoCanCreateTransaction(address deletePartner) public onlyRole(MANAGESTATION) {
        CreateTransactionAccess[msg.sender][deletePartner] = false;
    }


    function getTransactionsCount() public view returns(uint256){
        return transactionIdcounter;
    }
    function getStationsCount() public view returns(uint256){
        return stationIndex;
    }


    function addStation(StationStruct.Fields calldata station) public onlyRole(MANAGESTATION) returns(uint256){
  
        
        require(station.Owner == msg.sender, "owner_incorrect");
             
        if(ClientUrlById[station.ClientUrl] > 0)
            revert("already_exist");

        stationIndex++;
        Stations[stationIndex] = station;
        
        ClientUrlById[station.ClientUrl] = stationIndex;
        return stationIndex;
    }


    function updateStationName(uint256 id, string calldata name) public  onlyRole(MANAGESTATION) {
        Stations[id].Name = name;
    }


    function updateStationLocation(uint256 id, string calldata lat, string calldata lon) public  onlyRole(MANAGESTATION) {
        Stations[id].LocationLat = lat;
        Stations[id].LocationLon = lon;
    }


    function updateStationAddress(uint256 id, string calldata _address) public  onlyRole(MANAGESTATION) {
        Stations[id].Address = _address;
    }

    function updateStationTime(uint256 id, string calldata time) public  onlyRole(MANAGESTATION) {
        Stations[id].Time = time;
    }

    function updateStationDescription(uint256 id, string calldata desc) public  onlyRole(MANAGESTATION) {
        Stations[id].Description = desc;
    }


    function updateStationUrl(uint256 id, string calldata url) public  onlyRole(MANAGESTATION) {
        Stations[id].Url = url;
    }


    function getStation(uint256 stationId) public view onlyRole(VIEW) returns(StationStruct.Fields memory){
        StationStruct.Fields memory station = Stations[stationId];

        if( station.Owner == address(0))
            revert("station_not_found");

        return station;
    }

    function getStations() public view onlyRole(VIEW) returns(StationStruct.Fields[] memory){
        StationStruct.Fields[] memory ret = new StationStruct.Fields[](stationIndex);
        for (uint256 index = 1; index <= stationIndex; index++) {
            
            ret[index-1] = Stations[index];
        }

        return ret;
    }


    function getStationByUrl(string memory clientUrl) public view onlyRole(VIEW) returns(StationStruct.Fields memory){
        uint256 stationId = ClientUrlById[clientUrl];
        StationStruct.Fields memory station = Stations[stationId];
        
        if( station.Owner == address(0))
            revert("station_not_found");
        
        return station;
    }

    function getStationIdByUrl(string memory clientUrl) public view onlyRole(VIEW) returns(uint256){
        return ClientUrlById[clientUrl];              
    }

    function setState(string memory clientUrl, bool state) public {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");
        
        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        Stations[stationId].State = state;
        emit ChangeStateStation(stationId, clientUrl, state);
    }


    function getConnector(uint256 stationId, int connectorId) public view onlyRole(VIEW) returns(StationStruct.Connectors memory connector){
        StationStruct.Fields memory station = Stations[stationId];

        for (uint256 index = 0; index < station.Connectors.length; index++) {
            StationStruct.Connectors memory c = station.Connectors[index];

            if (c.ConnectorId == connectorId) {
                return c;
            }
        }

        revert("not_found");
    }

    function bootNotification(string memory clientUrl) public {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");

        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");
        
        if(Stations[stationId].IsActive){
           Stations[stationId].Heartbeat = block.timestamp; 
           emit BootNotification(stationId, clientUrl, block.timestamp);
        }
    }

    function statusNotification(string memory clientUrl, int connectorId, int status, int errorCode) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");

        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");
        
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

    function heartbeat(string memory clientUrl, uint256 timestamp) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");

        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");
        

        Stations[stationId].Heartbeat = timestamp;
        emit Heartbeat(stationId, clientUrl, timestamp);
    }

    function statusNotificationTriggers(StationStruct.Connectors memory connector, uint256 stationId) private {

    }



    function remoteStartTransaction(string memory clientUrl, int connectorId, string memory idtag) public onlyRole(PARTNER) {
        
        uint256 stationId = ClientUrlById[clientUrl];              

        StationStruct.Connectors memory connector  = getConnector(stationId, connectorId);


        if(!partnerCanCreateTransaction(Stations[stationId].Owner, msg.sender) ){
            revert("access_denied");
        }   
        
        if(  (connector.Status == StationStruct.Available || connector.Status == StationStruct.SuspendedEVSE || connector.Status == StationStruct.Preparing ) && Stations[stationId].State == StationStruct.Active && UserToTransaction[idtag] == 0 ) {
            
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

    function getUserTransaction(string memory idtag) public view onlyRole(VIEW) returns(uint256){
        return UserToTransaction[idtag];
    }

    function rejectTransaction(uint256 transactionId) public onlyRole(VIEW)  {
        
        if(Stations[Transactions[transactionId].StationId].Owner == msg.sender){
            Transactions[transactionId].State = TransactionStruct.Error;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;
            emit RejectTransaction(Transactions[transactionId].StationId, Stations[Transactions[transactionId].StationId].ClientUrl, transactionId);                        
        }else{
            revert("access_denied");
        }
            
    }

    function cancelTransaction(string memory clientUrl, uint256 transactionId) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if( Transactions[transactionId].Initiator == msg.sender || Stations[stationId].Owner == msg.sender ){
            Transactions[transactionId].State = TransactionStruct.Cancelled;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;
            emit CancelTransaction(stationId, clientUrl, transactionId);
        }else{
            revert("access_denied");
        }
    } 

    function remoteStopTransaction(string memory clientUrl, string memory idtag) public onlyRole(PARTNER) {
        uint256 stationId = ClientUrlById[clientUrl];
        uint256 transactionId = UserToTransaction[idtag];

        StationStruct.Connectors memory connector  = getConnector(stationId, Transactions[transactionId].ConnectorId);

        if(  
            (connector.Status == StationStruct.Charging || connector.Status == StationStruct.Preparing) 
            && Stations[stationId].State == StationStruct.Active 
            && (Transactions[transactionId].Initiator == msg.sender || Stations[Transactions[transactionId].StationId].Owner == msg.sender
        ) ) {
            emit RemoteStopTransaction(stationId, clientUrl, transactionId, Transactions[transactionId].ConnectorId, idtag);
        }
        
    }

    function getTransaction(uint256 id) public view returns(TransactionStruct.Fields memory){
        return Transactions[id];
    }

    function getTransactionByIdtag(string memory tagId) public view returns(uint256){
        uint256 transactionId =  UserToTransaction[tagId];
        return transactionId;
    }

    function getTransactions() public view returns(TransactionStruct.Fields[] memory){
        TransactionStruct.Fields[] memory ret = new TransactionStruct.Fields[](transactionIdcounter);
        for (uint256 index = 1; index <= stationIndex; index++) {
            
            ret[index-1] = Transactions[index];
        }

        return ret;
    }    

    function startTransaction(string memory clientUrl, string memory tagId, uint256 dateStart, uint256 meterStart) public {
        
        uint256  transactionId =  UserToTransaction[tagId];

        if( Transactions[transactionId].Initiator == address(0))
            revert("transaction_not_found");

        if(Stations[Transactions[transactionId].StationId].Owner != msg.sender)
            revert("access_denied");

        Transactions[transactionId].MeterStart = meterStart;
        Transactions[transactionId].DateStart = dateStart;
        Transactions[transactionId].State = TransactionStruct.Charging;
        emit StartTransaction(Transactions[transactionId].StationId, clientUrl, transactionId,  dateStart, meterStart);
    }


    function meterValues(string memory clientUrl, int connectorId,uint256 transactionId, TransactionStruct.MeterValue memory meterValue ) public {
        uint256 stationId = ClientUrlById[clientUrl];
        StationStruct.Connectors memory connector  = getConnector(stationId, connectorId);
        
        if( Transactions[transactionId].Initiator == address(0))
            revert("transaction_not_found");

        if(Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        if( Stations[stationId].Owner == msg.sender && connector.Status == StationStruct.Charging){
            
            Stations[stationId].Heartbeat = block.timestamp;
            Transactions[transactionId].LastMeter =  meterValue.EnergyActiveImportRegister_Wh;
            MeterValuesData[transactionId].push(meterValue);
            emit MeterValues(stationId, clientUrl, connectorId, transactionId,  meterValue );
        }

    }

    function getMeterValues(uint256 transactionId) public view returns(TransactionStruct.MeterValue[] memory){
        return MeterValuesData[transactionId];
    }

    function stopTransaction(string memory clientUrl, uint256 transactionId, uint256 dateStop, uint256 meterStop) public {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if( Stations[stationId].Owner == msg.sender ){
            Transactions[transactionId].MeterStop = meterStop;
            Transactions[transactionId].TotalImportRegisterWh = Transactions[transactionId].MeterStop-Transactions[transactionId].MeterStart;
            Transactions[transactionId].DateStop = dateStop;
            Transactions[transactionId].State = TransactionStruct.Finished;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;

            (uint256 invoiceid, uint256 amount) = __createInvoice(Transactions[transactionId], Stations[stationId].Owner, transactionId);
            Transactions[transactionId].Invoice = invoiceid;
            Transactions[transactionId].TotalPrice = amount;

            emit StopTransaction(stationId, clientUrl, transactionId, dateStop, meterStop);
        }else{
            revert("access_denied");
        }
    }


    function getTariff(uint256 id) public view returns(Tariff memory){
        return _getTariff(id);
    }

    function updateTariff(uint256 id, Tariff calldata _tariff) public {
        if(msg.sender != tariffs[id].owner){
            revert("access_denied");
        }

        _updateTariff(id, _tariff);
    }

    function getInvoice(uint256 id) public view returns(Invoice memory){
        return _getInvoice(id);
    }




    /* Events For Local transaction logs */
   // start transaction Local Event
   // stop transaction Local event
   // meterValue local event

   function startTransactionLocal(string memory clientUrl, uint256 transactionId, string memory tagId, uint256 dateStart, uint256 meterStart) public {
        uint256 stationId = ClientUrlById[clientUrl];
        emit StartTransactionLocal(stationId, clientUrl, transactionId,  dateStart, meterStart, tagId);
   }

   function stopTransactionLocal(string memory clientUrl, uint256 transactionId, uint256 dateStop, uint256 meterStop) public {
        uint256 stationId = ClientUrlById[clientUrl];
        emit StopTransactionLocal(stationId, clientUrl, transactionId,  dateStop, meterStop);
   }

   function meterValuesLocal(string memory clientUrl, int connectorId, uint256 transactionId, TransactionStruct.MeterValue memory meterValue) public{
        uint256 stationId = ClientUrlById[clientUrl];
        emit MeterValuesLocal(stationId, clientUrl, connectorId, transactionId,  meterValue );
   }
}
