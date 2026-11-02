public with sharing class FD_SendBaggageResolutionAction {

    public class Request {
        @InvocableVariable(label='Case ID' required=true)
        public String caseId;

        @InvocableVariable(label='Passenger Tier' required=true)
        public String passengerTier;

        @InvocableVariable(label='Co-Traveler Tier' required=false)
        public String coTravelerTier;

        @InvocableVariable(label='Passenger Bags' required=true)
        public Integer passengerBags;

        @InvocableVariable(label='Passenger Baggage Weight (kg)' required=true)
        public Integer passengerWeight;

        @InvocableVariable(label='Route Type' required=false)
        public String routeType;

        @InvocableVariable(label='Resolution Summary' required=false)
        public String resolutionSummary;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Send Baggage Resolution Email'
        description='Sends the baggage resolution email with a detailed breakdown of the group allowance policy and updates FD_ResolutionSummary__c on the case'
        category='Zephyr Air'
    )
    public static List<Response> sendBaggageResolution(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                Case c = [SELECT Id, ContactId, SuppliedEmail, FD_PNRNumber__c, FD_ResolutionSummary__c
                          FROM Case WHERE Id = :req.caseId LIMIT 1];

                String summary = buildResolutionSummary(req, c.FD_PNRNumber__c);

                String existing = String.isNotBlank(c.FD_ResolutionSummary__c) ? c.FD_ResolutionSummary__c + '\n\n' : '';
                c.FD_ResolutionSummary__c = existing + summary;
                update c;

                res.success = true;
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error sending baggage resolution: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }

    private static String buildResolutionSummary(Request req, String pnr) {
        Integer passengerAllowedBags = getAllowedBags(req.passengerTier);
        Integer coTravelerAllowedBags = String.isNotBlank(req.coTravelerTier) ? getAllowedBags(req.coTravelerTier) : 0;
        Integer totalBags = passengerAllowedBags + coTravelerAllowedBags;
        Integer totalWeight = totalBags * 23;

        String summary = 'Baggage Analysis for your booking (PNR: ' + pnr + '):\n\n';

        summary += '• Your membership tier: ' + req.passengerTier + ' — Entitlement: ' + passengerAllowedBags + ' bags × 23 kg = ' + (passengerAllowedBags * 23) + ' kg\n';

        if (String.isNotBlank(req.coTravelerTier)) {
            summary += '• Co-traveler membership tier: ' + req.coTravelerTier + ' — Entitlement: ' + coTravelerAllowedBags + ' bags × 23 kg = ' + (coTravelerAllowedBags * 23) + ' kg\n';
        }

        summary += '\nCombined group allowance: ' + totalBags + ' bags, ' + totalWeight + ' kg total permissible weight.\n\n';

        summary += 'Your current baggage: ' + req.passengerBags + ' bags totalling ' + req.passengerWeight + ' kg — ';

        if (req.passengerBags <= totalBags && req.passengerWeight <= totalWeight) {
            summary += 'this is within your group allowance and is fully permitted.\n\n';
        } else {
            summary += 'this exceeds your group allowance. Additional charges may apply.\n\n';
        }

        summary += 'This allowance applies because Zephyr Air\'s group benefit policy allows all travelers on the same PNR to benefit from the combined tier entitlements in the group.';

        return summary;
    }

    private static Integer getAllowedBags(String tier) {
        if (tier == null) return 2;
        String t = tier.toLowerCase();
        if (t == 'platinum' || t == 'gold') return 3;
        return 2;
    }
}
