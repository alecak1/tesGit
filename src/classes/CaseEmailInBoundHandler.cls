global class CaseEmailInBoundHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(
       Messaging.InboundEmail email,
       Messaging.InboundEnvelope envelope) {

 CaseEmailInBoundUtilities handler = new CaseEmailInBoundUtilities();
        Messaging.InboundEmailResult result = handler.processInboundEmail(email);
        return result;        
    }
}