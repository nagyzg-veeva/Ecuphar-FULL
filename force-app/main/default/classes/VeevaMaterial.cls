/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2021 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/


global without sharing virtual class VeevaMaterial {

    global class MaterialResult {
        public List<EM_Event_Material_vod__c> materials;
        public Map<String, String> lastModifiedDate;
        
        public MaterialResult(List<EM_Event_Material_vod__c> materials) {
            this(materials, null);
        }
        public MaterialResult(List<EM_Event_Material_vod__c> materials, Map<String, String> lastModifiedDate) {
            this.materials = materials;
            this.lastModifiedDate = lastModifiedDate;
        }
    }
        
    global class MaterialResultResponse extends VeevaBaseResponse{
        public MaterialResult data;
        public MaterialResultResponse(List<EM_Event_Material_vod__c> materials) {
            super();
            this.data = new MaterialResult(materials);
        }
        public MaterialResultResponse(String status, String message) {
            super(status, message);
        }
    }
    
    public static MaterialResultResponse createMissingMaterial(List<EM_Event_Material_vod__c> eventMaterials) {
        MaterialResultResponse materialResultResponse = new MaterialResultResponse(eventMaterials);
        if (!eventMaterials.isEmpty()) {
            try {
                String message = insertObjects(eventMaterials);
                if (String.isNotBlank(message)) {
                    materialResultResponse = new MaterialResultResponse('FAILURE', message);
                }
            } catch (Exception e) {
                materialResultResponse = new MaterialResultResponse('FAILURE', e.getMessage());
            }
        } 
        return materialResultResponse;
    }
    
    private static String insertObjects(List<SObject> sObjects) {
        String output = '';
        List<Database.Saveresult> results = Database.insert(sObjects, false);
        for (Database.Saveresult sr : results) {
            if (!sr.isSuccess()) {            	
                for (Database.Error err: sr.getErrors()) {
                    output += err.getMessage() + '; ';
                }
            }
        }
        return output; 
    }
    
}