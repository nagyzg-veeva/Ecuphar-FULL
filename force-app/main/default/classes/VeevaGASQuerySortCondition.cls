public inherited sharing class VeevaGASQuerySortCondition {
    private String objectName;
    private String fieldName;
    private String direction;
    
    public VeevaGASQuerySortCondition(String sortColumnInfo, String sortDirection) {
        List<String> sortObjectField = sortColumnInfo.split('\\.');
        objectName = sortObjectField[0];
        direction = sortDirection;
        //Ref field check
        if (sortObjectField.size() > 2){
            fieldName = getFieldRelationshipName(objectName, sortObjectField[1] + '.' + sortObjectField[2]);
        } else {
            fieldName = sortObjectField[1];            
        }
    }

    public String getObjectName(){
        return objectName;
    }

    public String getSortDirection(){
        return direction;
    }

    public String getOrderByClause(){
        String orderByClause = ' ORDER BY ';        
        orderByClause += fieldName + ' ' + (direction == 'DESC' ? + direction + ' NULLS LAST ' : direction);
        //Add Account Name as secondary sort if its not the primary sort
        orderByClause += (objectName == 'Address_vod__c' ? ', Account_vod__r.Name ' : (fieldName == 'Name' ? ' ' : ', Name '));
        return orderByClause;
    }

    public String getFieldRelationshipName(String objName, String field){
        List<String> fields = new List<String>();
        List<String> queryFields = new List<String>();
        Map<String, Schema.SObjectField> objectFieldsMap;
        String fieldDetail;
        fields.add(field);
        if (objName == 'Account'){
            objectFieldsMap = Schema.SObjectType.Account.fields.getMap();
        } else if (objName == 'Address_vod__c'){
            objectFieldsMap = Schema.SObjectType.Address_vod__c.fields.getMap();
        }
        List<String> fieldNameInfo = field.split('\\.');
        if (objectFieldsMap.get(fieldNameInfo[0]) != null){
            Schema.DescribeFieldResult fldDesc = objectFieldsMap.get(fieldNameInfo[0]).getDescribe();
            if (fldDesc.getType() == Schema.DisplayType.REFERENCE && !String.isEmpty(fldDesc.getRelationshipName())){
                fieldDetail = (fieldNameInfo.size() > 1)? (fldDesc.getRelationshipName() + '.' + fieldNameInfo[1]) : fldDesc.getRelationshipName();                
            }
        }
        return fieldDetail;
    }
}