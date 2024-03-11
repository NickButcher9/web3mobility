library DataTypesHub {

    enum Roles {
        None,
        CPO,
        EMSP,
        HUB,
        NSP,
        SCSP
    }

    enum Modules {
        None,
        Location,
        ChargingProfiles,
        Commands,
        Credentials
    }

    enum ConnectionStatus {
        None,
        CONNECTED,
        OFFLINE,
        PLANNED,
        SUSPENDED
    }

    struct Partner {
        bytes2 country_code;
        bytes3 party_id;
        bytes name;
        Roles[] role;
        ConnectionStatus status;
        address owner_address;
        uint256 last_updated;
    }

}