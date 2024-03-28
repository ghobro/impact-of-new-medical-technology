/*
This produces a list of years and months and the count of first appearances of
procedure codes on that date as well as the total incidence of procedures
which first appeared on that date. 

Would like that count of instances to be broken down by time. However, the other SQL script
"procedures_by_first_appearance.sql" can alternatively be used 
*/

select
	year(earliest_appearance_date) as first_appearance_year,
	month(earliest_appearance_date) as first_appearance_month,
	count(*) as count_of_new_procedures,
	sum(episodes) as total_episodes

from
	(
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
	) as SubQueryTable_proc_by_date -- this is the alias for the table produced by the sub query (i.e. one row per procedure code, includes first appearance, count of appearances, and count of unique episodes
group by 
	year(earliest_appearance_date),
	month(earliest_appearance_date)
order by 
	year(earliest_appearance_date),
	month(earliest_appearance_date);
