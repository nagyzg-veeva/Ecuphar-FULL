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
 * The VeevaRelativeDateToken is a child class implementation of VeevaValueToken.
 *
 * This specific implementation defines a relative date token (made up of multiple tokens) with supporting and overriden methods to retrieve information from the field.
 */
public inherited sharing class VeevaRelativeDateToken extends VeevaValueToken {
    public static final VeevaSyntaxToken RELATIVE_DATE_PREFIX_THIS = new VeevaSyntaxToken(null, 'this');
    public static final VeevaSyntaxToken RELATIVE_DATE_PREFIX_LAST = new VeevaSyntaxToken(null, 'last');

    private VeevaSyntaxToken relativeDatePrefix;
    private VeevaSyntaxToken relativeDateNumber;
    private VeevaSyntaxToken unitOfTime;

    /**
     * A VeevaRelativeDateToken is made up of a startingIndex, relative date prefix (this, last), a number token, a unit of time token and an ending index
     */
    public VeevaRelativeDateToken(Integer startingIndex, VeevaSyntaxToken relativeDatePrefix, VeevaSyntaxToken relativeDateNumber, VeevaSyntaxToken unitOfTime, Integer endingIndex) {
        super(startingIndex, '', endingIndex);
        this.relativeDatePrefix = relativeDatePrefix;
        this.relativeDateNumber = relativeDateNumber;
        this.unitOfTime = unitOfTime;
    }

    public override String getTokenText() {
        String text = relativeDatePrefix != null ? getRelativeDatePrefix() : '';
        text += relativeDateNumber != null ? ' ' + getNumber() : '';
        text += unitOfTime != null ? ' ' + getUnitOfTime() : '';
        return text;
    }

    public String getRelativeDatePrefix() {
        return relativeDatePrefix != null ? relativeDatePrefix.getTokenText() : '';
    }

    public String getNumber() {
        return relativeDateNumber != null ? relativeDateNumber.getTokenText() : '';
    }

    public String getUnitOfTime() {
        return unitOfTime != null ? unitOfTime.getTokenText() : '';
    }

    public VeevaSyntaxToken getRelativeDatePrefixToken() {
        return relativeDatePrefix;
    }

    public VeevaSyntaxToken getNumberToken() {
        return relativeDateNumber;
    }

    public VeevaSyntaxToken getUnitOfTimeToken() {
        return unitOfTime;
    }

    public override String generateSOQL() {
        String soqlCompatibleRelativeDate = '';
        String prefix = getRelativeDatePrefix();
        String relativeNumber = getNumber();
        String unitOfTime = getUnitOfTime();

        if (String.isNotBlank(prefix) && String.isNotBlank(relativeNumber) && String.isNotBlank(unitOfTime)) {
            soqlCompatibleRelativeDate = String.join(new List<String>{
                prefix.toUpperCase(),
                'N',
                unitOfTime.toUpperCase()},
            '_');
            soqlCompatibleRelativeDate += ':' + relativeNumber;
        } else if (String.isNotBlank(prefix) && String.isNotBlank(unitOfTime) && String.isBlank(relativeNumber)) {
            soqlCompatibleRelativeDate = String.join(new List<String>{
                prefix.toUpperCase(),
                unitOfTime.toUpperCase()
            }, '_');
        }

        if (isDayEdgeCase(soqlCompatibleRelativeDate)) {
            soqlCompatibleRelativeDate = convertDayEdgeCaseToSOQLCompatible(soqlCompatibleRelativeDate);
        }

        return soqlCompatibleRelativeDate;
    }

    private String convertDayEdgeCaseToSOQLCompatible(String relativeDateSOQLFormat) {
        String soqlCompatibleRelativeDay = '';
        switch on relativeDateSOQLFormat {
            when 'NEXT_DAY' {
                soqlCompatibleRelativeDay = 'TOMORROW';
            }
            when 'THIS_DAY' {
                soqlCompatibleRelativeDay = 'TODAY';
            }
            when 'LAST_DAY' {
                soqlCompatibleRelativeDay = 'YESTERDAY';
            }
        }
        return soqlCompatibleRelativeDay;
    }

    private boolean isDayEdgeCase(String relativeDateSOQLFormat) {
        return relativeDateSOQLFormat.equalsIgnoreCase('NEXT_DAY')
            || relativeDateSOQLFormat.equalsIgnoreCase('THIS_DAY')
            || relativeDateSOQLFormat.equalsIgnoreCase('LAST_DAY');
    }
}