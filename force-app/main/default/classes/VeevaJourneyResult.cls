global inherited sharing virtual class VeevaJourneyResult {
    private Object data;

    global VeevaJourneyResult() { }

    global VeevaJourneyResult(Object data) {
        this.data = data;
    }

    global virtual Object getData() {
        return data;
    }

    global virtual void setData(Object data) {
        this.data = data;
    }
}