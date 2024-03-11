// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Hub/HUB.sol";
import "hardhat/console.sol";

library StationStruct {

    struct Connectors {
        uint256 Id;
        uint256 StationId;
        uint256 SyncId;
        uint256 LastUpdated;
        int Power; // kW 
        int ConnectorId;
        int ConnectorType;
        int Status; 
        int ErrorCode;
        uint256 Tariff;
        bool IsHaveLock;

    }



    bool constant Active = true;
    bool constant InActive = false;

    struct Fields {
        uint256 Id;
        int Power;
        int FloorLevel; // 
        string LocationLat;
        string LocationLon;
        string ClientUrl;
        address Owner;     
        string PhysicalReference;
        Directions[] Directions;
        StatusSchedule StatusSchedule;
        Capabilities[] Capabilities; 
        Image[] Images;
        string ChargePointModel;
        string ChargePointVendor;
        string ChargeBoxSerialNumber;
        string FirmwareVersion;
        bool Online;
        bool InOperation; 

        int Type; // 1 = AC, 2 = DC, 3 = Mixed
        uint256 OcppInterval;
        uint256 Heartbeat; // lastUpdated;
        //Connectors[] uint256;
        uint256 SyncId;
        uint256 LastUpdated;
    }


}


contract Station is Initializable {
    mapping (uint256 => StationStruct.Fields)  Stations;
    mapping (uint256 => StationStruct.Fields)  Connectors;
    mapping (string => uint256) ClientUrlById;
    mapping (address => uint256[]) stationPartners;

    uint256 stationIndex;
    HUB _hub;
    string version;
    string[] stationIndexClientUrl;

    event BootNotification(uint256 indexed stationId, bytes32 indexed clientUrl, uint256 indexed timestamp);
    event StatusNotification(uint256 indexed stationId, bytes32 indexed clientUrl, int indexed connectorId, int indexed status, int indexed errorCode, uint256 indexed timestamp );
    event Heartbeat(uint256 indexed stationId, bytes32 indexed clientUrl, uint256 indexed timestamp);
    event ChangeStateStation(uint256 indexed stationId, bytes32 indexed clientUrl, bool state, uint256 indexed timestamp);
    event ChangeIsActiveStation(uint256 indexed stationId, bytes32 indexed clientUrl, bool state, uint256 indexed timestamp);
    event AddStation(uint256 indexed stationId, bytes32 indexed clientUrl, address indexed owner, uint256 indexed timestamp);
    event UpdateStation(uint256 indexed stationId, bytes32 indexed clientUrl, bytes32 indexed change, uint256 indexed timestamp);

    function initialize(address hubContract) public initializer {
        _hub = HUB(hubContract);
        version = "1.3";
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