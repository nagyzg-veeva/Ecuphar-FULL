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
 * This interface defines a common inteface to be used when retrieving error messages when parsing syntax.
 */
public interface VeevaSyntaxErrorMessageManager {
    // Note any of these method arguments can become a List<Object> to accommodate for any implementing class
    String getSyntaxError();
    String getInvalidFieldSyntaxError(String fieldName);
    String getFieldNotSupportedError(String fieldName);
    String getValueNotSupportedError(VeevaSyntaxToken token, String fieldName);
    String getOperatorNotSupportedError(VeevaSyntaxToken token, String fieldName);
    String getEmptyError();
}