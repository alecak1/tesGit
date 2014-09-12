public with sharing class FollowProjectControllerExtension {
  private ApexPages.StandardController controller;
  public FollowProjectControllerExtension(
    ApexPages.StandardController stdController) {
      this.controller = stdController;
  }    
  public PageReference followProject() {
    Id currentUserId = UserInfo.getUserId();
    Set<Id> userIds = new Set<Id>();
    for (List<Assignment__c> assignments : [ select Resource__r.User__c from Assignment__c where
         Project__c = :controller.getRecord().Id ]) {
     for (Assignment__c assignment : assignments) {
        Id uid = assignment.Resource__r.User__c;
        if (currentUserId != uid && uid != null) {
          userIds.add(uid);
        }
      }
    }
    if (userIds.size() == 0) {
        error('Project has no assignments.');
        return null;
    }
    Set<String> subs = new Set<String>();
    for (List<EntitySubscription> recs : [ select ParentId from EntitySubscription where SubscriberId = :currentUserId 
      and ParentId in :userIds ]) {
      for (EntitySubscription rec : recs) {
        subs.add(rec.ParentId);
      }
    }

    Integer followCount = 0;
    List<EntitySubscription> adds = new List<EntitySubscription>();
    for (Id userId : userIds) {
        if (!subs.contains(userId)) {
          adds.add(new EntitySubscription(ParentId = userId, SubscriberId = currentUserId));
          followCount++;
        }
      }
    insert adds;
    info(followCount + ' users followed');
    return null;
  }

  private static void info(String text) {
    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, text);
    ApexPages.addMessage(msg);
  } 
  private static void error(String text) {
    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, text);
    ApexPages.addMessage(msg);
  } 
}