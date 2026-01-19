---------------------------
-- 2. DIM_AIRPORT
--    2.1 combine origin and dest codes to make new table
--    2.2 dedup
--    2.3 clean airport name column
--    2.4 Enforce nullability & primary key
--    2.5 Quick checks
---------------------------

---------------------------
-- 0. CONTEXT
---------------------------
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;



CREATE OR REPLACE TABLE DIM_AIRPORT AS
-- 2.1 combine
WITH combined AS (
    SELECT
        "ORIGINAIRPORTCODE"           AS "AIRPORTCODE",
        "ORIGINCITYNAME"              AS "CITYNAME",
        "ORIGINSTATE"                 AS "STATECODE",
        "ORIGINSTATENAME"             AS "STATENAME",
        "ORIGAIRPORTNAME"             AS "AIRPORTNAME"
    FROM STG_FLIGHTS

    UNION ALL

    SELECT
        "DESTAIRPORTCODE"             AS "AIRPORTCODE",
        "DESTCITYNAME"                AS "CITYNAME",
        "DESTSTATE"                   AS "STATECODE",
        "DESTSTATENAME"               AS "STATENAME",
        "DESTAIRPORTNAME"             AS "AIRPORTNAME"
    FROM STG_FLIGHTS
),
-- 2.2 deduplicate
dedup AS (
    SELECT DISTINCT
        "AIRPORTCODE",
        "CITYNAME",
        "STATECODE",
        "STATENAME",
        "AIRPORTNAME"
    FROM combined
),
-- 2.3 clean up airport name
final AS (
    SELECT
        "AIRPORTCODE",
        "CITYNAME",
        "STATECODE",
        "STATENAME",
        -- remove city and state data from airport name
        SPLIT_PART("AIRPORTNAME", ': ', 2) AS "AIRPORTNAME"
    FROM dedup
)

SELECT * FROM final;

---------------------------
-- 2.4 Keys
---------------------------

ALTER TABLE "DIM_AIRPORT"
  ALTER COLUMN "AIRPORTCODE" SET NOT NULL;

ALTER TABLE "DIM_AIRPORT"
  ADD CONSTRAINT "PK_DIM_AIRPORT"
  PRIMARY KEY ("AIRPORTCODE");

---------------------------
-- 2.5 Airport Checks
---------------------------
SELECT *
FROM DIM_AIRPORT
LIMIT 10;

DESC TABLE DIM_AIRPORT;
