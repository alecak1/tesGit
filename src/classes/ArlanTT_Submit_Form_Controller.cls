public class ArlanTT_Submit_Form_Controller {

    private Case caseObj;
    
    public ArlanTT_Submit_Form_Controller(ApexPages.StandardController stdController) {
        this.caseObj = (Case) stdController.getRecord();
    }
    
    public PageReference submitCase() {
    
        try {
                
            // Specify DML options to ensure the assignment rules are executed
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;
            caseObj.setOptions(dmlOpts);
            
            // Insert the case
            INSERT caseObj;
            return new PageReference('/thanks');
        
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
            
    }

}