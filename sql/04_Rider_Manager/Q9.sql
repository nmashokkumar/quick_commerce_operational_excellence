-- Rider Operations Manager
-- Q9. . Which riders demonstrate consistently high or low operational performance?


SELECT
    r.rider_id,
    COUNT(d.delivery_id) AS completed_orders
FROM riders r
JOIN deliveries d
    ON r.rider_id = d.rider_id
GROUP BY
    r.rider_id
ORDER BY
    completed_orders DESC;
    
WITH rider_orders AS (
    SELECT
        r.rider_id,
        COUNT(d.delivery_id) AS completed_orders
    FROM riders r
    JOIN deliveries d
        ON r.rider_id = d.rider_id
    GROUP BY
        r.rider_id
)

SELECT
    rider_id,
    completed_orders,

    ROUND(
        AVG(completed_orders) OVER (),
        2
    ) AS avg_orders_per_rider,

    ROUND(
        completed_orders -
        AVG(completed_orders) OVER (),
        2
    ) AS difference_from_average,

    RANK() OVER (
        ORDER BY completed_orders DESC
    ) AS productivity_rank

FROM rider_orders
ORDER BY
    productivity_rank;
    
WITH rider_monthly AS (
    SELECT
        r.rider_id,
        DATE_FORMAT(
            d.actual_delivery_timestamp,
            '%Y-%m'
        ) AS delivery_month,

        COUNT(d.delivery_id) AS completed_orders

    FROM riders r
    JOIN deliveries d
        ON r.rider_id = d.rider_id

    GROUP BY
        r.rider_id,
        
        
        DATE_FORMAT(
            d.actual_delivery_timestamp,
            '%Y-%m'
        )
)

SELECT
    rider_id,
    delivery_month,
    completed_orders,

    ROUND(
        AVG(completed_orders)
        OVER (PARTITION BY rider_id),
        2
    ) AS rider_monthly_avg,

    RANK() OVER (
        PARTITION BY delivery_month
        ORDER BY completed_orders DESC
    ) AS monthly_productivity_rank

FROM rider_monthly

ORDER BY
    delivery_month,
    monthly_productivity_rank;
    
WITH rider_monthly AS (
    SELECT
        d.rider_id,
        DATE_FORMAT(
            d.actual_delivery_timestamp,
            '%Y-%m'
        ) AS delivery_month,
        COUNT(d.delivery_id) AS completed_orders
    FROM deliveries d
    GROUP BY
        d.rider_id,
        DATE_FORMAT(
            d.actual_delivery_timestamp,
            '%Y-%m'
        )
),

rider_consistency AS (
    SELECT
        rider_id,

        ROUND(
            AVG(completed_orders),
            2
        ) AS avg_monthly_orders,

        MIN(completed_orders) AS min_monthly_orders,

        MAX(completed_orders) AS max_monthly_orders,

        COUNT(*) AS months_active,

        ROUND(
            MAX(completed_orders) - MIN(completed_orders),
            2
        ) AS monthly_order_range

    FROM rider_monthly

    GROUP BY rider_id
)

SELECT
    rider_id,
    avg_monthly_orders,
    min_monthly_orders,
    max_monthly_orders,
    monthly_order_range,
    months_active
FROM rider_consistency
WHERE months_active = 6
ORDER BY avg_monthly_orders DESC;

-- Views
CREATE VIEW vw_q9_rider_performance AS

WITH rider_orders AS (
    SELECT
        d.rider_id,
        COUNT(d.delivery_id) AS completed_orders
    FROM deliveries d
    GROUP BY d.rider_id
),

rider_monthly AS (
    SELECT
        d.rider_id,
        DATE_FORMAT(
            d.actual_delivery_timestamp,
            '%Y-%m'
        ) AS delivery_month,
        COUNT(d.delivery_id) AS monthly_orders
    FROM deliveries d
    GROUP BY
        d.rider_id,
        DATE_FORMAT(
            d.actual_delivery_timestamp,
            '%Y-%m'
        )
),

rider_consistency AS (
    SELECT
        rider_id,
        ROUND(AVG(monthly_orders), 2) AS avg_monthly_orders,
        MIN(monthly_orders) AS min_monthly_orders,
        MAX(monthly_orders) AS max_monthly_orders,
        MAX(monthly_orders) - MIN(monthly_orders) AS monthly_order_range
    FROM rider_monthly
    GROUP BY rider_id
)

SELECT
    ro.rider_id,
    ro.completed_orders,
    rc.avg_monthly_orders,
    rc.min_monthly_orders,
    rc.max_monthly_orders,
    rc.monthly_order_range,

    RANK() OVER (
        ORDER BY ro.completed_orders DESC
    ) AS productivity_rank

FROM rider_orders ro

JOIN rider_consistency rc
    ON ro.rider_id = rc.rider_id;