public with sharing class FD_WebFormController {

    public class CaseRequest {
        @AuraEnabled public String fullName {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public String pnrNumber {get; set;}
        @AuraEnabled public String subject {get; set;}
        @AuraEnabled public String description {get; set;}
    }

    public class CaseResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String caseId;
        @AuraEnabled public String errorMessage;
    }

    @AuraEnabled
    public static CaseResult createCase(CaseRequest req) {
        CaseResult result = new CaseResult();
        try {
            Case c = new Case();
            c.SuppliedName    = req.fullName;
            c.SuppliedEmail   = req.email;
            c.Subject         = req.subject;
            c.Description     = req.description;
            c.Origin          = 'Website';
            c.Status          = 'New';
            c.FD_PNRNumber__c = req.pnrNumber;
            c.FD_IntentType__c = 'Multi-Intent';
            List<Contact> existing = [SELECT Id FROM Contact WHERE Email = :req.email LIMIT 1];
            if (!existing.isEmpty()) {
                c.ContactId = existing[0].Id;
            }
            insert c;

            Case inserted = [SELECT CaseNumber FROM Case WHERE Id = :c.Id LIMIT 1];
            result.success    = true;
            result.caseId     = c.Id;
            result.caseNumber = inserted.CaseNumber;
        } catch (Exception e) {
            result.success      = false;
            result.errorMessage = e.getMessage();
        }
        return result;
    }
}
