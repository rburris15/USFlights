---------------------------
-- SETUP FILE
-- 1. Check file and view header information
-- 2. Set File Format for Raw Load
---------------------------

---------------------------
-- 0. CONTEXT
---------------------------
USE ROLE CANDIDATE_00342;
USE WAREHOUSE WH_CANDIDATE_00342;
USE DATABASE RECRUITMENT_DB;
USE SCHEMA CANDIDATE_00342;

---------------------------
-- 1. View File
---------------------------
LIST @RECRUITMENT_DB.PUBLIC.S3_FOLDER;


--create file format and temporarily cofigure for viewing header
create or replace file format "FLIGHTS_FF"
    type = 'CSV'
    field_delimiter = ","
    skip_header = 0
    compression = 'GZIP';

--peak at file to get column headers
SELECT value as column_name
FROM (
    SELECT SPLIT($1, '|') AS cols
    FROM @RECRUITMENT_DB.PUBLIC.S3_FOLDER (file_format => FLIGHTS_FF)
    LIMIT 1
),
LATERAL FLATTEN(input => cols);



---------------------------
-- 2. Set File Format
---------------------------
create or replace file format "FLIGHTS_FF"
    type = 'CSV'
    field_delimiter = "|"
    skip_header = 1
    compression = 'GZIP'
    DATE_FORMAT = 'YYYYMMDD';


