public inherited sharing class VeevaGASSearchClause {
    private static final String EQUALS_OP = '=';
    private static final String NOT_EQUALS_OP = '!=';
    private static final String IN_OP = 'IN';
    private static final String NOT_IN_OP = 'NOT IN';

    private final Map<Schema.SObjectType, List<VeevaGASSearchCondition>> conditionsByObjectType;

    public VeevaGASSearchClause(List<VeevaGASSearchCondition> conditions) {
        conditionsByObjectType = getConditionsByObjectType(conditions);
    }

    public String generateSOSLClause(String objectName) {
        List<VeevaGASSearchCondition> objectConditions = getObjectConditions(objectName);
        Map<VeevaGASSearchConditionOperator, List<VeevaGASSearchCondition>> conditionsByOperator = getConditionsByOperator(objectConditions);
        List<VeevaGASSearchCondition> equalsObjectConditions = getConditions(VeevaGASSearchConditionOperator.EQUALS, conditionsByOperator);
        List<VeevaGASSearchCondition> notEqualsObjectConditions = getConditions(VeevaGASSearchConditionOperator.NOT_EQUALS, conditionsByOperator);
        Map<String, List<VeevaGASSearchCondition>> equalsConditionsByFieldName = getConditionsByFieldName(equalsObjectConditions);
        Map<String, List<VeevaGASSearchCondition>> notEqualsConditionsByFieldName = getConditionsByFieldName(notEqualsObjectConditions);

        List<String> conditionStrings = new List<String>();
        conditionStrings.addAll(getConditionStringsUsingConditionsByFieldName(equalsConditionsByFieldName, VeevaGASSearchConditionOperator.EQUALS));
        conditionStrings.addAll(getConditionStringsUsingConditionsByFieldName(notEqualsConditionsByFieldName, VeevaGASSearchConditionOperator.NOT_EQUALS));
        return String.join(conditionStrings, ' AND ');
    }

    private List<String> getConditionStringsUsingConditionsByFieldName(Map<String, List<VeevaGASSearchCondition>> conditionsByFieldName, VeevaGASSearchConditionOperator operatorEnum) {
        String operator = getOperatorString(operatorEnum);
        String multipleOperator = getMultipleOperatorString(operatorEnum);
        List<String> conditionStrings = new List<String>();
        for (String fieldName : conditionsByFieldName.keySet()) {
            List<VeevaGASSearchCondition> conditions = conditionsByFieldName.get(fieldName);
            // Ensures that the values are unique
            List<String> values = new List<String>(new Set<String>(getValues(conditions)));
            String conditionStringFormat;
            if (conditions.size() == 1) {
                conditionStringFormat = String.format(
                    '{0} {1} {2}',
                    new List<String>{fieldName, operator, values.get(0)}
                );
            } else {
                conditionStringFormat = String.format(
                    '{0} {1} ({2})',
                    new List<String>{fieldName, multipleOperator, String.join(values, ', ')}
                );
            }
            conditionStrings.add(conditionStringFormat);
        }
        return conditionStrings;
    }

    private List<VeevaGASSearchCondition> getObjectConditions(String objectName) {
        List<VeevaGASSearchCondition> objectConditions = conditionsByObjectType.get(getObjectType(objectName));
        if (objectConditions == null) {
            objectConditions = new List<VeevaGASSearchCondition>();
        }
        return objectConditions;
    }

    private static Schema.SObjectType getObjectType(String objectName) {
        Type typeOfObject = Type.forName(objectName);
        Schema.SObjectType objectType = ((SObject) typeOfObject.newInstance()).getSObjectType();
        return objectType;
    }

    private static List<VeevaGASSearchCondition> getConditions(String key, Map<String, List<VeevaGASSearchCondition>> mapToCheck) {
        List<VeevaGASSearchCondition> objectConditions = mapToCheck.get(key);
        if (objectConditions == null) {
            objectConditions = new List<VeevaGASSearchCondition>();
        }
        return objectConditions;
    }

    private static List<VeevaGASSearchCondition> getConditions(VeevaGASSearchConditionOperator key, Map<VeevaGASSearchConditionOperator, List<VeevaGASSearchCondition>> mapToCheck) {
        List<VeevaGASSearchCondition> objectConditions = mapToCheck.get(key);
        if (objectConditions == null) {
            objectConditions = new List<VeevaGASSearchCondition>();
        }
        return objectConditions;
    }

    private static Map<Schema.SObjectType, List<VeevaGASSearchCondition>> getConditionsByObjectType(List<VeevaGASSearchCondition> conditions) {
        Map<Schema.SObjectType, List<VeevaGASSearchCondition>> conditionsByObjectType = new Map<Schema.SObjectType, List<VeevaGASSearchCondition>>();
        for (VeevaGASSearchCondition condition : conditions) {
            List<VeevaGASSearchCondition> objectConditions = conditionsByObjectType.get(condition.getObject());
            if (objectConditions == null) {
                objectConditions = new List<VeevaGASSearchCondition>();
                conditionsByObjectType.put(condition.getObject(), objectConditions);
            }
            objectConditions.add(condition);
        }
        return conditionsByObjectType;
    }

    private static Map<String, List<VeevaGASSearchCondition>> getConditionsByFieldName(List<VeevaGASSearchCondition> conditions) {
        Map<String, List<VeevaGASSearchCondition>> conditionsByField = new Map<String, List<VeevaGASSearchCondition>>();
        for (VeevaGASSearchCondition condition : conditions) {
            List<VeevaGASSearchCondition> fieldConditions = conditionsByField.get(condition.getFieldName());
            if (fieldConditions == null) {
                fieldConditions = new List<VeevaGASSearchCondition>();
                conditionsByField.put(condition.getFieldName(), fieldConditions);
            }
            fieldConditions.add(condition);
        }
        return conditionsByField;
    }

    private static Map<VeevaGASSearchConditionOperator, List<VeevaGASSearchCondition>> getConditionsByOperator(List<VeevaGASSearchCondition> conditions) {
        Map<VeevaGASSearchConditionOperator, List<VeevaGASSearchCondition>> conditionsByOperator = new Map<VeevaGASSearchConditionOperator, List<VeevaGASSearchCondition>>();
        for (VeevaGASSearchCondition condition : conditions) {
            List<VeevaGASSearchCondition> operatorConditions = conditionsByOperator.get(condition.getOperator());
            if (operatorConditions == null) {
                operatorConditions = new List<VeevaGASSearchCondition>();
                conditionsByOperator.put(condition.getOperator(), operatorConditions);
            }
            operatorConditions.add(condition);
        }
        return conditionsByOperator;
    }

    private static List<String> getValues(List<VeevaGASSearchCondition> conditions) {
        List<String> values = new List<String>();
        for (VeevaGASSearchCondition condition : conditions) {
            values.add(condition.getValue());
        }
        return values;
    }

    private static String getOperatorString(VeevaGASSearchConditionOperator operator) {
        switch on operator {
            when EQUALS {
                return EQUALS_OP;
            }
            when NOT_EQUALS {
                return NOT_EQUALS_OP; 
            }
            when else {
                return EQUALS_OP;
            }
        }
    }

    private static String getMultipleOperatorString(VeevaGASSearchConditionOperator operator) {
        switch on operator {
            when EQUALS {
                return IN_OP;
            }
            when NOT_EQUALS {
                return NOT_IN_OP; 
            }
            when else {
                return IN_OP;
            }
        }
    }
}