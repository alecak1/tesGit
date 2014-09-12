public class ArlanTT_SiteLoginController {

    public String username {get; set;}
    public String password {get; set;}

    public ArlanTT_SiteLoginController() { }
    
    public PageReference login() {
    
        try {
            
            String user = username ;
            String pass = password;
            
            if (user == null || user == '' || 
                pass == null || pass == '') {
            
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Combinazione di username e password non corretta.'));
                return null;
                
            }
            
            List<Contact> contacts = [SELECT Id 
                                FROM Contact
                                WHERE ArlanTT_Username__c =: user AND ArlanTT_Password__c =: pass];
            
            if (contacts != null && contacts.size() == 1) {
            
                return new PageReference('/apex/ArlanTT_Submit_Form_Page?contact=contact.Id');
            
            } else {
            
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Combinazione di username e password non corretta.'));
                return null;
                
            }
            
        } catch (Exception ex) {
        
            ApexPages.addMessages(ex);
            System.debug('Exception occured '+ex.getMessage());
        
        }
        
        return null;
           
    }
    
}