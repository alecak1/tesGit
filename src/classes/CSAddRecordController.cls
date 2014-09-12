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

public with sharing class CSAddRecordController {

    //Map that holds all the object names and tokens in your org
    Map<String, Schema.SObjectType> gd;
    //List with just these tokens
    public List<SObjectType> tokens = new List<SObjectType>();
    public List<String> objectlabels {get;set;}
    public List<SelectOption> objectSelectOptions {get;set;}
    public SObjectType sot {get;set;} //holds the selected object's token
    
    public String selectedObject {get;set;} //holds the name of the selected SObject, bound to the SelectList
    public String selectedObjectLabel {get;set;} //holds the label of the selected SObject
    
    public List<SearchResult> searchresults {get;set;}
    
    public String searchterm {get;set;}
    public String folderid {get;set;}
    public String foldername {get;set;}
    public String spaceid {get;set;}
    
    public CSAddRecordController() {
        //get the foldername and id from url params
        folderid = System.currentPageReference().getParameters().get('folderid');
        foldername = System.currentPageReference().getParameters().get('foldername');
        spaceid = System.currentPageReference().getParameters().get('spaceid');
        
        //get a full list of all objecttokens
        gd = Schema.getGlobalDescribe();
        
        tokens = gd.values(); //get the tokens from this map
        objectlabels = new List<String>();
        List<Selectoption>objectSelectOptionsUnsorted = new List<SelectOption>();
        
        
        //get the tokens from the global describe map and drop their names and labels in the drop down list
        for(SObjectType s:gd.values()) {
            //don't add all objects to the list (there's a lot of internal objects that user's don't need or can use)           
            if(!acceptedObject(s)) continue;
            
            objectlabels.add(s.getDescribe().getLabel());
            SelectOption so = new SelectOption(s.getDescribe().getName(), s.getDescribe().getLabel());
            objectSelectOptionsUnsorted.add(so);            
        }
        objectSelectOptions = CSUtil.sortByLabel(objectSelectOptionsUnsorted);
                
    }
    
    
    //search the records
    public PageReference searchRecords() {
        
        searchresults = new List<SearchResult>();
        
        String sosl = 'FIND \'' + String.escapeSingleQuotes(searchterm) + '*\' IN ALL FIELDS RETURNING '+ String.escapeSingleQuotes(selectedObject) + ' (id, name)';
        if(selectedobject == 'Case') sosl = 'FIND \'' + String.escapeSingleQuotes(searchterm) + '*\' IN ALL FIELDS RETURNING '+ String.escapeSingleQuotes(selectedObject) + ' (id, CaseNumber, Subject)';

        
        try {
            List<List<SObject>> results = Search.query(sosl);

            List<SObject> objectresults = results[0];
            //move these results to the generic
            for(SObject so:objectresults) {
                SearchResult sr = new SearchResult();
                //cases don't have 'Name' fields
                if(selectedobject == 'Case') {
                    sr.id = (String)so.get('Id');
                    sr.name = (String)so.get('CaseNumber') + ': ' + (String)so.get('Subject');
                }
                else {                
                    sr.id = (String)so.get('Id');
                    sr.name = (String)so.get('Name');   
                }                 
                searchresults.add(sr);
            }
        }
        catch(Exception ex) {
            Apexpages.addMessage(new Apexpages.Message(ApexPages.SEVERITY.ERROR, ex.getMessage()));            
        }
        return null;
    }
    
    public PageReference addRecord() {
        String sfid = System.currentPageReference().getParameters().get('sfid');
        //Determine the object type of the id passed to this method     
        String objecttype = CSUtil.getObjectType(sfid);
        String objectlabel = CSUtil.getObjectLabel(sfid);
        
        try {
            String namefield = 'Name';
            if(objecttype == 'Case') namefield = 'CaseNumber, Subject'; //Cases don't have 'Name' fields
            
            //query the object and it's name
            String qry = 'select Id, '+namefield+' from ' + String.escapeSingleQuotes(objecttype) + ' where Id =\'' + String.escapeSingleQuotes(sfid) + '\' limit 1';
            SObject so = Database.query(qry);
            
            String namevalue;
            if(objecttype != 'Case') namevalue = (String)so.get('Name');
            if(objecttype == 'Case') namevalue =  (String)so.get('CaseNumber')+': '+(String)so.get('Subject');
             
            String ncomposite = objectlabel + ' : ' + namevalue;
            //only take the 80 leftmost characters. Name fields are 80chars
            String n ='';
            if(ncomposite.length() > 80) {
            	n = ncomposite.substring(0,80);
            }else {
            	n = ncomposite;
            }
            Collaboration_Space_Item__c csi = new Collaboration_Space_Item__c(Collaboration_Space_Folder__c = folderid, Salesforce_Record__c = sfid, Name=n);
            insert csi;
            
            //add a feedpost
            Collaboration_Space_Folder__c fldr = [Select c.Name, c.Id, c.Collaboration_Space__r.Name, c.Collaboration_Space__r.Id, c.Collaboration_Space__c From Collaboration_Space_Folder__c c where c.Id = :folderid];
            FeedPost fpost = new FeedPost();
            fpost.ParentId = fldr.Collaboration_Space__r.Id;
            fpost.Body = 'has added the ' +objectlabel + ' \'' + namevalue + '\' to the \''+ fldr.Name +'\' folder';
            insert fpost;
            
        }
        catch(Exception ex) {
            Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
    
 
    
    
    
    /**
    Helper methods and classes
    **/
    //method used to clean out all the internal objects we don't want the users to create
    public Boolean acceptedObject(SObjectType s) {
        DescribeSObjectResult r = s.getDescribe();

        //do not accept the collaboration spaces themselves
        if(r.getName().startsWith('Collaboration_Space')) return false;
        //We'll accepted all custom objects
        if(r.isCustom()) return true;
                
        //we're left with just the standard objects, just accept the common ones.
        String acceptedobjects = 'Case Lead Opportunity Account Contact Campaign Document CollaborationGroup';
        if(acceptedobjects.contains(r.getName())) return true;        
        
        //everything else is denied
        return false;
    }
    
    
    //class to hold the generic search result
    public class SearchResult {
        public String id {get;set;}
        public String name {get;set;}
    }
    
}