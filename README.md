# Snowpipe Project

A comprehensive Snowflake Snowpipe implementation for automated data ingestion from Google Cloud Storage (GCS) to Snowflake using Pub/Sub notifications.

## Overview

This project demonstrates how to set up an automated data pipeline using Snowflake Snowpipe to continuously ingest CSV files from a Google Cloud Storage bucket. The solution leverages GCS Pub/Sub notifications to trigger Snowpipe automatically when new files are uploaded to the storage bucket.

## Features

- **Automated Data Ingestion**: Snowpipe automatically loads data from GCS when new files arrive
- **Cloud Storage Integration**: Secure integration between Snowflake and Google Cloud Storage
- **Pub/Sub Notifications**: Real-time event-driven data loading using GCP Pub/Sub
- **CSV File Processing**: Handles CSV files with automatic schema mapping
- **Monitoring & Management**: Built-in commands to monitor pipe status and data loading history

## Project Structure

```
Snowpipe_Project/
├── steps.sql              # Complete Snowpipe setup script
└── data/                  # Sample CSV data files
    ├── orders_20231210.csv
    ├── orders_20231211.csv
    ├── orders_20241228.csv
    └── orders_20241229.csv
```

## Prerequisites

- Snowflake account with ACCOUNTADMIN role access
- Google Cloud Platform (GCP) account
- GCS bucket created (`snowpipe-raw-data-gds` in this example)
- GCP Pub/Sub topic and subscription configured

## Setup Instructions

### 1. Google Cloud Storage Setup

Create a GCS bucket and configure Pub/Sub notifications:

```bash
# Create Pub/Sub topic
gcloud pubsub topics create gcs-to-pubsub-notification

# Create Pub/Sub subscription
gcloud pubsub subscriptions create gcs-to-pubsub-notification-sub \
  --topic=gcs-to-pubsub-notification

# Create GCS notification
gsutil notification create -t gcs-to-pubsub-notification -f json \
  gs://snowpipe-raw-data-gds/
```

### 2. Snowflake Configuration

Execute the `steps.sql` script in Snowflake to:

1. **Create Database**: `snowpipe_dev`
2. **Create Table**: `orders_data_lz` with schema:
   - `order_id` (INT)
   - `product` (VARCHAR)
   - `quantity` (INT)
   - `order_status` (VARCHAR)
   - `order_date` (DATE)

3. **Create Storage Integration**: `gcs_bucket_read_int`
   - Enables secure access to GCS bucket
   - Note the service account from `DESC STORAGE INTEGRATION`

4. **Create Stage**: `snowpipe_stage`
   - Points to GCS bucket location
   - Uses storage integration for authentication

5. **Create Notification Integration**: `notification_from_pubsub_int`
   - Connects to GCP Pub/Sub subscription
   - Note the service account for IAM whitelisting

6. **Create Snowpipe**: `gcs_to_snowflake_pipe`
   - Auto-ingest enabled
   - Automatically loads CSV files from stage to table

### 3. GCP IAM Configuration

Grant necessary permissions to Snowflake service accounts:

1. **Storage Integration Service Account**: Grant `Storage Object Viewer` role on the GCS bucket
2. **Pub/Sub Integration Service Account**: Grant `Pub/Sub Subscriber` role on the subscription

## Usage

### Upload Data Files

Upload CSV files to your GCS bucket:
```bash
gsutil cp orders_20231210.csv gs://snowpipe-raw-data-gds/
```

Snowpipe will automatically detect and load the file into the `orders_data_lz` table.

### Monitor Snowpipe Status

```sql
-- Check pipe status
SELECT SYSTEM$PIPE_STATUS('gcs_to_snowflake_pipe');

-- View copy history
SELECT * 
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME=>'orders_data_lz', 
  START_TIME=> DATEADD(hours, -1, CURRENT_TIMESTAMP())
));

-- Query loaded data
SELECT * FROM orders_data_lz;
```

### Manage Snowpipe

```sql
-- Pause Snowpipe
ALTER PIPE gcs_to_snowflake_pipe SET PIPE_EXECUTION_PAUSED = true;

-- Resume Snowpipe
ALTER PIPE gcs_to_snowflake_pipe SET PIPE_EXECUTION_PAUSED = false;

-- Drop Snowpipe
DROP PIPE gcs_to_snowflake_pipe;
```

## Data Format

The CSV files should follow this format:
```csv
order_id,product,quantity,order_status,order_date
1,Keyboard,2,Completed,2023-08-07
2,Mouse,1,Pending,2023-08-07
```

## Key Components

### Storage Integration
Provides secure, credential-free access to GCS buckets without storing cloud provider credentials in Snowflake.

### Stage
A named location that points to your GCS bucket where data files are stored before loading.

### Notification Integration
Enables Snowpipe to receive notifications from GCP Pub/Sub when new files are uploaded to the bucket.

### Snowpipe
The automated data ingestion service that loads data from the stage into the target table when triggered by Pub/Sub notifications.

## Troubleshooting

- **Pipe not loading data**: Check pipe status and ensure notifications are properly configured
- **Permission errors**: Verify IAM roles are correctly assigned to Snowflake service accounts
- **File format issues**: Ensure CSV files match the expected format and encoding

## License

MIT License

## Author

Created as part of a Snowflake Snowpipe implementation project.
