--View Data
SELECT *
FROM Superstore.dbo.Sueprstore$
WHERE [Customer Name] = 'Mitch Willingham'

--CLEAN DATE
--Change date format (dd/mm/yyyy)
SELECT CONVERT (varchar(8), [Order Date], 3)
FROM Superstore.dbo.Sueprstore$

--Add month and year column
ALTER TABLE Superstore.dbo.Sueprstore$
ADD [Month] varchar(255), [Year] varchar(255)

UPDATE Superstore.dbo.Sueprstore$
SET [Month] = CONVERT(varchar(3), [Order date], 100),
[Year] = YEAR([Order date])



--ANALYSIS

--Q1: Which  month had the highest sales?
--A: Sales are higher towards end of year (i.e. Sep, Oct, Nov, Dec). This is consisten with previous years.
SELECT [Month],[Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
WHERE [Year] = 2018
GROUP BY [Month], [Year]
ORDER BY 3 DESC

--Q2: Which year had the highest sales?
--A: 2018 had the highest sales.
SELECT [Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
GROUP BY [Year]
ORDER BY 2 DESC

--Q3: Which customers had the highest sales?
--A: 2018 Raymond Buch, Tom Ashbrook Hunter Lopez. Varies every year.
SELECT [Customer Name], [Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
GROUP BY [Customer Name], [Year]
ORDER BY 2 DESC, 3 DESC 

--Q4: Which city had the highest sales?
--A: 2018: New York, Seattle, LA. NY and LA in top 3 every year since 2015.
SELECT City, [Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
GROUP BY City, [Year]
ORDER BY 2 DESC, 3 DESC 

--Q5: Which State had the highest sales?
--A: Calafornia and NY have highest sales. Consistent with City sales.
SELECT [State], [Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
GROUP BY [State], [Year]
ORDER BY 2 DESC, 3 DESC 

--Q6: Which Category had the highest sales?
--A: Technology has the highest selling category. However all categories had similar sales.
SELECT Category, [Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
GROUP BY Category, [Year]
ORDER BY 2 DESC, 3 DESC 

--Q7: Which sub-category had the highest sales? 
--A: Chairs and phones sold the best during each year.
SELECT [Sub-Category], [Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
GROUP BY [Sub-Category], [Year]
ORDER BY 2 DESC, 3 DESC 

--Q8: Which product had the highest sales? 
--A: Canon Advanced Copier
SELECT [Product Name], [Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
GROUP BY [Product Name], [Year]
ORDER BY 3 DESC 

--Q9: Which Segment had the highest sales? 
--A: Consumer sold the best followed by, corporate and Home Office.
SELECT Segment, [Year], SUM(Sales) as total_sales
FROM Superstore.dbo.Sueprstore$
GROUP BY Segment, [Year]
ORDER BY 3 DESC 

--Q10: Which products were purchased together? (use sub-categories) 
--A: Paper and binders most commonly purchased together. Many purchase combinations include binders.
WITH t1 AS(
	SELECT [Order ID] ,STUFF(
		(SELECT ',' + [Sub-Category]
		FROM Superstore.dbo.Sueprstore$ p
		WHERE [Order ID] in
			(
				SELECT [Order ID]
				FROM (
					SELECT [Order ID], COUNT(*) as total_orders
					FROM Superstore.dbo.Sueprstore$
					GROUP BY [Order ID]
					) m
				WHERE total_orders >= 2
				)
				AND p.[Order ID] = s.[Order ID]
				for xml path('')) 
				, 1, 1, '') as Products
	FROM Superstore.dbo.Sueprstore$ s
	GROUP BY [Order ID]		
)
SELECT DISTINCT Products, COUNT(Products)OVER(PARTITION BY Products) as count_products  
FROM t1
WHERE Products IS NOT NULL
GROUP BY [Order ID], Products
ORDER BY 2 DESC


--Q11 Perform RFM analysis. Recency, frequency, monetary.
--A: Created a scoring system to rate most valuable customers. Customers with rfm_score close to 30 indicates they have purchased recently, are frequent purchasers and spend a lot.
WITH t1 as(
	SELECT 
		[Customer Name],
		CAST((SELECT Max([Order Date]) FROM Superstore.dbo.Sueprstore$)  - MAX([Order Date]) as int) as Days_since_last_sale,
		COUNT([Customer Name]) as number_orders,
		AVG(Sales) as Average_sales,
		SUM(Sales) as Total_Sales
	FROM Superstore.dbo.Sueprstore$
	GROUP BY [Customer Name]
),
t2 as(
	SELECT*,
		NTILE(10) OVER (ORDER BY Days_since_last_sale DESC) as rfm_recency,
		NTILE(10) OVER (ORDER BY number_orders) as rfm_frequency,
		NTILE(10) OVER (ORDER BY Average_sales) as rfm_monetary
	FROM t1
)
SELECT *,rfm_recency+rfm_frequency+rfm_monetary as rfm_score 
FROM t2
ORDER BY 9 DESC