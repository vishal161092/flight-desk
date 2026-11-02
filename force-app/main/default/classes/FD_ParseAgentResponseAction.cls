public with sharing class FD_ParseAgentResponseAction {

    public class Request {
        @InvocableVariable(label='Agent Response JSON' required=true)
        public String agentResponseJson;
    }

    public class Response {
        @InvocableVariable public String message;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Parse Agent Response'
        description='Extracts the message text from an Agentforce agent JSON response'
        category='Zephyr Air'
    )
    public static List<Response> parseResponse(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(req.agentResponseJson);
                Map<String, Object> valueMap = (Map<String, Object>) parsed.get('value');
                res.message = (String) valueMap.get('message');
                res.success = true;
            } catch (Exception e) {
                res.success = false;
                res.message = req.agentResponseJson;
                res.errorMessage = 'Parse error: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
