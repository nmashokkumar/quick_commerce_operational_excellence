-- Q2. Which dark stores consistently underperform operationally?

SELECT
	ds.dark_store_name AS DS_Name,
	SUM((CASE 
    WHEN d.actual_delivery_timestamp <= d.promised_delivery_timestamp THEN 1 ELSE 0 END))/ COUNT(*)*100 AS SLA_breach_rate
FROM deliveries d 
JOIN orders o 
	ON d.order_id = o.order_id
JOIN dark_stores ds
	ON ds.dark_store_id = o.dark_store_id

GROUP BY 1
ORDER BY 2 DESC;


SELECT 
	ds.dark_store_name,
	SUM(CASE WHEN order_status ='Stockout' THEN 1 ELSE 0 END)/COUNT(*)*100 AS stockout_rate
FROM 
	orders o
JOIN dark_stores ds 
	ON o.dark_store_id = ds.dark_store_id
GROUP BY 1
ORDER BY 2 DESC;

SELECT 
	ds.dark_store_name,
	SUM(CASE WHEN oi.requested_quantity = oi.fulfilled_quantity THEN 1 ELSE 0 END) / COUNT(*)*100 AS Fill_rate
FROM 
	order_items oi
JOIN orders o 
	ON oi.order_id = o.order_id
JOIN dark_stores ds 
	ON o.dark_store_id = ds.dark_store_id
GROUP BY 1
ORDER BY 2 DESC;

-- Views

CREATE OR REPLACE VIEW vw_q2_dark_store_performance AS

SELECT
    ds.dark_store_id,
    ds.dark_store_name,

    ROUND(
        AVG(
            CASE
                WHEN o.order_status = 'Delivered'
                THEN TIMESTAMPDIFF(
                    MINUTE,
                    o.order_timestamp,
                    o.dispatch_ready_timestamp
                )
            END
        ),
        2
    ) AS avg_fulfillment_time,

    ROUND(
        100 * SUM(
            CASE
                WHEN o.order_status = 'Delivered'
                 AND d.actual_delivery_timestamp <= d.promised_delivery_timestamp
                THEN 1
                ELSE 0
            END
        ) /
        SUM(
            CASE
                WHEN o.order_status = 'Delivered'
                THEN 1
                ELSE 0
            END
        ),
        2
    ) AS on_time_delivery_rate,

    ROUND(
        100 * SUM(
            CASE
                WHEN o.order_status = 'Stockout'
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS stockout_rate,

    ROUND(
        100 * SUM(
            CASE
                WHEN oi_fulfillment.is_fully_fulfilled = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS fill_rate

FROM dark_stores ds

JOIN orders o
    ON ds.dark_store_id = o.dark_store_id

LEFT JOIN deliveries d
    ON o.order_id = d.order_id

LEFT JOIN (
    SELECT
        order_id,
        CASE
            WHEN MIN(
                CASE
                    WHEN fulfilled_quantity = requested_quantity
                    THEN 1
                    ELSE 0
                END
            ) = 1
            THEN 1
            ELSE 0
        END AS is_fully_fulfilled
    FROM order_items
    GROUP BY order_id
) oi_fulfillment
    ON o.order_id = oi_fulfillment.order_id

GROUP BY
    ds.dark_store_id,
    ds.dark_store_name;






