public with sharing class StarRatingController {
 public integer rating {get;set;}
 public List<SelectOption> listOfRatingOptions {get;set;}
 public StarRatingController(ApexPages.StandardController controller){
  listOfRatingOptions = new List<SelectOption>();
  rating = 3;
  string val = '';
  for(integer i=1;i<=5;i++){
   val = string.valueOf(i);
   listOfRatingOptions.add(new SelectOption(val,val));
  }
 }
}