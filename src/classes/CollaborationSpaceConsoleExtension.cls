//  Copyright (c) 2010, David Van Puyvelde, Sales Engineering, Salesforce.com Inc.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//  Neither the name of the salesforce.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

public with sharing class CollaborationSpaceConsoleExtension {

    public Collaboration_Space__c collaborationspace;
  
    public String csfolderprefix {get;set;}
      
    public String message {get;set;}
    public String messagetype {get;set;} //ERROR INFO WARNING are good values. This will be used by ext.js
    

    public CollaborationSpaceConsoleExtension(Apexpages.StandardController con) {
        this.collaborationspace = (Collaboration_Space__c)con.getRecord();
        this.csfolderprefix = Collaboration_Space_Folder__c.sObjectType.getDescribe().getKeyPrefix();
     }
    
    
    //detaches the selected record from this collaboration space
    public PageReference detachRecord() {
        //get the id of the collaboration space item that needs to be deleted
        String sfid = System.currentPageReference().getParameters().get('sfid');
        System.Debug('*********************************** Id to delete ' + sfid);
        Collaboration_Space_Item__c csi;
        
        //message = 'Some message from the controller';
        try {
            csi = new Collaboration_Space_Item__c(Id = sfid);
            messagetype = 'INFO';
            message = 'Record has been detached';
            delete csi;
        }
        catch(Exception ex) {
            messagetype = 'ERROR';
            message = 'Could not detach record : ' + ex.getMessage();
        }
        
        return null;
    }
    
    //delete a folder
    public PageReference deleteFolder() {
        //get the id of the collaboration space item that needs to be deleted
        String sfid = System.currentPageReference().getParameters().get('sfid');
        Collaboration_Space_Folder__c f;
        
        //message = 'Some message from the controller';
        try {
            f = new Collaboration_Space_Folder__c(Id = sfid);       
            messagetype = 'INFO';
            message = 'Folder has been deleted';
            delete f;
        }
        catch(Exception ex) {
            messagetype = 'ERROR';
            message = 'Could not delete folder : ' + ex.getMessage();
        }
        
        return null;
    }

}