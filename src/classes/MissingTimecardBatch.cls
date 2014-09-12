global class MissingTimecardBatch implements Database.Batchable<SObject> {
  global Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator([ select Name, Type__c,
	  (select Name, Start_Date__c, End_Date__c
        from Assignments__r where Status__c not in ('Tentative', 'Closed')),
      (select Status__c, Week_Ending__c
        from Timecards__r
      where Status__c in ('Submitted', 'Approved'))
      from Proj__c
    ]);
  }
  global void execute(Database.BatchableContext context,
    List<SObject> scope) {
    List<Missing_Timecard__c> missing = new List<Missing_Timecard__c>();
    for (SObject rec : scope) {
      Proj__c proj = (Proj__c)rec;
      Set<Date> timecards = new Set<Date>();
      if (proj.Assignments__r != null) {
      	for (Assignment__c assign : proj.Assignments__r) {
          if (proj.Timecards__r != null) {
            for (Timecard__c timecard : proj.Timecards__r) {
              timecards.add(timecard.Week_Ending__c);
            }
          }
/** Timecards are logged weekly, so the Week_Ending__c field is always
  * a Saturday. We need to convert an assignment, which can contain an
  * arbitrary start and end date, into a start and end period expressed
  * only in terms of Saturdays. To do this, we use the toStartOfWeek
  * method on the Date object, and then add 6 days to reach a Saturday.
  */
          Date startWeekEnding = assign.Start_Date__c.toStartOfWeek().addDays(6);
          Date endWeekEnding = assign.End_Date__c.toStartOfWeek().addDays(6);
          Integer weeks = 0;
          while (startWeekEnding.addDays(weeks * 7) < endWeekEnding) {
          	Date d = startWeekEnding.addDays(weeks * 7);
          	if (d >= Date.today()) {
              break;
          	}
          	if (!timecards.contains(d)) {
          	  missing.add(new Missing_Timecard__c(
          	    Assignment__c = assign.Id,
          	    Week_Ending__c = d));
          	}
          	weeks++;
          }
      	}
      }
    }
    insert missing;
  }
  global void finish(Database.BatchableContext context) {
  }
}