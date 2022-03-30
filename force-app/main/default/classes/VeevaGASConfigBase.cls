public inherited sharing abstract class VeevaGASConfigBase {

    public abstract List<String> getAccountObjectFields();
    public abstract List<String> getAddressObjectFields();
    public abstract List<String> getAccountQueryFields();
    public abstract List<String> getAddressQueryFields();
    public abstract String getMaxRowLimit();
    public abstract List<Map<String, String>> getResultSetColumnInfo();
    
    protected List<String> getObjectQueryFields(List<String> configuredFields, Map<String, Schema.SObjectField> objectFieldsMap, boolean fieldsForQuery){
        List<String> objectQueryFields = new List<String>();
        for (String field : configuredFields){
            List<String> fieldNameInfo = field.split('\\.');
            if (objectFieldsMap.get(fieldNameInfo[0]) != null){
                Schema.DescribeFieldResult fldDesc = objectFieldsMap.get(fieldNameInfo[0]).getDescribe();
                if (fldDesc.getType() == Schema.DisplayType.REFERENCE && !String.isEmpty(fldDesc.getRelationshipName()) && fldDesc.getRelationshipName() == 'RecordType'){
                    String fieldDetail;
                    if (fieldsForQuery){
                        fieldDetail = (fieldNameInfo.size() > 1)? (fldDesc.getRelationshipName() + '.' + fieldNameInfo[1]) : fldDesc.getRelationshipName();
                    } else {
                        fieldDetail = (fieldNameInfo.size() > 1)? (fieldNameInfo[0] + '.' + fieldNameInfo[1]) : fieldNameInfo[0];
                    }
                    objectQueryFields.add(fieldDetail);
                } else if (fldDesc.getType() == Schema.DisplayType.PICKLIST || fldDesc.getType() == Schema.DisplayType.MULTIPICKLIST){
                    if (fieldsForQuery){
                        objectQueryFields.add('toLabel(' + field + ')');
                    } else {
                        objectQueryFields.add(field);
                    }
                } else if (fldDesc.getType() == Schema.DisplayType.REFERENCE){
                    String refFieldName = (fieldNameInfo.size() > 1) ? fieldNameInfo[1] : 'Name';
                    if (fieldsForQuery){                        
                        objectQueryFields.add(fldDesc.getRelationshipName() + '.' + refFieldName);
                    } else {
                        objectQueryFields.add(fieldNameInfo[0] + '.' + refFieldName);
                    }
                } else {
                    objectQueryFields.add(fieldNameInfo[0]);
                }
            }
        }
        return objectQueryFields;
    }

    protected List<Map<String, String>> getResultSetFieldsInfo(String objectName, List<String> resultSetFields, Map<String, Schema.SObjectField> objectFieldsMap){
        List<Map<String, String>> resultSetInfo = new List<Map<String, String>>();
        for (String field : resultSetFields){
            List<String> fieldNameInfo = field.split('\\.');
            if (objectFieldsMap.get(fieldNameInfo[0]) != null){
                Map<String, String> fieldInfo = new Map<String, String>();
                Schema.DescribeFieldResult fldDesc = objectFieldsMap.get(fieldNameInfo[0]).getDescribe();
                fieldInfo.put('label', fldDesc.getLabel());
                fieldInfo.put('objectName', objectName);                
                if (fldDesc.getType() == Schema.DisplayType.PICKLIST || fldDesc.getType() == Schema.DisplayType.MULTIPICKLIST){
                    fieldInfo.put('fieldName', objectName + '.' + fieldNameInfo[0]);
                } else if (fldDesc.getType() == Schema.DisplayType.REFERENCE){
                    String refFieldName = (fieldNameInfo.size() > 1) ? fieldNameInfo[1] : 'Name';
                    fieldInfo.put('fieldName', objectName + '.' + fieldNameInfo[0] + '.' + refFieldName);
                } else{ 
                    fieldInfo.put('fieldName', objectName + '.' + fieldNameInfo[0]);
                 }
                resultSetInfo.add(fieldInfo);
            }
        }
        return resultSetInfo;
    }
}