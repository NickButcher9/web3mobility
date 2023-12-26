// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./HUB.sol";
import "hardhat/console.sol";

library StationStruct {

    struct Connectors {
        int Power; // kW 
        int ConnectorId;
        int connectorType; //
        int Status; // 1 - avaliable, 2 - preparing, 3 - charging, 4 - finished, 5 - error
        int ErrorCode;
        uint Tariff;
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

        string Name;
        string LocationLat;
        string LocationLon;
        string Address;
        string Time;
        string Description;
        string Url;
        int Power;

        string ClientUrl;
        address Owner;        
        string ChargePointModel;
        string ChargePointVendor;
        string ChargeBoxSerialNumber;
        string FirmwareVersion;
        bool IsActive;
        bool State; 

        int Type; // 1 = AC, 2 = DC, 3 = Mixed
        uint256 OcppInterval;
        uint256 Heartbeat;
        Connectors[] Connectors;
        uint256 OfflineCounter;
        uint256 SyncId;
    }
}


contract Station is Initializable {
    mapping (uint256 => StationStruct.Fields)  Stations;
    mapping (string => uint256) ClientUrlById;
    mapping (address => uint256[]) stationPartners;

    uint256 stationIndex;
    HUB _hub;
    string version;
    string[] stationIndexClientUrl;

    event BootNotification(uint256 indexed stationId, string clientUrl, uint256 timestamp);
    event StatusNotification(uint256 indexed stationId, string clientUrl, int connectorId, int status, int errorCode );
    event Heartbeat(uint256 indexed stationId, string clientUrl, uint256 timestamp);
    event ChangeStateStation(uint256 indexed stationId, string clientUrl, bool state);
    event ChangeIsActiveStation(uint256 indexed stationId, string clientUrl, bool state);
    event AddStation(uint256 indexed stationId, string clientUrl);
    event UpdateStation(uint256 indexed stationId, string clientUrl, string change);

    function initialize(address hubContract) public initializer {
        _hub = HUB(hubContract);
        version = "1.1";
    }

    function getVersion() public view returns(string memory){
        return version;
    }

    function addStation(StationStruct.Fields calldata station) public returns(uint256){
  
        if(!_hub.isPartner(msg.sender))
            revert("access_denied");
        
        require(station.Owner == msg.sender, "owner_incorrect");
             
        if(ClientUrlById[station.ClientUrl] > 0)
            revert("already_exist");

        stationIndex++;
        Stations[stationIndex] = station;
        
        ClientUrlById[station.ClientUrl] = stationIndex;
        stationPartners[station.Owner].push(stationIndex);
        stationIndexClientUrl.push(station.ClientUrl);
        emit AddStation(stationIndex, station.ClientUrl);
        return stationIndex;
    }


    function transfer(string memory clientUrl,address to) public{
        uint256 stationId = ClientUrlById[clientUrl];
        StationStruct.Fields memory station = Stations[stationId];

        if(Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        if(!_hub.isPartner(to))
            revert("recipient_not_partner");



        uint index = 0;

        for (uint i = 0; i < stationPartners[station.Owner].length; i++) {
            if(stationPartners[station.Owner][i] == stationId){
                index = i;
                break;
            }
        }

        if(index == 0)
            revert("station_not_found_in_index");

        
        stationPartners[station.Owner][index] = stationPartners[station.Owner][stationPartners[station.Owner].length - 1];
        stationPartners[station.Owner].pop();
        Stations[stationId].Owner = to;
        stationPartners[to].push(stationId);

    }

    function getPartnersStationIds(address partner) public view returns(uint256[] memory){
        return stationPartners[partner];
    }


    function getStationsCount() public view  returns(uint256){
        return stationIndex;
    }

    function getContStationTypes() public view returns(uint256,uint256){
        uint256  dcType = 0;
        uint256  acType = 0;

        
        for (uint256 index = 1; index <= stationIndex; index++) {
            
           if( Stations[index].Type == 1){
                acType++;
           }else if(Stations[index].Type == 2){
                dcType++;
           }
        }

        return (dcType,acType);
    }

    function getStationIndexClientUrl() public view returns(string[] memory){
        return stationIndexClientUrl;
    }



    function getStation(uint256 stationId) public view    returns(StationStruct.Fields memory){
        StationStruct.Fields memory station = Stations[stationId];

        if( station.Owner == address(0))
            revert("station_not_found");

        return station;
    }

    function getStations(uint offset, uint limit) public view  returns(StationStruct.Fields[] memory){
        
        uint256 output = limit;

        if(stationIndex-offset < limit)
            output = stationIndex-offset;
        
        StationStruct.Fields[] memory ret = new StationStruct.Fields[](output);
        
        if(offset > stationIndex)
            ret = new StationStruct.Fields[](0);
        
        uint b = 0;
        for ( uint i = offset; i < offset+limit; i++) {
            if(i == stationIndex)
                break;

            ret[b] = Stations[i+1];
            b++;
        }

        return ret;
    }

    function getStationByUrl(string memory clientUrl) public view   returns(StationStruct.Fields memory){
        uint256 stationId = ClientUrlById[clientUrl];
        StationStruct.Fields memory station = Stations[stationId];
        
        if( station.Owner == address(0))
            revert("station_not_found");
        
        return station;
    }

    function getStationIdByUrl(string memory clientUrl) public view    returns(uint256){
        return ClientUrlById[clientUrl];              
    }

    function getConnector(uint256 stationId, int connectorId) public view   returns(StationStruct.Connectors memory connector){
        StationStruct.Fields memory station = Stations[stationId];

        for (uint256 index = 0; index < station.Connectors.length; index++) {
            StationStruct.Connectors memory c = station.Connectors[index];

            if (c.ConnectorId == connectorId) {
                return c;
            }
        }

        revert("not_found");
    }

    function updateConnectorType(string memory clientUrl, int connectorId, int _type ) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if(Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        for (uint256 index = 0; index < Stations[stationId].Connectors.length; index++) {
            if (Stations[stationId].Connectors[index].ConnectorId == connectorId) {
                Stations[stationId].Connectors[index].connectorType = _type;
                emit UpdateStation(stationId, clientUrl, "update_connector_type");
                return;
            }
        }

        revert("connector_not_found");
    }

    function updateConnectorPower(string memory clientUrl, int connectorId, int power ) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if(Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        for (uint256 index = 0; index < Stations[stationId].Connectors.length; index++) {
            if (Stations[stationId].Connectors[index].ConnectorId == connectorId) {
                Stations[stationId].Connectors[index].Power = power;
                emit UpdateStation(stationId, clientUrl, "update_connector_power");
                return;
            }
        }
        

        revert("connector_not_found");
    }

    function updateConnectorTariff(string memory clientUrl, int connectorId, uint tariff ) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if(Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        for (uint256 index = 0; index < Stations[stationId].Connectors.length; index++) {
            if (Stations[stationId].Connectors[index].ConnectorId == connectorId) {
                Stations[stationId].Connectors[index].Tariff = tariff;
                emit UpdateStation(stationId, clientUrl, "update_connector_tariff");
                return;
            }
        }
        

        revert("connector_not_found");
    }



    function updateStationSyncId(string memory clientUrl, uint256 syncId) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if(Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        Stations[stationId].SyncId = syncId;

        emit UpdateStation(stationId, clientUrl, "update_station_syncid");
    }


    function updateStationLocation(string memory clientUrl, string calldata lat, string calldata lon) public {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if(Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        Stations[stationId].LocationLat = lat;
        Stations[stationId].LocationLon = lon;

        emit UpdateStation(stationId, clientUrl, "update_station_location");
    }

    function updateStationField(string memory clientUrl, string calldata value, uint key) public {
        uint256 stationId = ClientUrlById[clientUrl];

        if(Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        if(key == 1)
            Stations[stationId].Name = value;

        if(key == 2)
            Stations[stationId].Address = value;

        if(key == 3)
            Stations[stationId].Time = value;

        if(key == 4)
            Stations[stationId].Description = value;

        if(key == 5)
            Stations[stationId].Url = value;
            
        emit UpdateStation(stationId, clientUrl, "update_station");
    }

    function setState(string memory clientUrl, bool state) public {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");
        
        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        if(Stations[stationId].State != state){
            Stations[stationId].State = state;

            if(!state)
                Stations[stationId].OfflineCounter +=1;
    
            emit ChangeStateStation(stationId, clientUrl, state);
        }


    }




    function bootNotification(string memory clientUrl, uint256 timestamp) public  {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");

        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");
        
        if(Stations[stationId].IsActive){
           Stations[stationId].Heartbeat = timestamp; 
           emit BootNotification(stationId, clientUrl, timestamp);
        }
    }

    function statusNotification(string memory clientUrl, int connectorId, int status, int errorCode) public  {
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
        
        setState(clientUrl, true);

        Stations[stationId].Heartbeat = timestamp;
        emit Heartbeat(stationId, clientUrl, timestamp);
    }

    
    function updateIsActive(string memory clientUrl, bool state) public {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");
        
        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        Stations[stationId].IsActive = state;
        emit ChangeIsActiveStation(stationId, clientUrl, state);
    }
}