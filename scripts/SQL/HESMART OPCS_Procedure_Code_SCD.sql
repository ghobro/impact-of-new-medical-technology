/* 
This uses the table HESMART.OPCS_Procedure_Code_SCD which contains procedures codes and OPCS versions (4.5 to 4.9).

We select the relevant columns and this can be used in a join on the HES data so as to view instances of procedures by time alongside the 
date they were added to OPCS (i.e. the OPCS version which they were introduced in). 

Issues with the data:
- where a code appears in a previous edition, it will show up repeatedly for all futher editions - this is why I use a Min function on OPCS to identify the first
- similarly all the codes that were introduced prior to 4.5 (prior to April 2009) are grouped under 4.5 given that it doesn't include the earlier versions (4.2-4.4)
- It doesn't include any added in 4.10 (which was introduced in April 2023)

This goes to OPCS-4.9 and also everything prior to 4.5 is grouped under 4.5. If 
*/
SELECT 
	--[Selection_Indicators]
    --,[Procedure_Prefix]
    [Procedure_Code]
    ,[Procedure_Code_With_Decimal]
    ,[Procedure_Code_Description]
    ,[Procedure_Name_3_Char_Category]
    --,[Sex_Absolute]
    --,[Sex_Scrutiny]
    --,[Status_Of_Operation]
    --,[Method_Of_Delivery]
    --,[Method_Of_Delivery_Code]
    ,min([OPCS_Version]) as OPCS_Version
    --,[Import_Date]
    --,[Created_Date]
    --,[Effective_From]
    --,[Effective_To]
  FROM [HESMART].[OPCS_Procedure_Code_SCD]
  group by 
	[Procedure_Code]
    ,[Procedure_Code_With_Decimal]
    ,[Procedure_Code_Description]
    ,[Procedure_Name_3_Char_Category]
