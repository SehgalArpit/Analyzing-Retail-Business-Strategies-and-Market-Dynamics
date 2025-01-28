----------------------------------------------------------------------CREATE DATABASE----------------------------------------------------------------------------------
CREATE DATABASE PROJECT_01

-----------------------------------------------------------------------USE DATABASE---------------------------------------------------------------------------------------- 
USE PROJECT_01

---------------------------------------------------------------------IMPORTING TABLES----------------------------------------------------------------------------------
SELECT TOP 1 * FROM Customers
SELECT TOP 1 * FROM OrderPayments
SELECT TOP 1 * FROM OrderReview_Ratings
SELECT TOP 1 * FROM Orders
SELECT TOP 1 * FROM ProductsInfo
SELECT TOP 1 * FROM Stores_Info

----------------------------------------------------------------------TOTAL RECORDS---------------------------------------------------------------------------------------
--TOTAL_RECORDS IN Customers Table = 99441 , Duplicates = 0 , Unique = 99441
--TOTAL_RECORDS IN OrderPayments Table = 103886 , Duplicates = 615, Unique = 103271
--TOTAL_RECORDS IN OrderReview_Ratings Table = 100000 , Duplicates = 350 , Unique = 99650
--TOTAL_RECORDS IN Orders Table = 112650 , Duplicates = 0 , Unique = 112650
--TOTAL_RECORDS IN ProductsInfo Table = 32951 , Duplicates = 0 , Unique = 32951
--TOTAL_RECORDS IN Stores_Info Table = 535 , Duplicates = 1 , Unique = 534

-----------------------------------------------------------------------DATA CLEANING------------------------------------------------------------------------------------
--Customers TABLE
SELECT DISTINCT A.* FROM Customers AS A --THERE IS NO DUPLICATES RECORD

--OrderPayments TABLE
SELECT * INTO Order_Payments FROM --THERE IS 615 DUPLICATES RECORD
(SELECT DISTINCT A.* FROM OrderPayments AS A ) AS N

DROP TABLE OrderPayments --DROPPING OLD TABLE AND CREATING NEW TABLE WHICH CONTAINS ONLY UNIQUE RECORD

SELECT * FROM Order_Payments AS D --NEW TABLE

--OrderReview_Ratings Table
SELECT * INTO Order_Review_Ratings FROM
(SELECT DISTINCT A.* FROM OrderReview_Ratings AS A) N  --THERE IS 350 DUPLICATES IN RECORD

DROP TABLE OrderReview_Ratings --DROPPING OLD TABLE AND CREATING NEW TABLE WHICH CONTAINS ONLY UNIQUE RECORD

SELECT * FROM Order_Review_Ratings AS D --NEW TABLE

ALTER TABLE Order_Review_Ratings -- Changing datatype of Customer_Satisfaction_Score
ALTER COLUMN Customer_Satisfaction_Score FLOAT

--Orders Table
SELECT DISTINCT A.* FROM Orders AS A --THERE IS NO DUPLICATES RECORD

--ProductsInfo Table
SELECT DISTINCT A.* FROM ProductsInfo AS A --THERE IS NO DUPLICATES IN RECORD

--Stores_Info Table
SELECT * INTO StoresInfo FROM
(SELECT DISTINCT A.* FROM Stores_Info AS A ) AS N --THERE IS 01 DUPLICATE RECORD

DROP TABLE Stores_Info --DROPPING OLD TABLE AND CREATING NEW TABLE WHICH CONTAINS ONLY UNIQUE RECORD

SELECT * FROM StoresInfo AS D --NEW TABLE

ALTER TABLE Orders --Dropping Total Amount Column
DROP COLUMN Total_Amount

ALTER TABLE Orders --Creating Total Amount Column
ADD Total_Amount FLOAT

UPDATE Orders -- Updating Quantity Column With 1 where Total_Amount <> Payment Value
SET Quantity = 1
WHERE Customer_id IN (
SELECT DISTINCT A.Customer_id FROM Orders AS A
LEFT JOIN 
Order_Payments AS B
ON A.order_id = B.order_id
WHERE A.Total_Amount <> B.payment_value )

UPDATE Orders --Creating New Total Amount Column  
SET Total_Amount = Quantity*MRP - Quantity*Discount

----------------------------------------------------------------------NEW TABLES----------------------------------------------------------------------------------------
SELECT TOP 1 * FROM Customers
SELECT TOP 1 * FROM Order_Payments
SELECT TOP 1 * FROM Order_Review_Ratings
SELECT TOP 1 * FROM Orders
SELECT TOP 1 * FROM ProductsInfo
SELECT TOP 1 * FROM StoresInfo

--------------------------------------------------------------------CREATING NEW TABLES---------------------------------------------------------------------------------
--CUSTOMER LEVEL
SELECT * INTO CUSTOMER_LEVEL FROM
(SELECT F.Custid,F.customer_city,F.customer_state,F.Gender,COUNT(F.Custid) AS Total_Orders,
AVG(F.Customer_Satisfaction_Score) AS Cust_Satisfaction,Sum(F.Quantity) AS Total_Qty,SUM(F.Total_Amount) AS Total_Spend,
SUM(F.Discount*F.Quantity) AS Discount_Amt FROM
(SELECT A.*,C.order_id,C.payment_type,C.payment_value,D.Customer_Satisfaction_Score,B.Channel,B.Quantity,B.Total_Amount,B.Discount FROM Customers AS A
RIGHT JOIN 
Orders AS B
ON A.Custid = B.Customer_id
LEFT JOIN 
Order_Payments AS C
ON B.order_id = C.order_id
LEFT JOIN
Order_Review_Ratings AS D
ON B.order_id = D.order_id ) AS F
GROUP BY F.Custid,F.Gender,F.customer_city,F.customer_state
) AS G

SELECT * FROM CUSTOMER_LEVEL

---GENDER WISE CUSTOMER COUNT
SELECT A.Gender,COUNT(A.Gender) AS CUST_CNT FROM CUSTOMER_LEVEL AS A
GROUP BY A.Gender

---STATE WISE CUSTOMER COUNT
SELECT A.customer_state,COUNT(A.Gender) AS CUST_CNT FROM CUSTOMER_LEVEL AS A
GROUP BY A.customer_state
ORDER BY COUNT(A.Gender) DESC

--ORDER LEVEL
SELECT * INTO ORDER_LEVEL FROM
(SELECT F.order_id,CONCAT_WS(' ',F.seller_city,F.seller_state,F.Region) AS Order_Location,F.Channel,F.payment_type AS Order_Payment_Type,
SUM(F.Quantity) AS Total_Qty_Order,SUM(F.Total_Amount) AS Order_Price,SUM(F.Discount*F.Quantity) AS Discount_Amt FROM 
(SELECT A.order_id,A.Quantity,A.Channel,A.Total_Amount,B.payment_type,A.Discount,
C.Customer_Satisfaction_Score,D.Region,D.seller_city,D.seller_state FROM Orders AS A
LEFT JOIN 
Order_Payments AS B
ON A.order_id = B.order_id
LEFT JOIN 
Order_Review_Ratings AS C
ON A.order_id = C.order_id
LEFT JOIN 
StoresInfo AS D
ON D.StoreID = A.Delivered_StoreID ) AS F
GROUP BY F.order_id,CONCAT_WS(' ',F.seller_city,F.seller_state,F.Region),F.payment_type,F.Channel ) AS G

SELECT * FROM ORDER_LEVEL

---CHANNEL WISE ORDERS
SELECT A.Channel,COUNT(A.order_id) AS ORDERS FROM ORDER_LEVEL AS A
GROUP BY A.Channel

---PAYMENT TYPE WISE ORDERS
SELECT A.Order_Payment_Type,COUNT(A.order_id) AS ORDERS FROM ORDER_LEVEL AS A
GROUP BY A.Order_Payment_Type
ORDER BY COUNT(A.order_id) DESC

--STORE LEVEL
SELECT * INTO STORE_LEVEL FROM 
(SELECT D.StoreID,CONCAT_WS(' ',D.seller_city,D.seller_state,D.Region) AS Store_Location,COUNT(d.order_id) AS Total_Orders,
SUM(D.Quantity) AS Qunatity_Sold,
SUM(D.Total_Amount) AS Total_Revenue,SUM(D.Discount*D.Quantity) AS Discount_Amt FROM
(SELECT A.Customer_id,A.order_id,A.product_id,A.Quantity,A.Total_Amount,
B.Region,B.seller_city,B.seller_state,B.StoreID,A.Discount FROM Orders AS A
LEFT JOIN 
StoresInfo AS B
ON A.Delivered_StoreID = B.StoreID ) AS D
GROUP BY D.StoreID,CONCAT_WS(' ',D.seller_city,D.seller_state,D.Region)) AS G

SELECT * FROM STORE_LEVEL

---TOP 10 STORES ORDER WISE
SELECT TOP 10 A.StoreID,SUM(A.Total_Orders) AS ORDERS FROM STORE_LEVEL AS A
GROUP BY A.StoreID
ORDER BY SUM(A.Total_Orders) DESC

---TOP 5 STORES SALES WISE
SELECT TOP 5 A.StoreID,SUM(A.Total_Revenue) AS Sales FROM STORE_LEVEL AS A
GROUP BY A.StoreID
ORDER BY SUM(A.Total_Revenue) DESC

---TOP 5 STORES SALES WISE
SELECT TOP 5 A.StoreID,SUM(A.Discount_Amt) AS Discount FROM STORE_LEVEL AS A
GROUP BY A.StoreID
ORDER BY SUM(A.Discount_Amt) DESC

-------------------------------------------------------------Perform Detailed exploratory analysis-------------------------------------------------------------------------

--Number of Orders
SELECT COUNT(distinct a.order_id) AS Total_Orders
FROM orders AS A

--Total Discount In Amount
SELECT SUM(A.Quantity*A.Discount) AS Total_Discount FROM orders AS A

--Average Discount per Customer
SELECT AVG(S.Total_Discount_Per_Cust) AS Average_Discount_Per_Customer
FROM (
    SELECT A.Customer_id, SUM(A.Quantity*A.Discount) AS Total_Discount_Per_Cust
    FROM orders AS A
    GROUP BY A.Customer_id
) AS S

--Average Discount per Order
SELECT AVG(A.Quantity*A.Discount) AS Average_Discount_per_Order
FROM orders AS A

-- Average Order Value (Average Bill Value)
SELECT AVG(A.Total_Amount) AS Average_Order_Value
FROM orders AS A

--Average Sales per Customer
SELECT AVG(H.Avg_Sales) AS Average_Sales_Per_Customer
FROM (
    SELECT D.Customer_id, SUM(D.Total_Amount) AS Avg_Sales
    FROM orders AS D
    GROUP BY D.Customer_id
) AS H

--Average Profit per Customer
SELECT AVG(L.Profit) AS Average_Profit_per_Customer
FROM (
    SELECT D.Customer_id, SUM(D.Total_Amount - D.Quantity*D.Cost_Per_Unit) AS Profit
    FROM orders AS D
    GROUP BY D.Customer_id
) AS L

--Average Number of Categories per Order
SELECT AVG(F.Avg_Categories_Per_Order) AS Average_Number_of_Categories_per_Order
FROM (
    SELECT C.order_id, AVG(C.Categories_Per_Item) AS Avg_Categories_Per_Order
    FROM (
        SELECT A.order_id, COUNT(DISTINCT B.Category) AS Categories_Per_Item
        FROM Orders AS A
        LEFT JOIN
		ProductsInfo AS B 
		ON A.product_id = B.product_id
        GROUP BY A.order_id,A.product_id
        ) AS C
        GROUP BY C.order_id
) AS F

--Average Number of Items per Order
SELECT AVG(D.Items_per_order) AS Average_Number_of_Items_per_Order
FROM (
    SELECT A.order_id, SUM(A.Quantity) AS Items_per_order
    FROM Orders AS A
    GROUP BY A.order_id
) AS D

--Number of Customers
SELECT COUNT(DISTINCT A.Customer_id) AS Number_of_Customers
FROM Orders AS A

--Transactions per Customer
SELECT D.Total_Trans/D.Total_Customer AS Transactions_per_Customer FROM (
SELECT COUNT(*) AS Total_Trans,COUNT(DISTINCT customer_id) AS Total_Customer
FROM Orders AS A ) AS D

--Total Revenue
SELECT SUM(A.Total_Amount) AS Total_Revenue FROM Orders AS A

--Total Profit
SELECT SUM(A.Total_Amount - A.Quantity*A.Cost_Per_Unit) AS Total_Profit
FROM Orders AS A

--Total Cost
SELECT SUM(A.Cost_Per_Unit*A.Quantity) AS Total_Cost FROM Orders AS A

--Total Quantity
SELECT SUM(A.Quantity) AS Total_Quantity
FROM Orders AS A

--Total Products
SELECT COUNT(DISTINCT A.product_id) AS Total_Products
FROM ProductsInfo AS A

--Total Categories
SELECT COUNT(DISTINCT A.Category) AS Total_Categories
FROM ProductsInfo AS A

--Total Stores
SELECT COUNT(DISTINCT A.StoreID) AS Total_Stores FROM StoresInfo AS A

--Total Regions
SELECT COUNT(DISTINCT A.Region) AS Total_Region FROM StoresInfo AS A
SELECT DISTINCT A.Region AS Total_Region FROM StoresInfo AS A

--Total Channels
SELECT COUNT(DISTINCT A.Channel) AS Total_Channels FROM Orders AS A
SELECT DISTINCT A.Channel AS Total_Channels FROM Orders AS A

--Total Payment Method
SELECT COUNT(DISTINCT A.payment_type) AS Total_PaymentMethod FROM Order_Payments AS A
SELECT DISTINCT A.payment_type AS Total_PaymentMethod FROM Order_Payments AS A

--Total Locations
SELECT COUNT(*) AS Total_Location FROM
(SELECT CONCAT_WS(' ',A.seller_city,A.seller_city,A.Region)
  AS Location FROM StoresInfo AS A ) AS B

--Average Number of Days Between Two Transactions (if the customer has more than one transaction)
SELECT AVG(D.Days_Between_Two_Trans) AS Avg_Days_Between_Two_Trans FROM
(SELECT D.Customer_id,DATEDIFF(DAY,D.First_Trans,D.Last_Trans) AS Days_Between_Two_Trans FROM 
(SELECT A.Customer_id,MAX(A.Bill_date_timestamp) AS Last_Trans
,MIN(A.Bill_date_timestamp) AS First_Trans FROM Orders AS A
GROUP BY A.Customer_id ) AS D
WHERE DATEDIFF(DAY,D.First_Trans,D.Last_Trans) > 0 ) AS D

--Percentage of Profit
SELECT (SUM(A.Total_Amount - A.Cost_Per_Unit*A.Quantity) / SUM(A.Total_Amount)) * 100 AS Profit_Perc
FROM Orders AS A

--Percentage of Discount
SELECT (SUM(A.Discount) / SUM(A.Total_Amount)) * 100 AS Discount_Perc
FROM Orders AS A

--New Customers Acquired Every Month
SELECT YEAR(A.Bill_date_timestamp) AS Year,MONTH(A.Bill_date_timestamp) AS Month
,COUNT(DISTINCT A.Customer_id) AS New_Customers
FROM Orders AS A
GROUP BY MONTH(A.Bill_date_timestamp),YEAR(A.Bill_date_timestamp)
ORDER BY YEAR(A.Bill_date_timestamp),MONTH(A.Bill_date_timestamp)

--Top 10 Most Expensive Products
SELECT TOP 10 * FROM
(SELECT DISTINCT A.product_id,A.MRP FROM Orders AS A
 ) AS D
 ORDER BY D.MRP DESC

 --Top 10-Performing Stores in Terms of Sales
 SELECT TOP 10 * FROM
 (SELECT A.Delivered_StoreID AS Store,
SUM(A.Total_Amount-A.Cost_Per_Unit*A.Quantity) AS Profit  FROM Orders AS A
GROUP BY A.Delivered_StoreID ) AS D
ORDER BY D.Profit DESC

--Worst 10-Performing Stores in Terms of Sales
 SELECT TOP 10 * FROM
 (SELECT A.Delivered_StoreID AS Store,
SUM(A.Total_Amount-A.Cost_Per_Unit*A.Quantity) AS Profit  FROM Orders AS A
GROUP BY A.Delivered_StoreID ) AS D
ORDER BY D.Profit 

--Trends/Seasonality of Sales, Quantity by Category, Region, Store, Channel, Payment Method
--By Category
SELECT YEAR(A.Bill_date_timestamp) AS Year_,MONTH(A.Bill_date_timestamp) AS Month_,
B.Category,SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
ProductsInfo AS B
ON A.product_id = B.product_id
GROUP BY YEAR(A.Bill_date_timestamp),MONTH(A.Bill_date_timestamp),B.Category
ORDER BY YEAR(A.Bill_date_timestamp),SUM(A.Quantity) DESC,SUM(A.Total_Amount) DESC

SELECT 
B.Category,SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
ProductsInfo AS B
ON A.product_id = B.product_id
GROUP BY B.Category
ORDER BY SUM(A.Quantity) DESC,SUM(A.Total_Amount) DESC

 --By Region
SELECT YEAR(A.Bill_date_timestamp) AS Year_,MONTH(A.Bill_date_timestamp) AS Month_,
 B.Region,
SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
StoresInfo AS B
ON A.Delivered_StoreID = B.StoreID
GROUP BY YEAR(A.Bill_date_timestamp),MONTH(A.Bill_date_timestamp),B.Region
ORDER BY YEAR(A.Bill_date_timestamp),SUM(A.Total_Amount) desc

SELECT 
 B.Region,
SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
StoresInfo AS B
ON A.Delivered_StoreID = B.StoreID
GROUP BY B.Region
ORDER BY SUM(A.Total_Amount) desc

--By Store
SELECT YEAR(A.Bill_date_timestamp) AS Year_,MONTH(A.Bill_date_timestamp) AS Month_,
A.Delivered_StoreID AS Store,
SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
GROUP BY YEAR(A.Bill_date_timestamp),MONTH(A.Bill_date_timestamp),A.Delivered_StoreID
ORDER BY YEAR(A.Bill_date_timestamp),SUM(A.Quantity) desc,SUM(A.Total_Amount) desc

SELECT 
A.Delivered_StoreID AS Store,
SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
GROUP BY A.Delivered_StoreID
ORDER BY SUM(A.Quantity) desc,SUM(A.Total_Amount) desc

--By Channel
SELECT YEAR(A.Bill_date_timestamp) AS Year_,MONTH(A.Bill_date_timestamp) AS Month_,
A.Channel,
SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
GROUP BY YEAR(A.Bill_date_timestamp),MONTH(A.Bill_date_timestamp),A.Channel
ORDER BY YEAR(A.Bill_date_timestamp),SUM(A.Quantity) desc,SUM(A.Total_Amount) desc

SELECT 
 A.Channel,
SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
GROUP BY A.Channel
ORDER BY SUM(A.Quantity) desc,SUM(A.Total_Amount) desc

--By Payment Method
SELECT YEAR(A.Bill_date_timestamp) AS Year_,MONTH(A.Bill_date_timestamp) AS Month_,
B.payment_type AS Payment_Method,
SUM(A.Quantity) AS Quantity,SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
Order_Payments AS B
ON A.order_id = B.order_id
GROUP BY YEAR(A.Bill_date_timestamp),MONTH(A.Bill_date_timestamp),B.payment_type
ORDER BY YEAR(A.Bill_date_timestamp),MONTH(A.Bill_date_timestamp)

--Popular Categories/Popular Products by Store, State, Region

--Popular Products By Store
SELECT * FROM 
(SELECT *,ROW_NUMBER() OVER(PARTITION BY D.Delivered_StoreID ORDER BY D.Orders DESC,D.Quantity DESC,D.Sales DESC) AS RANK_
 FROM
(SELECT A.Delivered_StoreID,A.product_id,
COUNT(A.order_id) AS Orders,SUM(A.Quantity) AS Quantity,
sum(A.Total_Amount) AS Sales FROM Orders AS A
GROUP BY A.product_id,A.Delivered_StoreID 
) AS D
) AS F
WHERE F.RANK_ = 1

--Popular Categories By Store
SELECT * FROM (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY D.Delivered_StoreID ORDER BY D.Orders DESC,D.Quantity DESC,D.Sales DESC) AS RANK_ FROM
(SELECT A.Delivered_StoreID,B.Category,COUNT(A.order_id) AS Orders,SUM(A.Quantity) AS Quantity,
SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
ProductsInfo AS B
ON A.product_id = B.product_id
GROUP BY B.Category,A.Delivered_StoreID ) AS D
) AS P
WHERE P.RANK_ = 1

--Popular Products By State
SELECT * FROM 
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY D.State_ ORDER BY D.Orders DESC,D.Quantity DESC,D.Sales DESC) AS RANK_ FROM
(SELECT B.customer_state AS State_,A.product_id,COUNT(A.order_id) AS Orders,SUM(A.Quantity) AS Quantity,
SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
Customers AS B
ON A.Customer_id = B.Custid
GROUP BY a.product_id,b.customer_state ) AS D
) AS W
WHERE W.RANK_ = 1

--Popular Categories By State
SELECT * FROM 
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY D.State_ ORDER BY D.Orders DESC,D.Quantity DESC,D.Sales DESC) AS RANK_ FROM
(SELECT B.customer_state AS State_,C.Category,COUNT(A.order_id) AS Orders,SUM(A.Quantity) AS Quantity,
SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
Customers AS B
ON A.Customer_id = B.Custid
LEFT JOIN
ProductsInfo AS C
ON C.product_id = A.product_id
GROUP BY B.customer_state,C.Category) AS D
) AS W
WHERE W.RANK_ = 1

--Popular Products By Region
SELECT * FROM 
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY D.Region ORDER BY D.Orders DESC,D.Quantity DESC,D.Sales DESC) AS RANK_ FROM
(SELECT B.Region,A.product_id,COUNT(A.order_id) AS Orders,SUM(A.Quantity) AS Quantity,
SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
StoresInfo AS B
ON A.Delivered_StoreID = B.StoreID
GROUP BY a.product_id,B.Region) AS D
) AS W
WHERE W.RANK_ = 1

--Popular Categories By Region
SELECT * FROM 
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY D.Region ORDER BY D.Orders DESC,D.Quantity DESC,D.Sales DESC) AS RANK_ FROM
(SELECT B.Region,C.Category,COUNT(A.order_id) AS Orders,SUM(A.Quantity) AS Quantity,
SUM(A.Total_Amount) AS Sales FROM Orders AS A
LEFT JOIN 
StoresInfo AS B
ON A.Delivered_StoreID = B.StoreID
LEFT JOIN
ProductsInfo AS C
ON A.product_id = C.product_id
GROUP BY C.Category,B.Region) AS D
) AS W
WHERE W.RANK_ = 1

------------------------------------------------------------------------ Customer Behaviour -----------------------------------------------------------------------------
--Segment the customers (divide the customers into groups) based on the revenue

--STEP-O1.Finding out MAX & MIN Revenue
SELECT MIN(D.REVENUE) AS MIN_Revenue,MAX(D.REVENUE) AS MAX_Revenue FROM 
(SELECT A.Customer_id,SUM(A.Total_Amount) AS REVENUE FROM Orders AS A
GROUP BY A.Customer_id ) AS D

--STEP-02.Talking HIGH_REVENUE_CUSTOMERS(>=5000),MEDIUM_REVENUE_CUSTOMERS(>=2500),LOW_REVENUE_CUSTOMERS(<2500)

--STEP-03.
SELECT SUM(CASE WHEN D.REVENUE >= 5000 THEN 1 ELSE 0 END) AS HIGH_REVENUE_CUSTOMERS,
       SUM(CASE WHEN D.REVENUE >= 2500 THEN 1 ELSE 0 END) AS MEDIUM_REVENUE_CUSTOMERS,
	   SUM(CASE WHEN D.REVENUE < 2500 THEN 1 ELSE 0 END) AS LOW_REVENUE_CUSTOMERS FROM
(SELECT A.Customer_id,SUM(A.Total_Amount) AS REVENUE FROM Orders AS A
GROUP BY A.Customer_id 
) AS D

--Find out the number of customers who purchased in all the channels and find the key metrics.
SELECT DISTINCT D.Customer_id FROM Orders AS D
WHERE D.Customer_id IN (
SELECT A.Customer_id FROM Orders AS A
WHERE A.Channel = 'Online') AND D.Customer_id IN
(SELECT A.Customer_id FROM Orders AS A
WHERE A.Channel = 'Instore') AND D.Customer_id IN
(SELECT A.Customer_id FROM Orders AS A
WHERE A.Channel = 'Phone Delivery')

--Understand the behavior of one time buyers and repeat buyers
SELECT d.Customer_id AS Repeat_Buyers,D.Total_Order_Placed FROM  --REPEAT BUYERS
(SELECT A.Customer_id,COUNT( DISTINCT A.order_id)
AS Total_Order_Placed FROM Orders AS A
GROUP BY A.Customer_id ) AS D
WHERE D.Total_Order_Placed > 1
ORDER BY d.Total_Order_Placed desc

SELECT d.Customer_id AS one_time_buyer,D.Total_Order_Placed FROM  --one time buyer
(SELECT A.Customer_id,COUNT( DISTINCT A.order_id)
AS Total_Order_Placed FROM Orders AS A
GROUP BY A.Customer_id ) AS D
WHERE D.Total_Order_Placed = 1
ORDER BY d.Total_Order_Placed desc

--BEHAVIOUR OF ONE TIME BUYERS
SELECT B.Delivered_StoreID AS Store,COUNT(distinct B.Customer_id) AS Cust_Count FROM Orders AS B
WHERE B.Customer_id IN (SELECT d.Customer_id AS Repeat_Buyers FROM  --one time buyer
(SELECT A.Customer_id,COUNT( DISTINCT A.order_id)
AS Total_Order_Placed FROM Orders AS A
GROUP BY A.Customer_id ) AS D
WHERE D.Total_Order_Placed = 1
)
GROUP BY B.Delivered_StoreID
ORDER BY COUNT( distinct B.Customer_id) DESC --OUT OF 98537 BUYERS 25403 ARE PURCHASING FROM ST103

SELECT D.customer_state AS City,COUNT(distinct D.Custid) AS Cust_Count FROM Orders AS B
LEFT JOIN 
Customers AS D
ON B.Customer_id = D.Custid
WHERE B.Customer_id IN (SELECT d.Customer_id AS Repeat_Buyers FROM  --one time buyer
(SELECT A.Customer_id,COUNT( DISTINCT A.order_id)
AS Total_Order_Placed FROM Orders AS A
GROUP BY A.Customer_id ) AS D
WHERE D.Total_Order_Placed = 1)
GROUP BY D.customer_state
ORDER BY COUNT(D.Custid) DESC --OUT OF 98537 BUYERS 60142 ARE FROM ANDHRA PRADESH

SELECT D.Region,COUNT( distinct B.Customer_id) AS Cust_Count FROM Orders AS B
LEFT JOIN 
StoresInfo AS D
ON B.Delivered_StoreID = D.StoreID
WHERE B.Customer_id IN (SELECT d.Customer_id AS Repeat_Buyers FROM  --one time buyer
(SELECT A.Customer_id,COUNT( DISTINCT A.order_id)
AS Total_Order_Placed FROM Orders AS A
GROUP BY A.Customer_id ) AS D
WHERE D.Total_Order_Placed = 1)
GROUP BY D.Region
ORDER BY COUNT(B.Customer_id) DESC --OUT OF 98537 BUYERS 76046 ARE FROM SOUTH

--BEHAVIOUR OF REPEAT BUYERS
SELECT B.Delivered_StoreID AS Store,COUNT(DISTINCT B.Customer_id) AS Cust_Count FROM Orders AS B
WHERE B.Customer_id IN (SELECT d.Customer_id AS Repeat_Buyers FROM  --one time buyer
(SELECT A.Customer_id,COUNT( DISTINCT A.order_id)
AS Total_Order_Placed FROM Orders AS A
GROUP BY A.Customer_id ) AS D
WHERE D.Total_Order_Placed > 1)
GROUP BY B.Delivered_StoreID
ORDER BY COUNT(DISTINCT B.Customer_id) DESC --OUT OF 38 BUYERS 19 ARE PURCHASING FROM ST103

SELECT D.customer_state AS City,COUNT(DISTINCT B.Customer_id) AS Cust_Count FROM Orders AS B
LEFT JOIN 
Customers AS D
ON B.Customer_id = D.Custid
WHERE B.Customer_id IN (SELECT d.Customer_id AS Repeat_Buyers FROM  --one time buyer
(SELECT A.Customer_id,COUNT( DISTINCT A.order_id)
AS Total_Order_Placed FROM Orders AS A
GROUP BY A.Customer_id ) AS D
WHERE D.Total_Order_Placed > 1)
GROUP BY D.customer_state
ORDER BY COUNT(DISTINCT B.Customer_id) DESC --OUT OF 38 BUYERS 22 ARE FROM ANDHRA PRADESH


-------------------------Understand the behavior of discount seekers & non discount seekers
SELECT COUNT(DISTINCT A.Customer_id) AS NON_DISCOUNT_SEEKER FROM Orders AS A --NON_DISCOUNT_SEEKER ARE 56532
WHERE A.Discount = 0 AND A.Customer_id NOT IN (SELECT DISTINCT A.Customer_id FROM Orders AS A
WHERE A.Discount > 0)


SELECT COUNT(DISTINCT A.Customer_id) AS DISCOUNT_SEEKER FROM Orders AS A --DISCOUNT_SEEKER ARE 42043
WHERE A.Discount > 0

--BEHAVIOUR OF DISCOUNT SEEKER
SELECT B.Customer_id,SUM(B.Discount) AS Total_Discount FROM Orders AS B
WHERE B.Customer_id IN (SELECT DISTINCT A.Customer_id FROM Orders AS A 
WHERE A.Discount > 0)
GROUP BY B.Customer_id
ORDER BY SUM(B.Discount) DESC --HIGHEST DISCOUNT PROVIDED TO "7444228609" CUSTOMER

SELECT B.Delivered_StoreID AS STORE,COUNT(DISTINCT B.Customer_id) AS Cust_Count FROM Orders AS B
WHERE B.Customer_id IN (SELECT DISTINCT A.Customer_id FROM Orders AS A 
WHERE A.Discount > 0)
GROUP BY B.Delivered_StoreID 
ORDER BY COUNT(DISTINCT B.Customer_id) DESC --OUT OF 42043 DISCOUNT SEEKERS 8980 PURCHASING FROM ST103 & 3764 PURCHASING FROM ST143

SELECT D.Region,COUNT(DISTINCT F.Customer_id) AS Cust_Count FROM Orders AS F
LEFT JOIN 
StoresInfo AS D
ON F.Delivered_StoreID = D.StoreID
WHERE F.Customer_id IN (SELECT DISTINCT A.Customer_id FROM Orders AS A 
WHERE A.Discount > 0)
GROUP BY D.Region
ORDER BY COUNT(DISTINCT F.Customer_id) DESC --OUT OF 42043 DISCOUNT SEEKERS 31572 FROM SOUTH

SELECT D.seller_state AS State_,COUNT(DISTINCT F.Customer_id) AS Cust_Count FROM Orders AS F
LEFT JOIN 
StoresInfo AS D
ON F.Delivered_StoreID = D.StoreID
WHERE F.Customer_id IN (SELECT DISTINCT A.Customer_id FROM Orders AS A 
WHERE A.Discount > 0)
GROUP BY D.seller_state
ORDER BY COUNT(DISTINCT F.Customer_id) DESC --OUT OF 42043 DISCOUNT SEEKERS 31572 FROM ANDHRA PRADESH

--BEHAVIOUR OF NON-DISCOUNT SEEKER 
SELECT B.Delivered_StoreID AS STORE,COUNT(DISTINCT B.Customer_id) AS Cust_Count FROM Orders AS B
WHERE B.Customer_id IN (SELECT DISTINCT A.Customer_id FROM Orders AS A 
WHERE A.Discount = 0 AND A.Customer_id NOT IN (SELECT DISTINCT A.Customer_id FROM Orders AS A
WHERE A.Discount > 0))
GROUP BY B.Delivered_StoreID 
ORDER BY COUNT(DISTINCT B.Customer_id) DESC ----OUT OF 56532 NON DISCOUNT SEEKERS 16442 PURCHASING FROM ST103 & 3855 PURCHASING FROM ST143

SELECT D.Region,COUNT(DISTINCT F.Customer_id) AS Cust_Count FROM Orders AS F
LEFT JOIN 
StoresInfo AS D
ON F.Delivered_StoreID = D.StoreID
WHERE F.Customer_id IN (SELECT DISTINCT A.Customer_id FROM Orders AS A 
WHERE A.Discount = 0 AND A.Customer_id NOT IN (SELECT DISTINCT A.Customer_id FROM Orders AS A
WHERE A.Discount > 0))
GROUP BY D.Region
ORDER BY COUNT(DISTINCT F.Customer_id) DESC --OUT OF 56532 NON DISCOUNT SEEKERS 44512 FROM SOUTH

SELECT D.seller_state AS STATE_,COUNT(DISTINCT F.Customer_id) AS Cust_Count FROM Orders AS F
LEFT JOIN 
StoresInfo AS D
ON F.Delivered_StoreID = D.StoreID
WHERE F.Customer_id IN (SELECT DISTINCT A.Customer_id FROM Orders AS A 
WHERE A.Discount = 0 AND A.Customer_id NOT IN (SELECT DISTINCT A.Customer_id FROM Orders AS A
WHERE A.Discount > 0))
GROUP BY D.seller_state
ORDER BY COUNT(DISTINCT F.Customer_id) DESC --OUT OF 56532 NON DISCOUNT SEEKERS 44512 FROM ANDHRA PRADESH

--Understand preferences of customers (preferred channel, Preferred payment method, preferred store, discount preference, preferred categories etc.)
--Channel preferences of customers
SELECT A.Channel,COUNT(DISTINCT A.Customer_id) --MOST PREFERRED CHANNEL IS INSTORE(ABOUT 86726)
AS Customers FROM Orders AS A
GROUP BY A.Channel

--STORE preferences of customers
SELECT A.Delivered_StoreID AS STORE_,COUNT(DISTINCT A.Customer_id) --MOST PREFERRED STORE IS ST103(ABOUT 25422)
AS Customers FROM Orders AS A
GROUP BY A.Delivered_StoreID
ORDER BY COUNT(DISTINCT A.Customer_id) DESC


--CATEGORY preferences of customers
SELECT B.Category,COUNT(DISTINCT A.Customer_id) --MOST PREFERRED CATEGORY IS TOYS & GIFTS(15031) & BABY(12309) & HOME_APPLIANCES(11519)
AS Customers FROM Orders AS A
LEFT JOIN
ProductsInfo AS B
ON A.product_id = B.product_id
GROUP BY B.Category
ORDER BY COUNT(DISTINCT A.Customer_id) DESC

--PAYMENT METHOD preferences of customers
SELECT B.payment_type AS Payment_Method,COUNT(DISTINCT A.Customer_id) --MOST PREFERRED payment method IS Credit_Cards(75932) & UPI/CASH(19606) 
AS Customers FROM Orders AS A
LEFT JOIN
Order_Payments AS B
ON A.order_id = B.order_id
GROUP BY B.payment_type
ORDER BY COUNT(DISTINCT A.Customer_id) DESC

--Understand the behavior of customers who purchased one category and purchased multiple categories
SELECT H.Customer_id,H.Num_Category
FROM (
    SELECT A.Customer_id, COUNT(DISTINCT B.Category) AS Num_Category --97824 are purchasing only one category
	FROM Orders AS A
	LEFT JOIN 
	ProductsInfo AS B
	ON A.product_id = B.product_id
    GROUP BY A.Customer_id
) AS H
WHERE h.Num_Category = 1

SELECT H.Customer_id,H.Num_Category
FROM (
    SELECT A.Customer_id, COUNT(DISTINCT B.Category) AS Num_Category --751 are purchasing MULTIPLE CATEGORY
    FROM Orders AS A
	LEFT JOIN 
	ProductsInfo AS B
	ON A.product_id = B.product_id
    GROUP BY A.Customer_id
) AS H
WHERE h.Num_Category > 1

--customers who purchased one category
SELECT A.Delivered_StoreID AS STORE,COUNT(DISTINCT A.Customer_id) AS Customer FROM Orders AS A --25128 FROM ST103
WHERE A.Customer_id IN (
    SELECT A.Customer_id 
	FROM Orders AS A
	LEFT JOIN 
	ProductsInfo AS B
	ON A.product_id = B.product_id
	GROUP BY A.Customer_id
	HAVING COUNT(DISTINCT B.Category) =1 )
GROUP BY A.Delivered_StoreID
ORDER BY COUNT(DISTINCT A.Customer_id) DESC

SELECT G.Region,COUNT(DISTINCT A.Customer_id) AS Customer FROM Orders AS A --75458 FROM SOUTH 10745 FROM WEST
LEFT JOIN
StoresInfo AS G
ON A.Delivered_StoreID = G.StoreID
WHERE A.Customer_id IN (
    SELECT A.Customer_id 
	FROM Orders AS A
	LEFT JOIN 
	ProductsInfo AS B
	ON A.product_id = B.product_id
	GROUP BY A.Customer_id
	HAVING COUNT(DISTINCT B.Category) =1 )
GROUP BY G.Region
ORDER BY COUNT(DISTINCT A.Customer_id) DESC

SELECT G.seller_state AS State_,COUNT(DISTINCT A.Customer_id) AS Customer FROM Orders AS A --75458 FROM ANDHRA PRADESH & 10745 FROM GUJRAT
LEFT JOIN
StoresInfo AS G
ON A.Delivered_StoreID = G.StoreID
WHERE A.Customer_id IN (
    SELECT A.Customer_id 
	FROM Orders AS A
	LEFT JOIN 
	ProductsInfo AS B
	ON A.product_id = B.product_id
	GROUP BY A.Customer_id
	HAVING COUNT(DISTINCT B.Category) =1 )
GROUP BY G.seller_state
ORDER BY COUNT(DISTINCT A.Customer_id) DESC

----customers who purchased MULTIPLE category
SELECT A.Delivered_StoreID AS STORE,COUNT(DISTINCT A.Customer_id) AS Customer FROM Orders AS A --294 FROM ST103 & 150 FROM ST143
WHERE A.Customer_id IN (
    SELECT A.Customer_id 
	FROM Orders AS A
	LEFT JOIN 
	ProductsInfo AS B
	ON A.product_id = B.product_id
	GROUP BY A.Customer_id
	HAVING COUNT(DISTINCT B.Category) > 1 )
GROUP BY A.Delivered_StoreID
ORDER BY COUNT(DISTINCT A.Customer_id) DESC

SELECT G.Region,COUNT(DISTINCT A.Customer_id) AS Customer FROM Orders AS A --626 FROM SOUTH
LEFT JOIN
StoresInfo AS G
ON A.Delivered_StoreID = G.StoreID
WHERE A.Customer_id IN (
    SELECT A.Customer_id 
	FROM Orders AS A
	LEFT JOIN 
	ProductsInfo AS B
	ON A.product_id = B.product_id
	GROUP BY A.Customer_id
	HAVING COUNT(DISTINCT B.Category) > 1 )
GROUP BY G.Region
ORDER BY COUNT(DISTINCT A.Customer_id) DESC

SELECT G.seller_state AS State_,COUNT(DISTINCT A.Customer_id) AS Customer FROM Orders AS A --626 FROM ANDHRA PRADESH 
LEFT JOIN
StoresInfo AS G
ON A.Delivered_StoreID = G.StoreID
WHERE A.Customer_id IN (
    SELECT A.Customer_id 
	FROM Orders AS A
	LEFT JOIN 
	ProductsInfo AS B
	ON A.product_id = B.product_id
	GROUP BY A.Customer_id
	HAVING COUNT(DISTINCT B.Category) > 1 )
GROUP BY G.seller_state
ORDER BY COUNT(DISTINCT A.Customer_id) DESC

--Divide the customers into groups based on Recency, Frequency, and Monetary (RFM Segmentation) -
--Divide the customers into Premium, Gold, Silver, Standard customers and understand the behaviour of each segment of customers
/*SELECT * INTO RFM_SEGMENT FROM (SELECT 
    G.Customer_id,
    CASE 
        WHEN G.R_rank = 1 AND G.F_rank = 1 AND G.M_rank = 1 THEN 'Premium'
        WHEN G.R_rank = 1 AND G.F_rank = 1 THEN 'Gold'
        WHEN G.R_rank = 1 THEN 'Silver'
        ELSE 'Standard'
    END AS RFM_segment
FROM(
SELECT D.Customer_id,
       D.Recency,
       D.Frequency,
       D.Monetary,
       NTILE(4) OVER (ORDER BY D.Recency ASC) AS R_rank,
       NTILE(4) OVER (ORDER BY D.Frequency DESC) AS F_rank,
       NTILE(4) OVER (ORDER BY D.Monetary DESC) AS M_rank
    FROM
(SELECT 
    A.Customer_id,
    DATEDIFF(DAY,MIN(A.Bill_date_timestamp),MAX(A.Bill_date_timestamp)) AS Recency,
    COUNT(*) AS Frequency,
    SUM(A.Total_Amount) AS Monetary
FROM Orders AS A
GROUP BY A.Customer_id ) AS D ) AS G ) AS Y */

SELECT D.RFM_segment,COUNT(*) AS  --PREMIUM = 1741
Customers FROM RFM_SEGMENT AS D   --GOLD = 703
GROUP BY D.RFM_segment            --SILVER = 22200
                                  --SILVER = 73931

----------------------------------------------------Customer satisfaction towards category & product----------------------------------------------------------------------
--Which categories (top 10) are maximum rated & minimum rated and average rating score? 
SELECT AVG(F.Rating_Score) FROM (
SELECT B.Category,AVG(C.Customer_Satisfaction_Score) AS Rating_Score FROM Orders AS A    --maximum rated = Pet_Shop(4.17)
LEFT JOIN                                                                                --minimum rated = #NA(3.81)
ProductsInfo AS B                                                                        --average rating score = 4.01
ON A.product_id = B.product_id
LEFT JOIN
Order_Review_Ratings AS C
ON A.order_id = C.order_id
GROUP BY B.Category
/*ORDER BY AVG(C.Customer_Satisfaction_Score) DESC */) AS F

--Average rating by location, store, product, category, month, etc.
--Average rating by location
SELECT AVG(F.Rating) FROM
(SELECT CONCAT_WS(' ',B.seller_city,B.seller_state,B.Region) AS Location_,                --maximum rated = Chatakonda Andhra Pradesh South(4.20)
AVG(C.Customer_Satisfaction_Score) AS Rating FROM Orders AS A                             --minimum rated = Vijayawada Andhra Pradesh South(3.61)
LEFT JOIN                                                                                 --average rating score = 4.03
StoresInfo AS B
ON A.Delivered_StoreID = B.StoreID
LEFT JOIN 
Order_Review_Ratings AS C
ON A.order_id = C.order_id
GROUP BY CONCAT_WS(' ',B.seller_city,B.seller_state,B.Region)
/*ORDER BY AVG(C.Customer_Satisfaction_Score) DESC*/) AS F

--Average rating by STORE
SELECT AVG(F.Rating) FROM
(SELECT A.Delivered_StoreID AS Store,                                                     --maximum rated = ST301(4.20)
AVG(C.Customer_Satisfaction_Score) AS Rating FROM Orders AS A                             --minimum rated = ST180(3.61)
LEFT JOIN                                                                                 --average rating score = 4.03
Order_Review_Ratings AS C
ON A.order_id = C.order_id
GROUP BY A.Delivered_StoreID
/*ORDER BY AVG(C.Customer_Satisfaction_Score) DESC*/) AS F

--Average rating by Product
SELECT AVG(F.Rating) FROM
(SELECT A.product_id AS Product,                                                          --maximum rated = 67031f1b5ba68a9997efb630e43ada88(5)
AVG(C.Customer_Satisfaction_Score) AS Rating FROM Orders AS A                             --minimum rated = f8cc518b0812bb0ee889350296f284e4(1)
LEFT JOIN                                                                                 --average rating score = 4.03
Order_Review_Ratings AS C
ON A.order_id = C.order_id
GROUP BY A.product_id
/*ORDER BY AVG(C.Customer_Satisfaction_Score) DESC*/) AS F

--Average rating by Category
SELECT AVG(F.Rating) FROM
(SELECT MONTH(A.Bill_date_timestamp) AS Month_,                                           --maximum rated = July (4.19)
AVG(C.Customer_Satisfaction_Score) AS Rating FROM Orders AS A                             --minimum rated = March(3.68)
LEFT JOIN                                                                                 --average rating score = 4.01
Order_Review_Ratings AS C
ON A.order_id = C.order_id
GROUP BY MONTH(A.Bill_date_timestamp)
/* ORDER BY AVG(C.Customer_Satisfaction_Score) DESC */) AS F

--------------------------------------------Perform analysis related to Sales Trends, patterns, and seasonality--------------------------------------------------------
---Which months have had the highest sales, what is the sales amount and contribution in percentage?
SELECT 
MONTH(A.Bill_date_timestamp) AS MONTH_,SUM(A.Total_Amount) AS SALES_,
SUM(A.Total_Amount)*100/(SELECT SUM(B.Total_Amount) FROM Orders AS B) AS SALES_PERC FROM Orders AS A
GROUP BY MONTH(A.Bill_date_timestamp)
ORDER BY MONTH(A.Bill_date_timestamp) 

--Which months have had the least sales, what is the sales amount and contribution in percentage?  
SELECT 
MONTH(A.Bill_date_timestamp) AS MONTH_,SUM(A.Total_Amount) AS SALES_,
SUM(A.Total_Amount)*100/(SELECT SUM(B.Total_Amount) FROM Orders AS B) AS SALES_PERC FROM Orders AS A
GROUP BY MONTH(A.Bill_date_timestamp)
ORDER BY SUM(A.Total_Amount) 

--Is there any seasonality in the sales (weekdays vs. weekends)
SELECT 
CASE WHEN DATEPART(WEEKDAY,D.Bill_date_timestamp) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END AS DAY_TYPE,
SUM(D.Total_Amount) AS SALES 
FROM Orders AS D
GROUP BY CASE WHEN DATEPART(WEEKDAY,D.Bill_date_timestamp) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END

--Sales by Day of the Week
SELECT 
DATEPART(WEEKDAY,D.Bill_date_timestamp) AS DAY_NAME,
SUM(D.Total_Amount) AS SALES 
FROM Orders AS D
GROUP BY DATEPART(WEEKDAY,D.Bill_date_timestamp)
ORDER BY SUM(D.Total_Amount) DESC

--Sales by week
SELECT * FROM (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY F.YEAR_ ORDER BY F.SALES DESC ) AS RANK_ FROM
(SELECT YEAR(D.Bill_date_timestamp) AS YEAR_
,DATENAME(WEEK,D.Bill_date_timestamp) AS WEEK_,
SUM(D.Total_Amount) AS SALES 
FROM Orders AS D
GROUP BY YEAR(D.Bill_date_timestamp),DATENAME(WEEK,D.Bill_date_timestamp)
) AS F
) AS N
WHERE N.RANK_ = 1

--Sales by QUARTER
SELECT * FROM (
SELECT *,ROW_NUMBER() OVER(PARTITION BY F.YEAR_ ORDER BY F.SALES DESC ) AS RANK_ FROM (
SELECT YEAR(D.Bill_date_timestamp) AS YEAR_
,DATENAME(QUARTER,D.Bill_date_timestamp) AS QUARTER_,
SUM(D.Total_Amount) AS SALES 
FROM Orders AS D
GROUP BY YEAR(D.Bill_date_timestamp),DATENAME(QUARTER,D.Bill_date_timestamp)
/*ORDER BY YEAR(D.Bill_date_timestamp),DATENAME(QUARTER,D.Bill_date_timestamp)*/) AS F ) AS L
WHERE L.RANK_ = 1

--------------------------------------------------------------Understand the Category Behavior---------------------------------------------------------------------------
--Total Sales & Percentage of sales by category (Perform Pareto Analysis)
SELECT  B.Category,SUM(A.Total_Amount) AS SALES,
SUM(A.Total_Amount)*100/(SELECT SUM(A.Total_Amount) FROM Orders AS A) 
AS PERCENTAGE_ FROM Orders AS A
LEFT JOIN 
ProductsInfo AS B
ON A.product_id = B.product_id
GROUP BY B.Category
ORDER BY SUM(A.Total_Amount) desc

--Most Profitable Category and Contribution
SELECT  B.Category,SUM(A.Total_Amount - A.Cost_Per_Unit*A.Quantity) AS PROFIT
FROM Orders AS A
LEFT JOIN 
ProductsInfo AS B
ON A.product_id = B.product_id
GROUP BY B.Category
ORDER BY SUM(A.Total_Amount - A.Cost_Per_Unit*A.Quantity) DESC

--Category Penetration Analysis by Month-on-Month
SELECT YEAR(A.Bill_date_timestamp) AS YEAR_,
       MONTH(A.Bill_date_timestamp) AS MONTH_,
	   B.Category,COUNT(A.order_id)/(SELECT COUNT(F.order_id) FROM Orders AS F) AS CATEGORY_PENETRATION
	   FROM Orders AS A
LEFT JOIN 
ProductsInfo AS B
ON A.product_id = B.product_id
GROUP BY YEAR(A.Bill_date_timestamp),
       MONTH(A.Bill_date_timestamp),
	   B.Category
ORDER BY YEAR(A.Bill_date_timestamp),MONTH(A.Bill_date_timestamp)

--Cross-Category Analysis by Month-on-Month
SELECT 
    YEAR(F.Bill_date_timestamp) AS year,
    MONTH(F.Bill_date_timestamp) AS month,
    AVG(F.num_categories) AS avg_categories_per_bill
FROM (
    SELECT 
        o.order_id,o.Bill_date_timestamp,
        COUNT(DISTINCT s.category) AS num_categories
    FROM 
        ProductsInfo s
    JOIN 
        orders o ON s.product_id = o.product_id
    GROUP BY 
        o.order_id,o.Bill_date_timestamp
) AS F
GROUP BY YEAR(F.Bill_date_timestamp), MONTH(F.Bill_date_timestamp)
ORDER BY year, month

--Most Popular Category During First Purchase of Customer
SELECT D.Category,COUNT(D.Category) AS COUNT_CATEGORY FROM (
SELECT A.Customer_id,B.Category,
MIN(A.Bill_date_timestamp) AS First_Purchase_Date FROM Orders AS A
LEFT JOIN 
ProductsInfo AS B
ON A.product_id = B.product_id
GROUP BY A.Customer_id,B.Category ) AS D
GROUP BY D.Category
ORDER BY COUNT(D.Category) DESC

--------------------------------------------------------------Cross-Selling (Which products are selling together)------------------------------------------------------- 
SELECT M.Product_1,M.Product_2,M.Product_3,COUNT(DISTINCT M.order_id) AS Frequency FROM
(SELECT A.order_id,A.product_id AS Product_1,B.product_id AS Product_2,
C.product_id AS Product_3 FROM Orders AS A
LEFT JOIN 
Orders AS B
ON A.order_id = B.order_id AND A.product_id <> B.product_id
LEFT JOIN 
Orders AS C
ON A.order_id = C.order_id AND B.product_id <> C.product_id AND A.product_id <> C.product_id ) AS M
WHERE M.Product_2 IS NOT NULL AND M.Product_3 IS NOT NULL 
GROUP BY M.Product_1,M.Product_2,M.Product_3
ORDER BY COUNT(DISTINCT M.order_id) DESC









