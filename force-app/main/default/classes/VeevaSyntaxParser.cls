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
 * This interface was created to define a common interface for all VeevaSyntaxParsers.
 */
public interface VeevaSyntaxParser {
    /**
     * Given a set of tokens and a starting index a instance or child class of VeevaSyntaxToken will be returned.
     *
     * The specfic implementation of the VeevaSyntaxParser will dictate which instance of VeevaSyntaxToken will be returned
     * and the logic for constructing the instance.
     */
    VeevaSyntaxToken parse(List<VeevaSyntaxToken> tokens, Integer index);
}