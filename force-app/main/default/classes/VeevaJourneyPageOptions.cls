global inherited sharing class VeevaJourneyPageOptions {
    private Integer page;
    private Integer pageSize;
    private List<VeevaJourneyOrderConfig> orderConfigs;

    global VeevaJourneyPageOptions() { }

    global VeevaJourneyPageOptions(Integer page, Integer pageSize) {
        this.page = page;
        this.pageSize = pageSize;
    }

    global VeevaJourneyPageOptions(
        Integer page,
        Integer pageSize,
        List<VeevaJourneyOrderConfig> orderConfigs
    ) {
        this.page = page;
        this.pageSize = pageSize;
        this.orderConfigs = orderConfigs;
    }

    global Integer getPage() {
        return page;
    }

    global void setPage(Integer page) {
        this.page = page;
    }

    global Integer getPageSize() {
        return pageSize;
    }

    global void setPageSize(Integer pageSize) {
        this.pageSize = pageSize;
    }

    global List<VeevaJourneyOrderConfig> getOrderConfigs() {
        return orderConfigs;
    }

    global void setOrderConfigs(List<VeevaJourneyOrderConfig> orderConfigs) {
        this.orderConfigs = orderConfigs;
    }

    global void setOrderConfigs(String orderKey) {
        this.orderConfigs = new List<VeevaJourneyOrderConfig> {
            new VeevaJourneyOrderConfig(orderKey)
        };
    }

    global void setOrderConfigs(List<String> orderKeys) {
        this.orderConfigs = new List<VeevaJourneyOrderConfig>();
        for (String orderKey: orderKeys) {
            if (!String.isBlank(orderKey)) {
                this.orderConfigs.add(new VeevaJourneyOrderConfig(orderKey));
            }
        }
    }
}