// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.9;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./HUB.sol";

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

        int Type; // 1 = DC, 2 = AC, 3 = Mixed
        uint256 OcppInterval;
        uint256 Heartbeat;
        Connectors[] Connectors;

    }
}


contract Station is Initializable {
    mapping (uint256 => StationStruct.Fields)  Stations;
    mapping (string => uint256) ClientUrlById;

    uint256 stationIndex;
    HUB _hub;
    string version;

    event BootNotification(uint256 indexed stationId, string clientUrl, uint256 timestamp);
    event StatusNotification(uint256 indexed stationId, string clientUrl, int connectorId, int status, int errorCode );
    event Heartbeat(uint256 indexed stationId, string clientUrl, uint256 timestamp);
    event ChangeStateStation(uint256 indexed stationId, string clientUrl, bool state);

    function initialize(address hubContract) public initializer {
        _hub = HUB(hubContract);
        version = "1.0";
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
        return stationIndex;
    }


    function getStationsCount() public view  returns(uint256){
        return stationIndex;
    }


    function updateStationName(uint256 id, string calldata name) public {
        if(Stations[id].Owner != msg.sender)
            revert("access_denied");
        Stations[id].Name = name;
    }


    function updateStationLocation(uint256 id, string calldata lat, string calldata lon) public {
        if(Stations[id].Owner != msg.sender)
            revert("access_denied");
        Stations[id].LocationLat = lat;
        Stations[id].LocationLon = lon;
    }


    function updateStationAddress(uint256 id, string calldata _address) public {
        if(Stations[id].Owner != msg.sender)
            revert("access_denied");

        Stations[id].Address = _address;
    }

    function updateStationTime(uint256 id, string calldata time) public  {
        if(Stations[id].Owner != msg.sender)
            revert("access_denied");

        Stations[id].Time = time;
    }

    function updateStationDescription(uint256 id, string calldata desc) public{
        
        if(Stations[id].Owner != msg.sender)
            revert("access_denied");

        Stations[id].Description = desc;
    }


    function updateStationUrl(uint256 id, string calldata url) public  {
        if(Stations[id].Owner != msg.sender)
            revert("access_denied");

        Stations[id].Url = url;
    }


    function getStation(uint256 stationId) public view    returns(StationStruct.Fields memory){
        StationStruct.Fields memory station = Stations[stationId];

        if( station.Owner == address(0))
            revert("station_not_found");

        return station;
    }

    function getStations() public view  returns(StationStruct.Fields[] memory){
        StationStruct.Fields[] memory ret = new StationStruct.Fields[](stationIndex);
        for (uint256 index = 1; index <= stationIndex; index++) {
            
            ret[index-1] = Stations[index];
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



    function setState(string memory clientUrl, bool state) public {
        uint256 stationId = ClientUrlById[clientUrl];
        
        if( Stations[stationId].Owner == address(0))
            revert("station_not_found");
        
        if( Stations[stationId].Owner != msg.sender)
            revert("access_denied");

        Stations[stationId].State = state;
        emit ChangeStateStation(stationId, clientUrl, state);
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

    function bootNotification(string memory clientUrl) public  {
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
        

        Stations[stationId].Heartbeat = timestamp;
        emit Heartbeat(stationId, clientUrl, timestamp);
    }

}