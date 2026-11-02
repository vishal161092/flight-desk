public with sharing class FD_RequestPassportDocumentAction {

    public class Request {
        @InvocableVariable(label='Case ID' required=true)
        public String caseId;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Request Passport Document'
        description='Sends the passport request email to the customer and updates the case status to indicate passport is awaited'
        category='Zephyr Air'
    )
    public static List<Response> requestPassportDocument(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                Case c = [SELECT Id, ContactId, SuppliedEmail, FD_PNRNumber__c, FD_ResolutionSummary__c
                          FROM Case WHERE Id = :req.caseId LIMIT 1];

                EmailTemplate template = [SELECT Id FROM EmailTemplate
                                          WHERE DeveloperName = 'FD_PassportRequestEmail' LIMIT 1];

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(template.Id);
                mail.setWhatId(c.Id);

                if (c.ContactId != null) {
                    mail.setTargetObjectId(c.ContactId);
                } else if (String.isNotBlank(c.SuppliedEmail)) {
                    mail.setToAddresses(new List<String>{ c.SuppliedEmail });
                    mail.setTargetObjectId(UserInfo.getUserId());
                }

                mail.setSaveAsActivity(true);
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

                String existing = String.isNotBlank(c.FD_ResolutionSummary__c) ? c.FD_ResolutionSummary__c + '\n\n' : '';
                c.FD_ResolutionSummary__c = existing + '[Name Correction] Passport copy requested from customer. Case held open pending receipt.';
                update c;

                res.success = true;
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error sending passport request: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
