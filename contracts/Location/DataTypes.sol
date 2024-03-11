library DataTypesLocation {
    enum ConnectorTypes {
        None, 
        Type1, 
        Type2, 
        Chademo, 
        CCS1, 
        CCS2, 
        GBTDC, 
        GBTAC, 
        DOMESTIC_A,
        DOMESTIC_B,
        DOMESTIC_C,
        DOMESTIC_D,
        DOMESTIC_E,
        DOMESTIC_F,
        DOMESTIC_G,
        DOMESTIC_H,
        DOMESTIC_I,
        DOMESTIC_J,
        DOMESTIC_K,
        DOMESTIC_L,
        DOMESTIC_M,
        DOMESTIC_N,
        DOMESTIC_O,
        IEC_60309_2_single_16,
        IEC_60309_2_three_16,
        IEC_60309_2_three_32,
        IEC_60309_2_three_64,
        IEC_62196_T3A,
        NEMA_5_20,
        NEMA_6_30,
        NEMA_6_50,
        NEMA_10_30,
        NEMA_10_50,
        NEMA_14_30,
        NEMA_14_50,
        PANTOGRAPH_BOTTOM_UP,
        PANTOGRAPH_TOP_DOWN,
        TSL
    }

    enum ConnectorErrors {
        None,
        ConnectorLockFailure,
        EVCommunicationError,
        GroundFailure,
        HighTemperature,
        InternalError,
        LocalListConflict,
        NoError,
        OtherError,
        OverCurrentFailure,
        PowerMeterFailure,
        PowerSwitchFailure,
        ReaderFailure,
        ResetFailure,
        UnderVoltage,
        OverVoltage,
        WeakSignalint,
        PowerModuleFailure,
        EmergencyButtonPressed
    }


    enum ConnectorStatus {
        None,
        Available,
        Preparing,
        Charging,
        SuspendedEVSE,
        SuspendedEV,
        Finishing,
        Reserved,
        Unavailable,
        Faulted
    }

    enum EVSEStatus {
        None,
        Available,
        Unavailable,
        Planned,
        Removed,
        Blocked,
        Maintance
    }

    enum ConnectorFormat {
        None,
        Socket,
        Cable
    }

    enum Facility {
        None,
        Hotel,
        Restaurant,
        Cafe,
        Mall,
        Supermarket,
        Sport,
        RecreationArea,
        Nature,
        Museum,
        BikeSharing,
        BusStop,
        TaxiStand,
        TramStop,
        MetroStation,
        TrainStation,
        Airport,
        ParkingLot,
        CarpoolParking,
        FuelStation,
        Wifi
    }

    enum ImageCategory {
        None,
        Charger,
        Enterence,
        Location,
        Network,
        Operator,
        Other,
        Owner
    }

    enum ParkingRestriction {
        None,
        EvOnly,
        Plugged,
        Disabled,
        Customers,
        Motorcycles
    }

    enum ParkingType {
        None,
        AlongMotorway,
        ParkingGarage,
        ParkingLot,
        OnDriveway,
        OnStreet,
        UndergroundGarage
    }

    enum PowerType {
        None,
        AC_1_PHASE,
        AC_2_PHASE,
        AC_2_PHASE_SPLIT,
        AC_3_PHASE,
        DC
    }

    enum Capabilities {
        ChargingProfileCapabile,
        ChargingPreferencesCcapabale,
        ChipCardSupport,
        ContactlesCardSupport,
        CreditCardPayble,
        DebitCardPayble,
        PedTerminal,
        RemoteStartStopCapable,
        Reservable,
        RfidReader,
        StartSessionConnectorRequired,
        TokenGroupCapable,
        UnlockCapable
    }

    enum ImageType {
        None,
        JPG,
        PNG,
        GIF,
        SVG
    }

    enum TokenType {
        None,
        AD_HOC_USER,
        APP_USER,
        OTHER,
        RFID
    }


    struct AdditionalGeoLocation {
        string Latitude;
        string Longtitude;
        DisplayText[] Name;
    }

    struct BusinessDetails {
        string Name;
        string Website;
        Image Logo;
    }


    struct Directions {
        string Lang;
        string Text;
    }

    struct StatusSchedule{
        uint256 Begin;
        uint256 End;
        EVSEStatus Status;
    }

    struct Image {
        string Url;
        string Thumbnail;
        ImageCategory Category;
        ImageType Type;
        uint16 With;
        uint16 Height;
    }

    struct ExceptionalPeriod {
        uint256 Begin;
        uint256 End;
    }

    struct GeoLocation {
        int256 Latitude;
        int256 Longtitude;
    }

    struct Hours {
        bool Twentyfourseven;
        RegularHours[] RegularHours;
        ExceptionalPeriod[] ExceptionalOpenings;
        ExceptionalPeriod[] ExceptionalClosings;
    }

    struct PublishTokenType {
        string Uid;
        TokenType Type;
        string VisualNumber;
        string Issuer;
        string GroupId;
    }

    struct RegularHours {
        int WeekDay;
        string PeriodBegin;
        string PeriodEnd;
    }

    struct DisplayText {
        string Language;
        string Text;
    }

    struct Location {
        bytes32 id;
        bytes2 country_code;
        bytes3 party_id;
        bool publish;
        PublishTokenType[] publish_allowed_to;
        string name;
        string address_;
        string city;
        bytes10 postal_code;
        bytes20 state;
        bytes3 country;
        GeoLocation coordinates;
        AdditionalGeoLocation[] related_locations;
        ParkingType parking_type;
        EVSE[] evses;
        DisplayText[] directions;
        BusinessDetails operator;
        BusinessDetails owner;
        Facility[] facilities;
        string time_zone;
        Hours opening_times;
        bool charging_when_closed;
        Image images;
        uint256 last_updated;
    }


    struct EVSE {
        bytes32 uid;
        string evse_id;
        bytes2 label;
        EVSEStatus status;
        StatusSchedule[] status_schedule;
        Capabilities[] capabilities;
        Connector[] connectors;
        bytes4 floor_level;
        GeoLocation coordinates;
        bytes16 physical_reference;
        DisplayText[] directions;
        ParkingRestriction[] parking_restrictions;
        Image[] images;
        uint256 last_updated;
    }

    struct Connector {
        bytes32 id;
        ConnectorTypes standard;
        ConnectorFormat format;
        PowerType power_type;
        int16 max_voltage;
        int16 max_amperage;
        int16 max_electric_power;
        bytes32[] tariff_ids;
        string terms_and_conditions; // url
        uint256 last_updated;
    }
}

