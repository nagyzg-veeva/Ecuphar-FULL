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
 * VeevaSyntaxTokenizer tokenizes an input string into VeevaSyntaxTokens.
 */
public inherited sharing class VeevaSyntaxTokenizer {

    private LiteralTokenizer literalTokenizer;
    private GenericTokenizer genericTokenizer;

    public VeevaSyntaxTokenizer() {
        literalTokenizer = new VeevaSyntaxTokenizer.LiteralTokenizer(VeevaSyntaxToken.SINGLE_QUOTE, VeevaSyntaxToken.SINGLE_QUOTE_ESCAPED);
        genericTokenizer = new VeevaSyntaxTokenizer.GenericTokenizer();

    }

    public List<VeevaSyntaxToken> tokenize(String syntax) {
        List<VeevaSyntaxToken> tokens = new List<VeevaSyntaxToken>();

        Integer index = 0;
        while (syntax != null && index < syntax.length()) {
            String charAtIndex = syntax.substring(index, index + 1);
            if (!' '.equals(charAtIndex)) { // ignore leading/tailing whitespace
                VeevaSyntaxToken token = null;
                if (literalTokenizer.getTerminal().getTokenText().equalsIgnoreCase(charAtIndex)) {
                    token = literalTokenizer.nextToken(syntax, index);
                }
                
                if (token == null || VeevaSyntaxToken.NULL_TOKEN.equals(token)) {
                    token = genericTokenizer.nextToken(syntax, index);
                }
                // This will ignore any whitespaces the tokenizers also ignored primarily for LiteralTokenizer
                index = token.getStartingIndex() + token.length();
                tokens.add(token);
            } else {
                index++;
            }
        }

        return tokens;
    }

    /**
     * The LiteralTokenizer separates tokens based on the literal terminal. Everything inside of literal terminal will be considered single VeevaSyntaxToken (a literal terminal)
     */
    class LiteralTokenizer {

        private final VeevaSyntaxToken literalTerminal;
        private final VeevaSyntaxToken escapedTerminal;

        public LiteralTokenizer(VeevaSyntaxToken literalTerminal, VeevaSyntaxToken escapedTerminal) {
            this.literalTerminal = literalTerminal;
            this.escapedTerminal = escapedTerminal;
        }

        public VeevaSyntaxToken getTerminal() {
            return literalTerminal;
        }

        public VeevaSyntaxToken nextToken(String syntax, Integer startingIndex) {
            // we just encountered a literal starting terminal we will consider everything
            // between two literals terminals as part of the same token
            VeevaSyntaxToken token;
            if (literalTerminal.getTokenText().equalsIgnoreCase(
                    syntax.substring(startingIndex, startingIndex + literalTerminal.length()))) {
                boolean isValid = true;
                Integer nextLiteralTerminal = nextLiteralTerminal(syntax, startingIndex + literalTerminal.length());
                Integer endingIndex;
                if (nextLiteralTerminal == -1) {
                    // could not find next closing literal terminal so we will mark this as invalid
                    // and use the end of the syntax as the end of the literal
                    isValid = false;
                    endingIndex = syntax.length();
                } else {
                    endingIndex = nextLiteralTerminal + literalTerminal.length();
                }
                
                String literal =  syntax.substring(startingIndex, endingIndex);
                token = new VeevaSyntaxToken(startingIndex, literal, isValid);
            } else {
                token = VeevaSyntaxToken.NULL_TOKEN;
            }
            return token;
        }

        private Integer nextLiteralTerminal(String syntax, Integer startingIndex) {
            Integer escapedTerminalIndex = startingIndex;
            Integer nextEscapedTerminalIndex = syntax.indexOf(escapedTerminal.getTokenText(), escapedTerminalIndex);
            while (nextEscapedTerminalIndex >= 0) {
                escapedTerminalIndex = nextEscapedTerminalIndex + escapedTerminal.length();
                nextEscapedTerminalIndex = syntax.indexOf(escapedTerminal.getTokenText(), escapedTerminalIndex);
            }
            return syntax.indexOf(literalTerminal.getTokenText(), escapedTerminalIndex);
        }
    }

    /**
     * The GenericTokenizer separates tokens based on spaces and checks for TERMINALs to stop on.
     */
    class GenericTokenizer {

        public VeevaSyntaxToken nextToken(String syntax, Integer startingIndex) {
            startingIndex = nextNonWhitespace(syntax, startingIndex); // skip all starting whitespaces
            Integer nextWhitespaceOrTerminal = nextWhitespaceOrTerminalEndIndex(syntax, startingIndex);
            return new VeevaSyntaxToken(startingIndex, syntax.substring(startingIndex, nextWhitespaceOrTerminal));
        }

        private Integer nextWhitespaceOrTerminalEndIndex(String syntax, Integer startingIndex) {
            Integer nextWhitespaceOrTerminalEnd = syntax.indexOf(' ', startingIndex);
            if (nextWhitespaceOrTerminalEnd < 0) {
                nextWhitespaceOrTerminalEnd = syntax.length();
            }

            for (VeevaSyntaxToken terminal : VeevaSyntaxToken.TERMINALS) {
                Integer terminalIndex = syntax.indexOf(terminal.getTokenText(), startingIndex);
                if (terminalIndex >= 0 && terminalIndex < nextWhitespaceOrTerminalEnd) {
                    nextWhitespaceOrTerminalEnd = terminalIndex;
                }
            }

            if (startingIndex == nextWhitespaceOrTerminalEnd) {
                // this means the current index is a terminal so let's determine which terminal
                Integer lengthOfTerminal = 0;
                for (VeevaSyntaxToken terminal : VeevaSyntaxToken.TERMINALS) {
                    Integer terminalTextLength = terminal.length();
                    if (startingIndex + terminalTextLength <= syntax.length()) {
                        String text = syntax.substring(startingIndex, startingIndex + terminalTextLength);
                        if (terminal.getTokenText().equalsIgnoreCase(text)) {
                            lengthOfTerminal = terminalTextLength;
                        }
                    }
                }
                nextWhitespaceOrTerminalEnd += lengthOfTerminal;
            }

            return nextWhitespaceOrTerminalEnd;
        }

        private Integer nextNonWhitespace(String syntax, Integer index) {
            while (index < syntax.length() && ' '.equals(syntax.substring(index, index + 1))) {
                index++;
            }
            return index;
        }
    }
}