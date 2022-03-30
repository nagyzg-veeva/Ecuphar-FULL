public with sharing class VOD_GetRecordIds {

    ApexPages.StandardSetController m_controller;
    public VOD_GetRecordIds(ApexPages.StandardSetController controller) {
        m_controller = controller;
    }
    public String getRecordIds() {
        String ids = '';
        if (m_controller == null)
            return ids;

        Boolean first = true;
        sObject[] records = m_controller.getRecords();
        for (sObject record : records) {
            if (first)
                first = false;
            else
                ids += ',';
            ids += record.Id;
        }
        return ids;
    }

    public String getSelectedRecordIds() {
        String ids = '';
        if (m_controller == null)
            return ids;

        Boolean first = true;
        sObject[] records = m_controller.getSelected();
        for (sObject record : records) {
            if (first)
                first = false;
            else
                ids += ',';
            ids += record.Id;
        }
        return ids;
    }

    public boolean isPerson {get; set;}
    public String accountId {get; set;}

    public void initPerson() {
        Account account = [select IsPersonAccount from Account where Id = :ApexPages.currentPage().getParameters().get('id')];
        isPerson = account != null ? account.IsPersonAccount : false;
    }

    public String getNoRowMIMessage() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('NO_ROW_SELECTED', 'MEDICAL_INQUIRY', 'No row has been selected');
    }

}