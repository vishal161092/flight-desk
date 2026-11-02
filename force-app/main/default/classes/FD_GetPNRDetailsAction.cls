public with sharing class FD_GetPNRDetailsAction {

    public class Request {
        @InvocableVariable(label='PNR Number' required=true)
        public String pnrNumber;
    }

    public class Response {
        @InvocableVariable public String pnrId;
        @InvocableVariable public String passengerId;
        @InvocableVariable public String passengerName;
        @InvocableVariable public String ticketName;
        @InvocableVariable public String flightNumber;
        @InvocableVariable public String origin;
        @InvocableVariable public String destination;
        @InvocableVariable public DateTime departureDateTime;
        @InvocableVariable public String cabinClass;
        @InvocableVariable public Integer numberOfBags;
        @InvocableVariable public String coTravelerPNR;
        @InvocableVariable public String coTravelerPassengerId;
        @InvocableVariable public String bookingStatus;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Get PNR Details'
        description='Fetches a passenger booking record from the Data Cloud PNR_DMO by PNR number'
        category='Zephyr Air'
    )
    public static List<Response> getPNRDetails(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                String pnr = req.pnrNumber;
                // Data Cloud DMO objects surface as __dlm in SOQL
                // Verify the exact suffix in your org: Setup > Data Cloud > Data Model
                List<SObject> results = Database.query(
                    'SELECT Id__c, PassengerId__c, PassengerName__c, TicketName__c, ' +
                    'FlightNumber__c, Origin__c, Destination__c, DepartureDateTime__c, ' +
                    'ArrivalDateTime__c, CabinClass__c, NumberOfBags__c, ' +
                    'CoTravelerPNR__c, CoTravelerPassengerId__c, BookingStatus__c ' +
                    'FROM PNR_DMO__dlm WHERE PNRNumber__c = :pnr LIMIT 1'
                );
                if (!results.isEmpty()) {
                    SObject r = results[0];
                    res.pnrId                  = (String)  r.get('Id__c');
                    res.passengerId            = (String)  r.get('PassengerId__c');
                    res.passengerName          = (String)  r.get('PassengerName__c');
                    res.ticketName             = (String)  r.get('TicketName__c');
                    res.flightNumber           = (String)  r.get('FlightNumber__c');
                    res.origin                 = (String)  r.get('Origin__c');
                    res.destination            = (String)  r.get('Destination__c');
                    res.departureDateTime      = (DateTime)r.get('DepartureDateTime__c');
                    res.cabinClass             = (String)  r.get('CabinClass__c');
                    res.numberOfBags           = ((Decimal)r.get('NumberOfBags__c'))?.intValue();
                    res.coTravelerPNR          = (String)  r.get('CoTravelerPNR__c');
                    res.coTravelerPassengerId  = (String)  r.get('CoTravelerPassengerId__c');
                    res.bookingStatus          = (String)  r.get('BookingStatus__c');
                } else {
                    res.errorMessage = 'No PNR record found for: ' + req.pnrNumber;
                }
            } catch (Exception e) {
                res.errorMessage = 'Error fetching PNR: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
