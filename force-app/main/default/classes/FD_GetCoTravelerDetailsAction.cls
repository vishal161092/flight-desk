public with sharing class FD_GetCoTravelerDetailsAction {

    public class Request {
        @InvocableVariable(label='Co-Traveler PNR Number' required=true)
        public String coTravelerPNR;
    }

    public class Response {
        @InvocableVariable public String passengerId;
        @InvocableVariable public String passengerName;
        @InvocableVariable public String membershipTier;
        @InvocableVariable public Integer numberOfBags;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Get Co-Traveler Details'
        description='Fetches the co-traveling passenger PNR and their loyalty membership tier to assess group baggage benefits'
        category='Zephyr Air'
    )
    public static List<Response> getCoTravelerDetails(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                String coTravPNR = req.coTravelerPNR;
                List<SObject> pnrResults = Database.query(
                    'SELECT PassengerId__c, PassengerName__c, NumberOfBags__c ' +
                    'FROM PNR_DMO__dlm WHERE PNRNumber__c = :coTravPNR LIMIT 1'
                );
                if (!pnrResults.isEmpty()) {
                    SObject pnr = pnrResults[0];
                    res.passengerId  = (String)  pnr.get('PassengerId__c');
                    res.passengerName = (String) pnr.get('PassengerName__c');
                    res.numberOfBags = ((Decimal)pnr.get('NumberOfBags__c'))?.intValue();

                    String passId = res.passengerId;
                    List<SObject> loyResults = Database.query(
                        'SELECT MembershipTier__c FROM Loyalty_DMO__dlm ' +
                        'WHERE PassengerId__c = :passId LIMIT 1'
                    );
                    if (!loyResults.isEmpty()) {
                        res.membershipTier = (String)loyResults[0].get('MembershipTier__c');
                    }
                } else {
                    res.errorMessage = 'No PNR found for co-traveler: ' + req.coTravelerPNR;
                }
            } catch (Exception e) {
                res.errorMessage = 'Error fetching co-traveler: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
