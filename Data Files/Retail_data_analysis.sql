-- Create a new database called 'Retail_data_analysis'
-- Connect to the 'master' database to run this snippet
USE master
GO
-- Create the new database if it does not exist already
IF NOT EXISTS (
    SELECT name
        FROM sys.databases
        WHERE name = N'Retail_data_analysis'
)
CREATE DATABASE Retail_data_analysis
GO

-- Switch to the new database
USE Retail_data_analysis
GO

-- Create the Customer table if it does not exist
IF OBJECT_ID('dbo.Customer', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customer (
        CustomerID INT PRIMARY KEY,
        CustomerName NVARCHAR(100),
        Email NVARCHAR(100),
        Phone NVARCHAR(20)
    )
END
GO

-- Create the prod_cat_info table if it does not exist
IF OBJECT_ID('dbo.prod_cat_info', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.prod_cat_info (
        ProdCatID INT PRIMARY KEY,
        ProdCatName NVARCHAR(100),
        ProdSubCatID INT,
        ProdSubCatName NVARCHAR(100)
    )
END
GO

--DATA PREPARATION AND UNDERSTANDING

--1.  What is the total number of rows in each of the 3 tables in the database?

SELECT * FROM Retail_data_analysis.dbo.Transactions

SELECT * FROM Customer

SELECT * FROM Retail_data_analysis.dbo.Customer

SELECT * FROM Retail_data_analysis.dbo.prod_cat_info

--2.  What is the total number of transactions that have a return? 
SELECT COUNT(transaction_id) AS TotalReturns
FROM Transactions

/*As you would have noticed, the dates provided across the datasets are not in a 
correct format. As first steps, pls convert the date variables into valid date formats 
before proceeding ahead.*/

-- Convert date columns to proper date format
SELECT FORMAT(CONVERT(DATE, '27-02-2014', 105), 'dd-MMM-yyyy') AS FormattedDate
FROM Transactions

/*4.  What is the time range of the transaction data available for analysis? Show the 
output in number of days, months and years simultaneously in different columns.*/

SELECT 
    MIN(FORMAT(CONVERT(DATE, tran_date, 105), 'dd-MMM-yyyy')) AS StartDate,
    MAX(FORMAT(CONVERT(DATE, tran_date, 105), 'dd-MMM-yyyy')) AS EndDate,
    DATEDIFF(DAY, MIN(CONVERT(DATE, tran_date, 105)), MAX(CONVERT(DATE, tran_date, 105))) AS TotalDays,
    DATEDIFF(MONTH, MIN(CONVERT(DATE, tran_date, 105)), MAX(CONVERT(DATE, tran_date, 105))) AS TotalMonths,
    DATEDIFF(YEAR, MIN(CONVERT(DATE, tran_date, 105)), MAX(CONVERT(DATE, tran_date, 105))) AS TotalYears
FROM Transactions

--5.  Which product category does the sub-category “DIY” belong to?
SELECT prod_sub_cat_code
FROM Retail_data_analysis.dbo.prod_cat_info
WHERE prod_subcat = 'DIY'

