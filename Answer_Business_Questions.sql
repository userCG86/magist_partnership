USE magist;

/* 3.1
What categories of tech products does Magist have? */
SELECT 
	*
FROM 
	product_category_name_translation
WHERE
	product_category_name_english IN ('electronics', 'computers_accessories', 'computers', 'tablets_printing_image', 'telephony')
;

/* How many products of these tech categories have been sold 
(within the time window of the database snapshot)? */
SELECT
	COUNT(o.product_id) AS tech_items_sold
FROM
	order_items AS o
LEFT JOIN
	products AS p
USING 
	(product_id)
LEFT JOIN
	product_category_name_translation AS nt
USING
	(product_category_name)
WHERE
	nt.product_category_name_english IN ('electronics', 'computers_accessories', 'computers', 'tablets_printing_image', 'telephony')
;

/* What percentage does that represent from the overall number of products sold? */
SELECT
	CONCAT(
		ROUND(
			100 / 
			COUNT(*) * 
			SUM(
				CASE
					WHEN 
						nt.product_category_name_english 
						IN 
						('electronics', 'computers_accessories', 'computers', 'tablets_printing_image', 'telephony')
					THEN 
						1
					ELSE
						0
				END
				),
			2),
		'%') AS is_tech
FROM
	order_items AS o
JOIN
	products AS p
USING 
	(product_id)
JOIN
	product_category_name_translation AS nt
USING
	(product_category_name)
;

/* What’s the average price of the products being sold? */
SELECT 
	AVG(price)
FROM
	order_items
;

/* Are expensive tech products popular? */ 
-- How to define expensive...?
SELECT
	CONCAT(
		ROUND(
			100 / 
			COUNT(*) *
			SUM(
				CASE
				WHEN 
					o.price > ( SELECT 
									AVG(price)
								FROM
									order_items )
				THEN
					1
				ELSE
					0
				END),
			2),
		'%') AS is_expensive
FROM
	order_items AS o
LEFT JOIN
	products AS p
USING 
	(product_id)
LEFT JOIN
	product_category_name_translation AS nt
USING
	(product_category_name)
WHERE
	nt.product_category_name_english IN 
    ('electronics', 'computers_accessories', 'computers', 'tablets_printing_image', 'telephony')
; /* Here we see that the greater number must cluster at the lower end to allow a relatively
small part of the whole to exist above the numerical mean */

/* 3.2
How many months of data are included in the magist database? */
SELECT
	TIMESTAMPDIFF(MONTH, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp) ) + 1 -- TIMESTAMPDIFF is exclusive of endpoint
    AS num_months
FROM
	orders
;

/* How many sellers are there? */
SELECT
	COUNT(DISTINCT seller_id) AS num_sellers
FROM
	sellers
;

/*How many Tech sellers are there? */
SELECT
	COUNT(DISTINCT seller_id) AS num_tech_sellers
FROM
	sellers AS s
JOIN 
	order_items AS oi
USING
	(seller_id)
JOIN
	products AS p
USING 
	(product_id)
JOIN
	product_category_name_translation AS nt
USING
	(product_category_name)
WHERE
	nt.product_category_name_english IN 
    ('electronics', 'computers_accessories', 'computers', 'tablets_printing_image', 'telephony')
;

/* What percentage of overall sellers are Tech sellers? */
SELECT
	CONCAT(
		ROUND(
			100 / COUNT(DISTINCT seller_id) * (
				SELECT
					COUNT(DISTINCT seller_id) AS num_tech_sellers
				FROM
					sellers AS s
				JOIN 
					order_items AS oi
				USING
					(seller_id)
				JOIN
					products AS p
				USING 
					(product_id)
				JOIN
					product_category_name_translation AS nt
				USING
					(product_category_name)
				WHERE
					nt.product_category_name_english IN 
					('electronics', 'computers_accessories', 'computers', 'tablets_printing_image', 'telephony')
				), 
			0),
		'%') 
	AS perc_tech_sellers
FROM
	sellers
;

/* What is the total amount earned by all sellers? 
What is the total amount earned by all Tech sellers? */
SELECT 
	ROUND(SUM(price), 2) AS total_earnings
FROM
	order_items
UNION
SELECT
	ROUND(SUM(oi.price), 2)
FROM
	sellers AS s
JOIN 
	order_items AS oi
USING
	(seller_id)
JOIN
	products AS p
USING 
	(product_id)
JOIN
	product_category_name_translation AS nt
USING
	(product_category_name)
WHERE
	nt.product_category_name_english IN 
    ('electronics', 'computers_accessories', 'computers', 'tablets_printing_image', 'telephony')
;

/* Can you work out the average monthly income of all sellers? 
Can you work out the average monthly income of Tech sellers? */
SELECT 
	ROUND(
		  SUM(oi.price)
		  / 
		  (TIMESTAMPDIFF(MONTH, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp) ) +1), 
		  2
          ) AS avg_monthly_earnings
FROM
	order_items AS oi
	JOIN
	orders AS o
    USING
	(order_id)
UNION
SELECT
	ROUND(
		  SUM(oi.price)
		  / 
          (TIMESTAMPDIFF(MONTH, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp) ) +1), 
		  2
          )
FROM
	sellers AS s
	JOIN 
	order_items AS oi
	USING
	(seller_id)
	JOIN
	products AS p
	USING 
	(product_id)
	JOIN
	product_category_name_translation AS nt
	USING
	(product_category_name)
	JOIN
	orders AS o
    USING
	(order_id)
WHERE
	nt.product_category_name_english 
    IN 
    ('electronics', 'computers_accessories', 'computers', 'tablets_printing_image', 'telephony')
;

/* 3.2
What’s the average time between the order being placed and the product being delivered? */
SELECT 
    AVG(timestampdiff(HOUR, order_purchase_timestamp, order_delivered_customer_date) +1) AS avg_delivery_hrs, -- Function rounds hours down
    AVG(timestampdiff(DAY, order_purchase_timestamp, order_delivered_customer_date) +1) AS avg_delivery_days
    -- timestampdiff(HOUR, '2017-09-13 10:59:02', '2017-09-13 11:59:02')  -- Test rounding of function
FROM
	orders
;

/* How many orders are delivered on time vs orders delivered with a delay? */
SELECT
	SUM(
		CASE
			WHEN (TIMESTAMPDIFF(SECOND, order_delivered_customer_date, order_estimated_delivery_date) > 0)
			THEN 1
			ELSE 0
		END
        ) AS on_time
       ,
    SUM(
		CASE
			WHEN (TIMESTAMPDIFF(SECOND, order_delivered_customer_date, order_estimated_delivery_date) <=  0)
			THEN 1
			ELSE 0
		END
        ) AS late_delivery,
	(SUM(
		CASE
			WHEN (order_delivered_customer_date IS NULL)
			THEN 1
			ELSE 0
		END
        ) )AS undelivered,
	COUNT(*) AS total_orders
FROM
	orders
WHERE 
	order_status != 'canceled'
;

-- Is there any pattern for delayed orders, e.g. big products being delayed more often?
/*
Size and weight have seemingly nothing to do with it.
Are the estimated times very short?
	Well yes, but the runovers far exceed the shortened times
Particular sellers don't seem to blame, as the worst offenders sell almost nothing
and the highest sellers hit around 10% lateness.
Can I get the geography accounted for here?
*/
SELECT 
-- 	   o.order_estimated_delivery_date,
--     oi.shipping_limit_date,
--     oi.price,
--     oi.freight_value,
	'Late orders' AS class,
    AVG(p.product_weight_g) AS avg_weight_g,
    AVG(p.product_length_cm * p.product_width_cm * p.product_height_cm / 1000000) AS avg_volume_m_3,
    AVG(timestampdiff(DAY, order_purchase_timestamp, order_estimated_delivery_date) +1) AS avg_est_delivery_days,
    AVG(timestampdiff(DAY, order_estimated_delivery_date, order_delivered_customer_date) +1) AS avg_est_deliv
FROM 
	orders AS o
    JOIN
		order_items AS oi
	USING
		(order_id)
	JOIN
		products AS p
	USING
		(product_id)
WHERE
	order_estimated_delivery_date - order_delivered_customer_date < 0
UNION
SELECT
	'All orders',
	AVG(p.product_weight_g),
    AVG(p.product_length_cm * p.product_width_cm * p.product_height_cm / 1000000),
    AVG(timestampdiff(DAY, order_purchase_timestamp, order_estimated_delivery_date) +1),
    AVG(timestampdiff(DAY, order_estimated_delivery_date, order_delivered_customer_date) +1)
FROM 
	orders AS o
    JOIN
		order_items AS oi
	USING
		(order_id)
	JOIN
		products AS p
	USING
		(product_id)
;
-- No particular seller seems to be overly at fault
SELECT
	seller_id,
    COUNT(seller_id) AS total_sales,
    SUM(
		CASE
			WHEN order_estimated_delivery_date - order_delivered_customer_date < 0
            THEN 1
			ELSE 0
		END
        ) AS late_sales,
	(
		SUM(
		CASE
			WHEN order_estimated_delivery_date - order_delivered_customer_date < 0
            THEN 1
			ELSE 0
		END
        ) 
		/
		COUNT(seller_id)
	) AS ratio_late_total
FROM 
	orders AS o
    JOIN
		order_items AS oi
	USING
		(order_id)
	JOIN
		products AS p
	USING
		(product_id)
	JOIN
		sellers AS s
	USING
		(seller_id)
-- WHERE
-- 	order_estimated_delivery_date - order_delivered_customer_date < 0
GROUP BY
	seller_id
ORDER BY
	total_sales DESC
;

/* Check the operation of [o.order_delivered_customer_date - o.order_purchase_timestamp] in Tableau */
SELECT 
	product_category_name_english,
    AVG(timestampdiff(SECOND, o.order_purchase_timestamp, o.order_delivered_customer_date)/86400)
FROM 
	orders AS o
JOIN 
	order_items AS oi
	USING
	(order_id)
	JOIN
	products AS p
	USING 
	(product_id)
	JOIN
	product_category_name_translation AS nt
	USING
	(product_category_name)
GROUP BY
	product_category_name_english
ORDER BY
	2
; -- In order given rounding errors
