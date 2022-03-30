global inherited sharing class VeevaJourneyPageResult extends VeevaJourneyResult {
    private Integer pageSize;
    private Integer page;
    private Integer total;
    private List<VeevajourneyOrderConfig> orderConfigs;
    private List<Object> data;

    global VeevaJourneyPageResult(VeevaJourneyPageInfo pageInfo) {
        this.pageSize = pageInfo.getPageSize();
        this.page = pageInfo.getPage();
        this.total = pageInfo.getTotal();
        this.orderConfigs = pageInfo.getOrderConfigs();
        this.data = pageInfo.getData();
    }

    global Integer getPageSize() {
        return pageSize;
    }

    global Integer getPage() {
        return page;
    }

    global Integer getTotal() {
        return total;
    }

    global override Object getData() {
        return data;
    }

    global List<VeevajourneyOrderConfig> getOrderConfigs() {
        return orderConfigs;
    }
}