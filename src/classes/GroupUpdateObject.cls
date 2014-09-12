public with sharing class GroupUpdateObject {

    static final String PROFILE_PAGE = '/_ui/core/userprofile/UserProfilePage?u=';
    static final String GROUP_PAGE = '/_ui/core/chatter/groups/GroupProfilePage?g=';

    public GroupUpdateObject(){}
    
    public GroupUpdateObject(String fromName, String fromId, String toName, String toId, String message){
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
    
    public String getFromLink(){
        return PROFILE_PAGE + fromId;
    }
    
    public String getToLink(){
        return GROUP_PAGE + toId;
    }
    
    public String getJSON(){
        return 'feed= { "fromName": "' + fromName + '", "fromId": "'+ PROFILE_PAGE + fromId +'" , "toName" : "' + toName + '", "toId" : "' + GROUP_PAGE + toId +'", "message" : "' + message + '" }';
    }
}