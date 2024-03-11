// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Hub/HUB.sol";
import "./DataTypes.sol";


contract EVSE is Initializable {
    mapping (bytes => DataTypes.EVSE)  evses;
    HUB hub;
    string version;


    function initialize(address hubContract) public initializer {
        hub = HUB(hubContract);
        version = "1.3";
    }

    function getVersion() public view returns(string memory){
        return version;
    }

}