/* ============================================================
   02 - Load the CSV into dbo.raw_loans
   1. Download Loan_default.csv from Kaggle (see data/README.md)
   2. Put it in a folder SQL Server can read, e.g. C:\sql\loan\
   3. Change the path below, then run
   ============================================================ */

USE LoanDefault;
GO

TRUNCATE TABLE dbo.raw_loans;
GO

BULK INSERT dbo.raw_loans
FROM 'C:\sql\loan\Loan_default.csv'        -- <-- change this path
WITH (
    FIRSTROW        = 2,            -- skip the header row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',       -- the CSV uses LF line endings
    TABLOCK
);
GO

-- Verify the load: expect 255,347 rows and a default rate of 11.61%
SELECT COUNT(*) AS total_rows FROM dbo.raw_loans;

SELECT ROUND(100.0 * SUM(default_flag) / COUNT(*), 2) AS default_rate_pct
FROM dbo.raw_loans;
GO
