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

@isTest
private class CSTestUtil {

    private static Collaboration_Space__c c;
    private static Collaboration_Space_Folder__c f;
    private static Account a;
    private static List<Account> accounts;
    private static List<ID> soslAccountResults;
    private static Event e;
    private static Task t;
    private static Case cs;
    private static EntitySubscription es;
    private static FeedPost fp;
    private static FeedPost fp2;

    /**
    TESTS
    **/
    static testMethod void t1() {
        setupData();
        
        
        //test attaching a new related record to the collaboration space (it has a folder set up already)
        Test.setCurrentPage(Page.CSAddRecord);
        
        ApexPages.currentPage().getParameters().put('folderid', f.Id);
        ApexPages.currentPage().getParameters().put('foldername', f.Name);
        ApexPages.currentPage().getParameters().put('spaceid', c.Id);
        
        CSAddRecordController csar = new CSAddRecordController();
        
        //test the search - set the accounts we initialized as the results returned from the SOSL query
        Test.setFixedSearchResults(soslAccountResults);
        csar.searchterm = 'testsosl';
        csar.selectedObject = 'Account';
        csar.searchRecords();
        
        //see if the search found the accounts
        System.assertEquals(csar.searchresults.size(), 20);
        
        //test the search for a Case type
        List<ID> casesresults = new List<ID>();
        casesresults.add(cs.Id);
        Test.setFixedSearchResults(casesresults);
        csar.searchterm = 'testsosl';
        csar.selectedObject = 'Case';
        csar.searchRecords();
        
        //see if it found the case
        System.assertEquals(csar.searchresults.size(), 1);
        
        //search with less than 2 characters, forcing an exception
        csar.searchterm = 'a';
        csar.selectedObject = 'Account';
        csar.searchRecords();
        
        //attach an Account
        System.currentPageReference().getParameters().put('sfid', a.Id);
        csar.addRecord();
                
        //check if it's attached to the folder
        Collaboration_Space_Folder__c ftest = [Select c.Id, (Select Id, Name, Collaboration_Space_Folder__c, Salesforce_Record__c From Collaboration_Space_Items__r) From Collaboration_Space_Folder__c c where c.Id = :f.Id];
        List<Collaboration_Space_Item__c> fitems = ftest.Collaboration_Space_Items__r;
        System.assertEquals(fitems[0].Salesforce_Record__c, a.Id);
        
        //attach a Case
        System.currentPageReference().getParameters().put('sfid', cs.Id);
        csar.addRecord();
                
        //check if it's attached to the folder
        Collaboration_Space_Folder__c ftest2 = [Select c.Id, (Select Id, Name, Collaboration_Space_Folder__c, Salesforce_Record__c From Collaboration_Space_Items__r) From Collaboration_Space_Folder__c c where c.Id = :f.Id];
        List<Collaboration_Space_Item__c> fitems2 = ftest2.Collaboration_Space_Items__r;
        System.debug('****************** Items' + fitems2);
        System.assertEquals(2, fitems2.size());
        
        //add a record with a wrong id, forcing an exception
        System.currentPageReference().getParameters().put('sfid', 'xyzid');
        csar.addRecord();
        
        Test.setCurrentPage(Page.CollaborationSpaceConsole);

        ApexPages.currentPage().getParameters().put('id', c.Id);
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(c);
        CollaborationSpaceConsoleExtension csce = new CollaborationSpaceConsoleExtension(stdcon);
        
        //detach the folder item for the account again
        System.currentPageReference().getParameters().put('sfid', fitems[0].Id);
        csce.detachRecord();
        //check if it's detached
        Collaboration_Space_Folder__c ftest3 = [Select c.Id, (Select Id, Name, Collaboration_Space_Folder__c, Salesforce_Record__c From Collaboration_Space_Items__r) From Collaboration_Space_Folder__c c where c.Id = :f.Id];
        List<Collaboration_Space_Item__c> fitems3 = ftest3.Collaboration_Space_Items__r;
        System.debug(fitems3);
        System.assertEquals(1, fitems3.size()); 
        
        //detach again, now forcing an exception
        System.currentPageReference().getParameters().put('sfid', 'xyz');
        csce.detachRecord();
        System.assert(csce.message != null);
        
        //initally the Ext.js component passes a 'root' node parameter, this needs to give back the folders in this collabspace
        System.currentPageReference().getParameters().put('node', 'root');
        //instantiate the Folder controller
        CSFoldersJSController csfc = new CSFoldersJSController(stdCon);
        
        System.assertEquals(f.Id, csfc.folders[0].Id);
        //when a node is clicked, it's id will be passed
        System.currentPageReference().getParameters().put('node', f.Id);
        CSFoldersJSController csfc2 = new CSFoldersJSController(stdCon);
        //in this folder should still be the case we attached a bit higher
        System.assertEquals(cs.Id, csfc2.items[0].Salesforce_Record__c);
        
        //delete a folder
        System.currentPageReference().getParameters().put('sfid', f.Id);
        csce.deleteFolder();
        //check if it's deleted
        List<Collaboration_Space_Folder__c> folders = [Select c.Name, c.Id, c.Collaboration_Space__c From Collaboration_Space_Folder__c c where c.Collaboration_Space__c = :c.Id];
        System.assertEquals(0, folders.size());
        
        //delete a folder, invoking an exception
        System.currentPageReference().getParameters().put('sfid', 'xyz');
        csce.deleteFolder();
        System.assertEquals('ERROR', csce.messagetype);
    }
    
    
    //test the event and task triggers
    static testMethod public void t2() {
        //create a collaboration space
        Collaboration_Space__c c2 = new Collaboration_Space__c();
        c2.Name = 'collaborationspace for unit test';
        c2.Description__c = 'test';     
        insert c2;
        
        Task ts = new Task();
        ts.Subject = 'test';
        ts.WhatId = c2.Id;
        ts.Status = 'Not Started';
        ts.Priority = 'Normal';
        insert ts;
        
        ts.Subject = 'test2';
        update ts;
        
        Event ev = new Event();
        ev.Subject = 'test';
        ev.StartDateTime = System.now().addDays(1);
        ev.StartDateTime = System.now().addDays(1).addHours(1);
        ev.DurationInMinutes = 60;
        ev.WhatId = c2.Id;
        
        insert ev;
        
        ev.Subject = 'test2';
        update ev;
        
        //check if the new collaboration space now has 4 feeditems
        List<Collaboration_Space__Feed> feed = [Select c.Type, c.Id, c.FeedPost.Body, c.FeedPost.Title, c.FeedPostId From Collaboration_Space__Feed c where c.ParentId =:c2.Id];
        System.assertEquals(4, feed.size());
    }
    
    
    //test the related info extension
    static testMethod public void t3() {
        setupData();
        
        Test.setCurrentPage(Page.CollaborationSpaceConsole);

        ApexPages.currentPage().getParameters().put('id', c.Id);
        
        ApexPages.StandardController stdcon = new ApexPages.StandardController(c);
        //intialize the extension, it will get the followsers, Chatter link posts and document post
        CSRelatedInfoJSExtension csrie = new CSRelatedInfoJSExtension(stdcon);
        
        System.assert(csrie.followers.size() > 0);
        System.assert(csrie.chatterlinks.size() > 0);
        System.assert(csrie.chatterdocuments.size() > 0);
    }
    
    
    static testMethod public void t4() {
		setupData();
		CollaborationGroup cg = new CollaborationGroup();
		cg.Name = 'cs test group';
		cg.CollaborationType = 'Public';
		insert cg;
		
		Collaboration_Space_Item__c csi = new Collaboration_Space_Item__c();
		csi.Collaboration_Space_Folder__c = f.Id;
		csi.Salesforce_Record__c = cg.Id;
		insert csi;
		
		Test.setCurrentPage(Page.CollaborationSpaceConsole);

		ApexPages.currentPage().getParameters().put('id', c.Id);
		
		ApexPages.StandardController stdcon = new ApexPages.StandardController(c);
		CSRelatedInfoJSExtension csrie = new CSRelatedInfoJSExtension(stdcon);
		
		//check if it picked up on the group
		System.assert(csrie.groups.size() > 0);
	}


    static public void setupData() {
        
        //get the Standard User profile
        Profile p = [select id from profile where name='Standard User'];
        //create a user
        User u = new User(alias = 'test123', email='test123@noemail.com',  
             emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',  
             localesidkey='en_US', profileid = p.Id, country='United States',    
             timezonesidkey='America/Los_Angeles', username='test123@noemail.com'); 
         insert u;

        //create a collaboration space
        c = new Collaboration_Space__c();
        c.Name = 'collaborationspace for unit test';
        c.Description__c = 'test';      
        insert c;
        
        //create some folders
        f = new Collaboration_Space_Folder__c();
        f.Name = 'testfolder';
        f.Collaboration_Space__c = c.Id;
        insert f;
        
        //create an account to attach to the folder
        a = new Account();
        a.Name = 'test account';        
        insert a;
        
        //also create a bunch of accounts for the sosl testing
        accounts = new List<Account>();
        for(Integer i=0; i < 20; i++) {
            Account acc = new Account(Name='testsosl'+i, BillingStreet='street'+i, BillingCity='city'+i, BillingPostalCode='zip', BillingCountry='country'+i, BillingState='state'+i, Website='site'+i);
            accounts.add(acc);
        }
        insert accounts;
        
        //create a list of ID's of these accounts, we'll use these for setFixedSearchResults sosl testing
        soslAccountResults = new List<ID>();
        for(Account ac:accounts) {
            soslAccountResults.add(ac.Id);
        }
        
        //create a case
        cs = new Case();
        cs.Subject = 'testsosl case';
        insert cs;
        
        //create a meeting
        e = new Event();
        Datetime now = System.now();
        e.StartDateTime = now.addDays(1);
        e.EndDateTime = now.addDays(1).addHours(1);
        e.ActivityDate  = System.today().addDays(1);
        e.Subject = 'test meeting';
        e.WhatId = c.Id;
        insert e;
        
        //create a task
        t = new Task();
        t.ActivityDate = System.today().addDays(1);
        t.Status = 'Not Started';
        t.Priority = 'Normal';
        t.Subject = 'test task';
        t.WhatId = c.Id;
        insert t;
        
        //subscribe a user to the collaboration space
        es = new EntitySubscription();
        es.ParentId = c.Id;
        es.SubscriberId = u.Id;
        insert es;
        
        //post a link
        fp = new FeedPost();
        fp.Body = 'test body';
        fp.Title = 'test title';
        fp.LinkUrl = 'http://www.testlink.com';
        fp.Type = 'LinkPost';
        fp.ParentId = c.Id;
        insert fp;
        
        //post a document
        fp2 = new FeedPost();
        fp2.Title = 'test title';
        fp2.Type = 'ContentPost';
        fp2.ContentDescription = 'test description';
        fp2.ParentId = c.Id;
        fp2.ContentFileName = 'testfilename.txt';
        fp2.ContentData = Blob.valueOf('ABC');
        insert fp2;
        
        List<Collaboration_Space__c> spaces = [select Id from Collaboration_Space__c limit 10];
        System.assert(spaces.size() > 0);
        
        
    }

}