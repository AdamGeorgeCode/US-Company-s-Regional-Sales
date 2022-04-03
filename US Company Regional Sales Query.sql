-- Extract table column headings
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('customers','products','regions','sales_orders','sales_team', 'store_locations');

-- Profit calculation - computes the profit for each of the ordernumbers in sales_orders
-- This was to test the calculation was correct before the values were added to a newly created column in sales_orders
SELECT ordernumber, ROUND((((unit_price*(1-discount_applied)) - unit_cost)*order_quantity),2) AS Profit
FROM sales_orders

-- Add Profit column to sales_orders table
ALTER TABLE sales_orders ADD Profit DECIMAL(10,2)

-- Update sales_order Profit column with the Profit calculation
UPDATE sales_orders
SET Profit = ROUND((((unit_price*(1-discount_applied)) - unit_cost)*order_quantity),2)

-- Change sales_order productid column data type to smallint - to help with merger of data in Tableau
ALTER TABLE sales_orders ALTER COLUMN productid smallint

-- Calculates the total profit for each of the product ids then orders from highest to lowest (DESC)
SELECT productid, SUM(Profit) AS 'TotalProfit' FROM sales_orders
GROUP BY productid
ORDER BY SUM(Profit) DESC

-- Creates a new view that ranks the product_names by total profit from highest to lowest (DESC)
DROP VIEW IF EXISTS rtotal_profit;
GO
CREATE VIEW rtotal_profit AS
WITH t1 as (SELECT products.product_name, sales_orders.Profit FROM sales_orders
LEFT JOIN products
ON sales_orders.productid = products.productid) 
SELECT rank() over (order by sum(profit) desc) as Rank, product_name, SUM(profit) AS total_profit
FROM t1
GROUP BY (product_name)

-- Checks that rtotal_profit view has been created successfully
-- The rank values from this view are used for the rank values in the product dashboard in Tableau
SELECT * FROM rtotal_profit

-- Change sales_orders Salesteamid column data type to smallint - to help with merger of data in Tableau
ALTER TABLE sales_orders ALTER COLUMN Salesteamid smallint

-- Change sales_orders storeid column data type to smallint - to help with merger of data in Tableau
ALTER TABLE sales_orders ALTER COLUMN storeid smallint

-- Calculates the total_profit for each of the product_names in the the states of ('Arizona', 'Arkansas')
-- This was to check the same calculation that was created in Tableau was correct
SELECT product_name, SUM(profit) as 'total_profit'
FROM (
SELECT products.product_name, sales_orders.profit, store_locations.state FROM sales_orders
LEFT JOIN store_locations
ON sales_orders.storeid = store_locations.storeid
LEFT JOIN products
ON sales_orders.productid = products.productid
WHERE state in ('Arizona', 'Arkansas')) as t1
GROUP BY (product_name)
ORDER BY SUM(profit) DESC