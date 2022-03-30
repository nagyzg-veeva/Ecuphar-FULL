/**
 * VeevaBaseResponse is a base response for REST responses.
 *
 * Any child class of VeevaBaseResponse must put the data of the response in a field called data.
 * Any metadata for the child class response must be put in a field called meta.
 *
 * Since amount of characters is counted by Salesforce and since Salesforce does not support generic types.
 * We will make VeevaBaseResponse a virtual class instead of an abstract class. This means that this class should be
 * instantiated directly via the constructors if no data need to be passed back in the response.
 *
 * An example, would be return a FAILURE response that only returns a FAILURE status and a message describing the failure.
 */
global inherited sharing virtual class VeevaBaseResponse {
    private final String status;
    private final String message;

    /**
     * Default Constructor assumes a SUCCESS and no messages.
     */
    global VeevaBaseResponse() {
        this('SUCCESS', '');
    }

    /**
     * Constructor is used if we do not need to pass data back, or if we are creating
     * an FAILURE Response and do not need the data or meta fields
     */
    global VeevaBaseResponse(String status, String message) {
        this.status = status;
        this.message = message;
    }
}