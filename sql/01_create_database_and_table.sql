/* ============================================================
   01 - Create database and raw table
   Run in SSMS (SQL Server / SQL Server Express).
   ============================================================ */

IF DB_ID('LoanDefault') IS NULL
    CREATE DATABASE LoanDefault;
GO

USE LoanDefault;
GO

IF OBJECT_ID('dbo.raw_loans', 'U') IS NOT NULL
    DROP TABLE dbo.raw_loans;
GO

-- 'Default' is a reserved word in SQL Server, so the target column is named default_flag
CREATE TABLE dbo.raw_loans (
    LoanID          NVARCHAR(10) NOT NULL PRIMARY KEY,
    Age             INT,
    Income          INT,
    LoanAmount      INT,
    CreditScore     INT,
    MonthsEmployed  INT,
    NumCreditLines  INT,
    InterestRate    DECIMAL(5,2),
    LoanTerm        INT,
    DTIRatio        DECIMAL(3,2),
    Education       NVARCHAR(20),
    EmploymentType  NVARCHAR(20),
    MaritalStatus   NVARCHAR(20),
    HasMortgage     NVARCHAR(3),
    HasDependents   NVARCHAR(3),
    LoanPurpose     NVARCHAR(20),
    HasCoSigner     NVARCHAR(3),
    default_flag    INT           -- 1 = customer defaulted, 0 = did not default
);
GO
