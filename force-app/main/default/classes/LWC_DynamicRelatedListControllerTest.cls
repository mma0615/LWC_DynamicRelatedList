/*********************
*   LWC_DynamicRelatedListControllerTest
*   @author:        Minh H Ma
*   @date:          11/25/2020
*   descrtiption:   This is the test class for LWC_DynamicRelatedListController
*
*   Update History:
*   11/25/2020  Intial Version
*********************/
@istest
public with sharing class LWC_DynamicRelatedListControllerTest 
{
    @istest
    public static void DynamicRelatedListControllerTest()
    {
        Account oAccount = new Account(Name='TestAccount');
        Insert oAccount;
        
        Opportunity oOppo = new Opportunity(Name='Test', AccountId=oAccount.Id, StageName='Prospecting', CloseDate=system.today() );
        insert oOppo;

        Test.startTest();
        LWC_DynamicRelatedListController LWC_DynamicRelatedList = new LWC_DynamicRelatedListController();
        
        LWC_DynamicRelatedListController.lwcData theData = LWC_DynamicRelatedListController.getRecords(oAccount.Id, 
                    'Account', 
                    'Opportunity', 
                    'AccountId', 
                    'Oppo_FieldSet');
        
        /**** Test Custom IconName */
        //string iconName = FinancialAccountController.getIconName('OASP__Financial_Account__c');
        //system.debug('*****Custom iconName: ' + iconName);
        //System.assert(iconName != null, 'Custom iconName not found');
        
        /**** Test Standard IconName */
        //iconName = FinancialAccountController.getIconName('Account');
        //system.debug('***** Standard iconName: ' + iconName);
        //System.assert(iconName != null, 'Standard iconName not found');

        Test.stopTest();
    }
}