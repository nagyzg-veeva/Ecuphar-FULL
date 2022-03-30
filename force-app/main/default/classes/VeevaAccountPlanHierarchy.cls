public without sharing class VeevaAccountPlanHierarchy {

    public  VeevaAccountPlanHierarchy() {
        initializeAccountHierarchy();
    }

    private Map<String, String> objectFieldMap = new Map<String, String> ();
    private List<String> objectHierarchy = new List<String> ();



    private String[] getHierarchy() {
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
        if (vsc == null || vsc.Account_Plan_Object_Hierarchy_vod__c == null) {
            return null;
        }
        String[] hierarchy = vsc.Account_Plan_Object_Hierarchy_vod__c.split(',');
        return hierarchy;

    }


    private void initializeAccountHierarchy() {

        String[] hierarchy = getHierarchy();
        if (hierarchy != null) {
            String parentObject = 'Account_Plan_vod__c';
            Map<String, SObjectType> objectMap = Schema.getGlobalDescribe();
            for (String pairing : hierarchy) {
                String[] objectPairing = pairing.split('\\.');
                if (objectPairing.size() != 2) {
                    objectHierarchy.clear();
                    return;
                }
                String objectName = objectPairing[0].trim();
                if (!objectMap.containsKey(objectName)) {
                    objectHierarchy.clear();
                    return;
                }
                String objectRelationName = objectPairing[1].trim();
                SObjectType objectType = objectMap.get(objectName);
                boolean foundField = false;
                String fieldName = null;
                for (SObjectField field : objectType.getDescribe().fields.getMap().values()) {
                    if (field.getDescribe().getReferenceTo() != null && field.getDescribe().getReferenceTo().size() > 0 &&
                         (field.getDescribe().getRelationshipName() == objectRelationName  && field.getDescribe().getReferenceTo()[0].getDescribe().getName() == parentObject)) {
                            fieldName = field.getDescribe().getName();
                            objectFieldMap.put(objectName, fieldName);
                            parentObject = objectName;
                            foundField = true;
                            break;
                    }
                }
                if (!foundField) {
                    objectHierarchy.clear();
                    return;
                }
                objectHierarchy.add(objectName);
            }

        }
    }

    public boolean isValidHierarchy() {
       return objectHierarchy.size() > 0;
    }

    public  List<String> getObjectHierarchy() {
        return objectHierarchy;
    }


    public integer getObjectPosition(String objectName) {
        return objectHierarchy.indexOf(objectName);
    }

    public String getObjectName(integer index) {
        return objectHierarchy.get(index);
    }

    public  boolean isObjectInAccountHierarchy(String objectName) {
        return objectHierarchy.contains(objectName);

    }

    public String getFieldName(String objectName) {
        return objectFieldMap.get(objectName);
    }


}