-- Insert this mock data once all tasks are created 

INSERT INTO raw_transactions VALUES
(4, 104, 1004, 3, '2024-12-02 09:30:00', 'completed'),
(5, 105, 1005, 1, '2024-12-02 10:45:00', 'pending'),
(6, 106, 1006, 4, '2024-12-02 11:15:00', 'completed');

INSERT INTO raw_transactions VALUES
(7, 107, 1007, 2, '2024-12-03 08:00:00', 'completed'),
(8, 108, 1008, 1, '2024-12-03 09:30:00', 'canceled'),
(9, 109, 1009, 3, '2024-12-03 10:45:00', 'completed');

-- Brone Layer Table
CREATE OR REPLACE TABLE raw_transactions (
    transaction_id INT,
    customer_id INT,
    product_id INT,
    quantity INT,
    transaction_date TIMESTAMP,
    transaction_status VARCHAR
);

-- Silver Layer Table
CREATE OR REPLACE TABLE filtered_transactions (
    transaction_id INT,
    product_id INT,
    quantity INT,
    transaction_date DATE,
    transaction_status VARCHAR
);

-- Gold Layer Table
CREATE OR REPLACE TABLE aggregated_transactions (
    transaction_date DATE,
    total_quantity INT,
    completed_transactions INT,
    refunded_transactions INT
);


-- Task 1 (Scheduled for 1 minute) to perfom merge query from raw_transactions_table into filter_transaction_table

CREATE OR REPLACE TASK filter_transactions_task
WAREHOUSE = compute_wh
SCHEDULE = '1 MINUTES'
AS
MERGE INTO filtered_transactions tgt
USING (
    SELECT 
        transaction_id,
        product_id,
        quantity,
        DATE(transaction_date) AS transaction_date,
        transaction_status
    FROM raw_transactions
    WHERE transaction_status IN ('completed', 'refunded')
) src
ON tgt.transaction_id = src.transaction_id
WHEN MATCHED THEN UPDATE SET
    tgt.product_id = src.product_id,
    tgt.quantity = src.quantity,
    tgt.transaction_date = src.transaction_date,
    tgt.transaction_status = src.transaction_status
WHEN NOT MATCHED THEN INSERT (
    transaction_id, product_id, quantity, transaction_date, transaction_status
) VALUES (
    src.transaction_id, src.product_id, src.quantity, src.transaction_date, src.transaction_status
);

-- Task 2 (For aggregation) Will run after Task 1
CREATE OR REPLACE TASK aggregate_transactions_task
WAREHOUSE = COMPUTE_WH
AFTER filter_transactions_task -- Set dependency on Task 1
AS
MERGE INTO aggregated_transactions tgt
USING (
    SELECT 
        transaction_date,
        SUM(quantity) AS total_quantity,
        COUNT_IF(transaction_status = 'completed') AS completed_transactions,
        COUNT_IF(transaction_status = 'refunded') AS refunded_transactions
    FROM filtered_transactions
    GROUP BY transaction_date
) src
ON tgt.transaction_date = src.transaction_date
WHEN MATCHED THEN UPDATE SET
    tgt.total_quantity = src.total_quantity,
    tgt.completed_transactions = src.completed_transactions,
    tgt.refunded_transactions = src.refunded_transactions
WHEN NOT MATCHED THEN INSERT (
    transaction_date, total_quantity, completed_transactions, refunded_transactions
) VALUES (
    src.transaction_date, src.total_quantity, src.completed_transactions, src.refunded_transactions
);


-- Check the status of Tasks
describe task filter_transactions_task;
describe task aggregate_transactions_task;


-- By default Tasks will be in Suspend mode, activate them by setting it to RESUME
ALTER TASK aggregate_transactions_task RESUME;
ALTER TASK filter_transactions_task RESUME;

--- check the history of task
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME=>'filter_transactions_task')) ORDER BY SCHEDULED_TIME;

--- check the history of task
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME=>'aggregate_transactions_task')) ORDER BY SCHEDULED_TIME;

select * from raw_transactions;
select * from filtered_transactions;
select * from aggregated_transactions;


