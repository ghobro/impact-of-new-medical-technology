/*
Aim of this is to quantify the impact of new procedures. 

This script currently goes into HES APC data (filtered to 2019 for brevity) and unpivots the 24 procedure code fields `OPERTN_01` ... `OPERTN_24` into a single column `OPERTN`.

The new column `OPERTN_n` stored the name of the column from that list of 24 which held the code, so as to preserve the hierarchy of the codes. 

If there are no procedures for a given spell (which is flagged by `OPERSTAT` = '8') then we still keep a row. 

We also delete the inevitable empty rows resulting from the pivoting of episodes / rows where the number of procedures was greater than or equal to 1 but less than 24. 

And we extract the spell and episode IDs so as to be able to track. The date of admission is also stored given this is study across time. 

(NB there is a separate date given for each procedure's application, `OPDATE_01` ... `OPDATE_24`.

Will probably want to look at admission method, age, and sex eventually so they're there but commented out.

It produces millions of rows. 

Need to figure out a way to see the number of first instances of procedures by year within the SQL script. 

Would also probably want to look at procedures by their chapter in the OPCS-4 National Clinical Coding Standards. 
*/

SELECT 
	SUSSPELLID, 
	EPIKEY, 
	ADMIDATE_Derived, 
	--ADMIMETH, 
	--ACTIVAGE, 
	--SEX, 
	OPERTN_n, 
	OPERTN
FROM (
    SELECT 
		SUSSPELLID, 
		EPIKEY, 
		OPERSTAT, 
		ADMIDATE_Derived, 
		--ADMIMETH, 
		--ACTIVAGE, 
		--SEX, 
		OPERTN_n, 
		OPERTN
    FROM (
        SELECT 
			SUSSPELLID, 
			EPIKEY, 
			OPERSTAT, 
			ADMIDATE_Derived, 
			--ADMIMETH, 
			--ACTIVAGE, 
			--SEX, 
            OPERTN_01, OPERTN_02, OPERTN_03, OPERTN_04,
            OPERTN_05, OPERTN_06, OPERTN_07, OPERTN_08,
            OPERTN_09, OPERTN_10, OPERTN_11, OPERTN_12,
            OPERTN_13, OPERTN_14, OPERTN_15, OPERTN_16,
            OPERTN_17, OPERTN_18, OPERTN_19, OPERTN_20,
            OPERTN_21, OPERTN_22, OPERTN_23, OPERTN_24
        FROM [HESAPC].[vw_HESAPC]
		WHERE ADMIDATE_Derived = '2023-01-01'
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
) AS Data
WHERE OPERTN IS NOT NULL OR OPERSTAT = '8';



