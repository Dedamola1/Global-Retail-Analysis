-- Types of products sold, and customers location?
SELECT DISTINCT  Category, Subcategory, COUNT(category)  AS Amount_of_Products
FROM product_modified
GROUP BY Category, Subcategory
ORDER BY Category
;

SELECT DISTINCT Country, Continent
FROM customers
;

UPDATE product_modified
SET unitpriceusd = CAST(REPLACE(unitpriceusd, '$', '') AS DECIMAL);

UPDATE product_modified
SET unitcostusd = CAST(REPLACE(unitcostusd, '$', '') AS DECIMAL);

-- Seasonal Patterns & Trends for Order Volume and Revenue
SELECT Month_Name, 
		Year_Name,
		SUM(QTY) AS Order_Volume, 
		ROUND(SUM(Revenue),2) AS Total_Revenue_USD
FROM
	(SELECT monthname(sal.orderdate) AS Month_Name,
			year(sal.orderdate) AS Year_Name,
			SUM(sal.Quantity) AS QTY, 
			SUM(sal.Quantity * prod.UnitPriceUSD * Exchange) AS Revenue
	FROM new_sales_modified AS sal
	LEFT JOIN product_modified AS prod
			ON prod.ProductKey = sal.ProductKey
	LEFT JOIN recent_exchange_rates AS exc
			ON exc.Currency = sal.CurrencyCode
	GROUP BY monthname(sal.orderdate),
			year(sal.orderdate)
) AS agg_table
GROUP BY Year_Name, Month_Name
;

-- View of Revenue and Rates 
CREATE OR REPLACE VIEW Revenue_and_Rates AS
SELECT monthname(orderdate), 
		Quantity AS Orders, 
        UnitPriceUSD,
        Exchange,
        (Quantity * UnitPriceUSD * Exchange) AS Revenue
FROM new_sales_modified AS sal
JOIN product_modified AS prod
		ON sal.ProductKey = prod.ProductKey
JOIN recent_exchange_rates AS exc
		ON exc.Currency = sal.CurrencyCode
;

-- Average Delivery Time in Days
SELECT AVG(Delivery_Time) AS Avg_Delivery_Time
FROM
	(SELECT OrderDate, 
			DeliveryDate, 
			CAST(datediff(deliverydate, orderdate) AS SIGNED) AS Delivery_Time
	FROM new_sales_modified
	WHERE DeliveryDate IS NOT NULL
) AS agg_table2
;

-- Trend of Average Delivery Time by Month and Years
WITH Delivery_CTE AS
(SELECT monthname(deliverydate) Delivery_Month, 
        year(deliverydate) Delivery_Year,
		AVG(CAST(datediff(deliverydate, orderdate) AS SIGNED)) AS Avg_Delivery_Time
FROM new_sales_modified
GROUP BY monthname(deliverydate), 
        year(deliverydate)
)
SELECT *
FROM Delivery_CTE
WHERE Delivery_Month IS NOT NULL
;

-- Average Order Value for Online Sales
SELECT COUNT(*),
		Country,
		SUM(Quantity) AS Order_Volume,
		ROUND(SUM(Revenue),2) AS Total_Revenue_USD,
        ROUND(SUM(Revenue)/SUM(Quantity),2) AS Avg_Order_Value
FROM
	(SELECT Quantity, 
			Country,
			(sal.Quantity * prod.UnitPriceUSD * exc.Exchange) AS Revenue
	FROM new_sales_modified AS sal
	JOIN stores AS str
			ON str.StoreKey = sal.StoreKey
	JOIN product_modified AS prod
			ON prod.ProductKey = sal.ProductKey 
	JOIN recent_exchange_rates AS exc
			ON exc.Currency = sal.CurrencyCode
) AS agg_table3
GROUP BY Country
HAVING Country = 'Online'
;

-- Average Order Value for In-Store Sales
SELECT Country,
		SUM(Quantity) AS Order_Volume,
		ROUND(SUM(Revenue),2) AS Total_Revenue_USD,
        ROUND(SUM(Revenue)/SUM(Quantity),2) AS Avg_Order_Value
FROM
	(SELECT Quantity, 
			Country,
			(sal.Quantity * prod.UnitPriceUSD * exc.Exchange) AS Revenue
	FROM new_sales_modified AS sal
	LEFT JOIN stores AS str
			ON str.StoreKey = sal.StoreKey
	LEFT JOIN product_modified AS prod
			ON prod.ProductKey = sal.ProductKey 
	LEFT JOIN recent_exchange_rates AS exc
			ON exc.Currency = sal.CurrencyCode
) AS agg_table4
GROUP BY Country
HAVING Country != 'Online'
ORDER BY Country
;

-- Average Order Value for In-Store & Online Sales
WITH Store_CTE AS
(SELECT 
	CASE
		WHEN country = 'Online' THEN 'Online'
        ELSE 'In-store'
	END AS Stores,
    SUM(Quantity) AS Order_Volume,
    SUM(sal.Quantity * prod.UnitPriceUSD * exc.Exchange) AS Revenue
FROM new_sales_modified AS sal
JOIN stores AS st
		ON st.StoreKey = sal.StoreKey
JOIN product_modified AS prod
			ON prod.ProductKey = sal.ProductKey 
	JOIN recent_exchange_rates AS exc
			ON exc.Currency = sal.CurrencyCode
GROUP BY CASE
		WHEN country = 'Online' THEN 'Online'
        ELSE 'In-store'
	END
)
SELECT Stores, ROUND((Revenue/Order_Volume),2) AS Avg_Order_Value
FROM Store_CTE
    ;
    

-- Customers Age Range
CREATE VIEW Customers_Age_and_Gender AS
SELECT Name, Gender,TIMESTAMPDIFF(YEAR, birthday, CURDATE()) AS Age
FROM customers
;

SELECT Gender,
		MAX(age) AS Oldest_Age,
		MIN(age) AS Youngest_Age, 
        AVG(age) AS Average_Age
FROM customers_age_and_gender
GROUP BY Gender
;

-- Total Orders & Revenue by Customers
SELECT Name,
		Country,
		SUM(Quantity) AS Total_Orders,
        ROUND(SUM(Revenue),2) AS Total_Revenue_USD
FROM
	(SELECT Name,
			Quantity,
			Country,
			(sal.Quantity * prod.UnitPriceUSD * exc.Exchange) AS Revenue
	FROM new_sales_modified AS Sal
	JOIN Customers AS Cus
				ON Cus.Customerkey = Sal.customerkey
	JOIN product_modified AS prod
			ON prod.ProductKey = sal.ProductKey 
	JOIN recent_exchange_rates AS exc
			ON exc.Currency = sal.CurrencyCode
	) AS Agg_table5
GROUP BY Name, Country
ORDER BY Name
;

-- Total Gender Count of Customers
SELECT Gender, COUNT(Gender) AS Gender_Count
FROM customers_age_and_gender
GROUP BY Gender
;

-- Count of Customers by Continent and Country 
SELECT Continent, Country, 
		COUNT(Country) AS Customers_Count
FROM customers
GROUP BY Continent, Country
;

-- Total Orders for In-Strore Sales
SELECT Country, 
		SUM(Quantity) AS Total_Order_Volume
FROM new_sales_modified AS sal
LEFT JOIN stores AS str
		ON str.StoreKey = sal.StoreKey
GROUP BY Country
HAVING Country != 'Online' 
ORDER BY Country 
;

-- Total Orders for Online Sales
SELECT Country, 
		SUM(Quantity) AS Total_Order_Volume
FROM new_sales_modified AS sal
LEFT JOIN stores AS str
		ON str.StoreKey = sal.StoreKey
GROUP BY Country
HAVING Country = 'Online' 
;

WITH All_Stores_CTE AS
(SELECT 
	CASE
		WHEN country = 'Online' THEN 'Online'
        ELSE 'In-store'
	END AS Stores,
    SUM(Quantity) AS Order_Volume
FROM new_sales_modified AS sal
JOIN stores AS st
		ON st.StoreKey = sal.StoreKey
GROUP BY CASE
		WHEN country = 'Online' THEN 'Online'
        ELSE 'In-store'
	END
)
SELECT Stores, Order_Volume AS Total_Order_Volume
FROM All_Stores_CTE
;

-- Profit, Revenue, Total Cost, Average Order Value by Products Category
WITH Products_CTE AS
(SELECT Quantity, 
        Category,
		(sal.Quantity * prod.UnitPriceUSD * exc.Exchange) AS Revenue,
        (sal.Quantity * prod.UnitCostUSD * exc.Exchange) AS Cost
FROM new_sales_modified AS sal
LEFT JOIN product_modified AS prod
		ON prod.ProductKey = sal.ProductKey 
LEFT JOIN recent_exchange_rates AS exc
		ON exc.Currency = sal.CurrencyCode
)
SELECT Category AS Product_Category,
		SUM(Quantity) AS Total_Order_Vol,
        ROUND(SUM(Cost),2) AS Total_Cost_USD, 
        ROUND(SUM(Revenue),2) AS Total_Revenue_USD,
        ROUND(SUM(Revenue - Cost),2) AS Profit_USD,
        ROUND(SUM(Revenue)/SUM(Quantity),2) AS Avg_Order_Value
FROM Products_CTE
GROUP BY Category
ORDER BY Category
;
