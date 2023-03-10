//this is test clas
@isTest
public class REST_AccountInfoTest {
    
    public static testMethod void Test1(){
        //this is new chchange
        Account acc = new Account();
        acc.Name = 'TestAccount';
        acc.BillingStreet = 'TestStreet';
        acc.BillingCity = 'TestCity';
        acc.BillingState = 'TestState';
        acc.BillingPostalCode = '110011';
        acc.BillingCountry = 'TestCountry';
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'TestCon_FirstName';
        con.LastName = 'TestCon_LastName';
        con.AccountId = acc.Id;
        insert con;
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CustomerInfo'; 
        req.httpMethod = 'Get';
        req.addHeader('Content-Type', 'application/json');
        req.params.put('FirstName',con.FirstName);
        req.params.put('LastName',con.LastName);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        REST_AccountInfo.doGetMethod();
        
        req.requestBody = Blob.valueOf('{"BillingStreet":"test1","BillingState":"AK","BillingPostalCode":"221133","BillingCountry":"USA","BillingCity":"AKSX","AccountName":"Bitwise CORP","contacts":[{"contactId":"'+con.Id+'", "LastName":"Harish4","FirstName":"LANKA4","Email":"testHarish4@gmail.com"}]}');
        req.httpMethod = 'PUT';
        RestContext.request = req;
        
        REST_AccountInfo.doPutMethod();
        
        Test.stopTest();  
    }
    
    
    @isTest
    private static void testDoPostMethod() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('{"BillingStreet":"test1","BillingState":"AK","BillingPostalCode":"221133","BillingCountry":"USA","BillingCity":"AKSX","AccountName":"Bitwise CORP","contacts":[{"LastName":"Harish4","FirstName":"LANKA4","Email":"testHarish4@gmail.com"}]}');
        
        req.requestURI = '/services/apexrest/CustomerInfo'; 
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        REST_AccountInfo.doPostMethod();
        Test.stopTest();
    }
}