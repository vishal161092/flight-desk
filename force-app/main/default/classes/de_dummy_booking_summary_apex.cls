public with sharing class de_dummy_booking_summary_apex {
    public class BookingSummaryDTO {
        @AuraEnabled public String bookingId;
        @AuraEnabled public String pnr;
        @AuraEnabled public String passengerName;
        @AuraEnabled public String ticketName;
        @AuraEnabled public String flightNo;
        @AuraEnabled public String route;
        @AuraEnabled public DateTime departureTime;
        @AuraEnabled public DateTime arrivalTime;
        @AuraEnabled public String cabinClass;
        @AuraEnabled public Integer numberOfBags;
        @AuraEnabled public String status;
        @AuraEnabled public String coTravelerName;
        @AuraEnabled public String coTravelerPNR;
        @AuraEnabled public String membershipTier;
    }

    @AuraEnabled(cacheable=true)
    public static BookingSummaryDTO getLatestBookingSummary(Id contactId) {
        try {
            List<Booking__c> bookings = [
                SELECT Id, PNR__c, PassengerName__c, TicketName__c, Flight_No__c,
                    Departure_Destination__c, Arrival_Destination__c, Departure_Time__c,
                    Arrival_Time__c, CabinClass__c, NumberOfBags__c, Status__c,
                    CoTravelerPNR__c, CoTravelerPassengerId__c, Membership_Tier__c
                FROM Booking__c
                WHERE PassengerId__c = 'PASS001'
                ORDER BY Departure_Time__c DESC
                LIMIT 1
            ];

            if (bookings.isEmpty()) return null;

            Booking__c b = bookings[0];
            BookingSummaryDTO dto = new BookingSummaryDTO();
            dto.bookingId = b.Id;
            dto.pnr = b.PNR__c;
            dto.passengerName = b.PassengerName__c;
            dto.ticketName = b.TicketName__c;
            dto.flightNo = b.Flight_No__c;
            dto.route = b.Departure_Destination__c + ' → ' + b.Arrival_Destination__c;
            dto.departureTime = b.Departure_Time__c;
            dto.arrivalTime = b.Arrival_Time__c;
            dto.cabinClass = b.CabinClass__c;
            dto.numberOfBags = b.NumberOfBags__c != null ? b.NumberOfBags__c.intValue() : 0;
            dto.status = b.Status__c;
            dto.coTravelerPNR = b.CoTravelerPNR__c;
            dto.membershipTier = b.Membership_Tier__c != null ? b.Membership_Tier__c : 'Silver';

            if (String.isNotBlank(b.CoTravelerPassengerId__c)) {
                List<Booking__c> coTravelers = [SELECT TicketName__c FROM Booking__c WHERE PassengerId__c = :b.CoTravelerPassengerId__c LIMIT 1];
                dto.coTravelerName = coTravelers.isEmpty() ? '' : coTravelers[0].TicketName__c;
            }

            return dto;
        } catch (Exception e) {
            throw new AuraHandledException('Booking summary fetch failed: ' + e.getMessage());
        }
    }
}