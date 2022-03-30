global without sharing class UploadTransactionsModel {

    public class UploadRequest{
        public String action {get;}
        public String objectName{get;}
        public String upsertField {get;}
        public Boolean allOrNone {get;set;}
        public boolean allowFieldTruncation {get;set;}
        public List<UploadObject> uploadObjects {get;}
    }

    public class UploadObject{
        public String name {get;}
        public List<UploadObjectField> fields {get;}
    }

    public class UploadObjectField{
        public String name {get;}
        public String type {get;}
        public String value {get;}
        public String refObjectName {get;}
        public String refFieldName {get;}
    }

    public class UploadTransactionsResult{
        public boolean success {get; set;}
        List<UploadResult> uploadResults = new List<UploadResult>();
        Error error;

        public void addUploadResult(UploadResult uploadResultToAdd){
            if(uploadResultToAdd != null){
                uploadResults.add(uploadResultToAdd);
            }
        }

        public void addUploadResults(List<UploadResult> uploadResultsToAdd){
            if(uploadResultsToAdd != null && !uploadResultsToAdd.isEmpty()){
                this.uploadResults.addAll(uploadResultsToAdd);
            }
        }

        public void setError(String errorMessage){
            error = new Error(errorMessage);
        }

        public void setError(String errorMessage, String statusCode, String[] fields){
            error = new Error(errorMessage);
            error.statusCode = statusCode;
            error.fields = fields;
        }
    }

    public class UploadResult{
        boolean success;
        public boolean created{set;}
        String sfId;
        List<Error> errors = new List<Error>();

        public UploadResult(boolean isSuccess, String sfIdToSet){
            this.success = isSuccess;
            this.sfId = sfIdToSet;
        }

        public List<Error> getErrors(){return errors;}

        public void addError(String errorMessage){
            this.errors.add(new Error(errorMessage));
        }

        public void addError(String errorMessage, String statusCode, String[] fields){
            Error error = new Error(errorMessage);
            error.statusCode = statusCode;
            error.fields = fields;
            this.errors.add(error);
        }
    }

    public class Error{
        String errorMessage;
        String statusCode{set;}
        String[] fields{set;}

        public Error(String errorMessage){this.errorMessage = errorMessage;}
    }
}