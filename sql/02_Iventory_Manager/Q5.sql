-- Inventory Manager
/*
Q4.Which dark stores have the lowest inventory availability, resulting in delayed or 
incomplete order fulfillment?
*/

SELECT 
	ds.dark_store_name,
    SUM(CASE WHEN o.order_status ='Delivered' THEN 1 ELSE 0 END) / COUNT(*)*100 AS Fill_rate,
	SUM(CASE WHEN o.order_status ='stockout' THEN 1 ELSE 0 END)/COUNT(*)*100 AS stockout_rate
FROM
	orders o 
JOIN dark_stores ds	
	ON o.dark_store_id = ds.dark_store_id
GROUP BY ds.dark_store_id, 1
ORDER BY 2 ASC, 3 DESC;

SELECT
	SUM(CASE WHEN o.order_status ='Delivered' THEN 1 ELSE 0 END) / COUNT(*)*100 AS Fill_rate
FROM 
	orders o;
    
-- Views

CREATE VIEW vw_q5_inventory_store_performance AS
SELECT
    ds.dark_store_id,
    ds.dark_store_name,

    ROUND(
        SUM(
            CASE
                WHEN o.order_status = 'Delivered'
                THEN 1 ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS fill_rate,

    ROUND(
        SUM(
            CASE
                WHEN o.order_status = 'Stockout'
                THEN 1 ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS stockout_rate

FROM orders o
JOIN dark_stores ds
    ON o.dark_store_id = ds.dark_store_id

GROUP BY
    ds.dark_store_id,
    ds.dark_store_name;