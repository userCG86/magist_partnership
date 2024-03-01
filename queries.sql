-- Are orders actually delivered?
-- Relatively low rates of cancellation and undeliverable
SELECT order_status, 
    COUNT(*) AS orders
FROM orders
GROUP BY order_status;


-- Is Magist having user growth?
-- Would love to see a graph of this. OK growth and then just tanks at the end.
SELECT
    COUNT(*), YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
FROM
    orders
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
ORDER BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp);

-- Which are the categories with the most products?
-- Computer accessories are by category the 7th most offed item. Average sale price of 116.51 providing over 900thousand in revenue (25 months)
SELECT product_category_name_english, COUNT(product_id)
FROM products
    LEFT JOIN product_category_name_translation 
    USING(product_category_name)
GROUP BY product_category_name
ORDER BY COUNT(product_id) DESC
LIMIT 10
;


-- How many of those products were present in actual transactions? 
-- Every listed item has been sold.
SELECT COUNT(DISTINCT product_id)
-- FROM order_items;
FROM products;

-- How many computer accessories and related items are ordered on the Magist platform?
-- Computer accessorires in 7827 orders, 5th most sold category, electronics in 2767 orders
SELECT product_category_name_english, COUNT(o.product_id) 'Times Ordered'
FROM products P
    LEFT JOIN product_category_name_translation 
		USING(product_category_name)
    JOIN order_items o
		USING(product_id)
GROUP BY product_category_name_english
HAVING product_category_name_english IN ('computers','computers_accessories','consoles_games', 'electronics','tablets_printing_image')
ORDER BY COUNT(o.product_id) DESC
;

-- At what price points are computer accessories selling, roughly? 
-- Comment WHERE statement to look at platform in general.
SELECT product_category_name_english, count(*),
CASE
WHEN price < 5 THEN 'super low'
WHEN price < 25 THEN 'cheap'
WHEN price < 100 THEN 'midgrade'
WHEN price >= 100 THEN 'upmarket'
END PriceCat
FROM products p
JOIN order_items o 
	ON o.product_id = p.product_id
JOIN product_category_name_translation pt
	ON pt.product_category_name = p.product_category_name
WHERE product_category_name_english = 'computers_accessories'
GROUP BY PriceCat
;


-- What are the sales numbers just on computer accessories?
-- Average sale price of 116.51 providing over 900thousand in revenue (25 months)
select product_category_name_english, SUM(price), AVG(price)
from products p
join order_items o 
	on o.product_id = p.product_id
join product_category_name_translation pt
	on pt.product_category_name = p.product_category_name
group by product_category_name_english
HAVING product_category_name_english = 'computers_accessories'
;


-- What is the average price of electronics-related items? In total? By sub-category?
SELECT product_category_name_english, AVG(price)
FROM products p
JOIN order_items o ON o.product_id = p.product_id
JOIN product_category_name_translation USING(product_category_name)
WHERE product_category_name_english in ('computers','computers_accessories','consoles_games', 'electronics','tablets_printing_image')
-- GROUP BY product_category_name_english
-- ORDER BY product_category_name
;

-- How many high-value orders have been placed for electronics-related items?
select COUNT(price)
from products p
join order_items o on o.product_id = p.product_id
join product_category_name_translation using(product_category_name)
where product_category_name_english in ('computers','computers_accessories','consoles_games', 'electronics','tablets_printing_image') AND (price) >= 500
;

-- What delivery schedule does Magist work on? 
-- All times taken here from time of order to time of delivery.
SELECT Count(*),
	CASE
		WHEN datediff(order_delivered_customer_date, order_purchase_timestamp) IS NULL THEN 'Canceled/Undeliverable'
		WHEN datediff(order_delivered_customer_date, order_purchase_timestamp) <= 1 THEN 'Same Day' 
        WHEN datediff(order_delivered_customer_date, order_purchase_timestamp) <= 3 THEN 'Priority' 
        WHEN datediff(order_delivered_customer_date, order_purchase_timestamp) <= 7 THEN 'Same Week'
        WHEN datediff(order_delivered_customer_date, order_purchase_timestamp) <= 14 THEN 'Two Weeks'
        WHEN datediff(order_delivered_customer_date, order_purchase_timestamp) <= 30 THEN 'One Month'
        WHEN datediff(order_delivered_customer_date, order_purchase_timestamp) <= 60 THEN 'Two Months'
        ELSE 'Eternal'
	END AS Judgement
FROM orders
GROUP BY Judgement
Order BY FIELD(Judgement, 'Same Day', 'Priority', 'Same Week', 'Two Weeks', 'One Month', 'Two Months', 'Eternal', 'Canceled/Undeliverable')
;

-- How does the Magist delivery schedule compare to their estimates?
SELECT CASE
	WHEN timediff(order_delivered_customer_date, order_estimated_delivery_date) < 0 THEN 'Early'
    WHEN timediff(order_delivered_customer_date, order_estimated_delivery_date) > 48 THEN 'Over two days'
    WHEN timediff(order_delivered_customer_date, order_estimated_delivery_date) > 168 THEN 'A week?'
    ELSE 'Bit late'
END Judgement,
COUNT(*)
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY Judgement
;

-- Are delivery times geographically influenced?
SELECT CASE
	WHEN AVG(datediff(order_delivered_customer_date, order_purchase_timestamp)) < 1 THEN 'Same Day'
    WHEN AVG(datediff(order_delivered_customer_date, order_purchase_timestamp)) <= 3 THEN 'Priority'
    WHEN AVG(datediff(order_delivered_customer_date, order_purchase_timestamp)) <= 7 THEN 'Standard'
    WHEN AVG(datediff(order_delivered_customer_date, order_purchase_timestamp)) <= 14 THEN 'Slow'
    ELSE 'Very slow'
END ShipAvg, 
customer_zip_code_prefix
FROM orders
JOIN customers USING(customer_id)
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY customer_zip_code_prefix
HAVING AVG(datediff(order_delivered_customer_date, order_purchase_timestamp)) <= 21
ORDER BY customer_zip_code_prefix
;

-- How many customer reviews is Magist receiving? Is Magist responding to customer reviews? Do they respond more to negative reviews?
SELECT review_score, COUNT(*)
FROM order_reviews
GROUP BY review_score;

SELECT COUNT(review_comment_message), COUNT(*), review_score
FROM order_reviews
GROUP BY review_score;

-- What percentage of the business is conducted in Sao Paolo region?
-- 356 sales Electronics
-- 1228 sales Computer accessories
-- 19 sales Computers
SELECT product_category_name_english, COUNT(*), SUM(price)
FROM orders o
JOIN customers c USING(customer_id)
JOIN geo g
	ON g.zip_code_prefix = c.customer_zip_code_prefix
JOIN order_items USING(order_id)
JOIN products USING(product_id)
JOIN product_category_name_translation USING(product_category_name)
WHERE g.city = 'sao paulo' AND product_category_name_english IN ('computers','computers_accessories','consoles_games', 'electronics','tablets_printing_image')
GROUP BY product_category_name_english;

-- Where is Magist on average capable of delivering in a week or under?
SELECT CASE
    WHEN AVG(datediff(order_delivered_customer_date, order_purchase_timestamp)) <= 7 THEN 'Acceptable'
    ELSE 'Unacceptable'
END ShipAvg, 
customer_zip_code_prefix
FROM orders
JOIN customers USING(customer_id)
GROUP BY customer_zip_code_prefix
HAVING AVG(datediff(order_delivered_customer_date, order_purchase_timestamp)) <= 7
ORDER BY customer_zip_code_prefix
;

-- In cities where the delivery time averages a week or under, how many high-value orders are being placed for electronics-related items?
-- How many electroics-related orders are being placed in Sao Paulo?
SELECT (g.city), COUNT(order_id), SUM(price), AVG(datediff(order_delivered_customer_date, order_purchase_timestamp))
FROM orders o
JOIN customers c USING(customer_id)
JOIN order_items USING(order_id)
JOIN products USING(product_id)
JOIN product_category_name_translation USING(product_category_name)
JOIN geo g
	ON g.zip_code_prefix = c.customer_zip_code_prefix
WHERE product_category_name_english IN ('computers','computers_accessories','consoles_games', 'electronics','tablets_printing_image') AND g.city = 'sao paulo'
GROUP BY g.city
-- HAVING AVG(datediff(order_delivered_customer_date, order_purchase_timestamp)) <= 7 -- AND SUM(price) > 500
ORDER BY SUM(price) DESC
;