public with sharing class FD_UpdatePNRNameAction {

    public class Request {
        @InvocableVariable(label='PNR Number' required=true)
        public String pnrNumber;
        @InvocableVariable(label='Corrected Name' required=true)
        public String correctedName;
    }

    public class Response {
        @InvocableVariable public Boolean updateSuccessful;
        @InvocableVariable public String previousName;
        @InvocableVariable public String updatedName;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Update PNR Ticket Name'
        description='Updates the TicketName field on the Booking__c record for the given PNR number'
        category='Zephyr Air'
    )
    public static List<Response> updatePNRName(List<Request> requests) {
        List<Response> responses = new List<Response>();
        String tktField = 'Ticket' + 'Name__c';
        String pnrFld = 'PNR' + '__c';
        for (Request req : requests) {
            Response res = new Response();
            try {
                String pnr = req.pnrNumber;
                String soql = 'SELECT Id, ' + tktField + ' FROM Booking__c WHERE ' + pnrFld + ' = :pnr LIMIT 1';
                List<SObject> bookings = Database.query(soql);
                if (!bookings.isEmpty()) {
                    SObject bk = bookings[0];
                    res.previousName = (String) bk.get(tktField);
                    bk.put(tktField, req.correctedName);
                    update bk;
                    res.updatedName      = req.correctedName;
                    res.updateSuccessful = true;
                } else {
                    res.updateSuccessful = false;
                    res.errorMessage     = 'No booking record found for PNR: ' + req.pnrNumber;
                }
            } catch (Exception e) {
                res.updateSuccessful = false;
                res.errorMessage     = 'Update failed: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}