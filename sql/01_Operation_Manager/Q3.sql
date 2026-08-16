-- Q3: How has overall operational performance trended over time across key operational KPIs?

SELECT 
    MONTH(order_timestamp) mnt,
	AVG(TIMESTAMPDIFF(MINUTE, order_timestamp, dispatch_ready_timestamp)) AS avg_ord_ff_time
FROM
	orders
GROUP BY 1
ORDER BY 1;

SELECT 
    MONTH(order_timestamp) mnt,
	SUM((CASE 
    WHEN d.actual_delivery_timestamp <= d.promised_delivery_timestamp THEN 1 ELSE 0 END))/ COUNT(*)*100 AS SLA_breach_rate
FROM
	orders o
JOIN deliveries d
	ON o.order_id = d.order_id
GROUP BY 1
ORDER BY 1;

SELECT 
    MONTH(order_timestamp) mnt,
	SUM((CASE 
    WHEN d.actual_delivery_timestamp <= d.promised_delivery_timestamp THEN 1 ELSE 0 END))/ COUNT(*)*100 AS SLA_breach_rate
FROM
	orders o
JOIN deliveries d
	ON o.order_id = d.order_id
GROUP BY 1
ORDER BY 1;


SELECT
	MONTH(order_timestamp) AS mnt,
	SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, order_timestamp, dispatch_ready_timestamp) > 10 THEN 1 ELSE 0 END) /
    COUNT(*)*100 AS op_delay_rate
FROM
	orders 
WHERE order_status = 'Delivered'
GROUP BY 1
ORDER BY 1;

-- Views

CREATE OR REPLACE VIEW vw_q3_operational_trend AS
SELECT
    DATE(o.order_timestamp) AS order_date,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                o.order_timestamp,
                o.dispatch_ready_timestamp
            )
        ),
        2
    ) AS avg_fulfillment_time,
    ROUND(
        100 * SUM(
            CASE
                WHEN d.actual_delivery_timestamp > d.promised_delivery_timestamp
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS sla_breach_rate,
    ROUND(
        100 * SUM(
            CASE
                WHEN TIMESTAMPDIFF(
                    MINUTE,
                    o.order_timestamp,
                    o.dispatch_ready_timestamp
                ) > 10
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS operational_delay_rate
FROM orders o
JOIN deliveries d
    ON o.order_id = d.order_id
WHERE o.order_status = 'Delivered'
GROUP BY DATE(o.order_timestamp);
