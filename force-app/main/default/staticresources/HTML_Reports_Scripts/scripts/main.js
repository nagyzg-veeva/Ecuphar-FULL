'use strict';

(function (q) {
  'use strict';

  if (!window.veevaBridge) {
    var constructSOQL = function constructSOQL(object, fields, where, sort, limit) {
      var soql = ['SELECT', fields.join(), 'FROM', object];
      if (where) {
        soql.push('WHERE', where);
      }
      if (sort && sort.length) {
        soql.push('ORDER BY', sort);
      }
      if (limit) {
        soql.push('LIMIT', limit);
      }
      return soql.join(' '); //.replace(/ /g, '+');
    },
        idWhere = function idWhere(id) {
      return 'ID = \'' + id + '\'';
    },
        transformReturn = function transformReturn(resp, objectName) {
      var results = {
        success: true,
        record_count: resp.totalSize
      },
          records = resp.records,
          d = records.length,
          thisID,
          record;
      // stupid hack to normalize the ID/Id member name since it is different on the iPad vs in the Rest API
      while (d--) {
        record = records[d];
        if (record.Id) {
          record.ID = record.Id;
        }
      }
      results[objectName] = resp.records;
      return results;
    },
        cache = {
      objectLabels: {},
      objectQueries: {},
      objectDescriptions: {},
      translations: {},
      currentObject: {},
      veevaMessages: {}
    },
        b64EncodeUnicode = function b64EncodeUnicode(str) {
      return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, function (match, p1) {
        return String.fromCharCode(parseInt(p1, 16));
      }));
    },
        getQueryCacheSignature = function getQueryCacheSignature(queryConfig) {
      var strings = [queryConfig.object, queryConfig.fields, queryConfig.where || '', queryConfig.sort || '', queryConfig.limit || ''],
          string = strings.join('');
      return b64EncodeUnicode(string);
    },
        errorResponse = function errorResponse(errCode, errMessage, field) {
      var customErrorObject = {};
      customErrorObject.success = false;
      customErrorObject.code = errCode;
      customErrorObject.message = errMessage;
      customErrorObject.fields = field;
      return customErrorObject;
    };
    /**
     * Represents a wrapper for communicating with the Salesforce REST API via the ForceTK library.
     * @constructor
     * @param {object} forceClient - Instance of the ForceTK library.
     */
    window.veevaBridge = function (forceClient) {
      /**
       *  Run a query
       *  @private
       *  @param {object} queryConfig - \{object: String, fields: Array, where: String, sort: String, limit: String\}
       *  @param {string} queryConfig.object - Name of the object to query
       *  @param {array} queryConfig.fields - An array of field names to return
       *  @param {string} queryConfig.where - the where statement without the "where" string. ex: where: "Name = 'Bob\'s Port-o-potties"
       *  @param {string} queryConfig.sort - the sort statment without the "order by" string. ex: sort: "LastModifiedDate DESC"
       *  @param {integer} queryConfig.limit - the number of records to return.
       *  @return {promise} - The promise returned when resolved will return the results of the query.
       **/
      function queryObject(queryConfig) {
        var deferred = q.defer(),
            soql = constructSOQL(queryConfig.object, queryConfig.fields, queryConfig.where, queryConfig.sort, queryConfig.limit);
        deferred.promise.then(function (resp) {
          cache.objectQueries[getQueryCacheSignature(queryConfig)] = resp;
        });
        forceClient.query(soql, deferred.resolve, deferred.reject);
        return deferred.promise;
      }

      this.queryObject = queryObject;
      /**
       *  Run a query
       *  @param {object} queryConfig - \{object: String, fields: Array, where: String, sort: String, limit: String\}
       *  @param {string} queryConfig.object - Name of the object to query
       *  @param {array} queryConfig.fields - An array of field names to return
       *  @param {string} queryConfig.where - the where statement without the "where" string. ex: where: "Name = 'Bob\'s Port-o-potties"
       *  @param {string} queryConfig.sort - the sort statment without the "order by" string. ex: sort: "LastModifiedDate DESC"
       *  @param {integer} queryConfig.limit - the number of records to return.
       *  @return {promise} - The promise returned when resolved will return the results of the query.
       **/
      this.runQuery = function (queryConfig) {
        var deferred = q.defer(),
            queryCache = cache.objectQueries[getQueryCacheSignature(queryConfig)];
        if (queryCache) {
          deferred.resolve(transformReturn(queryCache, queryConfig.object));
        } else {
          this.queryObject(queryConfig).then(function (results) {
            deferred.resolve(transformReturn(results, queryConfig.object));
          }, function (e) {
            deferred.reject(e);
          });
        }
        return deferred.promise;
      };
      /**
       *  Run a query to get the labels of object(s)
       *  @param {array} objects - An array of object names for which to get labels.
       *  @return {promise} - The promise returned when resolved will return the results of the query.
       **/
      this.getObjectLabels = function (objects) {
        var deferred = q.defer(),
            deferredPool = [],
            promisePool = [],
            o = 0,
            deferredPoolLength = 0,
            deferredIndex;
        if (!(objects instanceof Array)) {
          objects = [objects];
        }
        for (o = objects.length; o--;) {
          deferredIndex = deferredPool.push(q.defer()) - 1;
          promisePool.push(deferredPool[deferredIndex].promise);
          if (cache.objectLabels[objects[o]]) {
            deferredPool[deferredIndex].resolve(cache.objectLabels[objects[o]]);
          } else {
            forceClient.metadata(objects[o], deferredPool[deferredIndex].resolve, deferredPool[deferredIndex].reject);
          }
        }
        q.all(promisePool).then(function (responses) {
          // coallesce all the object labels into a single return value
          var r = responses.length,
              response,
              labels = { success: true };
          // {success: true, Medical_Event_vod__c: [{plural: "Medical Events", singular: "Medical Event"}]}
          while (r--) {
            // cache.objectLabels[responses[r].objectDescribe.name] = responses[r]
            response = (cache.objectLabels[responses[r].objectDescribe.name] = responses[r]).objectDescribe;
            labels[response.name] = [{ singular: response.label, plural: response.labelPlural }];
            // put the labels into a labels object or array
          }
          deferred.resolve(labels);
        }, function (error) {
          deferred.reject(error);
        });
        return deferred.promise;
      };
      /**
       *  Run a query to get the a certain field value for the object that is the current top-level subject.
       *  @param {string} object - Name of the object.
       *  @param {string} field - Name of the field
       *  @param {string} id - ID of the object
       *  @return {promise} - The promise returned when resolved will return the results of the query.
       **/
      this.getDataForCurrentObject = function (object, field, id) {
        var deferred = q.defer();
        var queryConfig = { object: object, fields: [field], where: idWhere(id) };
        this.queryObject(queryConfig).then(function (results) {
          if (results.records && results.records.length > 0) {
            // send as message to frame
            var resp = transformReturn(results, object);
            var record = results.records[0];
            delete record.attributes;
            resp[object] = {};
            //Use first key that is the field API name for correct access to field data value
            resp[object][field] = record[Object.keys(record)[0]];
            deferred.resolve(resp);
          } else {
            deferred.reject({
              success: false,
              code: 0,
              message: 'getDataForCurrentObject request failed: ' + JSON.stringify(queryConfig),
              object: object
            });
          }
        }, function (e) {
          deferred.reject(e);
        });
        return deferred.promise;
      };
      /**
       *  Run a query to get the labels of fields
       *  @param {object} queryConfig - \{object: String, fields: Array\}
       *  @param {string} queryConfig.object - Name of the object for which to get the field labels
       *  @param {array} queryConfig.fields - An array of field names for which to get the field labels
       *  @return {promise} - The promise returned when resolved will return the results of the query.
       **/
      this.getFieldLabels = function (queryConfig) {
        var deferred = q.defer(),
            deferredInner = q.defer(),
            queryCache = cache.objectDescriptions[queryConfig.object],
            getLabelsFromResp = function getLabelsFromResp(describe) {
          var resp = { success: true },
              fields = describe.fields,
              f = fields.length,
              newFields = {};
          resp[queryConfig.object] = newFields;
          while (f--) {
            newFields[fields[f].name] = fields[f].label;
          }
          return resp;
        };
        if (queryCache) {
          deferredInner.promise.then(function (cached) {
            deferred.resolve(cached);
          });
          deferredInner.resolve(getLabelsFromResp(queryCache));
        } else {
          deferredInner.promise.then(function (describe) {
            cache.objectDescriptions[queryConfig.object] = describe;
            deferred.resolve(getLabelsFromResp(describe));
          }, function (error) {
            deferred.reject(error);
          });
          forceClient.describe(queryConfig.object, deferredInner.resolve, deferredInner.reject);
        }
        return deferred.promise;
      };
      /**
       *  Run a query to get the value labels of the items in a picklist
       *  @param {object} queryConfig - \{object: String, field: String\}
       *  @param {string} queryConfig.object - Name of the object for which to get the picklist value labels
       *  @param {string} queryConfig.field - The picklist field name
       *  @return {promise} - The promise returned when resolved will return the results of the query which will be an array of the value labels.
       **/
      this.getPicklistValueLabels = function (queryConfig) {
        var deferred = q.defer(),
            deferredInner = q.defer(),
            queryCache = cache.objectDescriptions[queryConfig.object],
            getPicklistValueLabelsFromResp = function getPicklistValueLabelsFromResp(describe) {
          var resp = { success: true },
              fields = describe.fields,
              f = fields.length,
              picklistValueLabels = {};
          resp[queryConfig.object] = picklistValueLabels;
          while (f--) {
            if (fields[f].name === queryConfig.field) {
              // at this point we found the field that is the picklist we are looking for. the picklist values are an array and we need to convert them to an object.
              for (var picklist = fields[f].picklistValues, p = picklist.length; p--;) {
                picklistValueLabels[picklist[p].value] = picklist[p].label;
              }
            }
          }
          if (Object.keys(picklistValueLabels).length === 0) {
            deferred.reject(errorResponse(21, 'getPicklistValueLabels called with field that cannot be accessed: ' + queryConfig.field, queryConfig.field));
          }
          return picklistValueLabels;
        };
        if (queryCache) {
          deferredInner.promise.then(function (cached) {
            deferred.resolve(getPicklistValueLabelsFromResp(cached));
          }, function (error) {
            if (error.status === 404) {
              //NOT_FOUND
              deferred.reject(errorResponse(11, 'getPicklistValueLabels called with an object that cannot be accessed: ' + queryConfig.object, queryConfig.object));
            } else {
              deferred.reject(errorResponse(error.status, 'getPicklistValueLabels request failed with error response: ' + error.responseJSON[0].message, queryConfig));
            }
          });
          deferredInner.resolve(queryCache);
        } else {
          deferredInner.promise.then(function (describe) {
            cache.objectDescriptions[queryConfig.object] = describe;
            deferred.resolve(getPicklistValueLabelsFromResp(describe));
          }, function (error) {
            if (error.status === 404) {
              //NOT_FOUND
              deferred.reject(errorResponse(11, 'getPicklistValueLabels called with an object that cannot be accessed: ' + queryConfig.object, queryConfig.object));
            } else {
              deferred.reject(errorResponse(error.status, 'getPicklistValueLabels request failed with error response: ' + error.responseJSON[0].message, queryConfig));
            }
          });
          forceClient.describe(queryConfig.object, deferredInner.resolve, deferredInner.reject);
        }
        return deferred.promise;
      };

      /**
       *  Run a query to get the text value of the requested veeva message
       *  @param {string} languageLocaleKey - the language value from the user's profile
       *  @param {array} msgsToGet - array of string names of the messages desired.
       *  @return {promise} - The promise returned when resolved will return the results of the messages query which will be an array of the value labels.
       **/
      this.getVeevaMessagesWithDefault = function (languageLocaleKey, msgsToGet) {

        var deferred = q.defer(),
            queryConfig = {
          object: 'Message_vod__c',
          fields: ['Name', 'Category_vod__c', 'Language_vod__c', 'Text_vod__c']
        },
            whereSubClauses = [],
            index = msgsToGet.length;
        while (index--) {
          whereSubClauses.push('(Name=\'' + msgsToGet[index].msgName + '\' AND Category_vod__c=\'' + msgsToGet[index].msgCategory + '\')');
        }
        queryConfig.where = '(' + whereSubClauses.join(' OR ') + ')' + ' AND Language_vod__c=\'' + languageLocaleKey + '\'';
        return this.runQuery(queryConfig);
      };

      function findUnavailableFields(availableFields, targetFields) {
        var notAvailableFields = [];

        targetFields.forEach(function (target) {
          var found = availableFields.filter(function (available) {
            return available.name === target;
          });

          if (found.length === 0) {
            notAvailableFields.push(target);
          }
        });

        return notAvailableFields;
      }

      function extractInfo(sfFields, configFields) {
        var MULTIPICKLIST = 'multipicklist';
        var specialField = 'MyInsights_Modified_By_vod__c'.toLowerCase();
        var hasSpecialField = false;
        var fieldName = null;

        sfFields.forEach(function (field) {
          var f = field.name.toLowerCase();

          if (f === specialField && field.updateable && field.type === 'reference') {
            hasSpecialField = true;
          }

          configFields.forEach(function (key) {
            if (f === key.toLowerCase() && field.type === MULTIPICKLIST) {
              fieldName = key;
            }
          });
        });

        return {
          hasSpecialField: hasSpecialField,
          fieldName: fieldName
        };
      }

      function prepareFields(sfFields, configFields, userId) {
        var specialField = 'MyInsights_Modified_By_vod__c';
        var targetFields = Object.keys(configFields);
        var info = extractInfo(sfFields, targetFields);

        if (info.fieldName && Array.isArray(configFields[info.fieldName])) {
          configFields[info.fieldName] = configFields[info.fieldName].join(';');
        }

        if (info.hasSpecialField) {
          configFields[specialField] = userId;
        }
      }

      /**
       *  Create a MyInsights_Data_vod__c record
       *  @param {object} config - the object that contains all data needed to create a record
       *  @param {string} userId - the Id of the current user
       *  @param {string} reportId - the Id of the current HTML report
       *  @return {promise} - The promise returned when resolved will return the results of creating a record which is object containing the created record id.
       **/
      this.createMyInsightsRecord = function (config, userId, reportId) {
        var deferred = q.defer();
        var targetFields = Object.keys(config.fields);

        if (hasInvalidFieldsForObject(config.object, targetFields, 'create')) {
          deferred.reject({
            code: 15,
            success: false,
            message: 'createRecord called with field types that are not supported: ' + targetFields
          });
        } else {
          forceClient.describe(config.object, function (res) {
            var unavailableFields = findUnavailableFields(res.fields, targetFields);

            if (unavailableFields.length > 0) {
              deferred.reject({
                code: 21,
                success: false,
                message: 'createMyInsightsRecord called with fields that cannot be accessed: ' + unavailableFields,
                fields: unavailableFields
              });
            } else {
              prepareFields(res.fields, config.fields, userId);

              forceClient.create(config.object, config.fields, function (resp) {
                deferred.resolve({
                  id: resp.id,
                  success: true
                });
              }, function (err) {
                deferred.reject({
                  success: false,
                  code: 0,
                  message: 'createMyInsightsRecord request failed: ' + JSON.stringify(config),
                  error: err
                });
              });
            }
          }, function (err) {
            deferred.reject({
              code: 11,
              success: false,
              message: 'createMyInsightsRecord called with an object that cannot be accessed: ' + config.object,
              object: config.object
            });
          });
        }

        return deferred.promise;
      };

      this.executeRequest = function (requestObject, messageId) {
        var deferred = q.defer(),
            url = requestObject.url,
            method = requestObject.method,
            body = requestObject.body,
            headers = requestObject.headers,
            expect = requestObject.expect,
            timeout = requestObject.timeout,
            headerKeys = Object.keys(headers),
            req = new window.XMLHttpRequest();

        req.open(method, url);
        if (expect === 'blob') {
          //set response type to array buffer is binary data is expected
          req.responseType = 'arraybuffer';
        }
        headerKeys.forEach(function (key) {
          req.setRequestHeader(key, headers[key]);
        });
        req.timeout = timeout * 1000;

        //handle 'successful' load
        req.onload = function () {
          if (req.status < 400) {
            deferred.resolve(transformHttpResponse(req, expect, messageId, true));
          } else {
            deferred.reject(transformHttpResponse(req, expect, messageId, false));
          }
        };
        //handle 'failed' load
        req.onerror = function () {
          deferred.reject(transformHttpResponse(req, expect, messageId, false));
        };
        //handle timeout
        req.ontimeout = function () {
          var error = {
            success: false,
            messageId: messageId,
            code: 4,
            message: 'Timeout value exceeded'
          };
          deferred.reject(error);
        };

        req.send(body);

        return deferred.promise;
      };

      function transformHttpResponse(request, expect, messageId, isSuccess) {
        var newResponse = {};
        newResponse.command = 'queryReturn';
        newResponse.success = isSuccess;
        newResponse.messageId = messageId;
        if (!isSuccess) {
          newResponse.code = request.status;
        }
        newResponse.data = {};
        newResponse.data.statusCode = request.status;
        newResponse.data.headers = getHeadersFromCRLFSeparatedString(request.getAllResponseHeaders());
        if (expect === 'blob') {
          //if blob, read response as arraybuffer and encode to base64
          var codes = new Uint8Array(request.response);
          var bin = "";
          for (var i = 0; i < codes.length; i++) {
            bin += String.fromCharCode(codes[i]);
          }
          newResponse.data.body = btoa(bin);
        } else {
          //default is text, so no need to check if equals "text"
          newResponse.data.body = request.responseText;
        }
        return newResponse;
      }

      function getHeadersFromCRLFSeparatedString(headerString) {
        var headerObject = {};
        var headerKeyValuePairs = headerString.split('\r\n');
        headerKeyValuePairs.forEach(function (keyValuePair) {
          var keyValue = keyValuePair.split(':');
          headerObject[keyValue[0]] = keyValue[1];
        });
        return headerObject;
      }

      /**
       *  Update the value of a MyInsights_Data_vod__c record
       *  @param {object} config - the object that contains all data needed to update a record
       *  @param {string} userId - the Id of the current user
       *  @param {string} reportId - the Id of the current HTML report
       *  @return {promise} - The promise returned when resolved will return the results of updating a record which is object containing the updated record id.
       **/
      this.updateMyInsightsRecord = function (config, userId, reportId) {
        var deferred = q.defer();
        var targetFields = Object.keys(config.fields);

        function rejectWithError(code, errorMessage, errorObject, fields) {
          var errorResponse = { code: code, success: false, message: errorMessage };

          if (errorObject) {
            errorResponse.object = errorObject;
          }

          if (fields) {
            errorResponse.fields = fields;
          }

          deferred.reject(errorResponse);
        }

        function resolveSuccessful() {
          deferred.resolve({ success: true });
        }

        if (hasInvalidFieldsForObject(config.object, targetFields, 'update')) {
          var fieldsNotSupportedMsg = 'updateRecord called with field types that are not supported: ' + targetFields;

          rejectWithError(15, fieldsNotSupportedMsg);
        } else {
          forceClient.describe(config.object, function (res) {
            var unavailableFields = findUnavailableFields(res.fields, targetFields);

            if (unavailableFields.length > 0) {
              var fieldsNotAccessibleMsg = 'updateMyInsightsRecord called with fields that cannot be accessed: ' + unavailableFields;

              rejectWithError(21, fieldsNotAccessibleMsg, null, unavailableFields);
            } else {
              prepareFields(res.fields, config.fields, userId);

              forceClient.update(config.object, config.id, config.fields, resolveSuccessful, function (err) {
                // Retry with mobile id
                var configuration = {
                  object: config.object,
                  fields: ['Id', 'Mobile_ID_vod__c'],
                  where: 'Mobile_ID_vod__c = \'' + config.id + '\''
                };

                var genericUpdateFailedMsg = 'updateMyInsightsRecord request failed: ' + JSON.stringify(config);

                queryObject(configuration).then(function (resp) {
                  if (resp.totalSize > 0) {
                    forceClient.update(config.object, resp.records[0].Id || resp.records[0].ID, config.fields, resolveSuccessful, function (e) {
                      rejectWithError(0, genericUpdateFailedMsg, e, null);
                    });
                  } else {
                    rejectWithError(0, genericUpdateFailedMsg, err, null);
                  }
                }, function (error) {
                  rejectWithError(0, genericUpdateFailedMsg, error, null);
                });
              });
            }
          }, function () {
            var objectNotAccessibleMsg = 'updateMyInsightsRecord called with an object that cannot be accessed: ' + config.object;

            rejectWithError(11, objectNotAccessibleMsg, config.object, null);
          });
        }

        return deferred.promise;
      };

      function hasIntersection(arr1, arr2) {
        var exists = false;
        var i, j;

        for (i = 0; i < arr1.length; i++) {
          for (j = 0; j < arr2.length; j++) {
            if (arr2[j].toLowerCase() === arr1[i].toLowerCase()) {
              exists = true;
              break;
            }
          }
        }

        return exists;
      }

      function hasInvalidFieldsForObject(objectName, fieldNames, action) {
        var disallowed = {
          MyInsights_Data_vod__c: ['HTML_Report_vod__c']
        };
        var blackList = ['Id', 'IsDeleted', 'CreatedById', 'CreatedDate', 'LastModifiedById', 'LastModifiedDate', 'SystemModstamp', 'MayEdit', 'Last_Device_vod__c', 'Mobile_Last_Modified_Datetime_vod__c', 'Mobile_Created_Datetime_vod__c', 'OwnerId', 'MyInsights_Modified_By_vod__c', 'Unlock_vod__c', 'IsLocked'];
        var disallowedFields = disallowed[objectName];
        var mergedList;

        if (objectName === 'MyInsights_Data_vod__c' && action === 'create' || !disallowedFields) {
          mergedList = blackList;
        } else {
          mergedList = disallowedFields.concat(blackList);
        }

        return hasIntersection(mergedList, fieldNames);
      }
    };
  }
})(Q);
//# sourceMappingURL=onOfflineBridge.js.map

'use strict';

/**
 *    Bridge Initialization Script
 *    @constructor
 *    @param {object} Bridge - the Bridge class defined in onOfflineBridge.js
 **/
(function (Bridge) {
    'use strict';

    var sfClient = new forcetk.Client(),
        prop,
        bridge,
        keywordToObjectMap = {
        'Account': 'Account',
        'AccountPlan': 'Account_Plan_vod__c',
        'HTMLReport': 'HTML_Report_vod__c',
        'Order': 'Order_vod__c',
        'TSF': 'TSF_vod__c',
        'User': 'User'
    },
        methodWhiteList = ['ajax', 'query', 'create', 'update', 'describe', 'metadata', 'setSessionToken'],
        returnMessage = function returnMessage(message, deferredId, source, command) {
        message.deferredId = deferredId;
        message.command = command || 'queryReturn';
        source.postMessage(JSON.stringify(message), '*');
    },
        returnError = function returnError(error, deferredId, source) {
        console.log('return error', error);
        returnMessage(error, deferredId, source, 'error');
    },
        idWhere = function idWhere(id) {
        return 'ID = \'' + id + '\'';
    },
        listen = function listen(message) {
        var data;
        if (typeof message.data === 'string') {
            try {
                data = JSON.parse(message.data);
            } catch (e) {
                data = {};
            }
        } else data = message.data;

        var queryConfig = data,
            // {command:'', object:'', where:''...}
        command = queryConfig.command,
            source = message.source,
            deferredId = queryConfig.deferredId,
            messageId = queryConfig.messageId,
            success = function success(results) {
            returnMessage(results, deferredId, source);
        },
            failure = function failure(error) {
            returnError(error, deferredId, source);
        },
            customActionFailure = function customActionFailure(error) {
            error.messageId = messageId;
            error.command = 'error';
            source.postMessage(JSON.stringify(error), '*');
        };
        switch (command) {
            case 'queryObject':
                {
                    bridge.runQuery(queryConfig).then(success, failure);
                    break;
                }
            case 'getFieldLabel':
                {
                    bridge.getFieldLabels(queryConfig).then(function (labels) {
                        returnMessage(labels, deferredId, source);
                    }, failure);
                    break;
                }
            case 'getObjectLabels':
                {
                    bridge.getObjectLabels(queryConfig.object).then(function (labels) {
                        returnMessage(labels, deferredId, source);
                    }, failure);
                    break;
                }
            case 'getDataForObjectV2':
                {
                    var objectName;

                    if (keywordToObjectMap.hasOwnProperty(queryConfig.object)) {
                        objectName = keywordToObjectMap[queryConfig.object];
                    } else {
                        objectName = queryConfig.object;
                    }

                    var id = getObjectIdByObjectName(objectName);

                    bridge.getDataForCurrentObject(objectName, queryConfig.fields[0], id).then(function (results) {
                        results[queryConfig.object] = results[objectName];
                        returnMessage(results, deferredId, source);
                    }, failure);
                    break;
                }
            case 'getPicklistValueLabels':
                {
                    bridge.getPicklistValueLabels(queryConfig).then(function (results) {
                        var retMsg = {};
                        retMsg[queryConfig.object] = {};
                        retMsg[queryConfig.object][queryConfig.field] = results;
                        returnMessage(retMsg, deferredId, source);
                    }, failure);
                    break;
                }
            case 'createRecord':
                {
                    if (queryConfig.object === 'MyInsights_Data_vod__c') {
                        queryConfig.fields.HTML_Report_vod__c = getObjectIdByObjectName('HTML_Report_vod__c');
                    }

                    bridge.createMyInsightsRecord(queryConfig, HTMLConfig.userID, HTMLConfig.reportID).then(function (result) {
                        var response = {
                            success: result.success,
                            command: 'queryReturn',
                            messageId: messageId,
                            data: {
                                id: result.id
                            }
                        };
                        source.postMessage(JSON.stringify(response), '*');
                        if (result.success) {
                            logActivity(queryConfig.object, 'Create', result.id, HTMLConfig.reportID);
                        }
                    }, customActionFailure);
                    break;
                }
            case 'updateRecord':
                {
                    bridge.updateMyInsightsRecord(queryConfig, HTMLConfig.userID, HTMLConfig.reportID).then(function (result) {
                        var response = {
                            command: 'queryReturn',
                            success: result.success,
                            messageId: messageId
                        };
                        source.postMessage(JSON.stringify(response), '*');
                        if (result.success) {
                            logActivity(queryConfig.object, 'Update', queryConfig.id, HTMLConfig.reportID);
                        }
                    }, customActionFailure);
                    break;
                }
            case 'getSFDCSessionID':
                {
                    var sessionId = HTMLConfig.sessionID;
                    if (sessionId) {
                        logSessionIdActivity(HTMLConfig.reportID, HTMLConfig.reportName, 'Success', '');
                        var resp = {
                            success: true,
                            messageId: messageId,
                            data: {
                                sessionId: sessionId,
                                instanceUrl: removeTrailingSlash(HTMLConfig.instanceUrl),
                                isSandbox: HTMLConfig.isSandbox === 'true'
                            }
                        };
                        returnMessage(resp, deferredId, source);
                    } else {
                        //spec defines error 72 to mean SFDC Session cannot be obtained
                        var errorMessage = 'Unable to obtain valid Session ID';
                        logSessionIdActivity(HTMLConfig.reportID, HTMLConfig.reportName, 'Error', errorMessage);
                        var error = {
                            success: false,
                            messageId: messageId,
                            code: 72,
                            message: errorMessage
                        };
                        failure(error);
                    }
                    break;
                }
            case 'request':
                {
                    bridge.executeRequest(queryConfig, messageId).then(success, failure);
                }
        }
    },
        removeTrailingSlash = function removeTrailingSlash(url) {
        if (!url) {
            return "";
        }

        var lastIndex = url.length - 1;
        return url[lastIndex] === '/' ? url.substr(0, lastIndex) : url;
    },
        getObjectIdByObjectName = function getObjectIdByObjectName(objectName) {
        var currentObjectName = HTMLConfig.currentObject;
        var id;

        if (objectName.toLowerCase() === currentObjectName.toLowerCase()) {
            id = HTMLConfig.currentObjectID;
        } else if (objectName.toLowerCase() === 'User'.toLowerCase()) {
            id = HTMLConfig.userID;
        } else if (objectName.toLowerCase() === 'Account'.toLowerCase()) {
            id = HTMLConfig.accountID;
        } else if (objectName.toLowerCase() === 'HTML_Report_vod__c'.toLowerCase()) {
            id = HTMLConfig.reportID;
        } else if (objectName.toLowerCase() === 'TSF_vod__c'.toLowerCase()) {
            id = HTMLConfig.tsfID;
        }

        return id;
    },
        initializeSFClient = function initializeSFClient(config) {
        sfClient.setSessionToken(config.sessionID, 'v49.0');
        bridge = new Bridge(sfClient);
    },
        getSession = function getSession() {
        var userInfo = window.userInfo;
        var sessionData = window.com && window.com.vod309 && window.com.vod309.crm && window.com.vod309.crm.sessionData ? window.com.vod309.crm.sessionData : null;
        return userInfo || sessionData;
    },
        logActivity = function logActivity(objName, actionType, recordId, reportId) {
        var entry = {
            process: 'MyInsights',
            MIObjectName: objName,
            description: 'Data Modified',
            param1: actionType,
            param2: recordId,
            param3: reportId
        };
        sendLogActivity(entry);
    },
        logSessionIdActivity = function logSessionIdActivity(reportId, reportName, status, errorMessage) {
        var entry = {
            process: 'MyInsights',
            MIObjectName: '',
            description: 'SFDC Session ID Requested',
            param1: reportId,
            param2: reportName,
            param3: status,
            param4: errorMessage
        };
        sendLogActivity(entry);
    },
        sendLogActivity = function sendLogActivity(entry) {
        var sessionData = getSession();
        var url = sessionData.vodUrl + '/api/v1/custom-reports/activities';
        var xhr = window.ActiveXObject ? new window.ActiveXObject('MSXML2.XMLHTTP.3.0') : new window.XMLHttpRequest();

        xhr.open('POST', url, false);
        xhr.setRequestHeader('Accept', 'application/json');
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.setRequestHeader('Authorization', sessionData.auth);
        xhr.setRequestHeader('sfSession', sessionData.sfSession);
        xhr.setRequestHeader('sfEndpoint', sessionData.sfEndpoint);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.log('MyInsights activity log created');
                } else {
                    console.error('Failed to create myInsights activity log');
                }
            }
        };
        xhr.send(JSON.stringify(entry));
    },
        checkReady = function checkReady() {
        if (window.HTMLConfig) {
            initializeSFClient(window.HTMLConfig);
        } else {
            setTimeout(checkReady, 50);
        }
    };

    var protoTypeList = Object.getPrototypeOf(sfClient);

    for (prop in protoTypeList) {
        if (protoTypeList.hasOwnProperty(prop)) {
            if (methodWhiteList.indexOf(prop) < 0) {
                protoTypeList[prop] = function () {};
            }
        }
    }

    if (window.addEventListener) {
        window.addEventListener('message', listen, false);
    } else {
        window.attachEvent('onmessage', listen);
    }
    checkReady();
})(window.veevaBridge);
//# sourceMappingURL=main.js.map
