---------------------------
-- CREATE FACT_FLIGHTS 
--    3.1 load original columns 
--    3.2 create requested columns
--    3.3 set key
--    3.4 quick validation checks
---------------------------
---------------------------
-- 0. CONTEXT
---------------------------
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;

---------------------------
-- 3.1 Load Columns
---------------------------
CREATE OR REPLACE TABLE "FACT_FLIGHTS" AS
WITH base AS (
    SELECT
-- original columns
        "TRANSACTIONID",
        "AIRLINECODE",
        "FLIGHTNUM",
        "ORIGINAIRPORTCODE",
        "DESTAIRPORTCODE",
        "TAILNUM",
        "FLIGHTDATE",
        --clean dep times
        CASE
            WHEN "CRSDEPTIME" = '2400' THEN TO_TIME('0000', 'HH24MI')
            ELSE TO_TIME(LPAD("CRSDEPTIME", 4, '0'), 'HH24MI')
        END AS "CRSDEPTIME",
        CASE
            WHEN "DEPTIME" = '2400' THEN TO_TIME('0000', 'HH24MI')
            ELSE TO_TIME(LPAD("DEPTIME", 4, '0'), 'HH24MI')
        END AS "DEPTIME",
        "DEPDELAY",
        "TAXIOUT",
        CASE
            WHEN "WHEELSOFF" = '2400' THEN TO_TIME('0000', 'HH24MI')
            ELSE TO_TIME(LPAD("WHEELSOFF", 4, '0'), 'HH24MI')
        END AS "WHEELSOFF",
        CASE
            WHEN "WHEELSON" = '2400' THEN TO_TIME('0000', 'HH24MI')
            ELSE TO_TIME(LPAD("WHEELSON", 4, '0'), 'HH24MI')
        END AS "WHEELSON",
        "TAXIIN",
        CASE
            WHEN "CRSARRTIME" = '2400' THEN TO_TIME('0000', 'HH24MI')
            ELSE TO_TIME(LPAD("CRSARRTIME", 4, '0'), 'HH24MI')
        END AS "CRSARRTIME",
        CASE
            WHEN "ARRTIME" = '2400' THEN TO_TIME('0000', 'HH24MI')
            ELSE TO_TIME(LPAD("ARRTIME", 4, '0'), 'HH24MI')
        END AS "ARRTIME",
        "ARRDELAY",
        "CRSELAPSEDTIME",
        "ACTUALELAPSEDTIME",
        "CANCELLED",
        "DIVERTED",

        -- clean distance for subsequent group column creation
        TRY_TO_NUMBER(REGEXP_REPLACE("DISTANCE"::STRING, '[^0-9]', '')) AS "DISTANCE"
    FROM "STG_FLIGHTS"
)

SELECT
    "TRANSACTIONID",
    "AIRLINECODE",
    "FLIGHTNUM",
    "TAILNUM",  
    "CRSDEPTIME",
    "DEPTIME",
    "DEPDELAY",
    "TAXIOUT",
    "WHEELSOFF",
    "WHEELSON",
    "TAXIIN",
    "CRSARRTIME",
    "ARRTIME",
    "ARRDELAY",
    "CRSELAPSEDTIME"
    "ACTUALELAPSEDTIME",
    "CANCELLED",
    "DIVERTED",
    "DISTANCE",
---------------------------
-- 3.2 Create New Columns
---------------------------

    -- DATE ID
    (YEAR("FLIGHTDATE") * 10000) + (MONTH("FLIGHTDATE") * 100) + DAY("FLIGHTDATE")   AS "DATEID",

    -- ROUTE ID
    CONCAT("ORIGINAIRPORTCODE", "DESTAIRPORTCODE") AS "ROUTEID",

    -- DISTANCEGROUP
    CAST(
        CASE
            WHEN "DISTANCE" <= 100 THEN '0-100 miles'
            ELSE CONCAT(
                TO_CHAR((FLOOR(( "DISTANCE" - 1 ) / 100 ) * 100) + 1),
                '-',
                TO_CHAR((FLOOR(( "DISTANCE" - 1 ) / 100 ) * 100) + 100),
                ' miles'
            )
        END
    AS VARCHAR(20)
    ) AS "DISTANCEGROUP",

    -- DEPDELAYGT15
    CAST(
        CASE WHEN "DEPDELAY" > 15 THEN 1 ELSE 0 END AS NUMBER(1,0)
    ) AS "DEPDELAYGT15",

    -- NEXTDAYARR
    CAST(
        CASE
            WHEN "DEPTIME" IS NULL OR "ARRTIME" IS NULL THEN 0
            WHEN "ARRTIME" < "DEPTIME" THEN 1
            ELSE 0
        END
        AS NUMBER(1,0)
    ) AS "NEXTDAYARR"

FROM base;

--------------------------
-- 3.3 SET KEY
--------------------------

-- primary key
ALTER TABLE "FACT_FLIGHTS"
  ALTER COLUMN "TRANSACTIONID" SET NOT NULL;
  
ALTER TABLE "FACT_FLIGHTS"
  ADD CONSTRAINT PK_FACT_FLIGHTS_TRANSACTIONID
  PRIMARY KEY ("TRANSACTIONID");

-- foreign keys
ALTER TABLE "FACT_FLIGHTS"
  ALTER COLUMN "AIRLINECODE" SET NOT NULL;

ALTER TABLE "FACT_FLIGHTS"
  ALTER COLUMN "DATEID" SET NOT NULL;

ALTER TABLE "FACT_FLIGHTS"
  ALTER COLUMN "ROUTEID" SET NOT NULL;

---------------------------
-- 3.4 CHECK OUTPUT
---------------------------
--view sample
SELECT * FROM FACT_FLIGHTS
LIMIT 10;

--view data types
DESC TABLE FACT_FLIGHTS;
