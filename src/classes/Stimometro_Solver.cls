public with sharing class Stimometro_Solver {
	private List<Espressione__c> exps_list;
	public string dbgg;
	public string vartest {get;set;}
	public List<Espressione__c> names;
	public Map<string,double> parameters;

	public void save() {
		apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'oh: '+vartest));

	}

	public Stimometro_Solver(ApexPages.StandardController controller) {
		vartest = '1';
		names = new List<Espressione__c>();
		parameters = new Map<string,double>();
		dbgg='';
		exps_list = [SELECT CreatedById,Name,CreatedDate,Espressione_Madre_Name__c,Espressione_Madre__c,Id,IsDeleted,LastModifiedById,LastModifiedDate,Operatore__c,OwnerId,SystemModstamp,Valore__c,Variabile__c,Versione__c FROM Espressione__c ORDER BY Name];
		system.debug(exps_list);
	}

	public List<Espressione__c> getSons(Espressione__c e) {
		List<Espressione__c> tmp = new List<Espressione__c>();
		for (Espressione__c x: exps_list)
			if (e.Name == x.Espressione_madre_name__c)
				tmp.add(x);
		return tmp;
	}

	public double solve(Espressione__c e) {
		//è non terminale
		if (e.Operatore__c != null) {
				List<Espressione__c> exps = getSons(e);
				Double tmp = solve(exps.get(0));
				exps.remove(0);
				for (Espressione__c x: exps) {
					double tmp_one = solve(x);
					if (e.Operatore__c == '+')
						tmp = tmp + tmp_one;
					if (e.Operatore__c == '-')
						tmp = tmp - tmp_one;
					if (e.Operatore__c == 'x')
						tmp = tmp * tmp_one;
					if (e.Operatore__c == ':')
						tmp = tmp / tmp_one;
				}
				return tmp;
		}
		//è variabile
		if (e.Variabile__c != null) return parameters.get(e.Variabile__c);
		//è terminale
		if (e.Valore__c != null) return e.Valore__c;
		return 0;

	}

	public void findParameters(Espressione__c e) {
		if (e.Operatore__c != null)
				for (Espressione__c x: getSons(e)) findParameters(x);
		if (e.Variabile__c != null) {
			parameters.put(e.Variabile__c,0);
		}
	}

	// Serve update dopo
	public string assignNames(Espressione__c e) {
		//è non terminale
		if (e.Operatore__c != null) {
				string tmp='';
				List<Espressione__c> exps = getSons(e);
				tmp = tmp+'(';
				for (Espressione__c x: exps) {
					tmp = tmp+''+assignNames(x)+''+e.Operatore__c;
				}
				tmp = tmp.substring(0,tmp.length()-1);
				tmp = tmp+')';
				e.stringa_espressione__c = tmp;
				names.add(e);
				return tmp;
		}

		//è terminale
		if (e.Valore__c != null) {
			e.stringa_espressione__c = string.valueof(e.Valore__c);
			names.add(e);
			return e.stringa_espressione__c;
		}

		//è variabile
		if (e.Variabile__c != null) {
			e.stringa_espressione__c = e.Variabile__c;
			names.add(e);
			return e.stringa_espressione__c;
		}

		return null;
	}



}