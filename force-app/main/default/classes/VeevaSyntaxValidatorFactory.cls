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
 * Copyright (c) 2020 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/

/**
 * This factory will be used to construct various VeevaSyntaxValidator and VeevaSyntaxParsers.
 *
 * Due to the complexity of some VeevaSyntaxParsers creating a generator method will make it easier to utilze a VeevaSyntaxParser or VeevaSyntaxValidator.
 */
public inherited sharing class VeevaSyntaxValidatorFactory {

    /**
     * Generates a VeevaSyntaxValidator instance for parsing Product View syntax.
     * Note that some of the classes created by the generator will contain generic VeevaSyntaxParsers
     * and some VeevaSyntaxParses unique to Product Views.
     */
    public static VeevaSyntaxValidator generateProductViewSyntaxValidator() {
        return new VeevaProductViewSyntaxValidator(new VeevaSyntaxTokenizer(), generateProductViewCompositeSyntaxParser());
    }

    /**
     * Generates a VeevaCompositeConditionSyntaxParser responsible for parsing Product View Syntax
     * and generating a VeevaCompositeConditionToken that represents the syntax.
     */
    public static VeevaCompositeConditionSyntaxParser generateProductViewCompositeSyntaxParser() {
        VeevaSyntaxErrorMessageManager errorMessageManager = new VeevaProductViewsErrorMessageManager();
        VeevaValueSyntaxParser valueParser = generateProductViewValueSyntaxParser(errorMessageManager);
        VeevaFieldSyntaxParser fieldParser = generateProductViewFieldSyntaxParser(errorMessageManager);
        VeevaConditionSyntaxParser conditionParser = new VeevaConditionSyntaxParser(fieldParser, valueParser, errorMessageManager);

        List<String> validJoiningOperators = new List<String>{'and'};
        // The following idea for VeevaSyntaxValidators and VeevaSyntaxParsers is to be able to inject the appropriate implementation of the parser through the factory generator methods.
        return new VeevaCompositeConditionSyntaxParser(conditionParser, validJoiningOperators, errorMessageManager);
    }

    /**
     * Generates a Product View specific instance of VeevaValueSyntaxParser
     */
    public static VeevaValueSyntaxParser generateProductViewValueSyntaxParser(VeevaSyntaxErrorMessageManager errorMessageManager) {

        List<VeevaSyntaxToken> validRelativeDatePrefix = new List<VeevaSyntaxToken>{
            VeevaRelativeDateToken.RELATIVE_DATE_PREFIX_LAST,
            VeevaRelativeDateToken.RELATIVE_DATE_PREFIX_THIS
        };
        List<String> validUnitsOfTime = new List<String>{'day', 'week', 'month', 'year'};
        List<String> validPluralUnitsOfTime = new List<String>{'days', 'weeks', 'months', 'years'};

        Map<Schema.DisplayType, VeevaSyntaxValueParser> fieldTypeValueParsers = new Map<Schema.DisplayType, VeevaSyntaxValueParser>{
            Schema.DisplayType.STRING => new VeevaTextSyntaxValueParser(errorMessageManager),
            Schema.DisplayType.BOOLEAN => new VeevaBooleanSyntaxValueParser(errorMessageManager),
            Schema.DisplayType.INTEGER => new VeevaWholeNumberSyntaxValueParser(errorMessageManager),
            Schema.DisplayType.LONG => new VeevaWholeNumberSyntaxValueParser(errorMessageManager),
            Schema.DisplayType.DOUBLE => new VeevaDecimalNumberSyntaxValueParser(errorMessageManager),
            Schema.DisplayType.PERCENT => new VeevaDecimalNumberSyntaxValueParser(errorMessageManager),
            Schema.DisplayType.PICKLIST => new VeevaPicklistSyntaxValueParser(errorMessageManager),
            Schema.DisplayType.DATE => new VeevaRelativeDateSyntaxValueParser(validRelativeDatePrefix, validUnitsOfTime, validPluralUnitsOfTime, errorMessageManager)
        };

        return new VeevaValueSyntaxParser(fieldTypeValueParsers, errorMessageManager);
    }

    /**
     * Generates a Product View specific instance of VeevaValueSyntaxParser
     */
    private static VeevaFieldSyntaxParser generateProductViewFieldSyntaxParser(VeevaSyntaxErrorMessageManager errorMessageManager) {
        List<String> supportedObjects = new List<String>{'product_vod', 'product_information_vod'};
        List<Schema.DisplayType> supportedFieldTypes = new List<Schema.DisplayType>{
            Schema.DisplayType.STRING,
            Schema.DisplayType.INTEGER,
            Schema.DisplayType.LONG,
            Schema.DisplayType.DOUBLE,
            Schema.DisplayType.PERCENT,
            Schema.DisplayType.BOOLEAN,
            Schema.DisplayType.PICKLIST,
            Schema.DisplayType.DATE
        };

        List<VeevaSyntaxToken> numberSupportedOperators = new List<VeevaSyntaxToken>{
            VeevaSyntaxToken.EQUALS,
            VeevaSyntaxToken.NOT_EQUALS,
            VeevaSyntaxToken.LESS_THAN,
            VeevaSyntaxToken.LESS_THAN_EQUALS,
            VeevaSyntaxToken.GREATER_THAN,
            VeevaSyntaxToken.GREATER_THAN_EQUALS
        };
        Map<Schema.DisplayType, List<VeevaSyntaxToken>> fieldToSupportedOperators = new Map<Schema.DisplayType, List<VeevaSyntaxToken>>{
            Schema.DisplayType.STRING => new List<VeevaSyntaxToken>{VeevaSyntaxToken.EQUALS},
            Schema.DisplayType.PICKLIST => new List<VeevaSyntaxToken>{VeevaSyntaxToken.EQUALS},
            Schema.DisplayType.BOOLEAN => new List<VeevaSyntaxToken>{VeevaSyntaxToken.EQUALS},
            Schema.DisplayType.INTEGER => numberSupportedOperators,
            Schema.DisplayType.LONG => numberSupportedOperators,
            Schema.DisplayType.DOUBLE => numberSupportedOperators,
            Schema.DisplayType.PERCENT => new List<VeevaSyntaxToken>{
                VeevaSyntaxToken.EQUALS,
                VeevaSyntaxToken.LESS_THAN,
                VeevaSyntaxToken.LESS_THAN_EQUALS,
                VeevaSyntaxToken.GREATER_THAN,
                VeevaSyntaxToken.GREATER_THAN_EQUALS
            },
            Schema.DisplayType.DATE => new List<VeevaSyntaxToken>{
                VeevaSyntaxToken.EQUALS,
                VeevaSyntaxToken.NOT_EQUALS,
                VeevaSyntaxToken.LESS_THAN,
                VeevaSyntaxToken.LESS_THAN_EQUALS,
                VeevaSyntaxToken.GREATER_THAN,
                VeevaSyntaxToken.GREATER_THAN_EQUALS
            }
        };
        return new VeevaFieldSyntaxParser(supportedObjects, supportedFieldTypes, fieldToSupportedOperators, errorMessageManager);
    }
}