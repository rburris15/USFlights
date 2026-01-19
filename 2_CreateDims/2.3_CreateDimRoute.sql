---------------------------
-- 3. DIM_ROUTE
--    3.1 Load & clean from STG_FLIGHTS
--    3.2 Create Route metrics
--    3.3 Set primary key
--    3.4 Quick checks
---------------------------
---------------------------
-- 0. CONTEXT
---------------------------
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;


---------------------------
-- 3.1 Create DIM_ROUTE table 
---------------------------
CREATE OR REPLACE TABLE "DIM_ROUTE" AS
WITH base AS (
    SELECT
        "ORIGINAIRPORTCODE",
        "DESTAIRPORTCODE",

        -- Clean numeric distance
        TRY_TO_NUMBER(REGEXP_REPLACE("DISTANCE", '[^0-9]', '')) AS "DISTANCE",

        -- Delays (for on-time metrics)
        TRY_TO_NUMBER("ARRDELAY") AS "ARRDELAY"
    FROM "STG_FLIGHTS"
),
---------------------------
-- 3.2 Create Route Metrics
---------------------------
route_agg AS (
    SELECT
        "ORIGINAIRPORTCODE",
        "DESTAIRPORTCODE",

        -- Route AVG Distance
        ROUND(AVG("DISTANCE")) AS "AVGDISTANCE",

        -- On-Time Metrics
        COUNT(*) AS "TOTALFLIGHTS",
        SUM(CASE WHEN "ARRDELAY" < 15 THEN 1 ELSE 0 END) AS "TOTALONTIMEFLIGHTS",
        ROUND(AVG(CASE WHEN "ARRDELAY" < 15 THEN 1 ELSE 0 END),2) AS "ONTIMERATE"

    FROM base
    GROUP BY
        "ORIGINAIRPORTCODE",
        "DESTAIRPORTCODE"
)

SELECT
    CONCAT("ORIGINAIRPORTCODE", "DESTAIRPORTCODE") AS "ROUTEID",
    "ORIGINAIRPORTCODE",
    "DESTAIRPORTCODE",
    "AVGDISTANCE",
    "TOTALFLIGHTS",
    "TOTALONTIMEFLIGHTS",
    "ONTIMERATE"
FROM route_agg;


---------------------------
-- 3.3 Set primary key
---------------------------
ALTER TABLE "DIM_ROUTE"
  ALTER COLUMN "ROUTEID" SET NOT NULL;
  
ALTER TABLE "DIM_ROUTE"
    ADD CONSTRAINT "PK_DIM_ROUTE"
        PRIMARY KEY ("ROUTEID");

---------------------------
-- 3.4 Quick checks
---------------------------

-- Row count
SELECT COUNT(*) AS "ROUTE_ROW_COUNT"
FROM "DIM_ROUTE";

--view sample
SELECT * 
FROM DIM_ROUTE 
ORDER BY TOTALFLIGHTS DESC 
LIMIT 5;

--view table desc
DESC TABLE DIM_ROUTE;