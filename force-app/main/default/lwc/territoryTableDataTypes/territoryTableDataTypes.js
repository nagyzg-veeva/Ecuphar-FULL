import LightningDatatable from 'lightning/datatable';
import textWithIconVariant from './textWithIconVariant.html';
import buttonWithStyling from './buttonWithStyling.html';
import geoChangesButton from './geoChangesButton.html';
import styledText from './styledText.html';
import styledNumber from './styledNumber.html';
import styledDateTime from './styledDateTime.html';
import goal from './goal.html';
export default class TerritoryTableDataTypes extends LightningDatatable {
    static customTypes = {
        'text-with-icon-variant': {
            template: textWithIconVariant,
            standardCellLayout: false,
            typeAttributes: ['iconName', 'iconVariant', 'leftAlignIcon', 'iconClass']
        },
        'button-with-styling': {
            template: buttonWithStyling,
            standardCellLayout: true,
            typeAttributes: ['clickHandler', 'id', 'disabled', 'isNumeric']
        },
        'geo-changes-button': {
            template: geoChangesButton,
            standardCellLayout: true,
            typeAttributes: ['clickHandler', 'id', 'disabled', 'noChangeLabel', 'numGeosAdded', 'numGeosDropped']
        },
        'styled-text': {
            template: styledText,
            standardCellLayout: true,
            typeAttributes: ['classes']
        },
        'styled-number': {
            template: styledNumber,
            standardCellLayout: true,
            typeAttributes: ['classes']
        },
        'styled-date-time': {
            template: styledDateTime,
            standardCellLayout: true,
            typeAttributes: ['isDateTime', 'classes']
        },
        'goal': {
            template: goal,
            standardCellLayout: true,
            typeAttributes: ['difference', 'differenceIsPositive', 'isNull', 'classes']
        }
    }
}