public inherited sharing class VeevaJourneyQueryBuilder {
    /**
     * @description build a pagination clause from a page options object
     * @param pageOptions the given page options object
     * @return the built clause, e.g. ORDER BY Name ASC NULLS LAST LIMIT 20 OFFSET 40
     */
    public static String buildPageClause(VeevaJourneyPageOptions pageOptions) {
        if (pageOptions.getPage() == null || pageOptions.getPageSize() == null) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.INVALID_PARAM,
                new List<Object> {'pageOptions', pageOptions}
            );
        }

        Integer offset = pageOptions.getPage() * pageOptions.getPageSize();
        String offsetClause = ' OFFSET ' + offset;

        String limitClause = ' LIMIT ' + pageOptions.getPageSize();

        String orderClause = buildOrderByClause(pageOptions.getOrderConfigs());

        return orderClause + limitClause + offsetClause;
    }

    public static String buildLikeClause(
        String fieldName,
        String filter,
        Boolean startWith,
        Boolean endWith
    ) {
        if (!String.isBlank(filter)) {
            return ' ' + fieldName + ' LIKE \'' + (startWith ? '' : '%') + String.escapeSingleQuotes(filter) +
                   (endWith ? '' : '%') + '\'';
        }
        return '';
    }
    /**
     * @description build a IN/NOT IN clause with/without null check
     * @param inSet the set of values for the field
     * @param inSetField the field that the values apply on
     * @param allowEmpty allow the field value to be null
     * @param notIn use NOT IN if true; use IN if false
     * @return the built clause, e.g. Name IN ('journey1', journey2') AND Name = null
     */
    public static String buildInOrNoneClause(
        List<Object> inSet,
        String inSetField,
        Boolean allowEmpty,
        Boolean notIn
    ) {
        String finalClause = '';
        List<String> clauses = new List<String>();

        List<Object> toJoinItems = new List<Object>();
        if (
            inSet != null &&
            !inSet.isEmpty() &&
            (
                inSet.get(0) instanceof String ||
                inSet.get(0) instanceof ID
            )
        ) {
            for (Object item: inSet) {
                toJoinItems.add('\'' + String.escapeSingleQuotes(String.valueOf(item)) + '\'');
            }
        } else {
            toJoinItems = inSet;
        }
        if (!toJoinItems.isEmpty()) {
            clauses.add(
                ' ' + inSetField + (notIn ? ' NOT IN ' : ' IN ') +
                wrapInParentheses(String.join(toJoinItems, ', '))
            );
        }

        if (!notIn && allowEmpty) {
            clauses.add(' ' + inSetField + ' = null');
            finalClause = joinClauses(clauses, ' OR ');
        } else if (notIn && !allowEmpty) {
            clauses.add(' ' + inSetField + ' != null');
            finalClause = joinClauses(clauses, ' AND ');
        } else if (!clauses.isEmpty()) {
            finalClause = clauses.get(0);
        }

        return finalClause;
    }
    /**
     * @description build a order by clause from order config objects
     * @param orderConfigs the order config objects
     * @return the built clause, e.g. ORDER BY Name ASC NULLS LAST
     */
    public static String buildOrderByClause(List<VeevaJourneyOrderConfig> orderConfigs) {
        if (orderConfigs == null || orderConfigs.isEmpty()) return '';

        List<String> orderClauses = new List<String>();
        for (VeevaJourneyOrderConfig orderConfig: orderConfigs) {
            String orderClause = String.join(
                new List<String> {
                    String.escapeSingleQuotes(orderConfig.getKey()),
                    orderConfig.getOrderName(),
                    'NULLS',
                    orderConfig.getNullValName()
                },
                ' '
            );
            orderClauses.add(orderClause);
        }
        return ' ORDER BY ' + String.join(orderClauses, ', ');
    }
    /**
     * @description join clauses with the given operator
     * @param clauses the clauses to join
     * @param operator the operator between the clauses
     * @return the joined clause, e.g. (Column1 != null AND Column2 = null)
     */
    public static String joinClauses(List<String> clauses, String operator) {
        if (String.isBlank(operator)) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.INVALID_PARAM,
                new List<Object> {'operator', operator}
            );
        }

        if (
            clauses == null ||
            clauses.isEmpty()
        ) {
            return '';
        }

        List<String> toJoin = new List<String>();
        for (String clause : clauses) {
            if (!String.isBlank(clause)) {
                toJoin.add(clause.trim());
            }
        }

        String joined = String.join(toJoin, ' ' + operator.trim() + ' ');

        return toJoin.size() > 1 ? wrapInParentheses(joined) : joined;
    }
    /**
     * @description run name lookup query against a object
     * @param objectName the object name of the object to lookup
     * @param fields the fields of the object
     * @whereClause the where clause for lookup
     * @pageOptions the pagination options
     * @return the lookup query result with the paginated data and the total count
     */
    public static VeevaJourneyLookupFieldQueryResult runLookupFieldQuery(
        String objectName,
        List<String> fields,
        String whereClause,
        VeevaJourneyPageOptions pageOptions
    ) {
        List<String> finalFields = new List<String>();
        finalFields.add('Id');
        finalFields.addAll(fields);
        String dataQuery = (
            buildSelectClause(objectName, finalFields) + ' WHERE ' + whereClause + buildPageClause(
                pageOptions
            )
        );
        System.debug('executing lookup field query: ' + dataQuery);
        List<SObject> data = Database.query(dataQuery);

        String escapedObjectName = String.escapeSingleQuotes(objectName);
        Integer count = Database.countQuery(
            'SELECT COUNT() FROM ' + escapedObjectName + ' WHERE ' + whereClause
        );

        return new VeevaJourneyLookupFieldQueryResult(data, count);
    }
    /**
     * @description build a select clause given an object name and a list of fields
     * @param objectName
     * @param fieldNames
     * @return the select clause, e.g. SELECT Id, Name FROM Andi_Journey_vod__c
     */
    public static String buildSelectClause(String objectName, List<String> fieldNames) {
        if (
            String.isBlank(objectName) ||
            fieldNames == null ||
            fieldNames.isEmpty()
        ) {
            return '';
        }
        List<String> escapedFieldNames = new List<String>();
        for (String fieldName : fieldNames) {
            escapedFieldNames.add(String.escapeSingleQuotes(fieldName));
        }
        String joinedFieldNames = String.join(escapedFieldNames, ', ');
        String escapedObjectName = String.escapeSingleQuotes(objectName);
        return 'SELECT ' + joinedFieldNames + ' FROM ' + escapedObjectName;
    }
    /**
     * @description wrap a string in parentheses
     * @param toWrap
     * @return if the string to wrap is blank, then returns an empty string; otherwise, wrap it in parentheses
     */
    public static String wrapInParentheses(String toWrap) {
        return String.isBlank(toWrap) ? '' : '(' + toWrap + ')';
    }
}