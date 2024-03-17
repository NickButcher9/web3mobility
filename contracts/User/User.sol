// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./DataTypes.sol";




contract User is Initializable, OwnableUpgradeable {

    string version;
    UserStructs.UserFields[] users;

    event AddUser(uint256 indexed userId);

    function initialize() public initializer {
        version = "1.0";
        __Ownable_init();
    }

    function addUser(address userAddress, string memory firstName, string memory lastName, string memory phone, string memory email, uint64 telegramId) public onlyOwner {
        //проверка на телефон, адрес
        UserStructs.UserFields memory _user;
        _user.userAddress = userAddress;
        _user.id = users.length;
        _user.firstName = firstName;
        _user.lastName = lastName;
        _user.phone = phone;
        _user.email = email;
        _user.telegramData.id = telegramId;
        //генерация idTag
        //подтверждение почты и телефона
        users.push(_user);

        emit AddUser(_user.id);//
    }

    //add, remove, update, get все поля для приложения

}