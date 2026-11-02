public with sharing class FD_GetLoyaltyDetailsAction {

    public class Request {
        @InvocableVariable(label='Passenger ID' required=true)
        public String passengerId;
    }

    public class Response {
        @InvocableVariable public String loyaltyId;
        @InvocableVariable public String passengerName;
        @InvocableVariable public String email;
        @InvocableVariable public String membershipTier;
        @InvocableVariable public String membershipNumber;
        @InvocableVariable public Decimal totalMiles;
        @InvocableVariable public String phoneNumber;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Get Loyalty Details'
        description='Fetches a passenger loyalty profile and membership tier from the Data Cloud Loyalty_DMO'
        category='Zephyr Air'
    )
    public static List<Response> getLoyaltyDetails(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                String passId = req.passengerId;
                List<SObject> results = Database.query(
                    'SELECT Id__c, PassengerName__c, Email__c, MembershipTier__c, ' +
                    'MembershipNumber__c, TotalMiles__c, PhoneNumber__c ' +
                    'FROM Loyalty_DMO__dlm WHERE PassengerId__c = :passId LIMIT 1'
                );
                if (!results.isEmpty()) {
                    SObject r = results[0];
                    res.loyaltyId        = (String) r.get('Id__c');
                    res.passengerName    = (String) r.get('PassengerName__c');
                    res.email            = (String) r.get('Email__c');
                    res.membershipTier   = (String) r.get('MembershipTier__c');
                    res.membershipNumber = (String) r.get('MembershipNumber__c');
                    res.totalMiles       = (Decimal)r.get('TotalMiles__c');
                    res.phoneNumber      = (String) r.get('PhoneNumber__c');
                } else {
                    res.errorMessage = 'No loyalty record for passenger: ' + req.passengerId;
                }
            } catch (Exception e) {
                res.errorMessage = 'Error fetching loyalty: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
