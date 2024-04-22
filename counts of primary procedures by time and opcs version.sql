/*
This script goes into the HES APC data and selects the primary procedure as well as the year and month. 

This is joined onto the lookup for procedure codes, which contains information about the chapter and group.

The procedures code lookup requires some wrangling to get the first OPCS-4 version which the code appeared in - this is used to identify the date the code was added to the classification.

We then take a count by year and month of the procedures' dates as well as the OPCS version and chapters of the procedure. 

Have also included procedure group but this produces a lot of rows. If desired, we could produce it by individual procedure code but that would scale the analysis by another order of magnitude.

NB also that all codes prior released in OPCS 4.2 - 4.5 are grouped together in the data, so we can only say is a code was introduced 
in or before April 2009. The lookup also does not include OPCS-4.10 which was released in April 2023.


*/

Declare @start_date date = '2009-01-01';
Declare @end_date date = '2022-12-31';


SELECT 
    --HES_data.FileID, - commented out but useful for understanding the structure of hes
    --HES_data.SUSSPELLID, -- commented out but would be useful if analysing spells
    HES_data.[Year],
    HES_data.[Month],
    --HES_data.[Primary procedure], --ignoring the actual code for now as it will be very long
    Procedures_lookup.[Chapter_Code],
    Procedures_lookup.[Chapter_Description],
    --Procedures_lookup.[Group_Code], --possibly ignore 
    --Procedures_lookup.[Group_Description], --possibly ignore
    Procedures_lookup.[Min_OPCS_Version],
	Procedures_lookup.[OPCS_Release_Date],
	COUNT(*) as [Count]
FROM 
    (SELECT 
        --HES_data.FileID, - commented out but useful for understanding the structure of hes
		--HES_data.SUSSPELLID, -- commented out but would be useful if analysing spells
        YEAR(OPDATE_01) as [Year],
		MONTH(OPDATE_01) as [Month],
        OPERTN_01 AS [Primary procedure]
    FROM 
        [HESAPC].[vw_HESAPC]
    WHERE 
        OPDATE_01 BETWEEN @start_date AND @end_date 
        AND OPERSTAT='1' -- To ignore episodes where there was no procedure carried out
    ) HES_data
JOIN 
    (SELECT 
        [Procedure_Code],
        [Chapter_Code],
        [Chapter_Description],
        --[Group_Code],
        --[Group_Description],
        CAST(MIN([OPCS_Version]) AS VARCHAR) AS [Min_OPCS_Version], -- We use the min OPCS to get the earliest OPCS version the code is found in
		CAST(MIN([Effective_From]) AS DATE) AS [OPCS_Release_Date]
    FROM 
        [HESMART].[Dim_Procedure]
	WHERE 
		[Chapter_Code] IS NOT NULL
    GROUP BY 
        [Procedure_Code],
        [Chapter_Code],
        [Chapter_Description]
        --[Group_Code],
        --[Group_Description]
	
    ) Procedures_lookup 
ON HES_data.[Primary procedure] = Procedures_lookup.[Procedure_Code]
GROUP BY
	HES_data.[Year],
    HES_data.[Month],
	--HES_data.[Primary procedure],
    Procedures_lookup.[Chapter_Code],
    Procedures_lookup.[Chapter_Description],
   -- Procedures_lookup.[Group_Code],
    --Procedures_lookup.[Group_Description],
    Procedures_lookup.[Min_OPCS_Version],
	Procedures_lookup.[OPCS_Release_Date]
ORDER BY 
	HES_data.[Year],
    HES_data.[Month],
	[Min_OPCS_Version];
	

