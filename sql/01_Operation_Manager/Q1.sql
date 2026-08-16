/*
Objective:
Improve overall fulfillment efficiency.

Business Questions:
Q1. Which operational bottlenecks contribute the most to delayed order fulfillment?
*/

-- Q1. Which operational bottlenecks contribute the most to delayed order fulfillment?
WITH metric_summary AS (
    SELECT
        -- Stage 1: Order to Dispatch Ready
        MIN(TIMESTAMPDIFF(MINUTE, o.order_timestamp, o.dispatch_ready_timestamp)) AS min_fulfillment,
        MAX(TIMESTAMPDIFF(MINUTE, o.order_timestamp, o.dispatch_ready_timestamp)) AS max_fulfillment,
        AVG(TIMESTAMPDIFF(MINUTE, o.order_timestamp, o.dispatch_ready_timestamp)) AS avg_fulfillment,
        
        -- Stage 2: Dispatch Ready to Rider Assigned
        MIN(TIMESTAMPDIFF(MINUTE, o.dispatch_ready_timestamp, d.rider_assigned_timestamp)) AS min_drt_to_rat,
        MAX(TIMESTAMPDIFF(MINUTE, o.dispatch_ready_timestamp, d.rider_assigned_timestamp)) AS max_drt_to_rat,
        AVG(TIMESTAMPDIFF(MINUTE, o.dispatch_ready_timestamp, d.rider_assigned_timestamp)) AS avg_drt_to_rat,
        
        -- Stage 3: Rider Assigned to Pickup
        MIN(TIMESTAMPDIFF(MINUTE, d.rider_assigned_timestamp, d.pickup_timestamp)) AS min_rat_to_pt,
        MAX(TIMESTAMPDIFF(MINUTE, d.rider_assigned_timestamp, d.pickup_timestamp)) AS max_rat_to_pt,
        AVG(TIMESTAMPDIFF(MINUTE, d.rider_assigned_timestamp, d.pickup_timestamp)) AS avg_rat_to_pt
    FROM orders o
    JOIN deliveries d 
        ON o.order_id = d.order_id
)
SELECT 
    'MIN' AS metric, 
    min_fulfillment AS order_to_dispatch, 
    min_drt_to_rat AS dispatch_to_rider, 
    min_rat_to_pt AS rider_to_pickup 
FROM metric_summary

UNION ALL

SELECT 
    'MAX' AS metric, 
    max_fulfillment, 
    max_drt_to_rat, 
    max_rat_to_pt 
FROM metric_summary

UNION ALL

SELECT 
    'AVG' AS metric, 
    ROUND(avg_fulfillment, 2), 
    ROUND(avg_drt_to_rat, 2), 
    ROUND(avg_rat_to_pt, 2) 
FROM metric_summary;

SELECT
	CASE WHEN TIMESTAMPDIFF(MINUTE, o.order_timestamp, o.dispatch_ready_timestamp) <= 10 THEN 'on-time' ELSE 'Delayed' END AS category,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_timestamp, o.dispatch_ready_timestamp)),2) AS avg_ot_to_drt,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.dispatch_ready_timestamp, d.rider_assigned_timestamp)),2) AS avg_drt_to_rat,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.rider_assigned_timestamp, d.pickup_timestamp)),2) AS avg_rat_to_pt
    
FROM 
	orders o
JOIN deliveries d 
	ON o.order_id = d.order_id
GROUP BY 1;

SELECT
	ds.dark_store_name AS DS_Name,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.order_timestamp, o.dispatch_ready_timestamp)),2) AS avg_ot_to_drt
FROM
	orders o 
JOIN dark_stores ds
	ON o.dark_store_id = ds.dark_store_id
GROUP BY 1
ORDER BY 2 desc;

SELECT
	HOUR(order_timestamp) as hr,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_timestamp, dispatch_ready_timestamp)),2) AS avg_ot_to_drt
FROM
	orders 
GROUP BY 1
ORDER BY 2 DESC;

SELECT
	SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, order_timestamp, dispatch_ready_timestamp) > 10 THEN 1 ELSE 0 END) /
    COUNT(*)*100 AS op_delay_rate
FROM
	orders 
WHERE order_status = 'Delivered';

-- views

CREATE OR REPLACE VIEW vw_q1_operational_analysis AS
SELECT
    o.order_id,
    o.dark_store_id,
    ds.dark_store_name,
    o.order_timestamp,

    TIMESTAMPDIFF(
        MINUTE,
        o.order_timestamp,
        o.dispatch_ready_timestamp
    ) AS order_to_dispatch_minutes,

    TIMESTAMPDIFF(
        MINUTE,
        o.dispatch_ready_timestamp,
        d.rider_assigned_timestamp
    ) AS dispatch_to_rider_minutes,

    TIMESTAMPDIFF(
        MINUTE,
        d.rider_assigned_timestamp,
        d.pickup_timestamp
    ) AS rider_to_pickup_minutes,

    CASE
        WHEN TIMESTAMPDIFF(
            MINUTE,
            o.order_timestamp,
            o.dispatch_ready_timestamp
        ) > 10
        THEN 'Delayed'
        ELSE 'On-time'
    END AS fulfillment_category,

    CASE
        WHEN TIMESTAMPDIFF(
            MINUTE,
            o.order_timestamp,
            o.dispatch_ready_timestamp
        ) > 10
        THEN 1
        ELSE 0
    END AS operational_delay_flag

FROM orders o

JOIN deliveries d
    ON o.order_id = d.order_id

JOIN dark_stores ds
    ON o.dark_store_id = ds.dark_store_id

WHERE o.order_status = 'Delivered';

select 
	
