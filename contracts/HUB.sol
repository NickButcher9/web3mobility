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
        string role;
        string webhookurl;
        string webhooktoken;
    }

    mapping(address => Partner) partners;
    address[] partnersIndex;

    function initialize() public initializer {
        __Ownable_init();
        addPartner(msg.sender, "PortalEnergy", "partner");
    }

    function addPartner(address partner, string memory name, string memory role) public onlyOwner {

        if(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("")))
            revert("name_required");

        partners[partner].name = name;
        partners[partner].active = true;
        partners[partner].role = role;
        partnersIndex.push(partner);
    }

    function removePartner(address partner) public onlyOwner {
        partners[partner].active = false;
    }

    function updateRole(address partner, string memory role) public onlyOwner {
        partners[partner].role = role;
    }

    function updateWebHookUrl(string memory webhookurl) public {

        if(partners[msg.sender].active == false )
            revert("access_denied");

        partners[msg.sender].webhookurl = webhookurl;
    }

    function updateWebHookToken(string memory token) public {

        if(partners[msg.sender].active == false )
            revert("access_denied");

        partners[msg.sender].webhooktoken = token;
    }

    function isPartner(address partner) public view returns(bool){
        return partners[partner].active;
    }

    function getPartners() public view returns(address[] memory){
        return partnersIndex;
    }

    function getPartner(address partner) public view returns(string memory, bool, string memory){
        return (partners[partner].name,partners[partner].active,partners[partner].role);
    }


    function me() public view returns(Partner memory){
        //if(partners[msg.sender].active == false )
        //    revert("access_denied");
        return partners[msg.sender];
    }


}