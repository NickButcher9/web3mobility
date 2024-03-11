// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Hub/HUB.sol";
import "./DataTypes.sol";


contract Location is Initializable {
    mapping (bytes => DataTypesLocation.Location)  locations;
    HUB hub;
    string version;


    function initialize(address hubContract) public initializer {
        hub = HUB(hubContract);
        version = "1.3";
    }

    function getVersion() public view returns(string memory){
        return version;
    }

    function addLocation() public {
        
    }

}