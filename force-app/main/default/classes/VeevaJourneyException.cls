public inherited sharing class VeevaJourneyException extends Exception {
    public enum Type {
        INVALID_PARAM,
        NO_DATA_FOUND,
        NO_READ_ACCESS,
        NO_CREATE_ACCESS,
        NO_UPDATE_ACCESS,
        NO_DELETE_ACCESS,
        EXPECT_ONE
    }

    private static final Map<Type, String> msgMap = new Map<Type, String> {
        Type.INVALID_PARAM => 'Param {0} is invalid with value {1}',
        Type.NO_DATA_FOUND => 'No data found for {0}:{1}',
        Type.NO_READ_ACCESS => 'No read access for {0}',
        Type.NO_CREATE_ACCESS => 'No create access for {0}',
        Type.NO_UPDATE_ACCESS => 'No update access for {0}',
        Type.NO_DELETE_ACCESS => 'No delete access for {0}',
        Type.EXPECT_ONE => 'Expecting one record from the query, but got more than one.'
    };

    private Type exceptionType;

    public VeevaJourneyException(Type exceptionType) {
        this(msgMap.get(exceptionType));
        this.exceptionType = exceptionType;
    }

    public VeevaJourneyException(Type exceptionType, List<Object> params) {
        this(String.format(msgMap.get(exceptionType), params));
        this.exceptionType = exceptionType;
    }

    public VeevaJourneyException(Type exceptionType, Object param) {
        this(String.format(msgMap.get(exceptionType), new List<Object> {param}));
        this.exceptionType = exceptionType;
    }

    public VeevaJourneyException(Type exceptionType, String msg) {
        this(msg);
        this.exceptionType = exceptionType;
    }

    public VeevaJourneyException(Type exceptionType, Exception ex) {
        this(msgMap.get(exceptionType), ex);
        this.exceptionType = exceptionType;
    }

    public VeevaJourneyException(Type exceptionType, List<Object> params, Exception ex) {
        this(String.format(msgMap.get(exceptionType), params), ex);
        this.exceptionType = exceptionType;
    }

    public VeevaJourneyException(Type exceptionType, Object param, Exception ex) {
        this(String.format(msgMap.get(exceptionType), new List<Object> {param}), ex);
        this.exceptionType = exceptionType;
    }

    public VeevaJourneyException(Type exceptionType, String msg, Exception ex) {
        this(msg, ex);
        this.exceptionType = exceptionType;
    }

    public VeevaJourneyException(VeevaJourneyException ex) {
        this(ex.getMessage(), ex);
        this.exceptionType = ex.getExceptionType();
    }

    public Type getExceptionType() {
        return exceptionType;
    }

    public void setExceptionType(Type exceptionType) {
        this.exceptionType = exceptionType;
    }
}