-----------------------
-- VIEW: VW_FLIGHTS
-- 1. Joins FACT_FLIGHTS f:
--      DIM_ROUTE        r
--      DIM_DATE         fd
--      DIM_AIRLINE      a
--      DIM_AIRPORT      ao
--      DIM_AIRPORT      ad
-- 2. Checks
-----------------------

---------------------------
-- 0. CONTEXT
---------------------------
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;

---------------------------
-- 1. CREATE VW_FLIGHTS
---------------------------
CREATE OR REPLACE VIEW "VW_FLIGHTS" AS
SELECT
    
    -- FACT_FLIGHTS
    
    f."TRANSACTIONID",
    f."DATEID",             -- for dim_date
    f."AIRLINECODE",        -- for dim_airline
    f."ROUTEID",            -- for dim_route
    f."CRSDEPTIME",
    f."DEPDELAY",
    f."TAXIOUT",
    f."WHEELSOFF",
    f."WHEELSON",
    f."TAXIIN",
    f."CRSARRTIME",
    f."ARRDELAY",
    f."CANCELLED",
    f."DIVERTED",
    f."DEPDELAYGT15",       -- required
    f."NEXTDAYARR",         -- required
    f."DISTANCEGROUP",      -- required

    -- from DIM_DATE
    fd."MONTH",
    fd."DAYOFMONTH",
    fd."YEAR",
    -- for seasonality analysis
    fd."ISHOLIDAY",
    fd."ISHOLIDAYWEEK",
    fd."WEEKOFYEAR",
    fd."DAYNAME",
    
    -- from DIM_AIRLINE
    a."AIRLINENAME",        -- required

    
    -- from DIM_AIRPORT (ORIGIN)
    
    ao."AIRPORTNAME"    AS "ORIGAIRPORTNAME",  -- required
  
    -- from DIM_AIRPORT (DESTINATION)
    
    ad."AIRPORTNAME"    AS "DESTAIRPORTNAME",  --required
    
    -- from DIM_ROUTE
    
    r."AVGDISTANCE"     AS "ROUTEAVGDISTANCE",
    r."ONTIMERATE"      AS "ROUTEONTIMERATE"

FROM "FACT_FLIGHTS" f
    LEFT JOIN "DIM_AIRLINE" a
        ON f."AIRLINECODE" = a."AIRLINECODE"
    LEFT JOIN "DIM_DATE" fd
        ON f."DATEID" = fd."DATEID"    
    LEFT JOIN "DIM_ROUTE" r
        ON f."ROUTEID" = r."ROUTEID"
    LEFT JOIN "DIM_AIRPORT" ao
        ON r."ORIGINAIRPORTCODE" = ao."AIRPORTCODE"
    LEFT JOIN "DIM_AIRPORT" ad
        ON r."DESTAIRPORTCODE" = ad."AIRPORTCODE";

---------------------------
-- 2. CHECKS
---------------------------
SELECT *
FROM "VW_FLIGHTS"
LIMIT 10;

