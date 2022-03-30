const SUPPORTED_STANDARD_ACTIONS = ['Edit', 'Delete'];
const BUTTONS_ON_EDIT = ['Submit_vod', 'Save_vod'];
const soqlFieldPattern = /^(toLabel\()?(([^().]+)(\.Name)?)\)?$/;
// utility class for a page layout, i.e. find fields in a section
const initializeSectionSignals = (section) => {
    section.rawHeading = section.heading;
    let splits = section.heading.split("--");
    section.signals = [];
    splits.forEach((value, headingIndex) => {
        let trim = value.trim();
        if (!headingIndex) {
            section.heading = trim;
        }
        else {
            section.signals.push(trim);
        }
    })
}

const toButtonsHelper = (clickables, nameAttr, isCustom) => {
    let result = [];
    if (clickables) {
        clickables.forEach(clickable => {
            const btnName = clickable[nameAttr];
            if (SUPPORTED_STANDARD_ACTIONS.includes(btnName)) {
                result.push({ name: btnName, label: clickable.label, standard: true });
            }
            else if (isCustom(clickable)) {
                result.push({ name: btnName, label: clickable.label, edit: BUTTONS_ON_EDIT.includes(btnName) });
            }
        });
    }
    return result;
}

export default class VeevaLayoutService {
    static getLayoutQueryParams = (pageCtrl) => {
        return {
            recordTypeId: pageCtrl.record.recordTypeId,
            objectApiName: pageCtrl.objectInfo.objectApiName,
            actionName: pageCtrl.page.action,
            relatedList: pageCtrl.page.showRelatedList && pageCtrl.page.action === "View"
        };
    };

    // Process layout metadata.
    // 1. add 'key' which is required by template iterator
    // 2. initialize section signals
    static toVeevaLayout = (layout, mode) => {
        if (layout && layout.sections) {
            layout.sections.forEach((section, index) => {
                section.key = index.toString();
                initializeSectionSignals(section);
                if (section.layoutRows) {
                    section.layoutRows.forEach((row, rowIndex) => {
                        row.key = rowIndex.toString();
                        if (row.layoutItems) {
                            row.layoutItems.forEach((item, itemIndex) => {
                                item.key = itemIndex.toString();
                                item.editable = (mode === 'New' && item.editableForNew) || (mode === 'Edit' && item.editableForUpdate);
                                if (mode === 'View') {
                                    item.required = false;
                                }
                                let component = item.layoutComponents.find(x => x.componentType === 'Field');
                                if (component) {
                                    item.field = component.apiName;
                                }
                            })
                        }
                    })
                }
            });
        }

        return layout;
    }

    static getSectionItems = (section) => {
        let result = [];
        section.layoutRows.forEach(function (row) {
            row.layoutItems.forEach(function (item) {
                if (item.field) {
                    result.push(item);
                }
            })
        });
        return result;
    }

    // Convert Salesforce Action to buttons
    static toButtons = (actions) => {
        return toButtonsHelper(actions, 'apiName', action => action.type === 'CustomButton');
    }

    // Convert Describe Layout Buttons to buttons
    static describeToButtons = (descButtons) => {
        return toButtonsHelper(descButtons, 'name', btn => btn.custom);
    }

    static getButton = (layout, name) => {
        if (layout && layout.buttons) {
            return layout.buttons.find(x => x.name === name);
        }
        return null;
    }

    static hasSignal = (section, signal) => {
        return section && section.signals && section.signals.includes(signal);
    }

    static toSearchLayoutColumns(searchLayoutResponse, objectInfo, targetSObject) {
        let columns = [];
        if (searchLayoutResponse){
            columns = searchLayoutResponse.searchColumns.map(
                column => {
                    const fldMatcher = soqlFieldPattern.exec(column.name);
                    const fldName = fldMatcher[3];
                    const fldObj = objectInfo.fields && objectInfo.fields[fldName];
                    let fldType = fldObj && fldObj.dataType && fldObj.dataType.toLowerCase();
                    if (fldName === 'Name') {
                        fldType = 'nameLink';
                    } else if (fldType !== 'boolean') {
                        fldType = 'text'
                    }

                    const columnObject = { 
                        label: column.label, type: fldType, fieldName: fldName,
                        queryFld: `${targetSObject}.${fldMatcher[2]}` 
                    };
                    if (fldName === 'Name') {
                        columnObject.typeAttributes = {
                            id: { fieldName: 'id' } 
                        };
                    }

                    return columnObject;
                });
        }
        return columns;
    }
}