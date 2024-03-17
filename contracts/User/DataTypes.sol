library UserStructs {
    
    struct UserFields {
        uint256 id;
        uint256 idTag;
        address userAddress;
        string firstName;
        string lastName;
        string phone;
        string email;
        bool phoneVerifyed;
        bool emailVerifyed;
        uint64 verificationCode;//?
        string photoUrl;
        WebAppUserData telegramData;
        int userType; // 0 - default user, 1 - company;
        uint256 companyId;//привязка к компании
        bool enable; 
        uint256 balance;
        CarData[] cars;
        uint256[] cardsNumbers;
        bool autoPayment;
        AutoPaymentData autoPaymentData;
        //история чата с поддержкой
    }

    struct WebAppUserData{
        uint64 id;
        string userName;
        bool isPremium;
        string adressTonSpace;//кошелек тон спейс?
    }

    struct CarData{
        string brand;
        string model;
        string[] connectors;
    }

    struct AutoPaymentData{
        uint256 sumPayment;
        uint256 monthLimitPay;
        uint256 minBalance;
    }

    struct AuthToken {//?
        uint256 dateStart;
        uint256 dateExpired;
        string token;
    }

    struct Company {//?
        uint256 id;
        string name;
        string description;
        uint256 meta;
    }

    struct CompanyMeta {
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