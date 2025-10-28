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

--DATA ANALYSIS
--1.  Which channel is most frequently used for transactions?
SELECT tran_channel, COUNT(*) AS TransactionCount
FROM Transactions
GROUP BY tran_channel
ORDER BY TransactionCount DESC

--2.  What is the count of Male and Female customers in the database?
SELECT Gender, COUNT(*) AS GenderCount
FROM Customer
GROUP BY Gender

--3.  From which city do we have the maximum number of customers and how many? 
SELECT city_code, COUNT(*) AS CustomerCount
FROM Customer
GROUP BY city_code
ORDER BY CustomerCount DESC
OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY

--4.  How many sub-categories are there under the Books category?
SELECT COUNT(*) AS SubCategoryCount
FROM Retail_data_analysis.dbo.prod_cat_info
WHERE prod_cat = 'Books'

--5.  What is the maximum quantity of products ever ordered?
SELECT DISTINCT(prod_cat), MAX(Qty) AS Max_QTY
FROM Retail_data_analysis.dbo.Transactions JOIN Retail_data_analysis.dbo.prod_cat_info
ON Transactions.prod_cat_code = prod_cat_info.prod_cat_code
GROUP BY prod_cat

--6.  What is the net total revenue generated in categories Electronics and Books?  

SELECT 
    p.prod_cat, 
    SUM((TRY_CONVERT(DECIMAL(10,2), t.Rate) * 
         TRY_CONVERT(INT, t.Qty)) - 
         TRY_CONVERT(DECIMAL(10,2), t.Tax)) AS NetRevenue
FROM Retail_data_analysis.dbo.Transactions AS t
JOIN Retail_data_analysis.dbo.prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
WHERE p.prod_cat IN ('Electronics', 'Books')     
GROUP BY p.prod_cat;

--7.  How many customers have >10 transactions with us, excluding returns?
SELECT COUNT(*) AS CustomerCount
FROM (
    SELECT c.customer_Id
    FROM Retail_data_analysis.dbo.Transactions AS t
    JOIN Retail_data_analysis.dbo.Customer AS c
        ON t.cust_id = c.customer_Id
    GROUP BY c.customer_Id
    HAVING COUNT(t.transaction_id) > 10
) AS sub;

--8.  What  is  the  combined  revenue  earned  from  the  “Electronics”  &  “Clothing” categories, from “Flagship stores”?

SELECT 
    SUM(
        (TRY_CONVERT(DECIMAL(18,2), t.Rate) * 
         TRY_CONVERT(INT, t.Qty)) - 
         TRY_CONVERT(DECIMAL(18,2), t.Tax)
    ) AS CombinedRevenue
FROM Retail_data_analysis.dbo.Transactions AS t
JOIN Retail_data_analysis.dbo.prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
WHERE p.prod_cat IN ('Electronics', 'Clothing')
  AND t.store_type = 'Flagship store';

--9.  What  is  the  total  revenue  generated  from  “Male”  customers  in  “Electronics” category? Output should display total revenue by prod sub-cat

SELECT 
    p.prod_subcat, 
    SUM(
        (TRY_CONVERT(DECIMAL(18,2), t.Rate) * TRY_CONVERT(INT, t.Qty)) + 
        ISNULL(TRY_CONVERT(DECIMAL(18,2), t.Tax), 0)
    ) AS Total_Revenue
FROM Retail_data_analysis.dbo.Transactions AS t
JOIN Retail_data_analysis.dbo.prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
    AND p.prod_sub_cat_code = t.prod_subcat_code  -- Added for accuracy
JOIN Retail_data_analysis.dbo.Customer AS c
    ON t.cust_id = c.customer_Id
WHERE p.prod_cat = 'Electronics'
  AND c.Gender = 'M'  -- Check if it's 'M' or 'Male' in your data
GROUP BY p.prod_subcat
ORDER BY Total_Revenue DESC;

--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?


WITH SalesData AS (
    SELECT 
        p.prod_subcat, 
        SUM(
            (TRY_CONVERT(DECIMAL(18,2), t.Rate) * TRY_CONVERT(INT, t.Qty)) + 
            ISNULL(TRY_CONVERT(DECIMAL(18,2), t.Tax), 0)
        ) AS Total_Revenue
    FROM Retail_data_analysis.dbo.Transactions AS t
    JOIN Retail_data_analysis.dbo.prod_cat_info AS p
        ON t.prod_cat_code = p.prod_cat_code
        AND p.prod_sub_cat_code = t.prod_subcat_code
    JOIN Retail_data_analysis.dbo.Customer AS c
        ON t.cust_id = c.customer_Id
    WHERE p.prod_cat = 'Electronics'
      AND c.Gender = 'M'
    GROUP BY p.prod_subcat
),
ReturnsData AS (
    SELECT 
        p.prod_subcat, 
        SUM(
            (TRY_CONVERT(DECIMAL(18,2), t.Rate) * TRY_CONVERT(INT, t.Qty)) + 
            ISNULL(TRY_CONVERT(DECIMAL(18,2), t.Tax), 0)
        ) AS Total_Returns
    FROM Retail_data_analysis.dbo.Transactions AS t
    JOIN Retail_data_analysis.dbo.prod_cat_info AS p
        ON t.prod_cat_code = p.prod_cat_code
        AND p.prod_sub_cat_code = t.prod_subcat_code
    JOIN Retail_data_analysis.dbo.Customer AS c
        ON t.cust_id = c.customer_Id
    WHERE p.prod_cat = 'Electronics'
      AND c.Gender = 'M'
    GROUP BY p.prod_subcat
)
SELECT 
    s.prod_subcat,
    s.Total_Revenue,
    r.Total_Returns,
    CASE WHEN s.Total_Revenue > 0 THEN 
        (r.Total_Returns * 100.0 / s.Total_Revenue) 
    ELSE 0 END AS Return_Percentage
FROM SalesData s
LEFT JOIN ReturnsData r ON s.prod_subcat = r.prod_subcat
ORDER BY s.Total_Revenue DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

/*11. For all customers aged between 25 to 35 years find what is the net total revenue 
generated by these consumers in last 30 days of transactions from max transaction 
date available in the data?*/


WITH ConvertedTransactions AS (
    SELECT 
        t.*,
        CASE 
            WHEN t.tran_date LIKE '%/%' 
                THEN TRY_CONVERT(date, t.tran_date, 101)   -- mm/dd/yyyy
            WHEN t.tran_date LIKE '%-%' 
                THEN TRY_CONVERT(date, t.tran_date, 105)   -- dd-mm-yyyy
            ELSE NULL
        END AS CleanDate,
        TRY_CAST(t.total_amt AS FLOAT) AS CleanTotal
    FROM Transactions t
)
SELECT 
    SUM(CleanTotal) AS Net_Total_Revenue
FROM 
    ConvertedTransactions t
    INNER JOIN Customer c ON t.cust_id = c.customer_id
WHERE 
    DATEDIFF(YEAR, c.DOB, (SELECT MAX(CleanDate) FROM ConvertedTransactions)) 
        BETWEEN 25 AND 35
    AND CleanDate BETWEEN 
        DATEADD(DAY, -30, (SELECT MAX(CleanDate) FROM ConvertedTransactions)) 
        AND (SELECT MAX(CleanDate) FROM ConvertedTransactions);


--12. Which product category has seen the max value of returns in the last 3 months of transactions?        
WITH ConvertedTransactions AS (
    SELECT 
        t.*,
        CASE 
            WHEN t.tran_date LIKE '%/%' 
                THEN TRY_CONVERT(date, t.tran_date, 101)   -- mm/dd/yyyy
            WHEN t.tran_date LIKE '%-%' 
                THEN TRY_CONVERT(date, t.tran_date, 105)   -- dd-mm-yyyy
            ELSE NULL
        END AS CleanDate,
        TRY_CAST(t.total_amt AS FLOAT) AS CleanTotal
    FROM Transactions t
),
FilteredReturns AS (
    SELECT 
        ct.prod_cat_code,
        SUM(ABS(ct.CleanTotal)) AS Total_Return_Value
    FROM 
        ConvertedTransactions ct
    WHERE 
        ct.CleanTotal < 0   -- only returns (negative amounts)
        AND ct.CleanDate BETWEEN 
            DATEADD(MONTH, -3, (SELECT MAX(CleanDate) FROM ConvertedTransactions))
            AND (SELECT MAX(CleanDate) FROM ConvertedTransactions)
    GROUP BY 
        ct.prod_cat_code
)
SELECT 
    p.prod_cat,
    fr.Total_Return_Value
FROM 
    FilteredReturns fr
    INNER JOIN prod_cat_info p 
        ON fr.prod_cat_code = p.prod_cat_code
WHERE 
    fr.Total_Return_Value = (
        SELECT MAX(Total_Return_Value) FROM FilteredReturns
    );

--13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
WITH CleanedTransactions AS (
    SELECT 
        Store_type,
        TRY_CAST(Qty AS INT) AS CleanQty,
        TRY_CAST(total_amt AS FLOAT) AS CleanTotal
    FROM Transactions
    WHERE 
        -- exclude returns or invalid entries
        TRY_CAST(total_amt AS FLOAT) > 0 
        AND TRY_CAST(Qty AS INT) > 0
)
-- total sales amount by store type
SELECT TOP 1 
    Store_type, 
    SUM(CleanTotal) AS Total_Sales_Value
FROM CleanedTransactions
GROUP BY Store_type
ORDER BY SUM(CleanTotal) DESC;


--14. What are the categories for which average revenue is above the overall average.
WITH CleanedTransactions AS (
    SELECT 
        TRY_CAST(t.total_amt AS FLOAT) AS CleanTotal,
        t.prod_cat_code
    FROM Transactions t
    WHERE TRY_CAST(t.total_amt AS FLOAT) > 0
),
CategoryAverages AS (
    SELECT 
        p.prod_cat,
        AVG(ct.CleanTotal) AS Avg_Revenue_By_Category
    FROM 
        CleanedTransactions ct
        INNER JOIN prod_cat_info p 
            ON ct.prod_cat_code = p.prod_cat_code
    GROUP BY 
        p.prod_cat
),
OverallAverage AS (
    SELECT 
        AVG(CleanTotal) AS Overall_Avg_Revenue
    FROM 
        CleanedTransactions
)
SELECT 
    ca.prod_cat,
    ca.Avg_Revenue_By_Category
FROM 
    CategoryAverages ca, OverallAverage oa
WHERE 
    ca.Avg_Revenue_By_Category > oa.Overall_Avg_Revenue
ORDER BY 
    ca.Avg_Revenue_By_Category DESC;


--15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold. 
WITH CleanedTransactions AS (
    SELECT 
        t.prod_cat_code,
        t.prod_subcat_code,
        TRY_CAST(t.Qty AS INT) AS CleanQty,
        TRY_CAST(t.total_amt AS FLOAT) AS CleanTotal
    FROM Transactions t
    WHERE TRY_CAST(t.Qty AS INT) > 0 AND TRY_CAST(t.total_amt AS FLOAT) > 0
),
Top5Categories AS (
    SELECT TOP 5 
        ct.prod_cat_code
    FROM 
        CleanedTransactions ct
    GROUP BY 
        ct.prod_cat_code
    ORDER BY 
        SUM(ct.CleanQty) DESC
)
SELECT 
    p.prod_cat,
    p.prod_subcat,
    SUM(ct.CleanTotal) AS Total_Revenue,
    AVG(ct.CleanTotal) AS Avg_Revenue
FROM 
    CleanedTransactions ct
    INNER JOIN Top5Categories t5 ON ct.prod_cat_code = t5.prod_cat_code
    INNER JOIN prod_cat_info p 
        ON ct.prod_cat_code = p.prod_cat_code 
        AND ct.prod_subcat_code = p.prod_sub_cat_code
GROUP BY 
    p.prod_cat, p.prod_subcat
ORDER BY 
    p.prod_cat, Total_Revenue DESC;
