global inherited sharing class VeevaJourneyLookupFieldQueryResult {
    private List<Object> data;
    private Integer count;

    global VeevaJourneyLookupFieldQueryResult() { }

    global VeevaJourneyLookupFieldQueryResult(List<Object> data, Integer count) {
        this.data = data;
        this.count = count;
    }

    global List<Object> getData() {
        return data;
    }

    global void setData(List<Object> data) {
        this.data = data;
    }

    global Integer getCount() {
        return count;
    }

    global void setCount(Integer count) {
        this.count = count;
    }
}