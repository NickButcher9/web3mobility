// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.9;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Payment.sol";
import "./Station.sol";
import "./Transaction.sol";


contract HUB is Initializable, OwnableUpgradeable {

    mapping(address => bool) partners;

    function initialize() public initializer {
        __Ownable_init();
        partners[msg.sender] = true;
    }

    function addPartner(address partner) public onlyOwner {
        partners[partner] = true;
    }

    function removePartner(address partner) public onlyOwner {
        partners[partner] = false;
    }

    function isPartner(address partner) public view returns(bool){
        return partners[partner];
    }

}