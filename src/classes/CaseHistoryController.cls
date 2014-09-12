public with sharing class CaseHistoryController {

  public List<CaseHistoryItem> CHIlist  {get; set;}
  public Case aCase                     {get; set;}
  public String caseID                  {get; set;}
  public List<Task> tasks               {get; set;}
  public boolean showAll                {get; set;}
  public Set<String> prefixSet          {get; set;}
  
  public CaseHistoryController(){
    CHIlist= new List<CaseHistoryItem>();
    caseId = Apexpages.currentPage().getParameters().get('id'); 
    if (caseId == null || caseId == '')
 	{
 		return;
 	}
	
 	aCase = [select CaseNumber, Account.Name, AccountId, Subject, Contact.Name, ContactId,
    (Select Id, CreatedById, CreatedBy.Name, WhatId, What.Name, Subject, ActivityDate, Status, OwnerId, Description, CreatedDate, Owner.Name From Tasks),
    (Select Id, CreatedDate, CreatedBy.Name, CreatedById, CommentBody From CaseComments),
    (Select Id, CreatedById, CreatedBy.Name, CreatedDate, Field, OldValue, NewValue From Histories),
    (Select Id, CreatedById, CreatedBy.Name, CreatedDate, TextBody, Subject, FromName, ToAddress, MessageDate From EmailMessages) 
    from Case where id = :caseID];
    

    
    setupTasks(aCase);
    setupCaseComments(aCase);
    setupHistories(aCase);
    setupEmails(aCase);
    //sortByCreateDate();
  }
  

    
  public void setupHistories(Case c){
    List<CaseHistory> cHistories = c.Histories;
    String subject;
    String oldVal;
    String newVal;
  
    for (CaseHistory ch:cHistories){      
      if(ch.OldValue==null&&ch.NewValue==null)
        subject = ch.Field+'--Modified, or Created';
      else if(ch.OldValue==null)
         subject = ch.Field+' changed or set to '+newVal;
      else if(ch.newValue==null)
         subject = ch.Field+' changed or set to '+oldVal;
      else{
        subject = ch.Field+' changed from '+oldVal+' to '+newVal;
      }
      
      
      if(subject!=null)
        CHIlist.add(new CaseHistoryItem(ch.CreatedDate, subject, ch.CreatedBy.Name, ch.CreatedById, null, 'History', null, null, null, null));
      }
    }

   public void setupEmails(Case c){
    List<EmailMessage> emailMessages=c.EmailMessages;
    String subject='';
    for(EmailMessage em:emailMessages){
     subject='On '+em.MessageDate.format('MM/d/yyyy')+' '+em.FromName+' wrote to '+em.ToAddress+'--'+em.Subject+'--'+em.TextBody;
     CHIlist.add(new CaseHistoryItem(em.CreatedDate, subject, em.CreatedBy.Name, em.CreatedById,  null, 'Email', null, null, null, null));
    }
  }
  

  public void setupCaseComments(Case c){
    List <CaseComment> cComments = c.CaseComments;
    for(CaseComment cc: cComments){
      CHIlist.add(new CaseHistoryItem(cc.CreatedDate, cc.CommentBody, cc.CreatedBy.Name, cc.CreatedById, null,'Comment', null, null, null, null));
    }
  }
  
  public void setupTasks(Case c){
    tasks = c.Tasks;
    for (task t: tasks){
    	if(t.Subject != 'Email')
        CHIlist.add(new CaseHistoryItem(t.CreatedDate, t.Subject, t.CreatedBy.Name, t.CreatedById, t.Id, 'Activity', t.ActivityDate, t.Owner.Name, '--  '+t.Description, t.OwnerId));
    }   
  }

  
  
  public Class CaseHistoryItem{
    public Datetime createdDate   {get; set;}
    public Date dueDate           {get; set;}
    public String subject         {get; set;}
    public String createdName     {get; set;} 
    public String createdId       {get; set;}
    public String mainId          {get; set;}
    public String itemType        {get; set;}
    public boolean isActivity     {get; set;}
    public String createDateFix   {get; set;}
    public String dueDateFix      {get; set;}
    public String subjectSort     {get; set;}
    public String ownerName       {get; set;}
    public String taskDescription {get; set;}
    public String ownerId         {get; set;}
    public String itemTypeName    {get; set;}
    
    CaseHistoryItem(Datetime aCreateDate, String aSubject, String aCreatedName, String aCreatedId,  String aMainId, String aType, Date aDueDate, String aOwnerName, String aTaskDesc, String aOwnerId){
      createdDate=aCreateDate;
      createDateFix=createdDate.format('MM/d/yyyy -- h:mm a');
      subject=aSubject;
      createdName=aCreatedName;
      createdId=aCreatedId;
      mainId=aMainId;
      itemType=getTypeImageMap(aType);
      itemTypeName=aType;
      dueDate=aDueDate;
      if(dueDate!=null){
        isActivity=true;
        dueDateFix=dueDate.format(); 
      }
      else 
        isActivity=false;
      ownerName=aOwnerName;
      taskDescription=aTaskDesc;
      ownerId=aOwnerId;
    }
    
    //this needs to be updated.
    private String getTypeImageMap(String aType){
      if (aType=='History')
        return 'history.png';
      else if(aType=='Comment')
        return 'comment.gif';
      else if(aType=='Email')
        return 'mail.png';
      else
        return 'activity.png';
    }
  }

  static testMethod void testCaseHistoryController() {
   //create a new case

  	
  	System.Test.startTest();
   	Case c = new Case();
  	c.origin='sample1';
  	insert c;
  	
  	Task t = new Task();
  	t.WhatId = c.Id;
  	t.ActivityDate = Date.today();
  	insert t; 	
  	  	
  	CaseComment cc = new CaseComment();
  	cc.parentId = c.id;
  	insert cc;


	EmailMessage em = new EmailMessage();
	em.parentId = c.id;
	em.MessageDate = Date.today();
	em.FromAddress = 'test@from.com';
	em.ToAddress = 'test@to.com';
	em.Subject = 'test subject';
	em.TextBody = 'heres a text body.';
	insert em;

  	
   ApexPages.currentPage().getParameters().put('id', c.id );
   CaseHistoryController CHC = new CaseHistoryController();

	System.assert(CHC.caseID != null);

	System.assert(CHC.CHIList.size() == 3);

	
	System.assert(CHC.CHIList.get(0).itemType=='activity.png');
   
   
   
   System.debug('TESTS ENDED');
  }
  
  static TestMethod void testNoId() {
  	
    CaseHistoryController CHC = new CaseHistoryController();

	System.assert(CHC.caseID == null);
  	
  }
}