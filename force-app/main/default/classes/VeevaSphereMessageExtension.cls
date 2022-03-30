public with sharing class VeevaSphereMessageExtension {

    private final String viewButtonLabel;

    public VeevaSphereMessageExtension(ApexPages.StandardController stdController) {
        this.viewButtonLabel = VOD_VEEVA_MESSAGE.getMsgWithDefault('VIEW_LABEL', 'SphereOfInfluence', 'View');
    }

    public String getViewButtonLabel() {
        return this.viewButtonLabel;
    }
}