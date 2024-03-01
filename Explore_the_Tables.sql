USE magist;

/* 1. How many orders are there in the dataset? 
The orders table contains a row for each order, so this should be easy to find out! */
SELECT 
	COUNT(*) AS orders_count
FROM 
	orders
;

/* 2. Are orders actually delivered? 
Look at columns in the orders table: one of them is called order_status. 
Most orders seem to be delivered, but some aren’t. 
Find out how many orders are delivered and how many are canceled, unavailable, 
or in any other status by grouping and aggregating this column. */
SELECT 
	order_status,
    COUNT(*) AS order_status_count
FROM
	orders
GROUP BY
	order_status
;

/* 3. Is Magist having user growth? 
A platform losing users left and right isn’t going to be very useful to us. 
It would be a good idea to check for the number of orders grouped by year and month. 
Tip: you can use the functions YEAR() and MONTH() to separate the year and the month 
of the order_purchase_timestamp. */
SELECT
	YEAR(order_purchase_timestamp) AS purchase_year,
    MONTH(order_purchase_timestamp) AS purchase_month,
    COUNT(customer_id) AS orders_by_month_year
FROM
	orders
GROUP BY
	purchase_year,
    purchase_month
ORDER BY 
	purchase_year,
    purchase_month
;

/* 4. How many products are there on the products table? (Make sure that there are no duplicate products.) */
SELECT 
	COUNT(DISTINCT(product_id)) AS products_count
FROM
	products
;

/* 5. Which are the categories with the most products? 
Since this is an external database and has been partially anonymized, 
we do not have the names of the products. But we do know which categories products belong to. 
This is the closest we can get to know what sellers are offering in the Magist marketplace. 
By counting the rows in the products table and grouping them by categories, 
we will know how many products are offered in each category. 
This is not the same as how many products are actually sold by category. 
To acquire this insight we will have to combine multiple tables together: 
we’ll do this in the next lesson. */
SELECT 
	product_category_name,
    COUNT(DISTINCT product_id) AS product_count
FROM
	products
GROUP BY
	product_category_name
ORDER BY
	product_count DESC
;

/* 6. How many of those products were present in actual transactions? 
The products table is a “reference” of all the available products. 
Have all these products been involved in orders? Check out the order_items table to find out! */
SELECT
	COUNT(DISTINCT product_id) AS products_sold
FROM 
	order_items
;


/* 7. What’s the price for the most expensive and cheapest products? 
Sometimes, having a basing range of prices is informative. 
Looking for the maximum and minimum values is also a good way to detect extreme outliers. */
SELECT
	MIN(price),
    MAX(price)
FROM
	order_items
;

/* 8. What are the highest and lowest payment values? 
Some orders contain multiple products. What’s the highest someone has paid for an order? 
Look at the order_payments table and try to find it out. */
SELECT
	MAX(payment_value) AS highest_paid,
	MIN(payment_value) AS lowest_paid
FROM
	order_payments
WHERE
	payment_value != 0
; -- Discard 0€ payments as mistakes

SELECT
	SUM(payment_value) AS highest_order
FROM
	order_payments
GROUP BY 
	order_id
ORDER BY
	highest_order DESC
LIMIT 
	1
;
