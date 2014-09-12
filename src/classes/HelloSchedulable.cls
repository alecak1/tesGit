global class HelloSchedulable implements Schedulable {
  global void execute(SchedulableContext sc) {
    HelloBatchApex batch = new HelloBatchApex(); 
    Database.executeBatch(batch);
  }
}