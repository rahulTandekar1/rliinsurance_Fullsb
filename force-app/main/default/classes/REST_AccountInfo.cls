@RestResource(urlMapping='/CustomerInfo')
Global class REST_AccountInfo { 
    
    public Class RsponseClass{
        public String ContactID{get;set;}
        public String AccountId{get;Set;}
        public String FirstName{get;Set;}
        public String LastName{get;Set;}
        public String Email{get;Set;}
        public String AccountName{get;Set;}
        public String BillingStreet{get;set;}
        public String BillingCity{get;set;}
        public String BillingState{get;set;}
        public String BillingCountry{get;set;}
        public String BillingPostalCode{get;set;}
        Public String Roles{get;set;}
    }
    
    public  Class RequestClass{
        public String AccountId{get;Set;}
        public String AccountName{get;Set;}
        public String BillingStreet{get;set;}
        public String BillingCity{get;set;}
        public String BillingState{get;set;}
        public String BillingCountry{get;set;}
        public String BillingPostalCode{get;set;}
        Public List<ContactData>Contacts = new List<ContactData>();
        
    }
    public Class ContactData{
        public String ContactID{get;set;}
        public String FirstName{get;Set;}
        public String LastName{get;Set;}
        public String Email{get;Set;}
    }
    
    //Generic method to return the response for GET method
    public static list<RsponseClass> genericResponseForGet(list<Contact>conList){
        Map<String,AccountContactRelation>mapId_AccountContactRelation = new Map<String,AccountContactRelation >();
        String key = '';
        for(AccountContactRelation relation :[select id,accountId,ContactId,Roles from AccountContactRelation  where ContactId in:conList]){
            key = relation.ContactId+'-'+relation.AccountId;
            if(!mapId_AccountContactRelation.containsKey(key)){
                mapId_AccountContactRelation.put(key,relation);
            }
        }
        
        List<RsponseClass> contactList = new List<RsponseClass>();
        for(Contact objCont : conList){
            key = objCont.Id+'-'+objCont.AccountId;
            RsponseClass wrapperObj = new RsponseClass();
            wrapperObj.ContactID = objCont.Id;
            wrapperObj.AccountId = objCont.AccountId;
            wrapperObj.AccountName = objCont.Account.Name;
            wrapperObj.FirstName = objCont.Firstname;
            wrapperObj.LastName = objCont.Lastname;
            wrapperObj.Email = objCont.Email;
            wrapperObj.BillingStreet = objCont.Account.BillingStreet;
            wrapperObj.BillingCity = objCont.Account.BillingCity;
            wrapperObj.BillingState = objCont.Account.BillingState;
            wrapperObj.BillingCountry = objCont.Account.BillingCountry;
            wrapperObj.BillingPostalCode = objCont.Account.BillingPostalCode;
            
            if(mapId_AccountContactRelation.containsKey(key)){
                wrapperObj.Roles = mapId_AccountContactRelation.get(key).Roles;
            }else{
                wrapperObj.Roles = '';
            }
            if(wrapperObj.Roles != null){
                wrapperObj.Roles = wrapperObj.Roles.replace(';',',');
            }else{
                wrapperObj.Roles = '';
            }
            contactList.add(wrapperObj);
        } 
        return contactList;
    }
    
    
    @httpGet
    global static void doGetMethod(){
        Map<String,String> paramsMap = RestContext.request.params;
        String firstNameParam = '';
        String lastNameParam = '';
        if(paramsMap.containsKey('firstName')){
            firstNameParam = paramsMap.get('firstName');
        }else if(paramsMap.containsKey('FirstName')){
            firstNameParam = paramsMap.get('FirstName');
        }
        
        if(paramsMap.containsKey('lastName')){
            lastNameParam = paramsMap.get('lastName');
        }else if(paramsMap.containsKey('LastName')){
            lastNameParam = paramsMap.get('LastName');
        }
        List<Contact> conList = new List<Contact>();
        try{
            conList = [select id,Firstname,Lastname,Email,Account.Name,Account.BillingStreet,Account.BillingCity,
                       Account.BillingState,Account.BillingCountry,Account.BillingPostalCOde from Contact where
                       FirstName =:firstNameParam AND LastName =:lastNameParam];
            
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        list<RsponseClass> contactList = genericResponseForGet(conList);
        RestResponse res = RestContext.response;
        res.responseBody = Blob.valueOf(JSON.serialize(contactList));
        res.statusCode = 200;
        if(contactList.isEmpty()) {
            res.responseBody = Blob.valueOf('Data Not found with parameter '+firstNameParam+' and '+lastNameParam);
            res.statusCode = 404;
        }
        RestContext.response = res;
    }
    
    /**
* Apex method to insert Account and Contact Data
* **/
    @httpPost
    global static void doPostMethod(){
        RestResponse res = RestContext.response;
        String requestBody = restcontext.request.requestbody.tostring();
        RequestClass requestBodyObj = (RequestClass) JSON.deserialize(requestBody, RequestClass.Class);
        
        try{
            system.debug('wRsponseClass====>'+requestBodyObj);
            Account objAcc = new Account();
            objAcc.Name = requestBodyObj.AccountName;
            objAcc.BillingStreet = requestBodyObj.BillingStreet;
            objAcc.BillingCity = requestBodyObj.BillingCity;
            objAcc.BillingCountry = requestBodyObj.BillingCountry;
            objAcc.BillingPostalCode = requestBodyObj.BillingPostalCode; 
            Insert objAcc;
            
            List<Contact> lstContactToInsert = new List<Contact>();
            for(ContactData objContactWrap : requestBodyObj.Contacts){
                Contact objCon = new Contact();
                objCon.FirstName = objContactWrap.FirstName;
                objCon.LastName = objContactWrap.Lastname;
                objCon.Email = objContactWrap.Email;
                objCon.AccountId = objAcc.Id;
                lstContactToInsert.add(objCon);  
            }
            list<RsponseClass> contactList;
            String response = '';
            if(!lstContactToInsert.isEMpty()){
                List<Database.SaveResult> InsertResults = database.Insert(lstContactToInsert,false);
                System.debug(' InsertResults '+InsertResults);
                set<ID>ContactIds= new Set<ID>();
                
                for (Database.SaveResult r : InsertResults){
                    if (!r.isSuccess()){
                        for (Database.Error e : r.getErrors()){
                            response += e.getMessage()+'\n';
                        }  
                    }else{
                        ContactIds.add(r.getId());
                    }
                }
                if(!ContactIds.isEMpty()){
                    List<Contact> conList = [select id,Firstname,Lastname,Email,Account.Name,Account.BillingStreet,Account.BillingCity,
                                             Account.BillingState,Account.BillingCountry,Account.BillingPostalCOde from Contact where Id in:ContactIds];
                    contactList = genericResponseForGet(conList);
                }
            }
            System.debug('contactList '+contactList);
            if(contactList != null){
                response += '\n\n Account Inserted with following details \n';
                response += JSON.serialize(contactList);
                res.responseBody = Blob.valueOf(response);
                res.statusCode = 200;
            }
        }catch(Exception e){
            res.responseBody = Blob.valueOf('Something went wrong.\n '+e.getMessage()+' '+e.getLineNumber());
            res.statusCode = 400; 
        }
    }
    
    /*This apex method is to update the account and Contact*/
    @HTTPPut
    global static void doPutMethod(){
        RestResponse res = RestContext.response;
        String requestBody = restcontext.request.requestbody.tostring();
        RequestClass requestBodyObj = (RequestClass) JSON.deserialize(requestBody, RequestClass.Class);
        Set<String>contactNames = new Set<String>();
        
        for(ContactData objContactWrap : requestBodyObj.Contacts){
            if(String.isNotBlank(objContactWrap.ContactId) ){
                contactNames.add(objContactWrap.ContactId);
            }
        } 
        
        Map<String,COntact>contactMap = new Map<String,COntact>();
        for(Contact objCon : [Select Id,Name,FirstName,LastName,Email,AccountId from Contact where Id  in:contactNames]){
            contactMap.put(objCon.Id,objCon);
        }
        
        
        try{
            List<Contact> lstContactToUpdate = new List<Contact>();
            List<Account> lstAccountToUpdate = new List<Account>();
            for(ContactData objContactWrap : requestBodyObj.Contacts){
                Contact objCon = new Contact();
                if(contactMap.containsKey(objContactWrap.ContactId)){
                    objCon.Id = contactMap.get(objContactWrap.ContactId).Id;
                    objCon.AccountId = contactMap.get(objContactWrap.ContactId).AccountId;
                    
                    Account objAcc = new Account();
                    objAcc.Id = objCon.AccountId;
                    objAcc.Name = requestBodyObj.AccountName;
                    objAcc.BillingStreet = requestBodyObj.BillingStreet;
                    objAcc.BillingCity = requestBodyObj.BillingCity;
                    objAcc.BillingCountry = requestBodyObj.BillingCountry;
                    objAcc.BillingPostalCode = requestBodyObj.BillingPostalCode;
                    lstAccountToUpdate.add(objAcc);
                }
                objCon.FirstName = objContactWrap.FirstName;
                objCon.LastName = objContactWrap.Lastname;
                objCon.Email = objContactWrap.Email;
                lstContactToUpdate.add(objCon);  
            }
            String response = '';
            list<RsponseClass> contactList;
            if(!lstContactToUpdate.isEMpty()){
                List<Database.SaveResult> updateResults = database.update(lstContactToUpdate,false);
                System.debug('updateResults '+updateResults);
                contactList = genericResponseForGet(lstContactToUpdate);
                for (Database.SaveResult r : updateResults){
                    if (!r.isSuccess()){
                        response +='Contact Update Error : ';
                        for (Database.Error e : r.getErrors()){
                            if(e.getMessage().containsIgnoreCase('id not specified')){
                                response += 'Contact not found \n';
                            }else{
                                response += e.getMessage()+'\n';
                            }
                        }  
                    }
                }
            }
            if(!lstAccountToUpdate.isEMpty()){
                List<Database.SaveResult> updateResults = database.update(lstAccountToUpdate,false);
                for (Database.SaveResult r : updateResults){
                    if (!r.isSuccess()){
                        response +='Account Update Error : ';
                            for (Database.Error e : r.getErrors()){
                                response += e.getMessage()+'\n';
                            }  
                    }
                }
            }
            System.debug('contactList '+contactList);
            if(contactList != null){
                response += '\n\n Account and Contact updated with following details \n';
                response += JSON.serialize(contactList);
                res.responseBody = Blob.valueOf(response);
                res.statusCode = 200;
            }
        }catch(Exception e){
            res.responseBody = Blob.valueOf('Something went wrong.\n '+e.getMessage()+' '+e.getLineNumber());
            res.statusCode = 400; 
        }
    }
}