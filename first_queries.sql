USE magist;

SELECT *
FROM order_payments
ORDER BY order_id;


SELECT *
FROM orders AS o
RIGHT JOIN customers AS c
	ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL
;

SELECT *
FROM customers AS c
RIGHT JOIN geo AS g
ON c.customer_zip_code_prefix = g.zip_code_prefix
RIGHT JOIN sellers AS s
ON s.seller_zip_code_prefix = g.zip_code_prefix
WHERE seller_id IS NULL
ORDER BY zip_code_prefix