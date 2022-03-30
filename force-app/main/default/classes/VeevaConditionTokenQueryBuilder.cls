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

/**
 * VeevaConditionTokenQueryBuilder is responsible for converting VeevaConditionTokens into a SOQL query that can be executed.
 *
 * VeevaConditionTokenQueryBuilder currently supports a max of two child objects and only supports the "AND" joining operator between conditions.
 */
public inherited sharing class VeevaConditionTokenQueryBuilder {

    private final Schema.SObjectType parentObject;
    private final Map<Schema.SObjectType, Schema.SObjectField> childObjectsWithParentFieldReference;
    private final Map<Schema.SObjectType, Schema.SObjectField> childObjectsWithReferenceToAccount;
    private final Map<Schema.SObjectType, Set<String>> whereClauseForObject;
    private final Set<String> fieldsToQuery;
    private List<String> filterToIds;
    private String accountIdToRestrictChildrenTo;

    public VeevaConditionTokenQueryBuilder(Schema.SObjectType parentObject, Map<Schema.SObjectType, Schema.SObjectField> childObjectsWithParentFieldReference,
                                            Map<Schema.SObjectType, Schema.SObjectField> childObjectsWithReferenceToAccount) {
        this.parentObject = parentObject;
        this.whereClauseForObject = new Map<Schema.SObjectType, Set<String>>();
        this.fieldsToQuery = new Set<String>{'ID'}; // we will always query for ID
        this.childObjectsWithReferenceToAccount = childObjectsWithReferenceToAccount;

        // this query builder is only able to build a query where there is a max of two child objects.
        if (childObjectsWithParentFieldReference == null) {
            this.childObjectsWithParentFieldReference = new Map<Schema.SObjectType, Schema.SObjectField>();
        } else if (childObjectsWithParentFieldReference.size() <= 2) {
            this.childObjectsWithParentFieldReference = childObjectsWithParentFieldReference;
        } else {
            throw new VeevaQueryArgumentException('Invalid Number of Child Objects for Query');
        }
    }

    public VeevaConditionTokenQueryBuilder(Schema.SObjectType parentObject, Map<Schema.SObjectType, Schema.SObjectField> childObjectsWithParentFieldReference) {
        this(parentObject, childObjectsWithParentFieldReference, new Map<Schema.SObjectType, Schema.SObjectField>());
    }

    public VeevaConditionTokenQueryBuilder addCondition(VeevaConditionToken conditionToken) {
        if (conditionToken != null) {
            String conditionSOQL = conditionToken.generateSOQL();
            Schema.SObjectType objectType = conditionToken.getSObjectTypeForCondition();
            if (String.isNotBlank(conditionSOQL)) {
                Set<String> objectWhereClauses = getObjectWhereClauses(objectType);
                objectWhereClauses.add(conditionSOQL);
            }
        }
        return this;
    }

    public VeevaConditionTokenQueryBuilder addField(Schema.SObjectField field) {
        this.fieldsToQuery.add(field.getDescribe().getName());
        return this;
    }

    public VeevaConditionTokenQueryBuilder addField(String fieldName) {
        this.fieldsToQuery.add(fieldName);
        return this;
    }

    public VeevaConditionTokenQueryBuilder filterIdsTo(List<String> filterToIds) {
        this.filterToIds = filterToIds;
        return this;
    }

    public VeevaConditionTokenQueryBuilder useAccountForQuery(String accountId) {
        this.accountIdToRestrictChildrenTo = accountId;
        return this;
    }

    /**
     * Builds a SOQL query that places an "AND" operator between the VeevaConditionTokens passed into the Builder.
     * The final SOQL query built will query from the parent object and up to a max of two child relational objects
     * if ids were passed in to filter to those ids will also be part of the final SOQL query.
     * 
     * If no conditions were added to builder a null query will be returned.
     *
     * If the parentObject was not defined during the instatiation of the builder then
     * a null query will be returned.
     */
    public String buildQuery() {
        String query = null;
        if (parentObject != null && whereClauseForObject.size() > 0) {
            String whereClause = '';
            whereClause += addIdsToFilterTo(filterToIds);

            Set<String> whereClausesForParent = whereClauseForObject.get(parentObject);
            // we only support building queries with the AND joining operator
            String compositeParentWhereClause = joinWhereClausesWith(whereClausesForParent, 'AND');
            whereClause += joiningOperatorIfNecessary(whereClause, compositeParentWhereClause, 'AND') + compositeParentWhereClause;

            String compositeChildWhereClause = generateChildWhereClauses();
            whereClause += joiningOperatorIfNecessary(whereClause, compositeChildWhereClause, 'AND') + compositeChildWhereClause;

            query = generateSelectAndWherePrefix() + whereClause;
        }
        return query;
    }

    private String generateSelectAndWHerePrefix() {
        String commaSeparatedFields = String.join(new List<String>(fieldsToQuery), ',');
        return String.format(
            'SELECT {0} FROM {1} WHERE ',
            new List<String>{commaSeparatedFields, parentObject.getDescribe().getName()}
        );
    }

    private String joiningOperatorIfNecessary(String leftSide, String rightSide, String joiningOperator) {
        return String.isNotBlank(leftSide) && String.isNotBlank(rightSide) ? ' ' + joiningOperator + ' ' : '';
    }

    private Set<String> getObjectWhereClauses(Schema.SObjectType objectType) {
        Set<String> objectWhereClauses = whereClauseForObject.get(objectType);
        if (objectWhereClauses == null) {
            objectWhereClauses = new Set<String>();
            whereClauseForObject.put(objectType, objectWhereClauses);
        }
        return objectWhereClauses;
    }

    private String joinWhereClausesWith(Set<String> whereClauses, String joiningOperator) {
        String joinedWhereClause = '';
        if (whereClauses != null && whereClauses.size() > 0) {
            joinedWhereClause = String.join(new List<String>(whereClauses), ' ' + joiningOperator + ' ' );
        }
        return joinedWhereClause;
    }

    private String addIdsToFilterTo(List<String> filterToIds) {
        String idsToFilterClause = '';
        if (filterToIds != null && filterToIds.size() > 0) {
            List<String> idsSurroundedWithSingleQuotes = new List<String>();
            for (String filterToId : filterToIds) {
                if (String.isNotBlank(filterToId)) {
                    idsSurroundedWithSingleQuotes.add('\'' + filterToId + '\'');
                }
            }
            idsToFilterClause = String.format('ID IN ({0})', new List<String>{
                String.join(idsSurroundedWithSingleQuotes, ',')
            });
        }
        return idsToFilterClause;
    }

    private String generateChildWhereClauses() {
        String childSemiJoinSubSelects = '';
        for (Schema.SObjectType childObject : childObjectsWithParentFieldReference.keySet()) {
            Schema.SObjectField field = childObjectsWithParentFieldReference.get(childObject);
            if (field != null) {
                String childSemiJoinSubSelectForChildObject = generateSemiJoinSubSelectForChild(childObject, field);
                childSemiJoinSubSelects += joiningOperatorIfNecessary(childSemiJoinSubSelects, childSemiJoinSubSelectForChildObject, 'AND') + childSemiJoinSubSelectForChildObject;
            }
        }
        return childSemiJoinSubSelects;
    }

    private String generateSemiJoinSubSelectForChild(Schema.SObjectType childObject, Schema.SObjectField field) {
        String childObjectSemiJoinSubSelect = '';
        Set<String> whereClausesForChild = whereClauseForObject.get(childObject);

        if (whereClausesForChild != null && whereClausesForChild.size() > 0) {
            Schema.SObjectField accountReferenceField = childObjectsWithReferenceToAccount.get(childObject);
            if (String.isNotBlank(accountIdToRestrictChildrenTo) && accountReferenceField != null) {
                String accountReferenceFieldName = accountReferenceField.getDescribe().getName();
                String accountIdIsWhereClause = String.format(
                    '{0} = {1}',
                    new List<String>{accountReferenceFieldName, '\'' + accountIdToRestrictChildrenTo + '\''}
                );
                whereClausesForChild.add(accountIdIsWhereClause);
            }

            // we only support building queries with the AND joining operator
            String whereClause = joinWhereClausesWith(whereClausesForChild, 'AND');
            String fieldName = field.getDescribe().getName();
            String childObjectName = childObject.getDescribe().getName();
            childObjectSemiJoinSubSelect = String.format(
                'ID IN (SELECT {0} FROM {1} WHERE {2})',
                new String[]{fieldName, childObjectName, whereClause}
            );
        }
        return childObjectSemiJoinSubSelect;
    }
}