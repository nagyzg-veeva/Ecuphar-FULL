global inherited sharing class VeevaJourneyPageInfo {
    private Integer pageSize;
    private Integer page;
    private Integer total;
    private List<VeevaJourneyOrderConfig> orderConfigs;
    private List<Object> data;

    global VeevaJourneyPageInfo() { }

    global VeevaJourneyPageInfo(VeevaJourneyPageOptions pageOptions, Integer total, List<Object> data) {
        this.pageSize = pageOptions.getPageSize();
        this.page = pageOptions.getPage();
        this.total = total;
        this.orderConfigs = pageOptions.getOrderConfigs();
        this.data = data;
    }

    global VeevaJourneyPageInfo(VeevaJourneyPageOptions pageOptions, VeevaJourneyLookupFieldQueryResult qr) {
        this(pageOptions, qr.getCount(), qr.getData());
    }

    global VeevaJourneyPageInfo(
        Integer pageSize,
        Integer page,
        Integer total,
        List<VeevaJourneyOrderConfig> orderConfigs,
        List<Object> data
    ) {
        this.pageSize = pageSize;
        this.page = page;
        this.total = total;
        this.orderConfigs = orderConfigs;
        this.data = data;
    }

    global Integer getPageSize() {
        return pageSize;
    }

    global void setPageSize(Integer pageSize) {
        this.pageSize = pageSize;
    }

    global Integer getPage() {
        return page;
    }

    global void setPage(Integer page) {
        this.page = page;
    }

    global Integer getTotal() {
        return total;
    }

    global void setTotal(Integer total) {
        this.total = total;
    }

    global List<Object> getData() {
        return data;
    }

    global void setData(List<Object> data) {
        this.data = data;
    }

    global List<VeevaJourneyOrderConfig> getOrderConfigs() {
        return orderConfigs;
    }

    global void setOrderConfigs(List<VeevaJourneyOrderConfig> orderConfigs) {
        this.orderConfigs = orderConfigs;
    }
}