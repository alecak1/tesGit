public with sharing class CaseEmailInBoundUtilities {

private Static Boolean TRACE = true;

protected Case theCase = null;
protected Messaging.InboundEmail inboundEmail;
protected String defaultCaseOwnerId;
protected String defaultCaseRecordTypeId;

public CaseEmailInBoundUtilities() {
 
}

public Messaging.InboundEmailResult processInboundEmail(Messaging.InboundEmail email)
{

    Email2Queue2RecordType__c myCS1 = null;
    
    if (email.fromAddress.containsIgnoreCase('support.fpt@reply.it')) {
    
        if (email.subject.containsIgnoreCase('Sales') || email.plainTextBody.containsIgnoreCase('Sales')) {
            myCS1 = Email2Queue2RecordType__c.getInstance('Fpt_Sales_Cases');
            
            Group[] queues = [select Id, Name from Group where DeveloperName = : myCS1.Case_Queue_Owner__c];
            this.defaultCaseOwnerId = queues[0].Id;  
            this.defaultCaseRecordTypeId = myCS1.Case_RecordTypeId__c;
        } else {
            myCS1 = Email2Queue2RecordType__c.getInstance('Fpt_Warranty_Cases');
            
            Group[] queues = [select Id, Name from Group where DeveloperName = : myCS1.Case_Queue_Owner__c];
            this.defaultCaseOwnerId = queues[0].Id;  
            this.defaultCaseRecordTypeId = myCS1.Case_RecordTypeId__c;
        }
        
    } else if (email.fromAddress.containsIgnoreCase('support.rcs@reply.it')) {
        myCS1 = Email2Queue2RecordType__c.getInstance('Rcs_SFA_Libri_Cases');
        
        Group[] queues = [select Id, Name from Group where DeveloperName = : myCS1.Case_Queue_Owner__c];
        this.defaultCaseOwnerId = queues[0].Id;  
        this.defaultCaseRecordTypeId = myCS1.Case_RecordTypeId__c;
        
    } else {
        return null;
    }
    
    // set up
    Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
    result.success = true;
    this.inboundEmail = email;

    // locate Case Number in email subject line, if present locate the main Case
    String caseNumber = extractRef(email.subject);
    if(caseNumber != null)
    {  
        this.theCase = locateByCaseNumberAsString(caseNumber);
        if(this.theCase == null) {
        // TODO email error message to SysAdmin
        }
        
     } else {
        // try to match subject
        String mainSubject = extractMainSubject(email.subject);
        
        Case[] matchingCases = [Select Id, CaseNumber, Subject, Description 
                                From Case 
                                Where Subject LIKE :mainSubject and CreatedDate = LAST_N_DAYS:30
                                Order By CreatedDate DESC];
        
        if(matchingCases.size() >= 1) {
        
            this.theCase = matchingCases[0];
            
            String mailplainTextBody = email.plainTextBody;
            
            if (mailplainTextBody.containsIgnoreCase(matchingCases[0].Description)) {
                
                if (mailplainTextBody.length() > 32000) {
                    mailplainTextBody = mailplainTextBody.subString(0, 32000);
                }
                matchingCases[0].Description = mailplainTextBody;
                
            } else {
                
                matchingCases[0].Description = email.plainTextBody + 
                                               '\n\n\n' + 
                                               matchingCases[0].Description;
                
                if (matchingCases[0].Description.length() > 32000) {
                    matchingCases[0].Description = matchingCases[0].Description.subString(0, 32000);
                }
                
            }
            
            update matchingCases;
  
        }
        
    }
    
    if (this.theCase == null) {
        
        // else create a new Case
        this.theCase = new Case();
        theCase.SuppliedEmail = email.fromAddress;
        theCase.SuppliedName = email.fromName;
        theCase.Status = 'New';
        theCase.Priority = 'Medium';
        theCase.OwnerId = this.defaultCaseOwnerId;
        theCase.Origin = 'Email';
        theCase.Subject = email.Subject;
        theCase.Description = email.plainTextBody;
        theCase.RecordTypeId = this.defaultCaseRecordTypeId;
        
        Contact[] contacts = [SELECT Id, Name, AccountId, Email 
                              FROM Contact 
                              WHERE Email = :email.fromAddress];
        
        if(contacts.size() >0) 
        {
            Contact theContact = contacts[0];
            theCase.ContactId = theContact.Id;
            theCase.AccountId = theContact.AccountId;   
            
            if(contacts.size() > 1) {
                // Could create a new Case here to get CS to resolve this....
                theCase.Description = 'Note: there is more than one Contact with this email address. Fix this. ' + theCase.Description;
            }
        }
        
        insertSObject(this.theCase);

    }
    
    if (this.theCase != null) {
    
        createEmailMessage(this.theCase, email);
        handleAttachments(this.theCase, email);
    
    }
    
    return result;
 
}

private String extractRef(String emailSubject)
{

    String itemRef = null;
    String target = emailSubject.toLowerCase();
    String patternString;
    Pattern thePattern;
    Matcher matcher;
     
    /*  Take the text between the period and ":ref"  For example in the ref [ ref:00D7JFzw.5007H3Rh8:ref ] extract 5007H3Rh8
     Take that text and remove the 5007. For example H3Rh8 
     Append H3Rh8 to https://na5.salesforce.com/5007000000  to produce https://na5.salesforce.com/5007000000H3Rh8.   This is your link to get to the case.
    */  
    patternString = '.*ref:(.{8}).(.{4})(.+):ref.*';
    thePattern = Pattern.compile(patternString);
    matcher = thePattern.matcher(emailSubject); // do not change to lower case for this test because Id's are case sensitive
  
    if (matcher.matches()) 
    {
        String caseId = matcher.group(2) + '000000' + matcher.group(3);
        if(TRACE) system.debug(Logginglevel.ERROR,'extractRef "' + caseId + '"');    
            Case[] matchingCases = [Select CaseNumber from Case where Id = :caseId];
            if(matchingCases.size() == 1) {
                Case theCase = matchingCases[0];
            itemRef = theCase.CaseNumber;
            }    
    }
  
 if(itemRef == null) {
  // extract the Case Number from the email Subject
  // Re: Test two numbers Case: 30088 and Case: 30089'
  // returns 30089, the last pattern matched
  patternString = '.*case[;:=]?\\s*([0-9]+).*';
  thePattern = Pattern.compile(patternString);
  matcher = thePattern.matcher(target);
  
  if (matcher.matches()) {
   itemRef = matcher.group(1);
   if(TRACE) system.debug('Extracted case number ' + itemRef); 
  }
 }

 return itemRef; 
}

private Case locateByCaseNumberAsString(String caseNumberStr){
 Integer target = Integer.valueOf(caseNumberStr);
 Case theResult = null;
 String caseNumber = '%' + String.valueOf(target);
 Case[] matchingCases = [Select Id, CaseNumber, Subject, Description from Case where CaseNumber like :caseNumber];
 for(Case aCase: matchingCases) {
  Integer cnum = Integer.valueOf(aCase.CaseNumber);
  if(cnum == target) {
  theResult = aCase;
  break;
  }
 }
 return theResult;
}


private String extractMainSubject(String emailSubject)
{
 if(emailSubject == null || emailSubject.length() < 3)
  return emailSubject;
 String[] prefixes = new String[] {'fw:','re:', 'automatic reply:', 'out of office autoreply:', 'out of office'};  
 String target = emailSubject.toLowerCase();
 for(String prefix: prefixes) {
  Integer index = target.indexOf(prefix); 
  if(index == 0 ){
   String mainSubject = emailSubject.substring(prefix.length(),emailSubject.length());
   return mainSubject.trim();
  }  
 }
 return emailSubject; 
}

private String extractAddress(String inAddress)
{
 String address;
 String patternString;
 Pattern thePattern;
 Matcher matcher;
 patternString = '.*<(.*)>.*';
 thePattern = Pattern.compile(patternString);
 matcher = thePattern.matcher(inAddress);
 if (matcher.matches()) {
  address = matcher.group(1);
  system.debug('Extracted address ' + address); 
 }
 else
 {
  address = inAddress;
  system.debug('Did not match angle-address ' + address);   
 }
 return address;
}

private void insertSObject(sObject obj) {
 try {insert obj;} catch (System.DmlException e) {handleError(e, 'Could not insert obj '+ obj);}
}

private void createEmailMessage(Case theCase, Messaging.InboundEmail email) {
 String value;
 Integer maxlength;
 EmailMessage theEmail = new EmailMessage();
 theEmail.ParentId = theCase.Id;
 theEmail.Incoming = true;
 Schema.DescribeFieldResult F = EmailMessage.HtmlBody.getDescribe();
 //.HtmlBody.getDescribe();
 maxlength = F.getLength();
 theEmail.Subject = limitLength(email.Subject, EmailMessage.Subject.getDescribe().getLength());
 theEmail.MessageDate = datetime.now();
 theEmail.HtmlBody = limitLength(email.htmlBody,EmailMessage.HtmlBody.getDescribe().getLength());  
 theEmail.TextBody = limitLength(email.plainTextBody,EmailMessage.TextBody.getDescribe().getLength());

 /* **** To */
 value = '';
 if(email.toAddresses != null) {
  Boolean seenOne= false;
  for(String to : email.toAddresses) {
   if(seenOne) {
    value += ';\n';
   }
   to  = extractAddress(to);
   system.debug('ToAddress: ' + to);
   value += to;
   seenOne = true;
  }
 }
 theEmail.ToAddress = limitLength(value,EmailMessage.ToAddress.getDescribe().getLength());
 
 /* **** From */
 theEmail.FromName = email.fromName;
 theEmail.FromAddress = email.fromAddress;
 
 /* **** CC */
 value = '';
 if(email.ccAddresses != null) {
  Boolean seenOne= false;
  for(String cc : email.ccAddresses) {
   if(seenOne) {
    value += ';\n';
   }
   cc  = extractAddress(cc);
   system.debug('CcAddress: ' + cc);
   value += cc;
   seenOne = true;
  }
 }
 theEmail.CcAddress = limitLength(value,EmailMessage.CcAddress.getDescribe().getLength()); 
 insertSObject(theEmail);
}

private void handleAttachments(Case theCase, Messaging.InboundEmail email) {
 
 Set<String> listaNameAttachments = new Set<String>();
 if(email.textAttachments!=null && email.textAttachments.size() >0) {
 for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
     listaNameAttachments.add(tAttachment.fileName);
 }
 }
 
 if(email.binaryAttachments!=null && email.binaryAttachments.size() >0) {
  for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
      listaNameAttachments.add(bAttachment.fileName);
  }
 }
 
 Attachment[] listAttachments = [SELECT Id, Name
                 FROM Attachment
                 WHERE ParentId = :theCase.Id AND Name IN :listaNameAttachments];
                 
 Set<String> SetNameAttachments = new Set<String>();
     if (!listAttachments.isEmpty()) {
         for (Attachment attach : listAttachments) {
             SetNameAttachments.add(attach.Name);
         }
     } 
 
 if (!listAttachments.isEmpty()) {         
 if(email.textAttachments!=null && email.textAttachments.size() >0) {       
  for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
    if (!SetNameAttachments.contains(tAttachment.fileName)) {
    Attachment attachment = new Attachment();  
    attachment.Name = tAttachment.fileName;
    attachment.Body = Blob.valueOf(tAttachment.body);
    attachment.ParentId = theCase.Id;
    insertSObject(attachment);
    }
  }
 }
 }
 
 if (!listAttachments.isEmpty()) {  
 if(email.binaryAttachments!=null && email.binaryAttachments.size() >0) {
  for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
    if (!SetNameAttachments.contains(bAttachment.fileName)) {
    Attachment attachment = new Attachment();
    attachment.Name = bAttachment.fileName;
    attachment.Body = bAttachment.body;
    attachment.ParentId = theCase.Id;
    insertSObject(attachment);
    }
  }
 }
 } 
}


private void handleError(System.DmlException e,  String message){
 String baseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
 if(TRACE)system.debug(baseURL);
 String caseURL;  
 String msg = message + '\n';
 if(this.theCase != null)
 {
  caseURL = baseURL + theCase.Id;
  msg += '\n';
  msg += 'Originating Case Number: ' + theCase.CaseNumber + '  '+ caseURL+'\n';   
 }
 if(this.inboundEmail != null) {
  msg += '\nEmail:';
  msg += '  subject: ' + inboundEmail.Subject + '\n'; 
  msg += '  from: ' + inboundEmail.FromName + '\n'; 
  msg += '  address: ' + inboundEmail.FromAddress + '\n'; 
 }
 if(e != null) { // compose the DmlException message on one line to minimize the number of untested lines.  AFAIK easy to instantiate a DmlException in a unit test. 
  msg += '\n';
  msg += 'EXCEPTION:\n  Error: ' + e.getMessage() + '\n  Type: ' + e.getTypeName() + '\n  Line Number: ' + e.getLineNumber() + '\n  Trace:\n' + e.getStackTraceString() + '\n(end stack trace)\n';
 }

 Case errCase = new Case();
 errCase.OwnerId = this.defaultCaseOwnerId;
 errCase.Status = 'New';
 errCase.Priority = 'Low';
    errCase.Origin = 'Email';
 errCase.Subject = 'Error processing incoming email';
 errCase.Description = limitLength(msg,Case.Description.getDescribe().getLength());
 insert errCase;
 errCase = [Select Id, CaseNumber from Case where Id = :errCase.Id limit 1];  

 caseURL = baseURL + errCase.Id;
 msg += '\n\n';
 msg += 'Created new Case number ' + errCase.CaseNumber + ' for this error.  See: ' + caseURL +'\n'; 

 //TriggerErrorNotification.reportError('CaseEmailInBoundUtilities', msg); 

}


private String limitLength(String input, Integer maxLength)
{
 String results;
 if(input != null && input.length() > maxLength)
  results = input.substring(0,maxLength);
 else 
  results = input;
 return results;
}


}