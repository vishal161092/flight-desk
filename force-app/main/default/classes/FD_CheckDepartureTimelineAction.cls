public with sharing class FD_CheckDepartureTimelineAction {

    public class Request {
        @InvocableVariable(label='Departure Date Time' required=true)
        public DateTime departureDateTime;
    }

    public class Response {
        @InvocableVariable public Long hoursUntilDeparture;
        @InvocableVariable public String windowCategory;
        // IDEAL (>=72h) | POSSIBLE (24-72h) | NOT_ALLOWED (<24h) | DEPARTED (past)
        @InvocableVariable public Boolean correctionAllowed;
        @InvocableVariable public String explanation;
    }

    @InvocableMethod(
        label='Check Departure Timeline'
        description='Calculates hours until departure and returns the name correction eligibility window per Zephyr Air policy'
        category='Zephyr Air'
    )
    public static List<Response> checkDeparture(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            Long diffMs    = req.departureDateTime.getTime() - DateTime.now().getTime();
            Long diffHours = diffMs / (1000L * 60 * 60);
            res.hoursUntilDeparture = diffHours;

            if (diffHours >= 72) {
                res.windowCategory    = 'IDEAL';
                res.correctionAllowed = true;
                res.explanation = 'Departure is ' + diffHours + ' hours away. Name correction is freely allowed (72+ hour window).';
            } else if (diffHours >= 24) {
                res.windowCategory    = 'POSSIBLE';
                res.correctionAllowed = true;
                res.explanation = 'Departure is ' + diffHours + ' hours away. Name correction is possible on a case-by-case basis (24–72 hour window).';
            } else if (diffHours >= 0) {
                res.windowCategory    = 'NOT_ALLOWED';
                res.correctionAllowed = false;
                res.explanation = 'Departure is only ' + diffHours + ' hours away. Name correction is not permitted within 24 hours of departure.';
            } else {
                res.windowCategory    = 'DEPARTED';
                res.correctionAllowed = false;
                res.explanation = 'This flight has already departed. Name correction is not possible.';
            }
            responses.add(res);
        }
        return responses;
    }
}
