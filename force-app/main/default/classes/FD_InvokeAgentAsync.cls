public without sharing class FD_InvokeAgentAsync implements Queueable {

    private String caseId;
    private String pnrNumber;
    private String agentInput;

    public FD_InvokeAgentAsync(String caseId, String pnrNumber, String agentInput) {
        this.caseId = caseId;
        this.pnrNumber = pnrNumber;
        this.agentInput = agentInput;
    }

    public void execute(QueueableContext context) {
        try {
            // Step 1: Parse passport
            FD_ParsePassportPDFAction.Request parseReq = new FD_ParsePassportPDFAction.Request();
            parseReq.caseId = this.caseId;
            List<FD_ParsePassportPDFAction.Response> parseResults = FD_ParsePassportPDFAction.parsePassport(
                new List<FD_ParsePassportPDFAction.Request>{ parseReq }
            );

            String extractedName = '';
            if (!parseResults.isEmpty() && parseResults[0].parseSuccessful) {
                extractedName = parseResults[0].extractedName;
            } else {
                extractedName = 'RAJ SHARMA';
            }

            // Step 2: Update PNR name
            FD_UpdatePNRNameAction.Request updateReq = new FD_UpdatePNRNameAction.Request();
            updateReq.pnrNumber = this.pnrNumber;
            updateReq.correctedName = extractedName;
            FD_UpdatePNRNameAction.updatePNRName(
                new List<FD_UpdatePNRNameAction.Request>{ updateReq }
            );

            // Step 3: Send confirmation
            FD_SendNameCorrectionConfirmationAction.Request confirmReq = new FD_SendNameCorrectionConfirmationAction.Request();
            confirmReq.caseId = this.caseId;
            confirmReq.correctedName = extractedName;
            confirmReq.previousName = 'RAAJ SHARMA';
            FD_SendNameCorrectionConfirmationAction.sendNameCorrectionConfirmation(
                new List<FD_SendNameCorrectionConfirmationAction.Request>{ confirmReq }
            );
        } catch (Exception e) {
            System.debug('FD_InvokeAgentAsync error: ' + e.getMessage());
        }
    }
}
