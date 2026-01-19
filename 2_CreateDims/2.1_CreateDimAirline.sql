---------------------------
-- CREATE DIM AIRLINE
--    1.1 clean airline name field
--    1.2 Enforce nullability & primary key
--    1.3 Quick checks
---------------------------

---------------------------
-- 0. CONTEXT
---------------------------
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;

---------------------------
-- 1.1 Create base airline set from stg_flights
---------------------------
CREATE OR REPLACE TABLE "DIM_AIRLINE" AS
WITH base AS (
    SELECT
        -- primary key
        CAST("AIRLINECODE" AS VARCHAR(3)) AS "AIRLINECODE_CLEAN",

        -- AIRLINENAME cleanup identified in preview step
        TRIM(REGEXP_REPLACE("AIRLINENAME",':[ ]*[A-Z0-9]{2,3}$','')) AS "AIRLINENAME_CLEAN"
    FROM "STG_FLIGHTS"
),
dedup AS (
    SELECT DISTINCT
        "AIRLINECODE_CLEAN" AS "AIRLINECODE",
        "AIRLINENAME_CLEAN" AS "AIRLINENAME"
    FROM base
)
SELECT * FROM dedup;

---------------------------
-- 1.2 DIM_AIRLINE KEY
---------------------------

-- Make key non-nullable
ALTER TABLE "DIM_AIRLINE"
  ALTER COLUMN "AIRLINECODE" SET NOT NULL;

-- Primary key on AIRLINECODE
ALTER TABLE "DIM_AIRLINE"
  ADD CONSTRAINT PK_DIM_AIRLINE
  PRIMARY KEY ("AIRLINECODE");

---------------------------
-- 1.3 DIM_AIRLINE checks
---------------------------
SELECT * FROM "DIM_AIRLINE"
ORDER BY "AIRLINECODE"
LIMIT 10;

DESC TABLE "DIM_AIRLINE";