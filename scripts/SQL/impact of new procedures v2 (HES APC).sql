/*
Ran for 01:13:05 to get 8.1m rows. It might be that what we do is make this a sub-query and wrap the thing I'm interested in around it. 

The aim is to get one row per instance of procedure which says the first time
that procedure appeared and also filtering to those were the admitted date is
less than a particular time period (currently 7 days) on from that.

*/

Declare @start_date date = '2009-01-01';
Declare @end_date date = '2019-12-31';

WITH EarliestAppearance AS (
    SELECT
        OPERTN,
        MIN(ADMIDATE_Derived) AS earliest_appearance_date
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
            WHERE ADMIDATE_Derived BETWEEN @start_date AND @end_date
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
)
SELECT
    t.*,
	e.earliest_appearance_date--,
    --CASE
    --    WHEN t.ADMIDATE_Derived >= e.earliest_appearance_date
    --         AND t.ADMIDATE_Derived <= DATEADD(day, 7, e.earliest_appearance_date)
    --    THEN 1
    --    ELSE 0
    --END AS new_flag
FROM
    (
        SELECT
            FileID,
            SUSSPELLID,
            EPIKEY,
            OPERSTAT,
            ADMIDATE_Derived,
            OPERTN_n,
            OPERTN
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
                WHERE ADMIDATE_Derived BETWEEN @start_date AND @end_date
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
    ) AS t
JOIN
    EarliestAppearance e ON t.OPERTN = e.OPERTN
WHERE t.ADMIDATE_Derived <= DATEADD(year, 2, e.earliest_appearance_date);
