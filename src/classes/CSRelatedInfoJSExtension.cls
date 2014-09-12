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

public with sharing class CSRelatedInfoJSExtension {
public Collaboration_Space__c collaborationspace;

    public List<ChatterDocument> chatterdocuments {get;set;}
    public List<ChatterLink> chatterlinks {get;set;}
    public List<User> followers {get;set;}
    public List<Task> tasks {get;set;}
    public List<Event> meetings {get;set;}
    public List<Collaboration_Space_Item__c> groups {get;set;}
    
    //we need to know which id is the last in the list to make sure we can stop outputting ',' in the JSON feed
    public String lastfollowerid {get;set;}     
    public String lastdocumentid {get;set;}
    public String lastlinkid {get;set;}
	public String lastmeetingid {get;set;}
    public String lasttaskid {get;set;}
    public String lastgroupid {get;set;}
    
	//constructor
	public CSRelatedInfoJSExtension(Apexpages.StandardController con) {
        this.collaborationspace = (Collaboration_Space__c)con.getRecord();
       
        //get all the information the UI needs.
        getFeedLinksAndDocuments();
        getFollowers();
        getMeetings();
        getTasks();
        getGroups();
    }

	/*****************************************************************
								DOCUMENTS & LINKS
	******************************************************************/	
	
	//get the chatter content post and link post information
    public void getFeedLinksAndDocuments() {
    	List<Collaboration_Space__Feed> feedposts = [SELECT Id, Type, 
                CreatedById, CreatedBy.FirstName, CreatedBy.LastName,
                ParentId, Parent.Name, 
                FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.ContentDescription, FeedPost.LinkUrl
            FROM Collaboration_Space__Feed
            WHERE 
                ParentId = :collaborationspace.Id AND
                (Type = 'ContentPost' OR Type = 'LinkPost')
            ORDER BY CreatedDate DESC LIMIT 200];
        
        chatterdocuments = new List<ChatterDocument>();
        chatterlinks = new List<ChatterLink>();
        
        for(Collaboration_Space__Feed csf:feedposts) {
        	if(csf.Type == 'ContentPost') {
        		ChatterDocument cd = new ChatterDocument();
	            cd.id = csf.FeedPostId;
	            if(csf.FeedPost.Title != null) cd.filename = String.escapeSingleQuotes(csf.FeedPost.Title);
	            if(csf.FeedPost.ContentDescription != null) cd.description = String.escapeSingleQuotes(csf.FeedPost.ContentDescription);
	            chatterdocuments.add(cd);
        	}
        	else if(csf.Type == 'LinkPost') {
        		ChatterLink cl = new ChatterLink();
	            cl.id = csf.FeedPostId;
	            cl.title = String.escapeSingleQuotes(csf.FeedPost.Title);
	            cl.link = String.escapeSingleQuotes(csf.FeedPost.LinkUrl);
	            chatterlinks.add(cl);
        	}
        }
        
        if(chatterdocuments.size() > 0) lastdocumentid = chatterdocuments.get(chatterdocuments.size()-1).Id;
        if(chatterlinks.size() > 0) lastlinkid = chatterlinks.get(chatterlinks.size()-1).Id;
    }
    
	/*****************************************************************
								MEMBERS
	******************************************************************/

    
    //gets the followers for this collaboration space
    public void getFollowers() {
        //Get the subscribers
        List<EntitySubscription> subs = [Select e.Subscriber.Email, e.Subscriber.Name, e.Subscriber.Id, e.SubscriberId, e.ParentId, e.Id From EntitySubscription e where ParentId = :collaborationspace.Id];
        //copy the users
        followers = new List<User>();
        for(EntitySubscription e:subs) {
            User u = e.Subscriber;
            followers.add(u);
        }
        if(followers.size() > 0) lastfollowerid = followers.get(followers.size()-1).Id;
    }
    
	/*****************************************************************
								COLLABORATION GROUPS
	******************************************************************/    
	
	//gets the related collaboration groups
	public void getGroups() {
		//get the prefix for CollaborationGroup objects
		String groupprefix = CollaborationGroup.sObjectType.getDescribe().getKeyPrefix();
		List<Collaboration_Space_Item__c> allitems = [Select c.Name, c.Id, c.Salesforce_Record__c, c.Collaboration_Space_Folder__r.Name, c.Collaboration_Space_Folder__r.Collaboration_Space__r.Name, c.Collaboration_Space_Folder__c From Collaboration_Space_Item__c c where c.Collaboration_Space_Folder__r.Collaboration_Space__c = :collaborationspace.Id];
		//leave only the CollaborationGroup records
		groups = new List<Collaboration_Space_Item__c>();
		for(Collaboration_Space_Item__c csi:allitems) {
			if(csi.Salesforce_Record__c.startswith(groupprefix)) {
				groups.add(csi);
			}
		}
		if(groups.size() > 0 ) lastgroupid = groups.get(groups.size()-1).Id;		
	}    

	/*****************************************************************
								TASKS
	******************************************************************/

    //get the tasks
    public void getTasks() {
        tasks = new List<Task>();
        tasks = [Select t.WhatId, t.Subject, t.Id, t.ActivityDate From Task t where t.WhatId =:collaborationspace.Id order by t.ActivityDate desc];
        if(tasks.size() > 0) lasttaskid = tasks.get(tasks.size()-1).Id; 
    }

	/*****************************************************************
								MEETINGS
	******************************************************************/
    
    //get the meetings
    public void getMeetings() {
        meetings = new List<Event>();
        meetings = [Select e.WhatId, e.Subject, e.StartDateTime, e.Id, e.ActivityDate From Event e where e.WhatId =:collaborationspace.Id order by e.ActivityDate desc];
        if(meetings.size() > 0) lastmeetingid = meetings.get(meetings.size()-1).Id; 
    }    
    
    /**
    HELPER CLASSES AND METHODS
    
    **/
    
    

    
    public class ChatterDocument {
        public String id {get;set;}
        public String filename {get;set;}
        public String description {get;set;}
    }
    
    public class ChatterLink {
        public String id {get;set;}
        public String title {get;set;}
        public String link {get;set;}
    }

}