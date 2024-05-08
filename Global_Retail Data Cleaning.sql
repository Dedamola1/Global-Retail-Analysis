USE global_electronics;

-- Data Cleaning
CREATE TABLE New_Sales_modified
LIKE New_sales;

-- Create Modified Sales Table
INSERT new_sales_modified
SELECT *
FROM new_sales;

CREATE TABLE product_modified
LIKE product;

-- Create Modified Products Table
INSERT product_modified
SELECT *
FROM product;

-- Removing Duplicates within Tables
WITH Sales_CTE AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY OrderNumber, lineitem, productkey, storekey, customerkey) AS Row_Num
FROM New_sales_modified
)
SELECT *
FROM Sales_CTE
WHERE Row_Num > 1;

WITH Products_CTE AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY productkey, productname, brand, color, subcategorykey, categorykey) AS Row_Num
FROM products_modified
)
SELECT *
FROM Products_CTE
WHERE Row_Num > 1;

WITH Customers_CTE AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY customerkey, gender, name, city, state, country) AS Row_Num
FROM customers
)
SELECT *
FROM customers_CTE
WHERE Row_Num > 1;

-- Updating Date Columns (Customers)
SELECT Birthday,
STR_TO_DATE(Birthday, '%m/%d/%Y')
FROM Customers;

UPDATE Customers
SET Birthday = STR_TO_DATE(Birthday, '%m/%d/%Y');

-- Updating Date Columns (Stores)
SELECT OpenDate,
STR_TO_DATE(OpenDate, '%m/%d/%Y')
FROM stores;

UPDATE Stores
SET OpenDate = STR_TO_DATE(OpenDate, '%m/%d/%Y');

UPDATE stores
SET SquareMeters = NULL
WHERE SquareMeters = '';

-- Updating Date Columns (Exhcange Rates)
SELECT `Date`,
STR_TO_DATE(`Date`, '%m/%d/%Y')
FROM exchange_rates;

UPDATE exchange_rates
SET `Date` = STR_TO_DATE(`Date`, '%m/%d/%Y');

-- Updating Date Columns (New_sales_modified)
SELECT OrderDate, STR_TO_DATE(OrderDate, '%m/%d/%Y'),
		DeliveryDate, STR_TO_DATE(DeliveryDate, '%m/%d/%Y')
FROM new_sales_modified;

UPDATE New_sales_modified
SET OrderDate = STR_TO_DATE(OrderDate, '%m/%d/%Y');

UPDATE New_sales_modified
SET DeliveryDate = STR_TO_DATE(DeliveryDate, '%m/%d/%Y')
WHERE DeliveryDate != '';

UPDATE New_sales_modified
SET DeliveryDate = NULL
WHERE DeliveryDate = '';

-- Updating Date Columns (New_Sales)
SELECT OrderDate, STR_TO_DATE(OrderDate, '%m/%d/%Y'),
		DeliveryDate, STR_TO_DATE(DeliveryDate, '%m/%d/%Y')
FROM New_sales;

UPDATE New_sales
SET OrderDate = STR_TO_DATE(OrderDate, '%m/%d/%Y');

UPDATE New_Sales
SET DeliveryDate = NULL
WHERE DeliveryDate = '';

UPDATE New_Sales
SET DeliveryDate = STR_TO_DATE(DeliveryDate, '%m/%d/%Y')
WHERE DeliveryDate IS NOT NULL;

-- Recent Exchange Rates
CREATE TABLE Recent_Exchange_Rates
LIKE exchange_rates;

INSERT Recent_Exchange_Rates
SELECT *
FROM exchange_rates
WHERE `Date` = '2021-02-20';


CREATE TABLE product 
LIKE products;