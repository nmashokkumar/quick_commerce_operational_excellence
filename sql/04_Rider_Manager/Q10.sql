-- Rider Operations Manager

-- Q10. Are rider resources allocated efficiently across dark stores relative to delivery demand?

SELECT
    ds.dark_store_id,
    ds.dark_store_name,

    COUNT(d.delivery_id) AS completed_deliveries

FROM dark_stores ds

JOIN orders o
    ON ds.dark_store_id = o.dark_store_id

JOIN deliveries d
    ON o.order_id = d.order_id

WHERE o.order_status = 'Delivered'

GROUP BY
    ds.dark_store_id,
    ds.dark_store_name

ORDER BY
    completed_deliveries DESC;
    
SELECT
    ds.dark_store_id,
    ds.dark_store_name,

    COUNT(DISTINCT r.rider_id) AS assigned_riders

FROM dark_stores ds

LEFT JOIN riders r
    ON ds.dark_store_id = r.dark_store_id

GROUP BY
    ds.dark_store_id,
    ds.dark_store_name

ORDER BY
    assigned_riders DESC;
    
WITH store_demand AS (
    SELECT
        o.dark_store_id,
        COUNT(d.delivery_id) AS completed_deliveries

    FROM orders o

    JOIN deliveries d
        ON o.order_id = d.order_id

    WHERE o.order_status = 'Delivered'

    GROUP BY
        o.dark_store_id
),

store_riders AS (
    SELECT
        dark_store_id,
        COUNT(DISTINCT rider_id) AS assigned_riders

    FROM riders

    GROUP BY
        dark_store_id
)

SELECT
    ds.dark_store_id,
    ds.dark_store_name,

    COALESCE(sd.completed_deliveries, 0) AS completed_deliveries,

    COALESCE(sr.assigned_riders, 0) AS assigned_riders,

    ROUND(
        COALESCE(sd.completed_deliveries, 0)
        /
        NULLIF(sr.assigned_riders, 0),
        2
    ) AS deliveries_per_rider

FROM dark_stores ds

LEFT JOIN store_demand sd
    ON ds.dark_store_id = sd.dark_store_id

LEFT JOIN store_riders sr
    ON ds.dark_store_id = sr.dark_store_id

ORDER BY
    deliveries_per_rider DESC;
    
WITH store_demand AS (
    SELECT
        o.dark_store_id,
        COUNT(d.delivery_id) AS completed_deliveries
    FROM orders o
    JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.dark_store_id
),

store_riders AS (
    SELECT
        dark_store_id,
        COUNT(DISTINCT rider_id) AS assigned_riders
    FROM riders
    GROUP BY dark_store_id
),

store_workload AS (
    SELECT
        ds.dark_store_id,
        ds.dark_store_name,

        COALESCE(sr.assigned_riders, 0) AS assigned_riders,
        COALESCE(sd.completed_deliveries, 0) AS completed_deliveries

    FROM dark_stores ds

    LEFT JOIN store_demand sd
        ON ds.dark_store_id = sd.dark_store_id

    LEFT JOIN store_riders sr
        ON ds.dark_store_id = sr.dark_store_id
),

benchmark AS (
    SELECT
        SUM(completed_deliveries)
        / NULLIF(SUM(assigned_riders), 0)
        AS overall_benchmark
    FROM store_workload
    WHERE assigned_riders > 0
)

SELECT
    sw.dark_store_id,
    sw.dark_store_name,
    sw.assigned_riders,
    sw.completed_deliveries,

    ROUND(
        sw.completed_deliveries
        / NULLIF(sw.assigned_riders, 0),
        2
    ) AS deliveries_per_rider,

    ROUND(
        b.overall_benchmark,
        2
    ) AS overall_benchmark,

    ROUND(
        (
            sw.completed_deliveries
            / NULLIF(sw.assigned_riders, 0)
        ) - b.overall_benchmark,
        2
    ) AS difference_from_benchmark,

    CASE
        WHEN sw.completed_deliveries = 0
            THEN 'No Delivery Activity'

        WHEN (
            sw.completed_deliveries
            / NULLIF(sw.assigned_riders, 0)
        ) > b.overall_benchmark
            THEN 'Above Benchmark'

        ELSE 'Below Benchmark'
    END AS workload_status

FROM store_workload sw

CROSS JOIN benchmark b

WHERE sw.assigned_riders > 0

ORDER BY
    deliveries_per_rider DESC;
    
-- Views

CREATE VIEW vw_q10_rider_allocation AS

WITH store_demand AS (
    SELECT
        o.dark_store_id,
        COUNT(d.delivery_id) AS completed_deliveries
    FROM orders o
    JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.dark_store_id
),

store_riders AS (
    SELECT
        dark_store_id,
        COUNT(DISTINCT rider_id) AS assigned_riders
    FROM riders
    GROUP BY dark_store_id
),

store_workload AS (
    SELECT
        ds.dark_store_id,
        ds.dark_store_name,

        COALESCE(sr.assigned_riders, 0) AS assigned_riders,

        COALESCE(
            sd.completed_deliveries,
            0
        ) AS completed_deliveries

    FROM dark_stores ds

    LEFT JOIN store_demand sd
        ON ds.dark_store_id = sd.dark_store_id

    LEFT JOIN store_riders sr
        ON ds.dark_store_id = sr.dark_store_id
),

benchmark AS (
    SELECT
        SUM(completed_deliveries)
        / NULLIF(SUM(assigned_riders), 0)
        AS overall_benchmark
    FROM store_workload
    WHERE assigned_riders > 0
)

SELECT
    sw.dark_store_id,
    sw.dark_store_name,
    sw.assigned_riders,
    sw.completed_deliveries,

    ROUND(
        sw.completed_deliveries
        / NULLIF(sw.assigned_riders, 0),
        2
    ) AS deliveries_per_rider,

    ROUND(
        b.overall_benchmark,
        2
    ) AS overall_benchmark,

    ROUND(
        (
            sw.completed_deliveries
            / NULLIF(sw.assigned_riders, 0)
        ) - b.overall_benchmark,
        2
    ) AS difference_from_benchmark,

    CASE
        WHEN sw.completed_deliveries = 0
            THEN 'No Delivery Activity'

        WHEN (
            sw.completed_deliveries
            / NULLIF(sw.assigned_riders, 0)
        ) > b.overall_benchmark
            THEN 'Above Benchmark'

        ELSE 'Below Benchmark'
    END AS workload_status

FROM store_workload sw

CROSS JOIN benchmark b

WHERE sw.assigned_riders > 0;