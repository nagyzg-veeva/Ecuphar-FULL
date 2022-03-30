const defaultMap = {
    name: "Name",
    line2: "Address_line_2_vod__c",
    city: "City_vod__c",
    state: "State_vod__c",
    zip: "Zip_vod__c",
    country: "Country_vod__c"
};

const getValue = value => {
    return value && value.value ? value.value : "";
}

const getLabel = (value, fld) => {
    if (value && fld && fld.values) {
        let found = fld.values.find(x => x.value === value);
        return found ? found.label : value;
    }
    return value || "";
}

const getUIRecordAddress = (data, map, stateFld, countryFld) => {
    let addressText = "";
    let result = {};
    if (data) {
        map = map || defaultMap;
        let name = getValue(data[map.name]);
        result.Address_Line_1_vod__c  = name;
        addressText = name;

        let line2 = getValue(data[map.line2]);
        if (line2) {
            result.Address_Line_2_vod__c = line2;
            addressText += ", " + line2;
        }
        
        let city = getValue(data[map.city]);
        if (city) {
            result.City_vod__c = city;
            addressText += ", " + city;
        }

        let state = getLabel(getValue(data[map.state]), stateFld);
        if (state) {
            addressText += ", " + state;
        }

        let zip = getValue(data[map.zip]);
        if (zip) {
            addressText += " " + zip;
        }

        let country = getLabel(getValue(data[map.country]), countryFld);
        if (country) {
            addressText += " " + country;
        }
    }

    result.value = result.label = addressText;    
    return result;
};

const getAddressText = (data, stateFld, countryFld) => {
    if (data) {
        let text = data.Name || '';
        let temp = data.Address_line_2_vod__c;
        if (temp) {
            text += ", " + temp;
        }
        temp = data.City_vod__c;
        if (temp) {
            text += ", " + temp;
        }
        temp = getLabel(data.State_vod__c, stateFld);
        if (temp) {
            text += ", " + temp;
        }
        temp = data.Zip_vod__c;
        if (temp) {
            text += " " + temp;
        }
        temp = getLabel(data.Country_vod__c, countryFld);
        if (temp) {
            text += " " + temp;
        }
        return text;
    }
    return "";
};

export {getUIRecordAddress, getAddressText};