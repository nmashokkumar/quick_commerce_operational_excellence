-- Last-Mile Delivery Manager
-- Q6. What operational factors contribute most to delivery delays?

SELECT
	SUM(CASE WHEN promised_delivery_timestamp > actual_delivery_timestamp THEN 1 ELSE 0 END) / COUNT(*)*100
FROM 
	deliveries;
WITH metric_summary AS (
    SELECT

        -- Stage 1: Dispatch Ready to Rider Assigned
        MIN(
            TIMESTAMPDIFF(
                MINUTE,
                o.dispatch_ready_timestamp,
                d.rider_assigned_timestamp
            )
        ) AS min_dispatch_to_rider,

        MAX(
            TIMESTAMPDIFF(
                MINUTE,
                o.dispatch_ready_timestamp,
                d.rider_assigned_timestamp
            )
        ) AS max_dispatch_to_rider,

        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                o.dispatch_ready_timestamp,
                d.rider_assigned_timestamp
            )
        ) AS avg_dispatch_to_rider,


        -- Stage 2: Rider Assigned to Pickup
        MIN(
            TIMESTAMPDIFF(
                MINUTE,
                d.rider_assigned_timestamp,
                d.pickup_timestamp
            )
        ) AS min_rider_to_pickup,

        MAX(
            TIMESTAMPDIFF(
                MINUTE,
                d.rider_assigned_timestamp,
                d.pickup_timestamp
            )
        ) AS max_rider_to_pickup,

        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                d.rider_assigned_timestamp,
                d.pickup_timestamp
            )
        ) AS avg_rider_to_pickup,


        -- Stage 3: Pickup to Actual Delivery
        MIN(
            TIMESTAMPDIFF(
                MINUTE,
                d.pickup_timestamp,
                d.actual_delivery_timestamp
            )
        ) AS min_pickup_to_delivery,

        MAX(
            TIMESTAMPDIFF(
                MINUTE,
                d.pickup_timestamp,
                d.actual_delivery_timestamp
            )
        ) AS max_pickup_to_delivery,

        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                d.pickup_timestamp,
                d.actual_delivery_timestamp
            )
        ) AS avg_pickup_to_delivery,


        -- SLA Delay
        MIN(
            TIMESTAMPDIFF(
                MINUTE,
                d.promised_delivery_timestamp,
                d.actual_delivery_timestamp
            )
        ) AS min_sla_delay,

        MAX(
            TIMESTAMPDIFF(
                MINUTE,
                d.promised_delivery_timestamp,
                d.actual_delivery_timestamp
            )
        ) AS max_sla_delay,

        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                d.promised_delivery_timestamp,
                d.actual_delivery_timestamp
            )
        ) AS avg_sla_delay

    FROM orders o
    JOIN deliveries d
        ON o.order_id = d.order_id

    WHERE
        o.order_status = 'Delivered'
        AND d.actual_delivery_timestamp >
            d.promised_delivery_timestamp
)

SELECT
    'MIN' AS metric,
    min_dispatch_to_rider AS dispatch_to_rider,
    min_rider_to_pickup AS rider_to_pickup,
    min_pickup_to_delivery AS pickup_to_delivery,
    min_sla_delay AS sla_delay
FROM metric_summary

UNION ALL

SELECT
    'MAX' AS metric,
    max_dispatch_to_rider,
    max_rider_to_pickup,
    max_pickup_to_delivery,
    max_sla_delay
FROM metric_summary

UNION ALL

SELECT
    'AVG' AS metric,
    ROUND(avg_dispatch_to_rider, 2),
    ROUND(avg_rider_to_pickup, 2),
    ROUND(avg_pickup_to_delivery, 2),
    ROUND(avg_sla_delay, 2)
FROM metric_summary;

-- Views

CREATE VIEW vw_q6_delivery_delay_analysis AS

SELECT
    o.order_id,
    o.dark_store_id,
    d.delivery_id,
    d.rider_id,

    o.order_timestamp,
    o.dispatch_ready_timestamp,
    d.rider_assigned_timestamp,
    d.pickup_timestamp,
    d.promised_delivery_timestamp,
    d.actual_delivery_timestamp,

    -- Delivery performance
    CASE
        WHEN d.actual_delivery_timestamp <= d.promised_delivery_timestamp
        THEN 'On Time'
        ELSE 'Delayed'
    END AS delivery_status,

    -- Overall SLA delay
    GREATEST(
        TIMESTAMPDIFF(
            MINUTE,
            d.promised_delivery_timestamp,
            d.actual_delivery_timestamp
        ),
        0
    ) AS sla_delay_minutes,

    -- Stage 1: Dispatch Ready → Rider Assigned
    TIMESTAMPDIFF(
        MINUTE,
        o.dispatch_ready_timestamp,
        d.rider_assigned_timestamp
    ) AS dispatch_to_rider_minutes,

    -- Stage 2: Rider Assigned → Pickup
    TIMESTAMPDIFF(
        MINUTE,
        d.rider_assigned_timestamp,
        d.pickup_timestamp
    ) AS rider_to_pickup_minutes,

    -- Stage 3: Pickup → Delivery
    TIMESTAMPDIFF(
        MINUTE,
        d.pickup_timestamp,
        d.actual_delivery_timestamp
    ) AS pickup_to_delivery_minutes

FROM orders o

JOIN deliveries d
    ON o.order_id = d.order_id

WHERE o.order_status = 'Delivered';
