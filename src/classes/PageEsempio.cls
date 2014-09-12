public class PageEsempio {
      public List<Account> listaccount {get; set;}
      
      public PageEsempio(){
            this.listaccount=new List<Account>();
            this.filter();
      } 
      
    public void filter(){
            this.listaccount = [SELECT Id, Name FROM Account a];
      }
      
    public void dmlAction() {
            Account a = new Account();
            a.Name = 'carllooo';
            insert a;
    }
}