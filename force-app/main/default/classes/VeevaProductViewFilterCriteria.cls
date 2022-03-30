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
  * VeevaProductViewFilterCriteria takes in a Product View and will determine which products in the Org meet the Product View's
  * Filter Criteria.
  */
public inherited sharing class VeevaProductViewFilterCriteria {

    private Product_View_vod__c productView;
    private VeevaSyntaxTokenizer tokenizer;
    private VeevaCompositeConditionSyntaxParser compositeConditionParser;
    private VeevaConditionTokenQueryBuilder queryBuilder;

    public VeevaProductViewFilterCriteria(Product_View_vod__c productView, VeevaSyntaxTokenizer tokenizer, VeevaCompositeConditionSyntaxParser compositeSyntaxParser,
                                        VeevaConditionTokenQueryBuilder queryBuilder) {
        this.productView = productView;
        this.tokenizer = tokenizer;
        this.compositeConditionParser = compositeSyntaxParser;
        this.queryBuilder = queryBuilder;
    }

    /**
     * Returns product ids that meet the Product View's Filter_Criteria_vod__c conditions.
     */
    public List<String> filterProductIds() {
        return filterProductIds(null, null);
    }

    /**
     * Filters Product Ids using the Product View's Filter_Criteria_vod__c conditions.
     * If the passed in product ids are null or empty we will return all product ids that meet the filter criteria's conditions.
     * We will also use an account id that will ultimately affect Child Objects that have Account reference fields (like Product_Information_vod__c).
     * Using the account id we will filter down the child objects that we care about.
     * 
     * Otherwise, the resulting product ids are a subset of the productIds passed in
     * that meet the Filter_Criteria_vod__c conditions.
     */
    public List<String> filterProductIds(List<String> productIds, String accountId) {
        // the trigger for Product Views makes sure that the filter criteria is valid and not empty
        List<VeevaSyntaxToken> tokens = tokenizer.tokenize(productView.Filter_Criteria_vod__c);
        VeevaCompositeConditionToken compositeConditionToken = compositeConditionParser.parse(tokens, 0);
        List<VeevaConditionToken> conditionTokens = compositeConditionToken.getConditions();
        for (VeevaConditionToken condition : conditionTokens) {
            queryBuilder.addCondition(condition);
        }
        String query = queryBuilder
            .filterIdsTo(productIds)
            .useAccountForQuery(accountId)
            .buildQuery();
        List<String> filteredProductIds = getFilteredProductIdsFromQuery(query);
        return filteredProductIds;
    }

    private List<String> getFilteredProductIdsFromQuery(String query) {
        List<String> filteredProductIds = new List<String>();
        try {
            // System.debug('Query to identify Products matching Filter Criteria conditions: ' + query);
            List<SObject> queryResults = Database.query(query);
            if (queryResults != null && queryResults.size() > 0) {
                for (SObject result : queryResults) {
                    filteredProductIds.add(result.Id);
                }
            }
        } catch (QueryException ex) {
            // If for some reason the query does not build correctly there are two possible issues:
            // - The syntax validation of the Product View Filter Criteria failed.
            // - VeevaConditionTokenQueryBuilder failed to build a valid SOQL query.
            // System.debug('QueryException occurred while querying Product View\'s Filter_Criteria_vod__c: ' + ex.getMessage());
            throw new InvalidSyntaxException('Unable to run SOQL query for Product View\'s Filter Criteria - Id:' + productView.Id);
        }
        return filteredProductIds;
    }

    public class InvalidSyntaxException extends Exception {}
}