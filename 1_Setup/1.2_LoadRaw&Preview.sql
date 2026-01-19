--set role, warehouse, db, schema
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;


--make the table
CREATE OR REPLACE TABLE "RAW_FLIGHTS" (
  "TRANSACTIONID"       VARCHAR,
  "FLIGHTDATE"          DATE,
  "AIRLINECODE"         VARCHAR,
  "AIRLINENAME"         VARCHAR,
  "TAILNUM"             VARCHAR,
  "FLIGHTNUM"           VARCHAR,
  "ORIGINAIRPORTCODE"   VARCHAR,
  "ORIGAIRPORTNAME"     VARCHAR,
  "ORIGINCITYNAME"      VARCHAR,
  "ORIGINSTATE"         VARCHAR,
  "ORIGINSTATENAME"     VARCHAR,
  "DESTAIRPORTCODE"     VARCHAR,
  "DESTAIRPORTNAME"     VARCHAR,
  "DESTCITYNAME"        VARCHAR,
  "DESTSTATE"           VARCHAR,
  "DESTSTATENAME"       VARCHAR,
  "CRSDEPTIME"          VARCHAR,
  "DEPTIME"             VARCHAR,
  "DEPDELAY"            VARCHAR,
  "TAXIOUT"             VARCHAR,
  "WHEELSOFF"           VARCHAR,
  "WHEELSON"            VARCHAR,
  "TAXIIN"              VARCHAR,
  "CRSARRTIME"          VARCHAR,
  "ARRTIME"             VARCHAR,
  "ARRDELAY"            VARCHAR,
  "CRSELAPSEDTIME"      VARCHAR,
  "ACTUALELAPSEDTIME"   VARCHAR,
  "CANCELLED"           VARCHAR,
  "DIVERTED"            VARCHAR,
  "DISTANCE"            VARCHAR
);

--copy data
COPY INTO RAW_FLIGHTS
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER
FILE_FORMAT = FLIGHTS_FF
ON_ERROR = continue;

-- Check raw matches original
SELECT COUNT(*) AS ROWCOUNT FROM "RAW_FLIGHTS"--my copy
EXCEPT
SELECT COUNT(*) AS FILE_ROWCOUNT
FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER (FILE_FORMAT => FLIGHTS_FF); -- orig

-- A quick sample
SELECT * 
FROM "RAW_FLIGHTS"
LIMIT 10;

---------------------------
--- Data Model Overview
---------------------------
-- DIM_AIRLINE: PK = AIRLINECODE
-- DIM_DATE: PK = DATEID(derived)
-- DIM_ROUTE: PK = ROUTEID(derived), FK = ORIGAIRPORTCODE, DESTAIRPORTCODE
-- DIM_AIRPORT: PK = AIRPORTCODE
-- FACT_FLIGHT: PK = TRANSACTIONID, FK= AIRLINECODE, DATEID, ROUTEID

---------------------------
---clean up items noted:
---------------------------
--  1 - airline name includes airline code suffix ": AC"     <-- to be fixed on DIM_AIRLINE
--  2 - tailnum includes nonalphanumeric symbols             <-- next step item: empty space or error
--  3 - origairportname includes "cityST: " prefix           <-- to be fixed on DIM_AIRPORT
--  4 - destairportname includes "cityST: " prefix           <-- to be fixed on DIM_AIRPORT
--  5 - cancelled boolean inconsistent                       <-- to be fixed on FACT
--  6 - diverterted boolean inconsistent                     <-- to be fixed on FACT
--  7 - distance column contains string values               <-- to be fixed on FACT
--  8 - date format: flightdate                              <-- to be fixed on STG
--  9 - time format (24hr): crsdeptime , deptime,            <-- to be fixed on FACT
--      crsarrtime, arrtime, wheels off, wheels on
-- 10 - numeric format: taxiin,taxiout,                      <-- to be fixed on STG
--      depdelay, arrdelay
-- 11 - Airlinename also occasionally includes additional    <-- next step item: reporting format
--      relevant information about airline merges

---------------------------
--quality checks to include:
---------------------------
--  1 - check for trailing/leading spaces
--  2 - check for nulls, na, unknown
--  3 - check uniqueness, completeness of transactionid
--  4 - check for next day arrivals
--  5 - check for negative distance
--  6 - check for negative elapsed
--  7 - check for all boolean values in cancelled/diverted (1, yes, true, T, Y, etc.)
--  8 - expected code length for airports
--  9 - expected code length for airlines
-- 10 - expected code length for flight number
-- 11 - expected code length for tail number

