global class ProjectIterable implements Iterator<Proj__c>, Iterable<Proj__c> {
  List<Proj__c> projects { get; set; }
  Integer i;
  public ProjectIterable() { 
    projects = [select Name from Proj__c order by Name ];
    i = 0; 
  }
  global Boolean hasNext() {
    if (i >= projects.size()) {
      return false;
    } else {
      return true; 
    }
  } 
  global Proj__c next() {
    i++;
    return projects[i-1]; 
  }
  global Iterator<Proj__c> Iterator() {
    return this;
  }
}