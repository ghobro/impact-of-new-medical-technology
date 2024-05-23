/*
This script selects all the procedure codes which appear in the data and then finds the first time that that code appears (based on admission date),
the total count of rows in which it appears and the total number of episodes. Theoretically, I would imagine that the latter two quantities would be the same
as I don't understand how a procedure would appear more than once in the same episode; but it is not identical. 
*/
SELECT 
        OPERTN,
        MIN(ADMIDATE_Derived) AS earliest_appearance_date,
		count(*) as count,
		count(distinct EPIKEY) as episodes
		
    FROM 
        (
            SELECT 
                FileID,
                SUSSPELLID, 
                EPIKEY, 
                OPERSTAT, 
                ADMIDATE_Derived, 
                OPERTN_01, OPERTN_02, OPERTN_03, OPERTN_04,
                OPERTN_05, OPERTN_06, OPERTN_07, OPERTN_08,
                OPERTN_09, OPERTN_10, OPERTN_11, OPERTN_12,
                OPERTN_13, OPERTN_14, OPERTN_15, OPERTN_16,
                OPERTN_17, OPERTN_18, OPERTN_19, OPERTN_20,
                OPERTN_21, OPERTN_22, OPERTN_23, OPERTN_24
            FROM [HESAPC].[vw_HESAPC_Current]
            WHERE ADMIDATE_Derived BETWEEN '2009-01-01' AND '2019-12-31'
        ) AS Source
    UNPIVOT (
        OPERTN FOR OPERTN_n IN (
            OPERTN_01, OPERTN_02, OPERTN_03, OPERTN_04,
            OPERTN_05, OPERTN_06, OPERTN_07, OPERTN_08,
            OPERTN_09, OPERTN_10, OPERTN_11, OPERTN_12,
            OPERTN_13, OPERTN_14, OPERTN_15, OPERTN_16,
            OPERTN_17, OPERTN_18, OPERTN_19, OPERTN_20,
            OPERTN_21, OPERTN_22, OPERTN_23, OPERTN_24
        )
    ) AS Unpivoted
    GROUP BY OPERTN
