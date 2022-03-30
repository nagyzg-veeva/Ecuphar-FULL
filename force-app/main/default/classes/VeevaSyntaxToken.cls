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
 * The VeevaSyntaxToken serves as a base class for various syntax tokens.
 * VeevaSyntaxTokenizer will primarily generate VeevaSyntaxTokens where these tokens will be used by child classes of VeevaSyntaxToken.
 */
public virtual class VeevaSyntaxToken {

    public static VeevaSyntaxToken OPENING_PARENTHESIS = new VeevaSyntaxToken(null, '(');
    public static VeevaSyntaxToken CLOSING_PARENTHESIS = new VeevaSyntaxToken(null, ')');

    public static VeevaSyntaxToken EQUALS = new VeevaSyntaxToken(null, '=');
    public static VeevaSyntaxToken NOT_EQUALS = new VeevaSyntaxToken(null, '!=');
    public static VeevaSyntaxToken LESS_THAN = new VeevaSyntaxToken(null, '<');
    public static VeevaSyntaxToken LESS_THAN_EQUALS = new VeevaSyntaxToken(null, '<=');
    public static VeevaSyntaxToken GREATER_THAN = new VeevaSyntaxToken(null, '>');
    public static VeevaSyntaxToken GREATER_THAN_EQUALS = new VeevaSyntaxToken(null, '>=');

    public static VeevaSyntaxToken SINGLE_QUOTE = new VeevaSyntaxToken(null, '\'');
    public static VeevaSyntaxToken SINGLE_QUOTE_ESCAPED = new VeevaSyntaxToken(null, '\\\'');

    public static VeevaSyntaxToken NULL_VALUE_TOKEN = new VeevaSyntaxToken(null, 'null');

    public static VeevaSyntaxToken NULL_TOKEN = new VeevaSyntaxToken(null, '', false);

    /**
     * TERMINALS are terminals operators used when tokenizing to determine if the input value is a token.
     * TERMINALS can also be used to determine if a given VeevaSyntaxToken is considered a terminal.
     */
    public static final List<VeevaSyntaxToken> TERMINALS = new List<VeevaSyntaxToken>{
        VeevaSyntaxToken.OPENING_PARENTHESIS,
        VeevaSyntaxToken.CLOSING_PARENTHESIS,
        VeevaSyntaxToken.EQUALS,
        VeevaSyntaxToken.NOT_EQUALS,
        VeevaSyntaxToken.LESS_THAN,
        VeevaSyntaxToken.GREATER_THAN,
        VeevaSyntaxToken.LESS_THAN_EQUALS,
        VeevaSyntaxToken.GREATER_THAN,
        VeevaSyntaxToken.GREATER_THAN_EQUALS,
        VeevaSyntaxToken.SINGLE_QUOTE
    };

    private Integer startingIndex;
    private String text;
    private boolean isValid;
    private String error;

    public VeevaSyntaxToken(Integer startingIndex, String token) {
        this.startingIndex = startingIndex;
        this.text = token;
        this.isValid = true;
        this.error = '';
    }

    public VeevaSyntaxToken(Integer startingIndex, String token, boolean valid) {
        this.startingIndex = startingIndex;
        this.text = token;
        this.isValid = valid;
        this.error = '';
    }

    public void setError(String error) {
        this.error = error;
    }

    public virtual String getError() {
        return error;
    }

    /**
     * This method sets if a Token is valid.
     * In the base implementation this will act as a setter method and the getter will be isValid.
     * A child class may utilize this method call to serve as a bypass (when false) for the logic contained in isValid.
     */
    public void setValid(boolean isValid) {
        this.isValid = isValid;
    }

    /**
     * This method will return if a VeevaSyntaxToken or child implementation is valid.
     * A child class may override this implementation dependent on what the child class may consider as valid.
     * A child class implementation may also call super.isValid to determine if the Token was originally valid.
     */
    public virtual boolean isValid() {
        return isValid;
    }

    public virtual String getTokenText() {
        return text;
    }

    public Integer getStartingIndex() {
        return startingIndex;
    }

    public virtual Integer length() {
        return text.length();
    }

    /**
     * This method will compare if the VeevaSyntaxToken's text values are equal.
     */
    public boolean equals(VeevaSyntaxToken token) {
        return text != null && text.equalsIgnoreCase(token.text);
    }

    /**
     * Generates a String that can be used in a SOQL query for this VeevaSyntaxToken.
     */
    public virtual String generateSOQL() {
        return text;
    }
}