// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

library UserStructs {
    struct Fields {
        uint256 Id;
        address Address;
        string Name;
        string Phone;
        string Email;
        int Type; // 0 - default user, 1 - company;
        bool Enable; 
        bool EmailVerifyed;
        bool PhoneVerifyed;
    }

    struct Company {
        uint256 Id;
        string Name;
        string Description;
        uint256 Meta;
    }

    struct RUCompanyMeta {
        uint256 Id;
        uint256 Inn;
        uint256 Kpp;
        uint256 Ogrn;
        uint256 BankAccount;
        string BankName;
        uint256 BankBik;
        uint256 BankCorAccount;
        uint256 BankInn;
        uint256 BankKppAccount;
    }
}

contract User is Initializable, AccessControlUpgradeable {
    string version;

    function initialize() public initializer {

        version = "1.0";

    }

}