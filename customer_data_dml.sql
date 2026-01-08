-- ============================================================================
-- Customer Data DML (Data Model Loading Worksheet)
-- Snowflake Data Warehouse - Customer Dimension Loading Script
-- ============================================================================
-- Description: This script contains DML commands for loading customer data
--              into the Snowflake data warehouse customer_dim table.
-- ============================================================================

-- Step 1: Use the car_rental database
USE DATABASE car_rental;
USE SCHEMA public;

-- Step 2: Verify customer_dim table structure
DESC TABLE customer_dim;

-- Step 3: Create file format for CSV loading (if not exists)
CREATE FILE FORMAT IF NOT EXISTS csv_customer_format
TYPE = CSV
FIELD_DELIMITER = ','
RECORD_DELIMITER = '\n'
SKIP_HEADER = 0
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
ESCAPE = 'NONE'
ESCAPE_UNENCLOSED_FIELD = '\134'
DATE_FORMAT = 'AUTO'
TIMESTAMP_FORMAT = 'AUTO'
NULL_IF = ('NULL', 'null', '');

-- Step 4: Create internal stage for customer data (if using local file)
CREATE OR REPLACE STAGE customer_data_stage
FILE_FORMAT = csv_customer_format;

-- Step 5: Upload CSV file to stage (run this command in SnowSQL or Snowflake UI)
-- PUT file://customer_10k_good_data.csv @customer_data_stage AUTO_COMPRESS=TRUE;

-- Step 6: Verify files in stage
LIST @customer_data_stage;

-- Step 7: Load customer data from CSV into customer_dim table
-- Using COPY INTO command for bulk loading
COPY INTO customer_dim (
    customer_id,
    name,
    email,
    phone,
    effective_date,
    end_date,
    is_current
)
FROM (
    SELECT 
        $1 AS customer_id,
        $2 AS name,
        $3 AS email,
        $4 AS phone,
        CURRENT_TIMESTAMP() AS effective_date,
        NULL AS end_date,
        TRUE AS is_current
    FROM @customer_data_stage/customer_10k_good_data.csv.gz
)
FILE_FORMAT = csv_customer_format
ON_ERROR = 'CONTINUE'
FORCE = FALSE;

-- Alternative: Load from external stage (GCS/S3) if configured
-- COPY INTO customer_dim (
--     customer_id,
--     name,
--     email,
--     phone,
--     effective_date,
--     end_date,
--     is_current
-- )
-- FROM @car_rental_data_stg/customer_10k_good_data.csv
-- FILE_FORMAT = csv_customer_format
-- ON_ERROR = 'CONTINUE';

-- Step 8: Verify loaded data
SELECT COUNT(*) AS total_customers FROM customer_dim;
SELECT * FROM customer_dim LIMIT 10;

-- Step 9: Check for duplicates
SELECT 
    customer_id,
    COUNT(*) AS duplicate_count
FROM customer_dim
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Step 10: Data quality checks
-- Check for NULL values in required fields
SELECT 
    COUNT(*) AS null_customer_id_count
FROM customer_dim
WHERE customer_id IS NULL;

SELECT 
    COUNT(*) AS null_email_count
FROM customer_dim
WHERE email IS NULL;

-- Check email format validity (basic check)
SELECT 
    COUNT(*) AS invalid_email_count
FROM customer_dim
WHERE email NOT LIKE '%@%.%';

-- Step 11: Summary statistics
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT email) AS unique_emails,
    MIN(effective_date) AS earliest_effective_date,
    MAX(effective_date) AS latest_effective_date
FROM customer_dim;

-- Step 12: Clean up stage (optional - after successful load)
-- REMOVE @customer_data_stage;

-- ============================================================================
-- End of Customer Data DML Script
-- ============================================================================

