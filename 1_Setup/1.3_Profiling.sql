---------------------------
-- 0. CONTEXT
---------------------------
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;

---------------------------
-- CHECK 1: TRAILING / LEADING SPACES
---------------------------
SELECT 'AIRLINECODE'        AS column_name, COUNT(*) AS num_trim_issues
FROM "RAW_FLIGHTS"
WHERE "AIRLINECODE" <> TRIM("AIRLINECODE")
UNION ALL
SELECT 'TAILNUM', COUNT(*)
FROM "RAW_FLIGHTS"
WHERE "TAILNUM" <> TRIM("TAILNUM")
UNION ALL
SELECT 'ORIGINAIRPORTCODE', COUNT(*)
FROM "RAW_FLIGHTS"
WHERE "ORIGINAIRPORTCODE" <> TRIM("ORIGINAIRPORTCODE")
UNION ALL
SELECT 'DESTAIRPORTCODE', COUNT(*)
FROM "RAW_FLIGHTS"
WHERE "DESTAIRPORTCODE" <> TRIM("DESTAIRPORTCODE");

---------------------------
-- CHECK 2: NULL / 'NA' / 'UNKNOWN'
---------------------------
--Generate Query from schema
SELECT
    'SELECT ' ||
    LISTAGG(
        'COUNT(*) - COUNT("' || column_name || '") AS "' || column_name || '_NULLS"',
        ', '
    ) WITHIN GROUP (ORDER BY ordinal_position)
    || ' FROM RAW_FLIGHTS;'
AS NULL_COUNT_SQL
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'RAW_FLIGHTS'
  AND table_schema = 'CANDIDATE_00342';
--Run Query
SELECT COUNT(*) - COUNT("TRANSACTIONID") AS "TRANSACTIONID_NULLS", COUNT(*) - COUNT("FLIGHTDATE") AS "FLIGHTDATE_NULLS", COUNT(*) - COUNT("AIRLINECODE") AS "AIRLINECODE_NULLS", COUNT(*) - COUNT("AIRLINENAME") AS "AIRLINENAME_NULLS", COUNT(*) - COUNT("TAILNUM") AS "TAILNUM_NULLS", COUNT(*) - COUNT("FLIGHTNUM") AS "FLIGHTNUM_NULLS", COUNT(*) - COUNT("ORIGINAIRPORTCODE") AS "ORIGINAIRPORTCODE_NULLS", COUNT(*) - COUNT("ORIGAIRPORTNAME") AS "ORIGAIRPORTNAME_NULLS", COUNT(*) - COUNT("ORIGINCITYNAME") AS "ORIGINCITYNAME_NULLS", COUNT(*) - COUNT("ORIGINSTATE") AS "ORIGINSTATE_NULLS", COUNT(*) - COUNT("ORIGINSTATENAME") AS "ORIGINSTATENAME_NULLS", COUNT(*) - COUNT("DESTAIRPORTCODE") AS "DESTAIRPORTCODE_NULLS", COUNT(*) - COUNT("DESTAIRPORTNAME") AS "DESTAIRPORTNAME_NULLS", COUNT(*) - COUNT("DESTCITYNAME") AS "DESTCITYNAME_NULLS", COUNT(*) - COUNT("DESTSTATE") AS "DESTSTATE_NULLS", COUNT(*) - COUNT("DESTSTATENAME") AS "DESTSTATENAME_NULLS", COUNT(*) - COUNT("CRSDEPTIME") AS "CRSDEPTIME_NULLS", COUNT(*) - COUNT("DEPTIME") AS "DEPTIME_NULLS", COUNT(*) - COUNT("DEPDELAY") AS "DEPDELAY_NULLS", COUNT(*) - COUNT("TAXIOUT") AS "TAXIOUT_NULLS", COUNT(*) - COUNT("WHEELSOFF") AS "WHEELSOFF_NULLS", COUNT(*) - COUNT("WHEELSON") AS "WHEELSON_NULLS", COUNT(*) - COUNT("TAXIIN") AS "TAXIIN_NULLS", COUNT(*) - COUNT("CRSARRTIME") AS "CRSARRTIME_NULLS", COUNT(*) - COUNT("ARRTIME") AS "ARRTIME_NULLS", COUNT(*) - COUNT("ARRDELAY") AS "ARRDELAY_NULLS", COUNT(*) - COUNT("CRSELAPSEDTIME") AS "CRSELAPSEDTIME_NULLS", COUNT(*) - COUNT("ACTUALELAPSEDTIME") AS "ACTUALELAPSEDTIME_NULLS", COUNT(*) - COUNT("CANCELLED") AS "CANCELLED_NULLS", COUNT(*) - COUNT("DIVERTED") AS "DIVERTED_NULLS", COUNT(*) - COUNT("DISTANCE") AS "DISTANCE_NULLS" FROM RAW_FLIGHTS;


---------------------------
-- CHECK 3: TRANSACTIONID UNIQUENESS
---------------------------
-- Overall counts
SELECT
    COUNT(*)                        AS TOTAL_ROWS,
    COUNT(DISTINCT "TRANSACTIONID") AS DISTINCT_TRANSACTIONID,
    COUNT(*) - COUNT(DISTINCT "TRANSACTIONID") AS NUM_DUPLICATES
FROM "RAW_FLIGHTS";

-- List any duplicate TRANSACTIONIDs (if any)
SELECT
    "TRANSACTIONID",
    COUNT(*) AS CNT
FROM "RAW_FLIGHTS"
GROUP BY "TRANSACTIONID"
HAVING COUNT(*) > 1
ORDER BY CNT DESC, "TRANSACTIONID"
LIMIT 100;

--only numerics?
SELECT *
FROM RAW_FLIGHTS
WHERE TRY_TO_NUMBER(TRANSACTIONID) IS NULL;

-- any nulls?
SELECT *
FROM RAW_FLIGHTS
WHERE TRANSACTIONID IS NULL;
---------------------------
-- 4 - CHECK FOR NEXT DAY ARRIVALS
---------------------------
WITH t AS (
    SELECT
        "TRANSACTIONID",
        LPAD(TRIM("DEPTIME"), 4, '0') AS dep,
        LPAD(TRIM("ARRTIME"), 4, '0') AS arr
    FROM "RAW_FLIGHTS"
    WHERE TRIM("DEPTIME") NOT IN ('','0','0000')
      AND TRIM("ARRTIME") NOT IN ('','0','0000')
)
SELECT
    COUNT(*) AS total_with_times,
    SUM(CASE WHEN arr < dep THEN 1 ELSE 0 END) AS next_day_arrivals
FROM t;

-- sample rows
WITH t AS (
    SELECT
        *,
        LPAD(TRIM("DEPTIME"), 4, '0') AS dep,
        LPAD(TRIM("ARRTIME"), 4, '0') AS arr
    FROM "RAW_FLIGHTS"
)
SELECT *
FROM t
WHERE arr < dep
LIMIT 50;


---------------------------
-- 5 - CHECK FOR NEGATIVE DISTANCE
---------------------------
SELECT
    "TRANSACTIONID",
    "DISTANCE",
    TRY_TO_NUMBER(REGEXP_REPLACE("DISTANCE", '[^0-9]', '')) AS distance_num
FROM "RAW_FLIGHTS"
WHERE TRY_TO_NUMBER(REGEXP_REPLACE("DISTANCE", '[^0-9]', '')) < 0
   OR TRY_TO_NUMBER(REGEXP_REPLACE("DISTANCE", '[^0-9]', '')) = 0
LIMIT 50;

-- show range after conversion
SELECT
    MIN(TRY_TO_NUMBER(REGEXP_REPLACE("DISTANCE", '[^0-9]', ''))) AS min_distance,
    MAX(TRY_TO_NUMBER(REGEXP_REPLACE("DISTANCE", '[^0-9]', ''))) AS max_distance
FROM "RAW_FLIGHTS";


---------------------------
-- 6 - CHECK FOR NEGATIVE ELAPSED
---------------------------

SELECT
    "TRANSACTIONID",
    "ACTUALELAPSEDTIME",
    TRY_TO_NUMBER("ACTUALELAPSEDTIME") AS elapsed_num
FROM "RAW_FLIGHTS"
WHERE TRY_TO_NUMBER("ACTUALELAPSEDTIME") < 0
LIMIT 50;

---------------------------
-- 7 - CHECK ALL BOOLEANS
---------------------------

SELECT DISTINCT "CANCELLED"
FROM "RAW_FLIGHTS";

SELECT DISTINCT "DIVERTED"
FROM "RAW_FLIGHTS";

---------------------------
-- 8 -  AIRPORT CODE FORMATS
---------------------------
SELECT 
    MAX(LENGTH("ORIGINAIRPORTCODE"))  AS max_len_origin,
    MAX(LENGTH("DESTAIRPORTCODE"))    AS max_len_dest
FROM "RAW_FLIGHTS";

---------------------------
-- 9 -  AIRLINE CODE FORMATS
---------------------------
SELECT 
    MAX(LENGTH("AIRLINECODE"))  AS max_len_airline,
FROM "RAW_FLIGHTS";

---------------------------
-- 10 -  FLIGHT NUMBER FORMATS
---------------------------
SELECT 
    MAX(LENGTH("FLIGHTNUM"))  AS max_len_flightnum,
FROM "RAW_FLIGHTS";

---------------------------
-- 11 -  TAIL NUMBER FORMATS
---------------------------
SELECT 
    MAX(LENGTH("TAILNUM"))  AS max_len_tailnum,
FROM "RAW_FLIGHTS";

---------------------------
--  QUICK LOOK TIME FORMATS
---------------------------

SELECT DISTINCT "DEPTIME"
FROM "RAW_FLIGHTS"
ORDER BY "DEPTIME" DESC
LIMIT 5;

SELECT
    MIN(TRY_TO_NUMBER("CRSDEPTIME")) AS min_crsdeptime_num,
    MAX(TRY_TO_NUMBER("CRSDEPTIME")) AS max_crsdeptime_num,

    MIN(TRY_TO_NUMBER("DEPTIME"))    AS min_deptime_num,
    MAX(TRY_TO_NUMBER("DEPTIME"))    AS max_deptime_num,

    MIN(TRY_TO_NUMBER("CRSARRTIME")) AS min_crsarrtime_num,
    MAX(TRY_TO_NUMBER("CRSARRTIME")) AS max_crsarrtime_num,

    MIN(TRY_TO_NUMBER("ARRTIME"))    AS min_arrtime_num,
    MAX(TRY_TO_NUMBER("ARRTIME"))    AS max_arrtime_num
FROM "RAW_FLIGHTS";



---------------------------
-- OUTCOMES
---------------------------
-- 1 - check for trailing/leading spaces: PASS
-- 2 - check for nulls, na, unknown: PASS FOR IDS, SOME METRICS MISSING
--       Tailnum, Originstate, originstatename, deststate, deststatename, depttime,deptdelay,
--       taxiout, wheelsoff, wheelson, taxiin, arrtime, arrdelay, crselapsedtime, actualelapsedtime.
--       DEPDELAY especially important as it's the premise for derived column DEPDELAYGT15. check to 
--       imput from DEPTIME-CRSDEPTIME where possible.
-- 3 - check uniqueness of transactionid: PASS
-- 4 - check for next day arrivals: EXIST (create a flag later)
-- 5 - check for negative distance: PASS
-- 6 - check for negative elapsed: PASS
-- 7 - check date and time formats: ERRORS (both 0 and 2400 formatting appears)
-- 8 - check airport code length (3 or 4 digit): 3 DIGIT
-- 9 - check airline code length: 2
-- 10 - check flight number length: 4
-- 11 - check tail number length: 6

