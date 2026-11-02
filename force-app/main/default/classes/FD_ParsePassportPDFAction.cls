public with sharing class FD_ParsePassportPDFAction {

    public class Request {
        @InvocableVariable(label='Case ID' required=true)
        public String caseId;
        @InvocableVariable(label='Content Document ID (optional)')
        public String contentDocumentId;
    }

    public class Response {
        @InvocableVariable public String extractedName;
        @InvocableVariable public String passportNumber;
        @InvocableVariable public Boolean parseSuccessful;
        @InvocableVariable public String errorMessage;
    }

    private static final Set<String> SUPPORTED_EXTENSIONS = new Set<String>{
        'pdf', 'png', 'jpg', 'jpeg', 'gif', 'bmp', 'tiff', 'tif'
    };

    @InvocableMethod(
        label='Parse Passport Document'
        description='Reads the most recent PDF or image attachment on a Case email thread and extracts the passenger name using Einstein LLM document extraction with regex and case description fallbacks.'
        category='Zephyr Air'
    )
    public static List<Response> parsePassport(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            try {
                Id docId;
                if (String.isNotBlank(req.contentDocumentId)) {
                    docId = Id.valueOf(req.contentDocumentId);
                } else {
                    docId = findLatestDocumentOnCase(req.caseId);
                }

                if (docId == null) {
                    res.parseSuccessful = false;
                    res.errorMessage    = 'No passport document (PDF or image) found on this case or its email thread.';
                    responses.add(res);
                    continue;
                }

                ContentVersion cv = [
                    SELECT Id, VersionData, Title, FileExtension, ContentDocumentId
                    FROM ContentVersion
                    WHERE ContentDocumentId = :docId AND IsLatest = true LIMIT 1
                ];

                // Primary: Use Einstein LLM Prompt Template for document extraction
                extractUsingEinsteinLLM(cv, res);

                // Fallback 1: Try reading as text (text-based PDFs)
                if (!res.parseSuccessful) {
                    String rawText = null;
                    try {
                        rawText = cv.VersionData.toString();
                    } catch (Exception blobEx) {
                        // Binary file
                    }
                    if (rawText != null) {
                        extractFromMRZ(rawText, res);
                        if (!res.parseSuccessful) {
                            extractFromPlainText(rawText, res);
                        }
                    }
                }

                // Fallback 2: Extract from file title
                if (!res.parseSuccessful) {
                    extractFromFileName(cv.Title, res);
                }

                // Fallback 3: Extract from case description
                if (!res.parseSuccessful) {
                    extractFromCaseDescription(req.caseId, res);
                }

            } catch (Exception e) {
                res.parseSuccessful = false;
                res.errorMessage    = 'Parse error: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }

    private static void extractUsingEinsteinLLM(ContentVersion cv, Response res) {
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput promptGenerationsInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            promptGenerationsInput.isPreview = false;
                            
            Map<String,ConnectApi.WrappedValue> valueMap = new Map<String,ConnectApi.WrappedValue>();
            // ConnectApi.WrappedValue strWrappedValue = new ConnectApi.WrappedValue();
            // strWrappedValue.value = JSON_Data;

            // System.debug('JSON data to prompt Input -> '+strWrappedValue.value);
                                            
            // valueMap.put('Input:recordsJSon', strWrappedValue);

            ConnectApi.WrappedValue fileWrapped = new ConnectApi.WrappedValue();
            fileWrapped.value = cv.ContentDocumentId;
            valueMap.put('Input:file', fileWrapped);
                                            
            promptGenerationsInput.inputParams = valueMap;
                                            
            promptGenerationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            promptGenerationsInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
                                            
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = 
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('0hfIg0000008RNaIAM', promptGenerationsInput); 
                                            
            System.debug('Prompt resolution: ' + generationsOutput.prompt);
                                            
            System.debug('Prompt response: ' + generationsOutput.generations[0].text);

            if (generationsOutput != null && generationsOutput.generations != null && !generationsOutput.generations.isEmpty()) {
                String responseText = generationsOutput.generations[0].text;
                parseEinsteinResponse(responseText, res);
            }
        } catch (Exception e) {
            System.debug('Einstein LLM extraction failed: ' + e.getMessage());
        }
    }

    private static void parseEinsteinResponse(String responseText, Response res) {
        if (String.isBlank(responseText)) return;

        // Try JSON format: {"name": "RAJ SHARMA", "passportNumber": "M1234567"}
        try {
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(responseText);
            if (parsed.containsKey('name')) {
                res.extractedName = ((String) parsed.get('name')).toUpperCase().trim();
                res.parseSuccessful = true;
            }
            if (parsed.containsKey('passportNumber')) {
                res.passportNumber = (String) parsed.get('passportNumber');
            }
            return;
        } catch (Exception jsonEx) {
            // Not JSON — try plain text
        }

        // Plain text response — look for a name pattern (all caps, 2-4 words)
        Pattern namePattern = Pattern.compile('([A-Z][A-Z\\s]{2,40})');
        Matcher m = namePattern.matcher(responseText.toUpperCase());
        if (m.find()) {
            String candidate = m.group(1).trim();
            if (candidate.contains(' ') && candidate.length() >= 5) {
                res.extractedName = candidate;
                res.parseSuccessful = true;
            }
        }
    }

    private static Id findLatestDocumentOnCase(String caseId) {
        Id docId = null;

        // First: check EmailMessages on the case (attachment comes via email)
        List<EmailMessage> emails = [
            SELECT Id FROM EmailMessage
            WHERE ParentId = :caseId
            ORDER BY MessageDate DESC LIMIT 20
        ];
        if (!emails.isEmpty()) {
            Set<Id> emailIds = new Map<Id, EmailMessage>(emails).keySet();
            List<ContentDocumentLink> cdls = [
                SELECT ContentDocumentId, ContentDocument.FileExtension, ContentDocument.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :emailIds
                ORDER BY SystemModstamp DESC LIMIT 10
            ];
            for (ContentDocumentLink cdl : cdls) {
                String ext = cdl.ContentDocument.FileExtension;
                if (ext != null && SUPPORTED_EXTENSIONS.contains(ext.toLowerCase())) {
                    docId = cdl.ContentDocumentId;
                    break;
                }
            }
        }

        // Second: check Case directly
        if (docId == null) {
            List<ContentDocumentLink> caseCdls = [
                SELECT ContentDocumentId, ContentDocument.FileExtension
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :caseId
                ORDER BY SystemModstamp DESC LIMIT 10
            ];
            for (ContentDocumentLink cdl : caseCdls) {
                String ext = cdl.ContentDocument.FileExtension;
                if (ext != null && SUPPORTED_EXTENSIONS.contains(ext.toLowerCase())) {
                    docId = cdl.ContentDocumentId;
                    break;
                }
            }
        }

        // Link the document to the Case if found on EmailMessage but not on Case
        if (docId != null) {
            List<ContentDocumentLink> existingLink = [
                SELECT Id FROM ContentDocumentLink
                WHERE ContentDocumentId = :docId AND LinkedEntityId = :caseId
                LIMIT 1
            ];
            if (existingLink.isEmpty()) {
                ContentDocumentLink newLink = new ContentDocumentLink();
                newLink.ContentDocumentId = docId;
                newLink.LinkedEntityId = caseId;
                newLink.ShareType = 'V';
                newLink.Visibility = 'AllUsers';
                insert newLink;
            }
        }

        return docId;
    }

    // ICAO MRZ line 1: P<IND<SURNAME<<GIVENNAMES<<<<<<<<<<<<<<<<
    private static void extractFromMRZ(String text, Response res) {
        Pattern mrzPattern = Pattern.compile('P<([A-Z]{3})([A-Z<]{39})');
        Matcher m = mrzPattern.matcher(text);
        if (m.find()) {
            String namePart = m.group(2);
            String[] parts  = namePart.split('<<');
            String surname   = parts.size() > 0 ? parts[0].replace('<', ' ').trim() : '';
            String givenName = parts.size() > 1 ? parts[1].replace('<', ' ').trim() : '';
            res.extractedName   = (givenName + ' ' + surname).trim();
            res.parseSuccessful = true;
        }
        // MRZ line 2 for passport number: positions 1-9
        Pattern pptPattern = Pattern.compile('[A-Z0-9]{9}[0-9]');
        Matcher pm = pptPattern.matcher(text);
        if (pm.find()) {
            res.passportNumber = pm.group(0).substring(0, 9);
        }
    }

    // Fallback: look for "Given Name: RAJ" or "Surname: SHARMA" patterns
    private static void extractFromPlainText(String text, Response res) {
        Pattern givenPattern   = Pattern.compile('(?i)(?:given\\s*names?|first\\s*name)[:\\s]+([A-Z][A-Z\\s]{1,30})');
        Pattern surnamePattern = Pattern.compile('(?i)(?:surname|last\\s*name|family\\s*name)[:\\s]+([A-Z][A-Z\\s]{1,30})');
        Matcher gm = givenPattern.matcher(text);
        Matcher sm = surnamePattern.matcher(text);

        String given   = gm.find() ? gm.group(1).trim() : '';
        String surname = sm.find() ? sm.group(1).trim() : '';

        if (String.isNotBlank(given) || String.isNotBlank(surname)) {
            res.extractedName   = (given + ' ' + surname).trim();
            res.parseSuccessful = true;
        }
    }

    // Fallback: extract name from file title (e.g. "RAJ SHARMA passport", "raj_sharma.pdf")
    private static void extractFromFileName(String title, Response res) {
        if (String.isBlank(title)) return;
        String cleaned = title.replaceAll('(?i)(passport|scan|copy|doc|document|img|image|photo)', '').trim();
        cleaned = cleaned.replaceAll('[_\\-\\.]', ' ').trim();
        cleaned = cleaned.replaceAll('\\s+', ' ').trim();
        if (String.isNotBlank(cleaned) && cleaned.length() >= 3 && cleaned.length() <= 40) {
            res.extractedName = cleaned.toUpperCase();
            res.parseSuccessful = true;
        }
    }

    // Last resort: look in case description for "passport says RAJ" or "correct name is RAJ SHARMA"
    private static void extractFromCaseDescription(String caseId, Response res) {
        List<Case> cases = [SELECT Description FROM Case WHERE Id = :caseId LIMIT 1];
        if (cases.isEmpty() || String.isBlank(cases[0].Description)) return;

        String caseDesc = cases[0].Description;
        System.Pattern p1 = System.Pattern.compile('(?i)passport\\s+(?:says|reads|shows|name\\s+is)\\s+([A-Z][A-Za-z\\s]{1,30})');
        System.Matcher m1 = p1.matcher(caseDesc);
        if (m1.find()) {
            res.extractedName = m1.group(1).trim().toUpperCase();
            res.parseSuccessful = true;
            return;
        }
        System.Pattern p2 = System.Pattern.compile('(?i)correct\\s+name\\s+(?:is|should\\s+be)\\s+([A-Z][A-Za-z\\s]{1,30})');
        System.Matcher m2 = p2.matcher(caseDesc);
        if (m2.find()) {
            res.extractedName = m2.group(1).trim().toUpperCase();
            res.parseSuccessful = true;
        }
    }
}
