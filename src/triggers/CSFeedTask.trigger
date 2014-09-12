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

trigger CSFeedTask on Task (after insert, after update) {

    //not for bulk uploads, we don't want to flood chatter messages
    if(Trigger.new.size() > 1) return;
    
    for(Task t:Trigger.new) {
        //if not related to anything or not to a collaboration space, stop here.
        if(t.WhatId == null) continue;
        String relatedobject = CSUtil.getObjectType(t.WhatId);
        if(relatedobject != 'Collaboration_Space__c') continue;
        
        //now that we know this event is related to a collaboration space, let's chat about it
        FeedPost fpost = new FeedPost();
        fpost.ParentId = t.WhatId;
        
        //extra query to get the owner name
        Task tx = [select Id, Subject, ActivityDate, Owner.Name from Task where Id =:t.Id];
        
        if(Trigger.isInsert) fpost.Body = 'has added a task \'' + tx.Subject + '\'' + ' for '+ tx.Owner.Name;
        if(Trigger.isUpdate) fpost.Body = 'has updated the task \'' + tx.Subject + '\'' + ' for '+ tx.Owner.Name;
        
        if(tx.ActivityDate != null) fpost.Body +=  ', due on ' + tx.ActivityDate.format();
        
        
        insert fpost;
    }

}