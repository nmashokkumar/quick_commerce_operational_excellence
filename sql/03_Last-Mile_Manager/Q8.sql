-- Last-Mile Delivery Manager
-- What is the average order fulfillment and delivery time across different locations and time periods?

SELECT
    COUNT(*) AS total_delivered_orders
FROM orders
WHERE order_status = 'Delivered';

SELECT
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                order_timestamp,
                dispatch_ready_timestamp
            )
        ),
        2
    ) AS avg_fulfillment_time
FROM orders
WHERE order_status = 'Delivered';
SELECT
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                d.pickup_timestamp,
                d.actual_delivery_timestamp
            )
        ),
        2
    ) AS avg_delivery_time
FROM deliveries d;

SELECT
    u.city,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                o.order_timestamp,
                o.dispatch_ready_timestamp
            )
        ),
        2
    ) AS avg_fulfillment_time
FROM orders o
JOIN users u
    ON o.user_id = u.user_id
WHERE o.order_status = 'Delivered'
GROUP BY u.city
ORDER BY avg_fulfillment_time DESC;

SELECT
    u.city,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                d.pickup_timestamp,
                d.actual_delivery_timestamp
            )
        ),
        2
    ) AS avg_delivery_time
FROM orders o
JOIN deliveries d
    ON o.order_id = d.order_id
JOIN users u
    ON o.user_id = u.user_id
WHERE o.order_status = 'Delivered'
GROUP BY u.city
ORDER BY avg_delivery_time DESC;

SELECT
    DATE_FORMAT(o.order_timestamp, '%Y-%m') AS order_month,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                o.order_timestamp,
                o.dispatch_ready_timestamp
            )
        ),
        2
    ) AS avg_fulfillment_time
FROM orders o
WHERE o.order_status = 'Delivered'
GROUP BY DATE_FORMAT(o.order_timestamp, '%Y-%m')
ORDER BY order_month;

WITH city_monthly AS (
    SELECT
        u.city,
        DATE_FORMAT(o.order_timestamp, '%Y-%m') AS order_month,

        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                o.order_timestamp,
                o.dispatch_ready_timestamp
            )
        ) AS avg_fulfillment_time,

        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                d.pickup_timestamp,
                d.actual_delivery_timestamp
            )
        ) AS avg_delivery_time

    FROM orders o
    JOIN deliveries d
        ON o.order_id = d.order_id
    JOIN users u
        ON o.user_id = u.user_id

    WHERE o.order_status = 'Delivered'

    GROUP BY
        u.city,
        DATE_FORMAT(o.order_timestamp, '%Y-%m')
)

SELECT
    city,
    order_month,
    ROUND(avg_fulfillment_time, 2) AS avg_fulfillment_time,
    ROUND(avg_delivery_time, 2) AS avg_delivery_time,

    RANK() OVER (
        PARTITION BY order_month
        ORDER BY avg_fulfillment_time DESC
    ) AS fulfillment_time_rank,

    RANK() OVER (
        PARTITION BY order_month
        ORDER BY avg_delivery_time DESC
    ) AS delivery_time_rank

FROM city_monthly
ORDER BY
    order_month,
    delivery_time_rank;
    
    SELECT
    u.city,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                o.order_timestamp,
                o.dispatch_ready_timestamp
            )
        ),
        2
    ) AS avg_fulfillment_time
FROM orders o
JOIN users u
    ON o.user_id = u.user_id
WHERE o.order_status = 'Delivered'
GROUP BY u.city
ORDER BY avg_fulfillment_time DESC;

-- Views

CREATE VIEW vw_q8_fulfillment_delivery_time AS

WITH city_monthly AS (
    SELECT
        u.city,
        DATE_FORMAT(o.order_timestamp, '%Y-%m') AS order_month,

        COUNT(*) AS delivered_orders,

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
            AVG(
                TIMESTAMPDIFF(
                    MINUTE,
                    d.pickup_timestamp,
                    d.actual_delivery_timestamp
                )
            ),
            2
        ) AS avg_delivery_time

    FROM orders o

    JOIN deliveries d
        ON o.order_id = d.order_id

    JOIN users u
        ON o.user_id = u.user_id

    WHERE o.order_status = 'Delivered'

    GROUP BY
        u.city,
        DATE_FORMAT(o.order_timestamp, '%Y-%m')
),

window_analysis AS (
    SELECT
        city,
        order_month,
        delivered_orders,
        avg_fulfillment_time,
        avg_delivery_time,

        -- Average performance of the city across all months
        ROUND(
            AVG(avg_fulfillment_time)
            OVER (PARTITION BY city),
            2
        ) AS city_avg_fulfillment_time,

        ROUND(
            AVG(avg_delivery_time)
            OVER (PARTITION BY city),
            2
        ) AS city_avg_delivery_time,

        -- Monthly ranking
        RANK() OVER (
            PARTITION BY order_month
            ORDER BY avg_fulfillment_time DESC
        ) AS fulfillment_time_rank,

        RANK() OVER (
            PARTITION BY order_month
            ORDER BY avg_delivery_time DESC
        ) AS delivery_time_rank

    FROM city_monthly
)

SELECT
    city,
    order_month,
    delivered_orders,

    avg_fulfillment_time,
    avg_delivery_time,

    city_avg_fulfillment_time,
    city_avg_delivery_time,

    fulfillment_time_rank,
    delivery_time_rank,

    ROUND(
        avg_fulfillment_time - city_avg_fulfillment_time,
        2
    ) AS fulfillment_vs_city_avg,

    ROUND(
        avg_delivery_time - city_avg_delivery_time,
        2
    ) AS delivery_vs_city_avg

FROM window_analysis;