---------------------------
-- 4. DIM_DATE
--    4.1 Determine date range
--    4.2 build dim date with derived date information
--    4.3 add holiday information
--    4.4 Set primary key
--    4.4 Quick checks
---------------------------

---------------------------
-- 0. CONTEXT
---------------------------
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;


---------------------------
-- 4.1 Determine date range from STG_FLIGHTS
--     we'll include every date regardless if a flight occurred to allow for future flights to be added
---------------------------

CREATE OR REPLACE TABLE "DIM_DATE" AS
WITH bounds AS (
    SELECT
        MIN("FLIGHTDATE") AS "MIN_DATE",
        MAX("FLIGHTDATE") AS "MAX_DATE"
    FROM "STG_FLIGHTS"
),
---------------------------
-- 4.2 Generate date rows between min and max
---------------------------
date_span AS (
    SELECT
        DATEADD('day', SEQ4(), "MIN_DATE") AS "FLIGHTDATE"
    FROM bounds, TABLE(GENERATOR(ROWCOUNT => 20000))
    WHERE DATEADD('day', SEQ4(), "MIN_DATE") <= "MAX_DATE"
)
SELECT

    -- create key from date for ease of recreating
    (YEAR("FLIGHTDATE") * 10000)
      + (MONTH("FLIGHTDATE") * 100)
      + DAY("FLIGHTDATE")                  AS "DATEID",      

    -- Base date, unchanged
    "FLIGHTDATE"                           AS "FLIGHTDATE",

    -- Calendar breakdown for ease of analysis. can be derived in tableau but my preference is at the           source.

    YEAR("FLIGHTDATE")                     AS "YEAR",
    QUARTER("FLIGHTDATE")                  AS "QUARTER",
    MONTH("FLIGHTDATE")                    AS "MONTH",
    MONTHNAME("FLIGHTDATE")                AS "MONTHNAME",
    DAY("FLIGHTDATE")                      AS "DAYOFMONTH",
    DAYOFWEEKISO("FLIGHTDATE")             AS "DAYOFWEEK_ISO",
    DAYNAME("FLIGHTDATE")                  AS "DAYNAME",
    WEEKOFYEAR("FLIGHTDATE")               AS "WEEKOFYEAR",


    -- Weekend flag (Sat/Sun)
    CASE
        WHEN DAYOFWEEKISO("FLIGHTDATE") IN (6, 7) THEN 1
        ELSE 0
    END                              AS "ISWEEKEND"
FROM date_span;
        
--------------------------
-- 4.3 Add Holiday Indicators
--------------------------
ALTER TABLE "DIM_DATE"
ADD COLUMN "ISHOLIDAY" NUMBER(1,0);

ALTER TABLE "DIM_DATE"
ADD COLUMN "ISHOLIDAYWEEK" NUMBER(1,0);

UPDATE "DIM_DATE"
SET "ISHOLIDAY" = CASE
    -- Fixed-date holidays
    WHEN MONTH("FLIGHTDATE") = 1 AND DAY("FLIGHTDATE") = 1 THEN 1              -- New Year's Day
    WHEN MONTH("FLIGHTDATE") = 7 AND DAY("FLIGHTDATE") = 4 THEN 1              -- 4th of july
    WHEN MONTH("FLIGHTDATE") = 12 AND DAY("FLIGHTDATE") = 25 THEN 1            -- Christmas Day
    

    -- Labor Day: 
    WHEN MONTH("FLIGHTDATE") = 9
         AND DAYOFWEEKISO("FLIGHTDATE") = 1                              -- Monday
         AND DAY("FLIGHTDATE") BETWEEN 1 AND 7 THEN 1

    -- Thanksgiving
    WHEN MONTH("FLIGHTDATE") = 11
         AND DAYOFWEEKISO("FLIGHTDATE") = 4                              -- Thursday
         AND DAY("FLIGHTDATE") BETWEEN 22 AND 28 THEN 1

    ELSE 0
END;

UPDATE "DIM_DATE" d
SET "ISHOLIDAYWEEK" = CASE
    WHEN EXISTS (
        SELECT 1
        FROM "DIM_DATE" h
        WHERE h."ISHOLIDAY" = 1
          AND d."FLIGHTDATE" BETWEEN h."FLIGHTDATE" - 3 AND h."FLIGHTDATE" + 3
    )
    THEN 1
    ELSE 0
END;


---------------------------
-- 4.4 DIM_DATE key
---------------------------

ALTER TABLE "DIM_DATE"
  ALTER COLUMN "DATEID" SET NOT NULL;

ALTER TABLE "DIM_DATE"
  ADD CONSTRAINT "PK_DIM_DATE"
  PRIMARY KEY ("DATEID");

---------------------------
-- 4.4 DIM_DATE checks
---------------------------

SELECT *
FROM "DIM_DATE"
ORDER BY "FLIGHTDATE"
LIMIT 10;

DESC TABLE "DIM_DATE";
