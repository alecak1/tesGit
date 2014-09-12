global class HelloStatefulBatchApex
  implements Database.Batchable<SObject>, Database.Stateful {
  Integer count = 0;
  global Database.QueryLocator start(Database.BatchableContext context) {
    System.debug('start: ' + count);
    return Database.getQueryLocator([select Name from Proj__c order by Name]);
  }
  global void execute(Database.BatchableContext context, List<SObject> scope) {
    System.debug('execute: ' + count);
    for(SObject rec : scope) {
      Proj__c p = (Proj__c)rec;
      System.debug('Project ' + count + ': ' + p.Name);
      count++;
    }
  }
  global void finish(Database.BatchableContext context) {
    System.debug('finish: ' + count);
  }
}