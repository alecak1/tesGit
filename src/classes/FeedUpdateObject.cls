public with sharing class FeedUpdateObject {

    static final String PROFILE_PAGE = '/_ui/core/userprofile/UserProfilePage?u=';

    public FeedUpdateObject(){}
    
    public FeedUpdateObject(String fromName, String fromId, String toName, String toId, String message){
        this.fromId = fromId;
        this.toId = toId;
        this.fromName = fromName;
        this.toName = toName;
        this.message = message;
    }
    
    public String fromName {get; set;}
    public String fromId {get; set;}
    
    public String toName {get; set;}
    public String toId {get; set;}

    public String message{get; set;}

    public boolean getIsStatusUpdate(){
        return fromId == toId;
    }
    
    public boolean getIsFeedPost(){
        return fromId != toId;
    }
    
    public String getFromLink(){
        return PROFILE_PAGE + fromId;
    }
    
    public String getToLink(){
        return PROFILE_PAGE + toId;
    }
    
    public String getJSON(){
        return 'feed = { "fromName": "' + escape(fromName) + '", "fromId": "'+ PROFILE_PAGE + escape(fromId) +'" , "toName" : "' + escape(toName) + '", "toId" : "' + PROFILE_PAGE + escape(toId) +'", "message" : "' + escape(message) + '" }';
    }
    
    public String escape(String s){
        return s.replace('"',''); 
    }
}