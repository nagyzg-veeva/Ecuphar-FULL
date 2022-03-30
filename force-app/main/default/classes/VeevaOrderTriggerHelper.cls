/* Definition: Util class which defines methods to help modify the OM/IM reference (with Last_Inventory_Monitoring field in an Order
               and Related_Order field in an IM) and to check if an IM operation is valid.
   Purpose: Primarily used for different triggers like update, delete, or insert triggers and modify the OM/IM reference accordingly
            whether to update, delete, or insert the value in the Related_Order field in an IM object */

public class VeevaOrderTriggerHelper {

    public static void updateImRelatedRecords(Map<ID, Order_vod__c> oldOrders, Map<ID, Order_vod__c> newOrders) {
        //map used to contain the list of valid orders to update IM reference
        Map<ID, Order_vod__c> ordersToUpdate = new Map<ID, Order_vod__c>();
        List<ID> imRecordsToDelete = new List<ID>();
        //loop through each ID to compare each old and new order
        for (Id orderId : oldOrders.keySet()) {
            Order_vod__c oldOrder = oldOrders.get(orderId);
            Order_vod__c newOrder = newOrders.get(orderId);

            //add the new Order to map if Last IM field is null, then populated from old to new order
            if (oldOrder.Last_Inventory_Monitoring_vod__c == null && newOrder.Last_Inventory_Monitoring_vod__c != null) {
                ordersToUpdate.put(newOrder.Id, newOrder);
            }
            else if (oldOrder.Last_Inventory_Monitoring_vod__c != null && newOrder.Last_Inventory_Monitoring_vod__c == null) {
                imRecordsToDelete.add(oldOrder.Last_Inventory_Monitoring_vod__c);
            }
            else if (oldOrder.Last_Inventory_Monitoring_vod__c != newOrder.Last_Inventory_Monitoring_vod__c) {
                imRecordsToDelete.add(oldOrder.Last_Inventory_Monitoring_vod__c);
                ordersToUpdate.put(newOrder.Id, newOrder);
            }
        }
        imRelatedRecordHelper(ordersToUpdate, imRecordsToDelete);
    }

    public static void createImRelatedRecords(Map<ID, Order_vod__c> newOrders) {

        //map used to contain list of valid new orders to update IM reference
        Map<ID, Order_vod__c> newOrdersToUpdate = new Map<ID, Order_vod__c>();

        //loop through each new order
        for (ID orderId : newOrders.keyset()) {
            Order_vod__c newOrder = newOrders.get(orderId);

            //if last IM field is populated, add to map.
            if (newOrder.Last_Inventory_Monitoring_vod__c != null) {
                newOrdersToUpdate.put(newOrder.Id, newOrder);
            }
        }
        //creating records, so we don't need to add a list to delete any IM fields
        imRelatedRecordHelper(newOrdersToUpdate, new List<ID>());
    }
    public static void deleteImRelatedRecords(Map<ID, Order_vod__c> deleteOrders) {
        //map of valid orders that need to delete the im reference
        Map<ID, Order_vod__c> ordersToDeleteRef = new Map<ID, Order_vod__c>();
        List<ID> imRecordsToDelete = new List<ID>();
        //loop through deleteOrders
        for (ID orderId : deleteOrders.keySet()) {
            Order_vod__c deleteOrder = deleteOrders.get(orderId);

            //if order has Last IM field populated, add order to map to pass into helper method
            if (deleteOrder.Last_Inventory_Monitoring_vod__c != null) {
                imRecordsToDelete.add(deleteOrder.Last_Inventory_Monitoring_vod__c);
            }
        }
        imRelatedRecordHelper(ordersToDeleteRef, imRecordsToDelete);
    }
    private static void imRelatedRecordHelper(Map<ID, Order_vod__c> orders, List<ID> imIdsToDelete) {
        //list of IM's created to hold modified IM's in order to update all IMs in a single DML call
        List<Inventory_Monitoring_vod__c> imToUpdate = new List<Inventory_Monitoring_vod__c>();

        //loop through orders map which contains valid orders to modify the OM/IM reference
        for (Id orderId : orders.keySet()) {
            Order_vod__c order = orders.get(orderId);

            //Retrieve the valid IM object and modify Related_Order field
            String imRecordID = order.Last_Inventory_Monitoring_vod__c;
            Inventory_Monitoring_vod__c imRecord = new Inventory_Monitoring_vod__c(Id = imRecordID);
            imRecord.Related_Order_vod__c = orderId;
            imRecord.Override_Lock_vod__c = true;

            //add modified IM into imToUpdate
            imToUpdate.add(imRecord);
        }
        //loop over any leftover im IDs and remove the relatedOrder
        for (Id imRecordID : imIdsToDelete) {
            Inventory_Monitoring_vod__c imRecord = new Inventory_Monitoring_vod__c(Id = imRecordID);
            imRecord.Related_Order_vod__c = null;
            imRecord.Override_Lock_vod__c = true;
            imToUpdate.add(imRecord);
        }

        update imToUpdate;
    }
    public static Boolean isValidImOp(Inventory_Monitoring_vod__c oldInv, Inventory_Monitoring_vod__c newInv) {
        if (newInv.Override_Lock_vod__c == false) {
            Map<String, Object> oldFields = oldInv.getPopulatedFieldsAsMap();
            Map<String, Object> newFields = newInv.getPopulatedFieldsAsMap();
            return oldFields.equals(newFields);
        }
        return true;
    }
    public static void checkImRelatedOrder(Map<ID, Inventory_Monitoring_vod__c> deleteImRecords) {
        List<ID> relatedOrderIds = new List<ID>();
        List<ID> relatedMobileIds = new List<ID>();
        for (ID deleteImId : deleteImRecords.keySet()) {
            Inventory_Monitoring_vod__c deleteImRecord = deleteImRecords.get(deleteImId);
            if (VOD_UTILS.matchesSfdcId(Id.valueOf(deleteImId))) {
                ID relatedOrderID = deleteImRecord.Related_Order_vod__c;
                relatedOrderIds.add(relatedOrderID);
            }
            else {
                ID relatedMobileID = deleteImRecord.Related_order_vod__c;
                relatedMobileIds.add(relatedMobileID);
            }
        }
        List<Order_vod__c> ordersToCheck = [SELECT Id, Name, Last_Inventory_Monitoring_vod__c, Status_vod__c FROM Order_vod__c WHERE (Id IN: relatedOrderIds) OR (Mobile_Id_vod__c IN: relatedMobileIds)];
        for (Order_vod__c orderRecord : ordersToCheck) {
           if (orderRecord.Status_vod__c != 'Voided_vod' && orderRecord.Last_Inventory_Monitoring_vod__c != null) {
               Inventory_Monitoring_vod__c relatedImRecord = deleteImRecords.get(orderRecord.Last_Inventory_Monitoring_vod__c);
               if (relatedImRecord != null) {
                   relatedImRecord.addError(VOD_VEEVA_MESSAGE.getMsgWithDefault('IM_RELATED_OM_NOT_VOIDED','ORDER_MANAGEMENT',
                    'The related Order {0} must be voided before this Inventory Monitoring may be deleted').replace('{0}', orderRecord.Name));
                }
           }
        }
    }
}