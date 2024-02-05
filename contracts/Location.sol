// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

library LocationStructs {

/*
    // TODO, continue in version 1.3
         
    struct Hours {
        bool Twentyfourseven; // True to represent 24 hours a day and 7 days a week, except the given exceptions.
    }
 */
    struct Fields {
        uint256 Id;
        string Name;
        string LocationLat;
        string LocationLon;
        string Address;
        string City;
        string Country;
//        string TimeZone; TODO, continue in version 1.3
//        string OpeningTimes; TODO, continue in version 1.3
        string Description;
        address Owner;        
        bool Publish; 
        uint256 SyncId;
        uint256 LastUpdated;
    }

}

contract User is Initializable, AccessControlUpgradeable {
    string version;

    function initialize() public initializer {

        version = "1.0";

    }

}