// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.9;

library TransactionStruct {

    struct Fields {
        address Initiator;
        uint256 TotalPrice;
        uint256 TotalImportRegisterWh;
        bool IsPaidToOwner;
        string Idtag;
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
    int constant Cancelled = 6;

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
