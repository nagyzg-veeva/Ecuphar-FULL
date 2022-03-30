@RestResource(urlMapping='/veeva/transactions')
global without sharing class UploadTransactionsService {

    static Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

    enum SupportedActions { INS, UPS, UPD }

    class BadDataException extends Exception {}

    @HttpPost
    global static void process() {
        UploadTransactionsModel.UploadTransactionsResult transactionsResult  = new UploadTransactionsModel.UploadTransactionsResult();
        RestResponse res = RestContext.response;

        if(RestContext.request.requestBody != null){
            Savepoint sp;
            try{
                String requestBodyStr = RestContext.request.requestBody.toString();
                UploadTransactionsModel.UploadRequest uploadRequest = (UploadTransactionsModel.UploadRequest) JSON.deserialize(requestBodyStr, UploadTransactionsModel.UploadRequest.class);
                validateRequest(uploadRequest);
                List<SObject> sObjects = convertToSObjects(uploadRequest);
                sp = Database.setSavepoint();
                List<UploadTransactionsModel.UploadResult> uploadResults = saveData(uploadRequest, sObjects);
                transactionsResult.success = true;
                transactionsResult.addUploadResults(uploadResults);
                res.statusCode = 200;
            }catch(BadDataException be){
                transactionsResult.success = false;
                transactionsResult.setError(be.getMessage());
                res.statusCode = 400;
            }catch(DmlException de){
                transactionsResult.success = false;
                transactionsResult.setError(de.getDmlMessage(0), de.getDmlType(0).name(), de.getDmlFieldNames(0));
                Database.rollback(sp);
                res.statusCode = 400;
            }catch (Exception e) {
                transactionsResult.success = false;
                transactionsResult.setError(e.getMessage());
                if(sp != null){
                    Database.rollback(sp);
                }
                res.statusCode = 500;
            }
        }else{
            transactionsResult.success = false;
            transactionsResult.setError('Request body is null');
            res.statusCode = 400;
        }
        res.responseBody = Blob.valueOf(JSON.serialize(transactionsResult));
    }

    private static void validateRequest(UploadTransactionsModel.UploadRequest uploadRequest){

        if(!isValidAction(uploadRequest.action)){
            throw new BadDataException('Action : ' + uploadRequest.action + ' not supported. Need to be one of ' + supportedActions.values());
        }

        if(String.isEmpty(uploadRequest.objectName) || gd.get(uploadRequest.objectName) == null){
            throw new BadDataException('Object name ' + uploadRequest.objectName + ' in request is not valid');
        }

        //DML option allOrNone is true by default if not provided in request
        if(uploadRequest.allOrNone == null){
            uploadRequest.allOrNone = true;
        }

        List<UploadTransactionsModel.UploadObject> objects = uploadRequest.uploadObjects;
        if(objects == null || objects.isEmpty()){
            throw new BadDataException('SObject list is empty in request');
        }

        if(objects.size() > 200){
            throw new BadDataException('Saving more than 200 records is not supported');
        }

    }

    private static List<SObject> convertToSObjects(UploadTransactionsModel.UploadRequest uploadRequest){
        List<SObject> sObjects = new List<SObject>();

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.allowFieldTruncation = uploadRequest.allowFieldTruncation;

        for(UploadTransactionsModel.UploadObject currentObject : uploadRequest.uploadObjects){
            String sObjectName = currentObject.name;
            if(String.isBlank(sObjectName) || !sObjectName.equals(uploadRequest.objectName)){
                throw new BadDataException('SObject name : ' + sObjectName + ' does not match object name : ' + uploadRequest.objectName + ' in request');
            }

            SObject targetSObject = (SObject)(Type.forName('Schema.'+ sObjectName).newInstance());
            List<UploadTransactionsModel.UploadObjectField> uploadObjectFields = currentObject.fields;

            for(UploadTransactionsModel.UploadObjectField field:uploadObjectFields){
                addField(field, targetSObject);
            }
            targetSObject.setOptions(dml);
            sObjects.add(targetSObject);
        }
        return sObjects;
    }

    private static void addField(UploadTransactionsModel.UploadObjectField reqField, SObject sObj) {
        String fldType = reqField.type;
        String value = reqField.value;
        String name = reqField.name;

        if(value == null || value.length() == 0){
            sObj.put(name,null);
        }else if('_boolean' == fldType || 'boolean' == fldType){
            boolean targetFldValue = false;
            if('true'.equalsIgnoreCase(value)) {
                targetFldValue = true;
            }
            sObj.put(name,targetFldValue);
        }else if('date' == fldType){
            Date targetFldValue = Date.valueOf(value);
            sObj.put(name,targetFldValue);
        }else if('datetime' == fldType || 'time' == fldType){
            if(value == null || value.length() == 0)
                return;
            Long l = Long.valueOf(value);
            Datetime dateTimeValue = Datetime.newInstance(l);
            if('datetime' == fldType){
                sObj.put(name,dateTimeValue);
            }else{
                Time timeValue = Time.newInstance(dateTimeValue.hour(), dateTimeValue.minute(), dateTimeValue.second(), dateTimeValue.millisecond());
                sObj.put(name,timeValue);
            }
        }else if('time' == fldType) {
            if(value == null || value.length() == 0)
                return;
            Long l = Long.valueOf(value);
            Datetime targetFldValue = Datetime.newInstance(l);
        }else if('_double' == fldType || 'double' == fldType || 'currency' == fldType ){
            Double targetFldValue = Double.valueOf(value);
            sObj.put(name,targetFldValue);
        }else if('_long' == fldType || 'long' == fldType){
            Long targetFldValue = Long.valueOf(value);
            sObj.put(name,targetFldValue);
        }else if('_int' == fldType || 'int' == fldType){
            Integer targetFldValue = Integer.valueOf(value);
            sObj.put(name,targetFldValue);
        }else if('percent' == fldType || '_precent' == fldType){
            Double targetFldValue = Double.valueOf(value);
            sObj.put(name,targetFldValue);
        }else if('base64' == fldType){
            Blob targetFldValue = EncodingUtil.base64Decode(value);
            sObj.put(name, targetFldValue);
        }else if ('reference' == fldType) {
            String refObjectName = reqField.refObjectName;
            String refFieldName = reqField.refFieldName;
            boolean refObjectAdded = false;
            if (refObjectName != null && refObjectName.length() > 0 && refFieldName != null && refFieldName.length() > 0) {
                // External id reference to another object
                Schema.SObjectType refObjectType = gd.get(refObjectName);
                if(refObjectType != null){
                    SObject refObject = refObjectType.newSObject();
                    refObject.put(refFieldName, value);
                    sobj.putSObject(name, refObject);
                    refObjectAdded = true;
                }
            }
            if(!refObjectAdded){
                sobj.put(name, value);
            }
        } else{
            sObj.put(name,value);
        }
    }

    private static boolean isValidAction(String action){
        if(!String.isEmpty(action)){
            for(SupportedActions supportedAction: SupportedActions.values()){
                if(supportedAction.name() == action){
                    return true;
                }
            }
        }
        return false;
    }

    private static List<UploadTransactionsModel.UploadResult> saveData(UploadTransactionsModel.UploadRequest uploadRequest, List<SObject> sObjects){
        List<UploadTransactionsModel.UploadResult> uploadResults = new List<UploadTransactionsModel.UploadResult>();

        if(uploadRequest.action == SupportedActions.INS.name()){
            uploadResults.addAll(doInsert(sObjects, uploadRequest.allOrNone));
        }else if(uploadRequest.action == SupportedActions.UPD.name()){
            uploadResults.addAll(doUpdate(sObjects, uploadRequest.allOrNone));
        }else if(uploadRequest.action == SupportedActions.UPS.name()){
            uploadResults.addAll(doUpsert(sObjects, uploadRequest.objectName, uploadRequest.upsertField, uploadRequest.allOrNone));
        }
        return uploadResults;
    }

    private static List<UploadTransactionsModel.UploadResult> doInsert(List<SObject> sObjects, boolean allOrNone){
        List<UploadTransactionsModel.UploadResult> uploadResults = new List<UploadTransactionsModel.UploadResult>();
        List<Database.Saveresult> results = Database.insert(sObjects, allOrNone);
        for(Database.Saveresult sr : results){
            UploadTransactionsModel.UploadResult result = new UploadTransactionsModel.UploadResult(sr.isSuccess(), sr.getId());
            if(!sr.isSuccess()){
                for(Database.Error error : sr.getErrors()){
                    result.addError(error.getMessage(), error.getStatusCode().name(), error.getFields());
                }
            }
            uploadResults.add(result);
        }
        return uploadResults;
    }

    private static List<UploadTransactionsModel.UploadResult> doUpdate(List<SObject> sObjects, boolean allOrNone){
        List<UploadTransactionsModel.UploadResult> uploadResults = new List<UploadTransactionsModel.UploadResult>();
        List<Database.Saveresult> results = Database.update(sObjects, allOrNone);
        for(Database.Saveresult sr : results){
            UploadTransactionsModel.UploadResult result = new UploadTransactionsModel.UploadResult(sr.isSuccess(), sr.getId());
            if(!sr.isSuccess()){
                for(Database.Error error : sr.getErrors()){
                    result.addError(error.getMessage(), error.getStatusCode().name(), error.getFields());
                }
            }
            uploadResults.add(result);
        }
        return uploadResults;
    }

    private static List<UploadTransactionsModel.UploadResult> doUpsert(List<SObject> sObjects, String objectName, String upsertField, boolean allOrNone){
        List<UploadTransactionsModel.UploadResult> uploadResults = new List<UploadTransactionsModel.UploadResult>();
        List<Database.Upsertresult> results;
        if(!String.isEmpty(upsertField)){
            Schema.SObjectType sObjectType = gd.get(objectName);
            Schema.SObjectField upsertFld = sObjectType.getDescribe().fields.getMap().get(upsertField);
            if(upsertFld == null){
                throw new BadDataException('upsert field ' + upsertField + ' is not valid for ' + objectName);
            }
            results = Database.upsert(sObjects, upsertFld, allOrNone);
        }else{
            results = Database.upsert(sObjects,allOrNone);
        }
        for(Database.Upsertresult sr : results){
            UploadTransactionsModel.UploadResult result = new UploadTransactionsModel.UploadResult(sr.isSuccess(), sr.getId());
            result.created = sr.isCreated();
            if(!sr.isSuccess()){
                for(Database.Error error : sr.getErrors()){
                    result.addError(error.getMessage(), error.getStatusCode().name(), error.getFields());
                }
            }
            uploadResults.add(result);
        }
        return uploadResults;
    }
}