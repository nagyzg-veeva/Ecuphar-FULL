export default class GasRecordTypeIconConfig {

    static STANDARD_RECTYPE_ICON_MAP = new Map([
        ["Business_Professional_vod", "business_professional"], ["Professional_vod", "professional"], ["MCOPlan_vod", "mco"],
        ["MCO_vod", "mco"], ["Practice_vod", "private_practice"], ["Hospital_vod", "hospital"], ["Pharmacy_vod", "pharmacy"],
        ["HospitalDepartment_vod", "hospital_department"], ["Laboratory_vod", "laboratory"], ["Organization_vod", "board"],
        ["Board_vod", "board"], ["Employer_vod", "employer"], ["ExtendedCare_vod", "ambulatory"], ["Institution_vod", "institution"],
        ["Publication_vod", "publication"], ["KOL_vod", "kol"], ["Wholesaler_vod", "wholesaler"], ["Government_Agency_vod", "government"],
        ["Distributor_vod", "distributor"], ["Distributor_Branch_vod", "distributor"], ["PersonAccount", "person"]
    ]);

    constructor(customRecTypesIconSetting) {
        this._customRecordTypeIconMap = this.getCustomRecordTypesMap(customRecTypesIconSetting);
    }

    getCustomRecordTypesMap(customRecTypesIconSetting){
        const customRecTypeIconMap = new Map();
        if  (customRecTypesIconSetting){
            const iconSettingsArr = customRecTypesIconSetting.split(';');
            if (iconSettingsArr && (iconSettingsArr.length > 0)){
                iconSettingsArr.forEach(setting => {
                    const settingValues = setting.split(':');
                    // If the settingValues array has more than two values after splitting on ':'
                    // this means the customer has a misconfigured custom setting value
                    if (settingValues.length === 2) {
                        const iconRecType = settingValues[0];
                        const customRecTypesArr = settingValues[1].split(',');
                        customRecTypesArr.forEach(customRecType => {
                            customRecTypeIconMap.set(customRecType, iconRecType);
                        });
                    }
                });
            }
        }
        return customRecTypeIconMap;
    }

    getIconUrlForRecordType(recordType, isPersonAccount, isInTerr){
        let iconName;
        //check if its already on the map
        if (GasRecordTypeIconConfig.STANDARD_RECTYPE_ICON_MAP.has(recordType)){
            iconName = GasRecordTypeIconConfig.STANDARD_RECTYPE_ICON_MAP.get(recordType);
        } else if (this._customRecordTypeIconMap.has(recordType)){
            iconName = GasRecordTypeIconConfig.STANDARD_RECTYPE_ICON_MAP.get(this._customRecordTypeIconMap.get(recordType));
        } 
        if (!iconName) {
            iconName = isPersonAccount ? 'person' : 'business';
        }
        if (!isInTerr){
            iconName += '_gray';
        }
        const iconUrl = '/icons/' + iconName + '.svg';
        return iconUrl;
    }
}