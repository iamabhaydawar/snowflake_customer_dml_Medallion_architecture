# Customer Data DML - Data Model Loading Worksheet

## 📋 Overview

This repository contains SQL DML (Data Manipulation Language) commands and data files for loading customer data into a Snowflake data warehouse. The repository is designed to support batch ingestion of customer dimension data with proper data quality checks and validation.

## 🎯 Purpose

- Load customer data from CSV files into Snowflake `customer_dim` table
- Perform data quality checks and validation
- Support batch ingestion workflows for customer dimension data

## 📁 Repository Structure

```
customer-data-dml/
├── README.md                      # This file
├── customer_data_dml.sql          # SQL DML commands for loading customer data
└── customer_10k_good_data.csv    # Sample customer data file (10,000 records)
```

## 🚀 Getting Started with Snowflake

### Prerequisites

1. **Snowflake Account**: You need access to a Snowflake account
2. **SnowSQL or Snowflake Web UI**: For executing SQL commands
3. **Database Setup**: The `car_rental` database and `customer_dim` table should already exist

### Step 1: Connect to Snowflake

#### Using SnowSQL (Command Line)
```bash
snowsql -a <account_identifier> -u <username> -d car_rental
```

#### Using Snowflake Web UI
1. Navigate to your Snowflake account URL
2. Log in with your credentials
3. Select the `car_rental` database

### Step 2: Verify Database and Table Structure

Before loading data, ensure the following exist:
- Database: `car_rental`
- Schema: `public` (or your target schema)
- Table: `customer_dim` with the following structure:
  ```sql
  CREATE TABLE customer_dim (
      customer_key INTEGER AUTOINCREMENT PRIMARY KEY,
      customer_id STRING UNIQUE NOT NULL,
      name STRING,
      email STRING,
      phone STRING,
      effective_date TIMESTAMP,
      end_date TIMESTAMP,
      is_current BOOLEAN
  );
  ```

### Step 3: Prepare the Data File

The CSV file (`customer_10k_good_data.csv`) should have the following format:
```csv
customer_id,name,email,phone
CUST001,John Doe,john.doe@example.com,123-456-7890
CUST002,Jane Smith,jane.smith@example.com,123-456-7801
...
```

**Important**: Ensure your CSV file:
- Has a header row
- Uses comma (`,`) as delimiter
- Fields are properly quoted if they contain commas
- No trailing commas

### Step 4: Upload Data to Snowflake Stage

#### Option A: Using SnowSQL PUT Command
```sql
PUT file://customer_10k_good_data.csv @customer_data_stage AUTO_COMPRESS=TRUE;
```

#### Option B: Using Snowflake Web UI
1. Go to **Data** → **Databases** → **car_rental** → **Stages**
2. Select `customer_data_stage`
3. Click **Upload Files**
4. Select your CSV file and upload

### Step 5: Execute the DML Script

Run the SQL commands from `customer_data_dml.sql` in order:

1. **Create File Format** (if needed)
2. **Create Stage** (if using internal stage)
3. **Upload File** to stage
4. **Load Data** using COPY INTO command
5. **Verify Data** with quality checks

### Step 6: Verify the Load

After loading, run these verification queries:

```sql
-- Check total record count
SELECT COUNT(*) AS total_customers FROM customer_dim;

-- View sample records
SELECT * FROM customer_dim LIMIT 10;

-- Check for duplicates
SELECT customer_id, COUNT(*) 
FROM customer_dim 
GROUP BY customer_id 
HAVING COUNT(*) > 1;
```

## 📊 Data Quality Checks

The DML script includes several data quality checks:

1. **Record Count Verification**: Ensures all records were loaded
2. **Duplicate Detection**: Identifies duplicate customer IDs
3. **NULL Value Checks**: Validates required fields are not NULL
4. **Email Format Validation**: Basic email format verification
5. **Summary Statistics**: Provides overview of loaded data

## 🔧 Configuration

### File Format Settings

The default CSV file format configuration:
- **Field Delimiter**: Comma (`,`)
- **Record Delimiter**: Newline (`\n`)
- **Header Row**: Skipped (first row)
- **Field Enclosure**: Double quotes (`"`)
- **Error Handling**: Continue on error

### Stage Configuration

- **Stage Type**: Internal stage (for local file uploads)
- **Compression**: Auto-compress on upload
- **File Format**: Uses `csv_customer_format`

## 📝 Usage Examples

### Basic Load
```sql
-- Execute the full DML script
-- This will create stages, upload files, and load data
```

### Incremental Load
```sql
-- For incremental loads, modify the COPY INTO command to:
COPY INTO customer_dim (...)
FROM @customer_data_stage/customer_10k_good_data.csv.gz
FILE_FORMAT = csv_customer_format
ON_ERROR = 'CONTINUE'
FORCE = FALSE;
```

### Load from External Stage (GCS/S3)
```sql
-- If using external stage configured in snowflake_dwh_setup.sql
COPY INTO customer_dim (...)
FROM @car_rental_data_stg/customer_10k_good_data.csv
FILE_FORMAT = csv_customer_format;
```

## ⚠️ Troubleshooting

### Common Issues

1. **File Not Found in Stage**
   - Verify file was uploaded: `LIST @customer_data_stage;`
   - Check file name matches exactly (case-sensitive)

2. **Column Mismatch Errors**
   - Verify CSV structure matches table schema
   - Check for extra/missing columns

3. **Permission Errors**
   - Ensure you have USAGE privilege on database and schema
   - Verify you have INSERT privilege on `customer_dim` table

4. **Data Type Errors**
   - Check phone numbers are in correct format
   - Verify email addresses are valid
   - Ensure customer_id is unique

## 🔄 Best Practices

1. **Always backup** before bulk loads
2. **Test with small sample** before full load
3. **Monitor load performance** using Snowflake query history
4. **Validate data quality** after each load
5. **Use transactions** for critical loads
6. **Document any data transformations** applied

## 📚 Related Resources

- [Snowflake COPY INTO Documentation](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table.html)
- [Snowflake Stages Documentation](https://docs.snowflake.com/en/user-guide/data-load-local-file-system-create-stage.html)
- [Snowflake File Formats](https://docs.snowflake.com/en/sql-reference/sql/create-file-format.html)

## 📄 License

This repository is part of the Car Rental Batch Ingestion Project.

## 👥 Contributing

When adding new customer data files:
1. Follow the CSV format specified above
2. Update the DML script if schema changes
3. Test with sample data before production loads
4. Document any changes in this README

---

**Last Updated**: January 2026  
**Snowflake Version**: Compatible with Snowflake Standard Edition and above

