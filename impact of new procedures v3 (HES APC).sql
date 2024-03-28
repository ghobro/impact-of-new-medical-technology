/*
This is an attempt of using the sub-query. Ran 27 March evening but it after 25:42 it hadn't rendered any results.

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
    t.OPERTN_n,
    COUNT(DISTINCT t.EPIKEY) AS Distinct_Epikey_Count,
    e.earliest_appearance_date,
    t.ADMIDATE_Derived
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
WHERE t.ADMIDATE_Derived <= DATEADD(day, 7, e.earliest_appearance_date)
GROUP BY t.OPERTN_n, e.earliest_appearance_date, t.ADMIDATE_Derived;

