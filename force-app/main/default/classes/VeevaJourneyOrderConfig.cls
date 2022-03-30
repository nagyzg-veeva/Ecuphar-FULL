global inherited sharing class VeevaJourneyOrderConfig {
    // have to avoid apex reserved words by using other names other than ASC, DESC...
    global enum OrderOption { ASC_ORDER, DESC_ORDER }
    global enum NullValOption { AT_FIRST, AT_LAST }

    private String key;
    private OrderOption order = OrderOption.ASC_ORDER;
    private NullValOption nullVal = NullValOption.AT_LAST;

    global VeevaJourneyOrderConfig() { }

    global VeevaJourneyOrderConfig(String key) {
        this.key = key;
    }

    global VeevaJourneyOrderConfig(String key, OrderOption order, NullValOption nullVal) {
        this.key = key;
        this.order = order;
        this.nullVal = nullVal;
    }

    global String getKey() {
        return key;
    }

    global void setKey(String key) {
        this.key = key;
    }

    global OrderOption getOrder() {
        return order;
    }

    global void setOrder(OrderOption order) {
        this.order = order;
    }

    global NullValOption getNullVal() {
        return nullVal;
    }

    global void setNullVal(NullValOption nullVal) {
        this.nullVal = nullVal;
    }

    global String getOrderName() {
        String name = '';
        if (order === OrderOption.ASC_ORDER) {
            name = 'ASC';
        } else if (order === OrderOption.DESC_ORDER) {
            name = 'DESC';
        }
        return name;
    }

    global String getNullValName() {
        String name = '';
        if (nullVal === NullValOption.AT_FIRST) {
            name = 'FIRST';
        } else if (nullVal === NullValOption.AT_LAST) {
            name = 'LAST';
        }
        return name;
    }
}