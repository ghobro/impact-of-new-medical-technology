SELECT 
        [Procedure_Code],
        [Chapter_Code],
        [Chapter_Description],
        [Group_Code],
        [Group_Description],
        CAST([OPCS_Version] AS VARCHAR) OPCS_Version
    FROM 
        [HESMART].[Dim_Procedure]
	WHERE 
		[Chapter_Code] IS NOT NULL 
		and [OPCS_Version] = 4.9
    