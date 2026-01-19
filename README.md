# USFlights
Pipeline scripts to clone, transform and store US flight data for FAA route level analysis.

### Snowflake
This pipeline connects to an existing flatfile stored in Amazon S3. The flatfile contains US Flights Data. For practice, a sample can be found in the data folder. 

The purpose of this repository is to demonstrate basic data profiling. normalization modelling, and feature creation to optimize the data source for Tableau vizualization.

### Snowflake setup
This repo does not include account-specific credentials.  
Create `sql/setup.sql` from `sql/setup.template.sql` and set your own ROLE, WAREHOUSE, DATABASE, and SCHEMA before running queries. Alternatively, these can be referenced in each file under the 0 - CONTEXT section to run independently.