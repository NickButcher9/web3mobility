
// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Transaction.sol";
import "./HUB.sol";



library CountryCode {
    int constant RU = 1;
    int constant KZ = 2;
    int constant BL = 3;
}

library Currency {
    int constant RUB = 1;
    int constant KZT = 2;
    int constant BYR = 3;
    int constant EUR = 4;
    int constant USD = 5;
}



contract Payment is Initializable  {


    uint8 constant ENERGY = 1;
    uint8 constant FLAT = 2;
    uint8 constant TIME = 3;

    // 1 - ENERGY Defined in kWh, step_size multiplier: 1 Wh
    // 2 - FLAT Flat fee without unit for step_size
    // 3 - TIME Time charging: defined in hours, step_size multiplier: 1 second. Can also be used in combination with a RESERVATION restriction to describe the price of the reservation time.

    struct Tariff {
        uint8 country_code;
        uint8 currency; 
        address owner; 
        PriceComponents[3] price_components;
        uint256 SyncId;
    }

    struct PriceComponents {
        uint256 price;        
        uint8 ctype;
        uint8 vat;
        uint8 step_size;
        // Minimum amount to be billed. This unit will be billed in this step_size
        // blocks. Amounts that are less then this step_size are rounded up to
        // the given step_size. For example: if type is TIME and step_size
        // has a value of 300, then time will be billed in blocks of 5 minutes. If 6
        // minutes were used, 10 minutes (2 blocks of step_size) will be billed       
        Restrictions restrictions;    
    }

    struct Restrictions {
        uint64 start_date; // unixtime
        uint64 end_date; // unixtime         
        uint8 start_time; // in 24 howrs format, can be from 00 to 24
        uint8 end_time; // in 24 howrs format, can be from 00 to 24
        uint256 min_wh; // Minimum consumed energy in kWh, for example 20, valid from this amount of energy (inclusive) being used.
        uint256 max_wh; // Maximum consumed energy in kWh, for example 50, valid until this amount of energy (exclusive) being used.
        uint8 min_duration; // duration in seconds
        uint8 max_duration; //  duration in seconds
    }


    struct Invoice {
        uint256 id;
        uint256 transactionId;
        uint256 amount;
        uint256 consumed;
        uint8 currency;
        uint8 country_code;
        bool paid;

        address from;
        address to;

        InvoiceDetails[3] details;
    }

    struct InvoiceDetails {
        uint256 price;
        uint ctype;
        uint8 vat;
        uint8 step_size;
        uint256 amount;
    }

    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    HUB _hub;
    string version;

    uint256 tariffsCount;
    uint256 invoicesCount;
    uint256 BIGNUMBER;

    mapping(uint256 => Tariff) tariffs;
    mapping(uint256 => Invoice) invoices;   

    event AddTariff(uint256 indexed tariffId);
    event UpdateTariff(uint256 indexed tariffId);
    event CreateInvoice(uint256 indexed id, uint256 indexed transactionId);

    function initialize(Tariff calldata _tariff, address hubContract)  public initializer {
        BIGNUMBER = 10**18;
        version = "1.0";
        _hub = HUB(hubContract);
        addTariff(_tariff);
    }

    function getVersion() public view returns(string memory){
        return version;
    }

    function addTariff(Tariff calldata _tariff) public {


        if(!_hub.isPartner(msg.sender))
            revert("access_denied");

        tariffsCount++;

        tariffs[tariffsCount] = _tariff;

        emit AddTariff(tariffsCount);
    }

    function getTariff(uint256 id) public view returns (Tariff memory){
        return tariffs[id];
    }

    function updateTariff(uint256 id, Tariff calldata _tariff) public { 
        if(tariffs[id].owner != msg.sender)
            revert("acces_denied");

        tariffs[id] = _tariff;
        emit UpdateTariff(id);
    }

    function __getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function createInvoice(TransactionStruct.Fields memory transaction, address stationOowner, uint256 transactionId) external returns(uint256,uint256){

        Tariff memory _tariff = tariffs[transaction.Tariff];
        uint256 consumed = (transaction.MeterStop-transaction.MeterStart);


        invoicesCount++;
        Invoice storage invoice = invoices[invoicesCount];

        invoice.id = invoicesCount;
        invoice.country_code = _tariff.country_code;
        invoice.currency = _tariff.currency;
        invoice.from = stationOowner;
        invoice.to = transaction.Initiator;
        invoice.paid = false;
        invoice.transactionId = transactionId;
        invoice.amount = 0;
        invoice.consumed = consumed;
        


        for (uint i = 0; i < _tariff.price_components.length; i++) {


            PriceComponents memory component = _tariff.price_components[i];

            if(component.ctype == 0){
                continue;
            }

            InvoiceDetails memory invoiceDetails;
            invoiceDetails.price = component.price;
            invoiceDetails.ctype = component.ctype;
            invoiceDetails.vat = component.vat;
            invoiceDetails.step_size = component.step_size;
            uint256 minimum_for_pay;
            uint256 diffDate = transaction.DateStop-transaction.DateStart;

            if(component.ctype == ENERGY){

                invoiceDetails.amount = (consumed/(1000*BIGNUMBER))*invoiceDetails.price;

                minimum_for_pay = invoiceDetails.price*invoiceDetails.step_size;

                if(invoiceDetails.amount < minimum_for_pay)
                    continue;
                
            }


            if( component.ctype == FLAT){
                invoiceDetails.amount = invoiceDetails.price;                
            }

            if( component.ctype == TIME){
                uint _minutes = (diffDate) / 60/60;
                
                invoiceDetails.amount = _minutes*invoiceDetails.price;

                minimum_for_pay = invoiceDetails.price*invoiceDetails.step_size;

                if(invoiceDetails.amount < minimum_for_pay)
                    continue;

            }

            if(component.restrictions.start_date != 0 && component.restrictions.end_date != 0){
                if(transaction.DateStart < component.restrictions.start_date || transaction.DateStop > component.restrictions.end_date){
                    continue;
                }
            }

            if(component.restrictions.start_time != 0 && component.restrictions.end_time !=0){
                uint hour = __getHour(transaction.DateStart);

                if(hour < component.restrictions.start_time || hour > component.restrictions.end_time){
                    continue;
                }

            }

            if(component.restrictions.min_wh != 0 && component.restrictions.max_wh !=0){
                if(consumed < component.restrictions.min_wh || consumed > component.restrictions.max_wh){
                    continue;
                }  

            }

            if(component.restrictions.min_duration != 0 && component.restrictions.max_duration !=0 ){
                uint _seconds = (diffDate) / 60;

                if( _seconds < component.restrictions.min_duration || _seconds > component.restrictions.max_duration){
                    continue;
                }

            }

            invoice.details[i]  = invoiceDetails;
            invoice.amount = invoice.amount+invoiceDetails.amount;
        }


        emit CreateInvoice(invoice.id, transactionId);
        return (invoice.id, invoice.amount);
    }

    function getInvoice(uint256 id) public view  returns(Invoice memory){
        return invoices[id];
    }
}