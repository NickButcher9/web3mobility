// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./DataTypes.sol";

contract HUB is Initializable, OwnableUpgradeable {


    mapping(uint256 => DataTypesHub.Partner) partners;
    mapping (address => uint256) owner_address_to_id;
    uint256 counter;

    function initialize() public initializer {
        __Ownable_init();
    }

    function addPartner(DataTypesHub.Partner memory partnerData) public onlyOwner {

        if(partnerData.name.length < 3)
            revert("name_length_more_than_3");

        if(partnerData.party_id.length != 3)
            revert("party_id_lenght_should_be_3_bytes");

        if(partnerData.country_code.length != 2)
            revert("country_code_lenght_should_be_2_bytes");

        counter++;
        owner_address_to_id[partnerData.owner_address] = counter;
        partners[counter] = partnerData;

    }

    function updateStatus(uint256 id, DataTypesHub.ConnectionStatus status) public onlyOwner {
        partners[id].status = status;
    }

    function updateRole(uint256 id, DataTypesHub.Roles[] memory role) public onlyOwner {
        partners[id].role = role;
    }

    function getPartners() public view returns(DataTypesHub.Partner[] memory){
        
        DataTypesHub.Partner[] memory ret = new DataTypesHub.Partner[](counter);

        for (uint i = 1; i <= counter; i++) {
            ret[i-1] = partners[i];
        }

        return ret;
    }

    function me() public view returns(DataTypesHub.Partner memory){
        return partners[owner_address_to_id[msg.sender]];
    }


}