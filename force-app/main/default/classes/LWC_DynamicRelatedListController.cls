/*********************
*   LWC_DynamicRelatedListController
*   @author:        Minh H Ma
*   @date:          11/25/2020
*   descrtiption:   This is to display related list from dynamically from fieldset
*
*   Update History:
*   11/25/2020  Intial Version
*********************/
public with sharing class LWC_DynamicRelatedListController 
{
    public LWC_DynamicRelatedListController() { }

    /*****
     * Populating custom class LWCData.
     * Parameters Input:
     *  parentAPIName
     *  childAPIName
     *  childParentField
     *  fieldSet
     */
    @AuraEnabled(Cacheable = true)
    public static lwcData getRecords(id recordId, 
        string parentAPIName,
        string childAPIName,
        string childParentField,
        string fieldSet)
    {
        System.debug('getRecords ==> parentAPIName: '+ parentAPIName);
        System.debug('getRecords ==> childAPIName: '+ childAPIName);
        System.debug('getRecords ==> childParentField: '+ childParentField);
        System.debug('getRecords ==> fieldSet: '+ fieldSet);

        lwcData oLWCData = new lwcData();
        oLWCData.parentId = recordId;
        System.debug('getRecords ==> parentId: '+ recordId);
        
        oLWCData.iconName = getIconName(childAPIName);
        System.debug('getRecords ==> oLWCData.iconName: ' + oLWCData.iconName);

        /***** Get Object label */
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
    	Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(childAPIName);
    	Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        oLWCData.objectLabel = DescribeSObjectResultObj.getLabelPlural();

        /***** Get relationship name*/
        oLWCData.relationshipName = getParentRelationshipName(parentAPIName, childAPIName, childParentField);

        /***** Populating from fields & type map */
        String s = '';
        Integer i = 0;
        Map<string, Column> mapFields = getFields(fieldSet, childAPIName, DescribeSObjectResultObj);
        List<Column> listColumn = new List<Column>();
        for (string fieldName : mapFields.keySet()) 
        {
            Column oColumn = mapFields.get(fieldName);
            listColumn.Add(oColumn);
            if(i == 0)
                s+= fieldName;
            else
                s+= ',' + fieldName;

            /***** including relationship name */
            if (oColumn.relationshipName != null)
                s+= ',' + oColumn.relationshipName + '.Name';

            i++;
        }

        oLWCData.listColumn = JSON.serialize(listColumn);

        String query = 'SELECT Id, ' + s + 
                ' from ' + childAPIName +
                ' where ' + childParentField + ' =\'' + recordId + '\'' +
                ' limit 100';
        System.debug('getRecords ==> query: '+ query);        
        oLWCData.listRecord = Database.query(query);

        return oLWCData;
       
    }

    /*****
     * Populating map of field & column from fieldsets
     */
    private static Map<string, Column> getFields(string fieldSetName,
            string objectName,
            Schema.DescribeSObjectResult DescribeSObjectResultObj)
    {
        Map<string, Column> mapFields = new Map<string, Column>();

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

    	List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
    	//system.debug('getFields ==> fieldSetMemberList:' + fieldSetMemberList);
    	       
        List<String> selFields = new List<String>();
        for(Schema.FieldSetMember fld :fieldSetMemberList) 
        {
            String fieldName = fld.getFieldPath();
            if (mapFields.get(fieldName) == null)
                mapFields.put(fieldName, getColumn(objectName, fieldName));
        }
        return mapFields;
    }

    /*****
     * Populating custom class column from fieldName
     */
    private static Column getColumn(String objectName, string field)
    {	
        System.debug('getColumn ==> objectName:' + objectName);
        Schema.SObjectField describeField = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(field);            
        Schema.DescribeFieldResult dfr = describeField.getDescribe();

        column selCols = new column();
        selCols.label = dfr.getLabel();
        selCols.fieldName = dfr.getName();
        selCols.type = String.valueOf(dfr.getType() ).toLowercase();
        selCols.relationshipName = dfr.getRelationshipName();
        if (selCols.fieldName == 'Name' ||
            dfr.getRelationshipName() != null)
        {
            if (selCols.fieldName == 'Name')
                selCols.fieldName = 'Id';
            else
                selCols.fieldName = selCols.relationshipName + '_Id';

            selCols.type = 'url';
            //selCols.sortable = true;

            label selLab = new label();
            if (selCols.fieldName == 'Id')
                selLab.fieldName = 'Name';
            else
                selLab.fieldName = selCols.relationshipName + '_Name';
            
            attributes selAtt = new attributes();
            selatt.label = selLab;
            selAtt.target = '_blank';

            selCols.typeAttributes = selAtt;                
        }   

        //selCols.editable = 'false';
        System.debug('getColumn ==> column:' + selCols);
        System.debug('getColumn ==> column in JSon:' + JSON.serialize(selCols));             
                
        return selCols;
    }

    /*****
     * geting Related List Name
     */
    private static String getParentRelationshipName(string parentAPIName, 
            String childSobjectApiName, 
            String relatedFieldApiName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
    	Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(parentAPIName);
    	Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        String name;
        for (Schema.ChildRelationship cr: DescribeSObjectResultObj.getChildRelationships())
        { 
            if(cr.getChildSObject().getDescribe().getName() == childSobjectApiName
            && cr.getField().getDescribe().getName() == relatedFieldApiName)
            {
          	 	name = cr.getRelationshipName();
                break;
            }
        }     
        return name;
    } 

    /*****
     * geting IconName from ObjectName
     */
    public static String getIconName(String objectName)
    {
        System.debug('getIconName ==> objectName:' + objectName);
        String iconName;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) 
        { 
            tabDesc.addAll(tsr.getTabs()); 
        }

        for(Schema.DescribeTabResult tr : tabDesc) 
        {
            if( objectName == tr.getSobjectName() ) 
            {
                if( tr.isCustom() ) 
                {
                    iconDesc.addAll(tr.getIcons());
                } 
                else 
                {
                    iconName = 'standard:' + objectName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) 
        {
            if (ir.getContentType() == 'image/svg+xml')
            {
                iconName = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }

        System.debug('getIconName ==> iconName:' + iconName);
        return iconName;
    }  
    
    /*****
     * lwcData
    */
    public with sharing class lwcData 
    {
        @AuraEnabled public id parentId;
        @AuraEnabled public string iconName;
        @AuraEnabled public string objectLabel;
        @AuraEnabled public string relationshipName;
        @AuraEnabled public List<Object> listRecord;
        @AuraEnabled public string listColumn;

        public lwcData() {}
    }


    /*****
     * data column Class
     */
    public with sharing class column 
    {
        public String label;
        public string fieldName;
        public String type;
        public Attributes typeAttributes;
        public Boolean editable;
        public Boolean sortable;
        public String relationshipName;

        public column() { }
    }

    public with sharing class attributes 
    {
        public label label;
        public string target;

        public attributes() { }
    }

    public with sharing class label
    {
        public string fieldName;

        public label() { }
    }
}