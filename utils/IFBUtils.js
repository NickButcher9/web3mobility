module.exports.ConvertContractResponseStructToNormalObject = function(schemeObjRef, contractResponseStruct) {
    const target = Object.assign({}, schemeObjRef);
    let i = 0;
    for(let key in schemeObjRef) {
        target[key] = contractResponseStruct[i];
        i++;
    }

    return target;
};

module.exports.GenerateRandomAddress = function() {
    const ethers = require("ethers");  
    const crypto = require("crypto");

    const id = crypto.randomBytes(32).toString("hex");
    const privateKey = "0x"+id;
    //console.log("SAVE BUT DO NOT SHARE THIS:", privateKey);

    const wallet = new ethers.Wallet(privateKey);
    //console.log("Address: " + wallet.address)

    return {
        privateKey: privateKey,
        publicKey: wallet.address
    }
}

module.exports.GetEventArgumentsByNameAsync = async function(transaction, eventName) {
    const result = await transaction.wait();
    for (let index = 0; index < result.events.length; index++) {
        const event = result.events[index];
        if(event.event == eventName){
            //console.log("EVENT: "+ eventName, event.args )
            return event.args
        } 
    }

    return false;
}