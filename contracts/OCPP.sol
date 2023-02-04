// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./OCPPStructs.sol";

contract OCPP is Initializable {

    uint256 transactionIdcounter;
    uint256 stationIndex;

    mapping (uint256 => TransactionStruct.Fields) Transactions;
    mapping (string => uint256) UserToTransaction;
    mapping (uint256 => StationStruct.Fields)  Stations;
    mapping (string => uint256) ClientUrlById;
    mapping (uint256 => TransactionStruct.MeterValue[]) MeterValuesData;
    

    event BootNotification(uint256 indexed stationId, string clientUrl, uint256 timestamp);
    event StatusNotification(uint256 indexed stationId, string clientUrl, int connectorId, int status, int errorCode );
    event Heartbeat(string clientUrl, uint256 timestamp);
    event StartTransaction(string clientUrl, uint256 indexed transactionId, uint256 dateStart, uint256 meterStart);
    event StopTransaction(string clientUrl, uint256 indexed transactionId, uint256 dateStop, uint256 meterStop);
    event CancelTransaction(string clientUrl, uint256 indexed transactionId);
    event ChangeStateStation(uint256 indexed stationId, string clientUrl, bool state);
    event RemoteStartTransaction(string clientUrl, int connectorId, string idtag, uint256 indexed transactionId);
    event MeterValues(string clientUrl, int connectorId, uint256 indexed transactionId, TransactionStruct.MeterValue  meterValue );
    event RemoteStopTransaction(string clientUrl, uint256 indexed transactionId, int connectorId, string idtag);
    event RejectTransaction(uint256 indexed transactionId);

    function initialize() public initializer {
        stationIndex = 0;
        transactionIdcounter = 0;
    }


    function getTransactionsCount() public view returns(uint256){
        return transactionIdcounter;
    }
    function getStationsCount() public view returns(uint256){
        return stationIndex;
    }


    function addStation(StationStruct.Fields calldata station) public returns(uint256){
  
        
        require(station.Owner == msg.sender, "owner_incorrect");
             
        if(ClientUrlById[station.ClientUrl] > 0)
            revert("already_exist");

        stationIndex++;
        Stations[stationIndex] = station;
        
        ClientUrlById[station.ClientUrl] = stationIndex;
        return stationIndex;
    }

    function getStation(uint256 stationId) public view returns(StationStruct.Fields memory){
        StationStruct.Fields memory station = Stations[stationId];

        if( station.Owner == address(0))
            revert("station_not_found");

        return station;
    }

    function getStations() public view returns(StationStruct.Fields[] memory){
        StationStruct.Fields[] memory ret = new StationStruct.Fields[](stationIndex);
        for (uint256 index = 1; index <= stationIndex; index++) {
            
            ret[index-1] = Stations[index];
        }

        return ret;
    }


    function getStationByUrl(string memory clientUrl) public view returns(StationStruct.Fields memory){
        uint256 stationId = ClientUrlById[clientUrl];
        StationStruct.Fields memory station = Stations[stationId];
        
        if( station.Owner == address(0))
            revert("station_not_found");
        
        return station;
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


    function getConnector(uint256 stationId, int connectorId) public view returns(StationStruct.Connectors memory connector){
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

    function heartbeat(string memory clientUrl) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");

        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");
        

        Stations[stationId].Heartbeat = block.timestamp;
        emit Heartbeat(clientUrl, block.timestamp);
    }

    function statusNotificationTriggers(StationStruct.Connectors memory connector, uint256 stationId) private {

    }



    function remoteStartTransaction(string memory clientUrl, int connectorId, string memory idtag) public  {
        
        uint256 stationId = ClientUrlById[clientUrl];              

        StationStruct.Connectors memory connector  = getConnector(stationId, connectorId);
        
        if(  (connector.Status == StationStruct.Available || connector.Status == StationStruct.SuspendedEVSE || connector.Status == StationStruct.Preparing ) && Stations[stationId].State == StationStruct.Active && UserToTransaction[idtag] == 0 ) {
            
            transactionIdcounter++;

            UserToTransaction[idtag] = transactionIdcounter;

            Transactions[transactionIdcounter] = TransactionStruct.Fields({
                Initiator: msg.sender,
                TotalPrice: 0,
                TotalImportRegisterWh: 0,
                IsPaidToOwner: false,
                Idtag:idtag,
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

        }else{
            revert("cannot_start_transaction");
        }

    }

    function getUserTransaction(string memory idtag) public view returns(uint256){
        return UserToTransaction[idtag];
    }

    function rejectTransaction(uint256 transactionId) public {
        Transactions[transactionId].State = TransactionStruct.Error;
        UserToTransaction[Transactions[transactionId].Idtag] = 0;

        if(Transactions[transactionId].Initiator == msg.sender)
            emit RejectTransaction(transactionId);
    }

    function remoteStopTransaction(string memory clientUrl, string memory idtag) public {
        uint256 stationId = ClientUrlById[clientUrl];
        uint256 transactionId = UserToTransaction[idtag];

        StationStruct.Connectors memory connector  = getConnector(stationId, Transactions[transactionId].ConnectorId);

        if(  (connector.Status == StationStruct.Charging || connector.Status == StationStruct.Preparing) && Stations[stationId].State == StationStruct.Active && Transactions[transactionId].Initiator == msg.sender) {
            emit RemoteStopTransaction(clientUrl, transactionId, Transactions[transactionId].ConnectorId, idtag);
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

        Transactions[transactionId].MeterStart = meterStart;
        Transactions[transactionId].DateStart = dateStart;
        Transactions[transactionId].State = TransactionStruct.Preparing;
        emit StartTransaction(clientUrl, transactionId,  dateStart, meterStart);
    }


    function meterValues(string memory clientUrl, int connectorId,uint256 transactionId, TransactionStruct.MeterValue memory meterValue ) public {
        uint256 stationId = ClientUrlById[clientUrl];
        StationStruct.Connectors memory connector  = getConnector(stationId, connectorId);

        if( Transactions[transactionId].Initiator == msg.sender && connector.Status == StationStruct.Charging){
            
            Stations[stationId].Heartbeat = block.timestamp;
            Transactions[transactionId].State = TransactionStruct.Charging;
            Transactions[transactionId].LastMeter =  meterValue.EnergyActiveImportRegister_Wh;
            MeterValuesData[transactionId].push(meterValue);
            emit MeterValues(clientUrl, connectorId, transactionId,  meterValue );
        }

    }

    function getMeterValues(uint256 transactionId) public view returns(TransactionStruct.MeterValue[] memory){
        return MeterValuesData[transactionId];
    }

    function stopTransaction(string memory clientUrl, uint256 transactionId, uint256 dateStop, uint256 meterStop) public {
        if( Transactions[transactionId].Initiator == msg.sender ){
            Transactions[transactionId].MeterStop = meterStop;
            Transactions[transactionId].TotalImportRegisterWh = Transactions[transactionId].MeterStop-Transactions[transactionId].MeterStart;
            Transactions[transactionId].DateStop = dateStop;
            Transactions[transactionId].State = TransactionStruct.Finished;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;

            if(  Transactions[transactionId].ConnectorPriceFor == TransactionStruct.Kw){
                Transactions[transactionId].TotalPrice = (Transactions[transactionId].TotalImportRegisterWh/1000)*Transactions[transactionId].ConnectorPrice;
            }
            

            emit StopTransaction(clientUrl, transactionId, dateStop, meterStop);
        }else{
            revert("access_denied");
        }
    }

    function cancelTransaction(string memory clientUrl, uint256 transactionId) public {
        if( Transactions[transactionId].Initiator == msg.sender ){
            Transactions[transactionId].State = TransactionStruct.Cancelled;
            UserToTransaction[Transactions[transactionId].Idtag] = 0;
            emit CancelTransaction(clientUrl, transactionId);
        }else{
            revert("access_denied");
        }
    }    
}
