-- Last-Mile Delivery Manager

-- Q7. Which delivery zones consistently fail to meet the promised delivery SLA?
SELECT
    u.city,
    COUNT(*) AS total_delivered_orders,
    SUM(
        CASE
            WHEN d.actual_delivery_timestamp
                 <= d.promised_delivery_timestamp
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,
    SUM(
        CASE
            WHEN d.actual_delivery_timestamp
                 > d.promised_delivery_timestamp
            THEN 1
            ELSE 0
        END
    ) AS delayed_orders,
    ROUND(
        SUM(
            CASE
                WHEN d.actual_delivery_timestamp
                     <= d.promised_delivery_timestamp
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS on_time_delivery_rate
FROM orders o
JOIN deliveries d
    ON o.order_id = d.order_id
JOIN users u
    ON o.user_id = u.user_id
WHERE o.order_status = 'Delivered'
GROUP BY
    u.city
ORDER BY
    on_time_delivery_rate ASC;
    
    
SELECT
    u.city,
    DATE_FORMAT(o.order_timestamp, '%Y-%m') AS order_month,

    COUNT(*) AS total_delivered_orders,

    SUM(
        CASE
            WHEN d.actual_delivery_timestamp <= d.promised_delivery_timestamp
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,

    ROUND(
        SUM(
            CASE
                WHEN d.actual_delivery_timestamp <= d.promised_delivery_timestamp
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS on_time_delivery_rate

FROM orders o
JOIN deliveries d
    ON o.order_id = d.order_id
JOIN users u
    ON o.user_id = u.user_id

WHERE o.order_status = 'Delivered'

GROUP BY
    u.city,
    DATE_FORMAT(o.order_timestamp, '%Y-%m')

ORDER BY
    u.city,
    order_month;
    
-- Views
CREATE VIEW vw_q7_city_sla_trend AS
SELECT
    u.city,
    DATE_FORMAT(o.order_timestamp, '%Y-%m') AS order_month,

    COUNT(*) AS total_delivered_orders,

    SUM(
        CASE
            WHEN d.actual_delivery_timestamp
                 <= d.promised_delivery_timestamp
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,

    SUM(
        CASE
            WHEN d.actual_delivery_timestamp
                 > d.promised_delivery_timestamp
            THEN 1
            ELSE 0
        END
    ) AS delayed_orders,

    ROUND(
        SUM(
            CASE
                WHEN d.actual_delivery_timestamp
                     <= d.promised_delivery_timestamp
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS on_time_delivery_rate

FROM orders o

JOIN deliveries d
    ON o.order_id = d.order_id

JOIN users u
    ON o.user_id = u.user_id

WHERE o.order_status = 'Delivered'

GROUP BY
    u.city,
    DATE_FORMAT(o.order_timestamp, '%Y-%m');