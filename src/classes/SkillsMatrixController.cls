public with sharing class SkillsMatrixController {

  public String selectedResourceId { get; set; }
  public Boolean isEditable { get; private set; }
  public Resource__c selectedResource { get; private set; }
  public List<Skill__c> selectedSkills { get; private set; }
  public String selectedSkillType { get; set; }
  
  public List<SelectOption> getResourceOptions() {
  	List<SelectOption> options = new List<SelectOption>();
  	options.add(new SelectOption(
  	  '', '-- Select Resource --'));
  	List<Resource__c> resources = [ SELECT Id, Name
  	  FROM Resource__c ORDER BY Contact__r.LastName ];
    for (Resource__c resource : resources) {
      options.add(new SelectOption(resource.Id,
        resource.Name));      
    }
    return options;
  }
  
  public PageReference refresh() {
  	if (selectedResourceId == null) {
      addError('Select a resource');
      return null;
  	}

  	selectedResource = [ SELECT Id, Name,
        User__r.UserRoleId,
        User__r.ProfileId,
        (SELECT Type__c, Rating__c, LastModifiedDate
          FROM Skills__r ORDER BY Rating__c DESC)
        FROM Resource__c
        WHERE Id = :selectedResourceId
        LIMIT 1 ];
    
    Set<String> skillTypes = new Set<String>();
    selectedSkills = new List<Skill__c>();
    for (Skill__c skill : selectedResource.Skills__r) {
      skillTypes.add(skill.Type__c);
      selectedSkills.add(skill);
    }
    Schema.DescribeFieldResult field = Skill__c.Type__c.getDescribe(); 
    String picklistValue = null;
    for (Schema.PicklistEntry entry : field.getPicklistValues()) {
      picklistValue = entry.getLabel();
      if (!skillTypes.contains(picklistValue)) {
        selectedSkills.add(
          new Skill__c(Resource__c = selectedResource.Id,
            Type__c = picklistValue));
      }
    }
    
    if (isManager()) {
       isEditable = true;
    } else {
      Resource__c userResource = getCurrentUserResource();
      isEditable = 
        selectedResource != null && userResource != null
        && selectedResource.Id == userResource.Id;
    }
  	return null;
  }

  private void addError(String msg) {
    ApexPages.addMessage(new ApexPages.Message(
      ApexPages.Severity.ERROR, msg));
  }

  private void addInfo(String msg) {
    ApexPages.addMessage(new ApexPages.Message(
      ApexPages.Severity.INFO, msg));
  }

  public Resource__c getCurrentUserResource() {
    List<Resource__c> userResource = [ SELECT Id, Name,
      User__r.UserRoleId, User__r.ProfileId
      FROM Resource__c
      WHERE User__c = :UserInfo.getUserId()
      LIMIT 1 ];
    if (userResource.size() == 0) {
      addError('No resource associated with user');
      return null;
    } else {
      return userResource.get(0);  	
    }
  }
  
  private Boolean isManager() {
    List<Profile> profiles = [ SELECT Id FROM Profile WHERE Name IN (
  	  'Project Manager', 'Vice President', 'System Administrator') 
      AND Id = :UserInfo.getProfileId() LIMIT 1 ];
  	return profiles.size() == 1;
  }
  
  public PageReference save() {
  	try {
      upsert selectedSkills;
      addInfo('Changes saved');
  	} catch(DmlException e) {
      addError('Could not save changes: ' +e.getMessage());
  	}
  	return null;
  }

  public PageReference refreshCompareSkills() {
  	return null;
  }
}