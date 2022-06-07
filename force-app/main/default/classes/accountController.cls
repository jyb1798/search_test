public with sharing class accountController {
    @AuraEnabled(cacheable=true)
    public static list<Account> getAccounts(string searchkey){
        return [select id, Name, Phone, Industry, AnnualRevenue from Account where Name Like : '%A' + searchkey + '%'];
}

    @AuraEnabled(cacheable=true)
    public static list<Contact> getContacts(string searchkey){
        return [select id, Name, Phone, Email,  Title, Fax from Contact where Name Like : '%' + searchkey + '%'];
    }
}