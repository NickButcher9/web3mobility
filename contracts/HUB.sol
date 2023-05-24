// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Payment.sol";
import "./Station.sol";
import "./Transaction.sol";


contract HUB is Initializable, OwnableUpgradeable {

    struct Partner {
        string name;
        bool active;
    }

    mapping(address => Partner) partners;
    address[] partnersIndex;

    function initialize() public initializer {
        __Ownable_init();
        addPartner(msg.sender, "PortalEnergy");
    }

    function addPartner(address partner, string memory name) public onlyOwner {
        partners[partner].name = name;
        partners[partner].active = true;
        partnersIndex.push(partner);
    }

    function removePartner(address partner) public onlyOwner {
        partners[partner].active = false;
    }

    function isPartner(address partner) public view returns(bool){
        return partners[partner].active;
    }

    function getPartners() public view returns(address[] memory){
        return partnersIndex;
    }

    function getPartner(address partner) public view returns(Partner memory){
        return partners[partner];
    }

}