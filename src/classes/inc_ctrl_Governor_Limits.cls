public with sharing class inc_ctrl_Governor_Limits {
    
    public Integer getQueries() { return Limits.getQueries(); }
    public Integer getLimitQueries() { return Limits.getLimitQueries(); }
    public Decimal getQueryPerc() { return (Decimal.valueOf(getQueries()) / Decimal.valueOf(getLimitQueries())) * 100; }
    
    public Integer getQueryRows() { return Limits.getQueryRows(); }
    public Integer getLimitQueryRows() { return Limits.getLimitQueryRows(); }
    public Decimal getQueryRowsPerc() { return (Decimal.valueOf(getQueryRows()) / Decimal.valueOf(getLimitQueryRows())) * 100; }
    
    public Integer getDmlStatements() { return Limits.getDmlStatements(); }
    public Integer getLimitDmlStatements() { return Limits.getLimitDmlStatements(); }
    public Decimal getDmlStatementsPerc() { return (Decimal.valueOf(getDmlStatements()) / Decimal.valueOf(getLimitDmlStatements())) * 100; }
    
    public Integer getDmlRows() { return Limits.getDmlRows(); }
    public Integer getLimitDmlRows() { return Limits.getLimitDmlRows(); }
    public Decimal getDmlRowsPerc() { return (Decimal.valueOf(getDmlRows()) / Decimal.valueOf(getLimitDmlRows())) * 100; }
    
    public Integer getScriptStatements() { return Limits.getScriptStatements(); }
    public Integer getLimitScriptStatements() { return Limits.getLimitScriptStatements(); }
    public Decimal getScriptStatementsPerc() { return (Decimal.valueOf(getScriptStatements()) / Decimal.valueOf(getLimitScriptStatements())) * 100; }
}