--Reformat the final_assignments_qa to look like the final_assignments table, filling in any missing values with a placeholder of the appropriate data type.

SELECT item_id,
       test_a AS test_assignment,
       (CASE
            WHEN test_a IS NOT NULL then 'item_test_a'
            ELSE NULL
        END) AS test_number,
       (CASE
            WHEN test_a IS NOT NULL then '2013-01-05 00:00:00'
            ELSE NULL
        END) AS test_start_date
FROM dsv1069.final_assignments_qa
UNION
SELECT item_id,
       test_b AS test_assignment,
       (CASE
            WHEN test_b IS NOT NULL then 'item_test_b'
            ELSE NULL
        END) AS test_number,
       (CASE
            WHEN test_b IS NOT NULL then '2013-01-05 00:00:00'
            ELSE NULL
        END) AS test_start_date
FROM dsv1069.final_assignments_qa
UNION
SELECT item_id,
       test_c AS test_assignment,
       (CASE
            WHEN test_c IS NOT NULL then 'item_test_c'
            ELSE NULL
        END) AS test_number,
       (CASE
            WHEN test_c IS NOT NULL then '2013-01-05 00:00:00'
            ELSE NULL
        END) AS test_start_date
FROM dsv1069.final_assignments_qa
UNION
SELECT item_id,
       test_d AS test_assignment,
       (CASE
            WHEN test_d IS NOT NULL then 'item_test_d'
            ELSE NULL
        END) AS test_number,
       (CASE
            WHEN test_d IS NOT NULL then '2013-01-05 00:00:00'
            ELSE NULL
        END) AS test_start_date
FROM dsv1069.final_assignments_qa
UNION
SELECT item_id,
       test_e AS test_assignment,
       (CASE
            WHEN test_e IS NOT NULL then 'item_test_e'
            ELSE NULL
        END) AS test_number,
       (CASE
            WHEN test_e IS NOT NULL then '2013-01-05 00:00:00'
            ELSE NULL
        END) AS test_start_date
FROM dsv1069.final_assignments_qa
UNION
SELECT item_id,
       test_f AS test_assignment,
       (CASE
            WHEN test_f IS NOT NULL then 'item_test_f'
            ELSE NULL
        END) AS test_number,
       (CASE
            WHEN test_f IS NOT NULL then '2013-01-05 00:00:00'
            ELSE NULL
        END) AS test_start_date
FROM dsv1069.final_assignments_qa;


-- Use this table to 
-- compute order_binary for the 30 day window after the test_start_date
-- for the test named item_test_2

SELECT test_assignment,
       COUNT(DISTINCT item_id) AS number_of_items,
       SUM(order_binary) AS items_ordered
FROM
  (SELECT item_test_2.item_id,
          item_test_2.test_assignment,
          item_test_2.test_number,
          item_test_2.test_start_date,
          item_test_2.created_at,
          MAX(CASE
                  WHEN (created_at > test_start_date
                        AND DATE_PART('day', created_at - test_start_date) <= 30) THEN 1
                  ELSE 0
              END) AS order_binary
   FROM
     (SELECT final_assignments.*,
             DATE(orders.created_at) AS created_at
      FROM dsv1069.final_assignments AS final_assignments
      LEFT JOIN dsv1069.orders AS orders
        ON final_assignments.item_id = orders.item_id
        WHERE test_number = 'item_test_2') AS item_test_2
   GROUP BY item_test_2.item_id,
            item_test_2.test_assignment,
            item_test_2.test_number,
            item_test_2.test_start_date,
            item_test_2.created_at) AS order_binary
GROUP BY test_assignment;

-- Use this table to 
-- compute view_binary for the 30 day window after the test_start_date
-- for the test named item_test_2
SELECT
  test_assignment,
  COUNT(DISTINCT item_id) AS number_of_items,
  SUM(order_binary) AS viewed_items,
  CAST(100 * SUM(order_binary) / COUNT(item_id) AS FLOAT) AS viewed_percentage,
  SUM(views) AS views,
  SUM(views) / COUNT(item_id) AS average_views_per_item
FROM
  (
    SELECT
      fa.item_id,
      fa.test_assignment,
      fa.test_number,
      fa.test_start_date, 
      MAX(
        CASE
          WHEN views.event_time > fa.test_start_date THEN 1
          ELSE 0
        END
      ) AS order_binary,
      COUNT(views.event_id) AS views
    FROM
      dsv1069.final_assignments fa
      LEFT OUTER JOIN(
        SELECT
          event_time,
          event_id,
          CAST(EVENTS.parameter_value AS int) AS item_id
        FROM
          dsv1069.events
        WHERE
          event_name = 'view_item'
          AND parameter_name = 'item_id'
      ) views ON fa.item_id = views.item_id
      AND views.event_time >= fa.test_start_date
      AND date_part('day', views.event_time - fa.test_start_date) <= 30
    WHERE
      fa.test_number = 'item_test_2'
    GROUP BY
       fa.item_id,
      fa.test_assignment,
      fa.test_number,
      fa.test_start_date
  ) item_level
GROUP BY
  test_assignment
LIMIT 100;
  
  
--Use the https://thumbtack.github.io/abba/demo/abba.html to compute the lifts in metrics and the p-values for the binary metrics ( 30 day order binary and 30 day view binary) using a interval 95% confidence. 

SELECT test_assignment,
       test_number,
       COUNT(DISTINCT item) AS order_binary,
       SUM(view_binary) AS view_binary
FROM
  (SELECT final_assignments.item_id AS item,
          test_assignment,
          test_number,
          test_start_date,
          MAX((CASE
                   WHEN date(event_time) - date(test_start_date) BETWEEN 0 AND 30 THEN 1
                   ELSE 0
               END)) AS view_binary
   FROM dsv1069.final_assignments
   LEFT JOIN dsv1069.view_item_events
     ON final_assignments.item_id = view_item_events.item_id
   WHERE test_number = 'item_test_2'
   GROUP BY final_assignments.item_id,
            test_assignment,
            test_number,
            test_start_date) AS view_binary
GROUP BY test_assignment,
         test_number,
         test_start_date;
         
--p-value 0.25 not significant
--average improvement 2.3% (-1.6%-6.1%)
--CONCLUSION. no statistically significant improvement
