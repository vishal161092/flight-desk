public without sharing class FD_InvokeAgentAsyncAction {

    public class Request {
        @InvocableVariable(label='Case ID' required=true)
        public String caseId;
        @InvocableVariable(label='PNR Number' required=true)
        public String pnrNumber;
        @InvocableVariable(label='Agent Input Message' required=false)
        public String agentInput;
    }

    public class Response {
        @InvocableVariable public Boolean queued;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label='Invoke Agent Async (Name Correction)'
        description='Queues the passport parsing, PNR name update, and confirmation email as an async job that runs in system context'
        category='Zephyr Air'
    )
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                System.enqueueJob(new FD_InvokeAgentAsync(req.caseId, req.pnrNumber, req.agentInput));
                res.queued = true;
                res.message = 'Name correction job queued successfully';
            } catch (Exception e) {
                res.queued = false;
                res.message = 'Failed to queue: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
