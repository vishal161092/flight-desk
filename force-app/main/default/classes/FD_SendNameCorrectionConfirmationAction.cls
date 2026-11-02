public with sharing class FD_SendNameCorrectionConfirmationAction {

    public class Request {
        @InvocableVariable(label='Case ID' required=true)
        public String caseId;

        @InvocableVariable(label='Corrected Name' required=true)
        public String correctedName;

        @InvocableVariable(label='Previous Name' required=false)
        public String previousName;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Send Name Correction Confirmation'
        description='Sends the name correction confirmation email to the customer and appends a resolution summary to the case'
        category='Zephyr Air'
    )
    public static List<Response> sendNameCorrectionConfirmation(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                Case c = [SELECT Id, CaseNumber, ContactId, SuppliedEmail, SuppliedName, FD_PNRNumber__c, FD_ResolutionSummary__c
                          FROM Case WHERE Id = :req.caseId LIMIT 1];

                String customerName = String.isNotBlank(c.SuppliedName) ? c.SuppliedName : 'Valued Customer';
                String pnr = String.isNotBlank(c.FD_PNRNumber__c) ? c.FD_PNRNumber__c : '';
                String previousName = String.isNotBlank(req.previousName) ? req.previousName : '';

                String body = 'Dear ' + customerName + ',\n\n' +
                    'We are pleased to confirm that the name correction for your Zephyr Air booking has been successfully processed.\n\n' +
                    'Booking Reference: ' + pnr + '\n' +
                    'Previous Name: ' + previousName + '\n' +
                    'Corrected Name: ' + req.correctedName + '\n\n' +
                    'Your updated ticket now reflects the correct name as per your passport. Please ensure you carry your passport when you travel, as it must match your ticket name for international check-in.\n\n' +
                    'Important reminders for your upcoming journey:\n' +
                    '- Arrive at the airport at least 3 hours before your international departure\n' +
                    '- Carry your valid passport and this booking confirmation\n' +
                    '- Check-in counters for international flights typically open 3 hours before departure\n\n' +
                    'If you have any further questions, please reply to this email or contact us at 1800-000-000.\n\n' +
                    'We look forward to welcoming you on board. Have a wonderful journey!\n\n' +
                    'Warm regards,\n' +
                    'Zephyr Air Customer Support\n' +
                    'support@zephyrair.example | 1800-000-000\n\n' +
                    'Reference: Case ' + c.CaseNumber;

                // Email sending handled by record-triggered flow on Case when FD_ResolutionSummary__c is updated
                // Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                // mail.setToAddresses(new List<String>{ c.SuppliedEmail });
                // mail.setSubject('Name Correction Confirmed – ' + pnr);
                // mail.setPlainTextBody(body);
                // mail.setSenderDisplayName('Zephyr Air Customer Support');
                // mail.setSaveAsActivity(true);
                // Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

                String nameChange = String.isNotBlank(req.previousName)
                    ? req.previousName + ' → ' + req.correctedName
                    : req.correctedName;
                c.FD_ResolutionSummary__c = 'Your ticket name has been successfully updated from ' + req.previousName + ' to ' + req.correctedName + ' for booking ' + c.FD_PNRNumber__c + '.\n\nYour ticket will be reissued with the corrected name and shared with you via email shortly. Please ensure you carry your passport when you travel, as it must match your ticket name for international check-in.\n\nImportant reminders for your upcoming journey:\n- Arrive at the airport at least 3 hours before your international departure\n- Carry your valid passport and the reissued ticket confirmation\n- Check-in counters for international flights typically open 3 hours before departure';
                c.Status = 'Closed';
                update c;

                res.success = true;
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error sending name correction confirmation: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
