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
 * The VeevaValueToken is a child class implementation of VeevaSyntaxToken.
 *
 * This specific implementation defines a value token with supporting and overriden methods to retrieve information from the field.
 */
public virtual class VeevaValueToken extends VeevaSyntaxToken {

    private Integer endingIndex;

     /**
     * A VeevaRelativeDateToken is made up of a startingIndex, token text, and an ending index
     */
    public VeevaValueToken(Integer startingIndex, String token, Integer endingIndex) {
        super(startingIndex, token);
        this.endingIndex = endingIndex;
    }

    public Integer getEndingIndex() {
        return endingIndex;
    }
}