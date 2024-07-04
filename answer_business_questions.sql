USE magist;
/*3.1. In relation to the products:
What categories of tech products does Magist have?*/
SELECT * FROM product_category_name_translation
WHERE product_category_name_english LIKE '%tech%'
OR product_category_name_english LIKE '%comp%'
OR product_category_name_english LIKE '%tablet%'
OR product_category_name_english LIKE '%elec%';

/*How many products of these tech categories have been sold 
(within the time window of the database snapshot)? 
What percentage does that represent from the overall number of products sold?*/
SELECT
    p.product_category_name,
    pcnt.product_category_name_english,
    COUNT(p.product_id) AS product_count,
	ROUND((COUNT(p.product_id) * 100) / (SELECT COUNT(*) FROM products),2) AS 'Percentage_of_total'
FROM
    products p
JOIN
    product_category_name_translation pcnt ON p.product_category_name = pcnt.product_category_name
LEFT JOIN
    order_items oi ON p.product_id = oi.product_id
WHERE
    product_category_name_english LIKE 'industry%' OR
    product_category_name_english LIKE '%commerce' OR
    product_category_name_english LIKE '%tools' OR
    product_category_name_english LIKE 'tablets%' OR
    product_category_name_english LIKE '%appliance' OR
    product_category_name_english LIKE '%print%' OR
    product_category_name_english LIKE 'office%' OR
    product_category_name_english LIKE 'computers%' OR
    product_category_name_english LIKE 'dvds%' OR
    product_category_name_english IN ('audio', 'music', 'computers', 'telephony', 'electronics', 'pc_gamers')
GROUP BY
    p.product_category_name,
    pcnt.product_category_name_english
ORDER BY 
    product_count DESC;
    
SELECT pt.product_category_name_english AS category, COUNT(oi.order_item_id) AS total_qty, ROUND(SUM(oi.price)) as sales,
	   ROUND(COUNT(oi.order_item_id) /
       (SELECT COUNT(order_item_id)
		FROM order_items
        ) * 100, 2) AS 'ratio by qty',
	   ROUND(SUM(oi.price) / 
       (SELECT SUM(price)
        FROM order_items) * 100, 2) AS 'ratio by sales'
FROM order_items AS oi
JOIN products AS p USING (product_id)
JOIN product_category_name_translation AS pt USING (product_category_name)
JOIN orders AS o USING (order_id)
WHERE pt.product_category_name_english IN ('audio', 'computers_accessories', 'electronics', 'computers')
AND o.order_status = 'delivered'
GROUP BY category
ORDER BY Total_qty DESC;
    
/*What’s the average price of the products being sold?*/
SELECT ROUND(AVG(price),2) FROM order_items;

/*Are expensive tech products popular? *
* TIP: Look at the function CASE WHEN to accomplish this task.*/
SELECT product_category_name_english, count(*) / (select count(*) from order_items) * 100
FROM order_items oi
join products using (product_id)
join product_category_name_translation using (product_category_name)
where product_category_name_english IN ('computers', 'computers_accessories', 'electronics', 'pc_gamers')
and price > 120.65
group by product_category_name_english
;

/*3.2. In relation to the sellers:
How many months of data are included in the magist database?*/
SELECT 
	max(order_purchase_timestamp), min(order_purchase_timestamp)
FROM orders;

select timestampdiff(month, min(order_purchase_timestamp), max(order_purchase_timestamp)) + 1
from orders;

select timestampdiff(month, '2024-01-15', '2024-02-15') result;

/*How many sellers are there? */
select count(*) from sellers;

/*How many Tech sellers are there? */
select count(DISTINCT seller_id) tech_sellers
FROM order_items oi
join products using (product_id)
join product_category_name_translation using (product_category_name)
where product_category_name_english IN ('computers', 'computers_accessories', 'electronics', 'pc_gamers');

/*What percentage of overall sellers are Tech sellers?*/
select count(DISTINCT seller_id) / (select count(*) from sellers) * 100
FROM order_items oi
join products using (product_id)
join product_category_name_translation using (product_category_name)
where product_category_name_english IN ('computers', 'computers_accessories', 'electronics', 'pc_gamers');

/*What is the total amount earned by all sellers?*/
select sum(price)/1000000 total_sales_millions from order_items;
 
/*What is the total amount earned by all Tech sellers?*/
select sum(price)/1000000 total_sales_millions_tech_sellers
FROM order_items oi
join products using (product_id)
join product_category_name_translation using (product_category_name)
where product_category_name_english IN ('computers', 'computers_accessories', 'electronics', 'pc_gamers');

/*Can you work out the average monthly income of all sellers? */
select sum(price)/26 from order_items;

/*Can you work out the average monthly income of Tech sellers?*/
select sum(price)/26 from order_items
join products using (product_id)
join product_category_name_translation using (product_category_name)
where product_category_name_english IN ('computers', 'computers_accessories', 'electronics', 'pc_gamers');

/*3.3. In relation to the delivery time:
What’s the average time between the order being placed 
and the product being delivered?*/
select avg(timestampdiff(day, order_purchase_timestamp, order_delivered_customer_date)) from orders;
select timestampdiff(day, '2024-01-01 00:00:00', '2024-01-01 22:00:00');

/*How many orders are delivered on time 
vs orders delivered with a delay?*/
select count(*), 
case when timestampdiff(day, order_estimated_delivery_date, order_delivered_customer_date) <= 0 then 'on time'
when timestampdiff(day, order_estimated_delivery_date, order_delivered_customer_date) > 0 then 'late'
end lateness

from orders
group by lateness
;

/*Is there any pattern for delayed orders, 
e.g. big products being delayed more often?*/
select avg(product_weight_g) as avg_weight,
avg(product_height_cm*product_length_cm*product_width_cm) as avg_volume,
avg(price) as avg_price,
case when timestampdiff(day, order_estimated_delivery_date, order_delivered_customer_date) <= 0 then 'on time'
when timestampdiff(day, order_estimated_delivery_date, order_delivered_customer_date) > 0 then 'late'
end lateness
from orders
join order_items using (order_id)
join products using(product_id)
group by lateness
;