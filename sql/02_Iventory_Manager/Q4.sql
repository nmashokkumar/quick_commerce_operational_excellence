-- Inventory Manager

-- Q4.Which products experience the highest stockout rates?

SELECT
	SUM(CASE WHEN oi.fulfilled_quantity < oi.requested_quantity THEN 1 ELSE 0 END) / COUNT(*)*100 AS stockout_rate
FROM 
	order_items oi;
SELECT
	p.product_name,
	ROUND(SUM(CASE WHEN oi.fulfilled_quantity < oi.requested_quantity THEN 1 ELSE 0 END) / COUNT(*)*100,2) AS stockout_rate
FROM 
	orders o 
JOIN order_items oi 	
	ON o.order_id = oi.order_id
JOIN products p 
	ON p.product_id = oi.product_id
GROUP BY p.product_id
ORDER BY 2 DESC
LIMIT 10;


-- Views 

CREATE VIEW vw_q4_product_stockout_rate AS
SELECT
    p.product_id,
    p.product_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN oi.fulfilled_quantity < oi.requested_quantity
        THEN oi.order_id
    END) AS stockout_orders,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN oi.fulfilled_quantity < oi.requested_quantity
            THEN oi.order_id
        END)
        / COUNT(DISTINCT oi.order_id) * 100,
        2
    ) AS stockout_rate
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name;