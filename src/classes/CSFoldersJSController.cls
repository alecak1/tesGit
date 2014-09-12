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

public with sharing class CSFoldersJSController {

    public String lastid {get;set;}
    public Collaboration_Space__c cs {get;set;}
    public List<Collaboration_Space_Folder__c> folders {get;set;}
    public List<Collaboration_Space_Item__c> items {get;set;}
    
    
    public CSFoldersJSController(Apexpages.Standardcontroller con){
        this.cs = (Collaboration_Space__c)con.getRecord();
        //get the node parameter (if it exists)
        String node = System.currentPageReference().getParameters().get('node');
        //if node = root, the root tree needs to be build, just find the folders under the collaboration space
        if(node == 'root') {
            folders = [Select c.Name, c.LastModifiedDate, c.Id, c.Collaboration_Space__c From Collaboration_Space_Folder__c c where c.Collaboration_Space__c = :cs.Id];
            if(folders != null && folders.size() > 0) this.lastid = folders.get(folders.size() -1).Id;
        }
        //if there's a node id, we want to find records in the folders
        else {
            items = [Select c.Salesforce_Record__c, c.Name, c.Link__c, c.LastModifiedDate, c.Id, c.Collaboration_Space_Folder__c From Collaboration_Space_Item__c c where c.Collaboration_Space_Folder__c =:node];
            if(items != null && items.size() > 0) this.lastid = items.get(items.size() -1).Id;
        }
    }

}