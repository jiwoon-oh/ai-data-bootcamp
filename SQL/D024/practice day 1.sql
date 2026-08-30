-- [C25] 📒 연습 문제 — CTE와 윈도우 함수 (1/5)

-- 문제: CTE로 고객별 총구매액을 구한 뒤, 30만원 이상인 고객만 조회합니다.

-- 아래에 SQL 쿼리를 작성하세요.
WITH total AS (
  SELECT
  c.name,
  SUM(amount) AS total_price
FROM `your-project-id.ai_bootcamp_sql.customers` AS c
JOIN `your-project-id.ai_bootcamp_sql.orders` AS o
ON c.customer_id = o.customer_id
WHERE
  o.amount IS NOT NULL
GROUP BY
  c.name
ORDER BY
  total_price DESC
)
SELECT *
FROM total
WHERE
  total_price >= 300000
ORDER BY
  total_price DESC;
-- [C26] 📒 연습 문제 — CTE와 윈도우 함수 (2/5)

-- 문제: 각 카테고리 안에서 매출 1위 상품만 뽑으세요. (PARTITION BY + ROW_NUMBER)

-- 아래에 SQL 쿼리를 작성하세요.
WITH prod AS (
  SELECT
  p.product_name,
  p.category,
  SUM(oi.quantity * oi.unit_price) AS revenue
FROM `your-project-id.ai_bootcamp_sql.products` AS p
JOIN `your-project-id.ai_bootcamp_sql.order_item` AS oi
ON p.product_id = oi.product_id
GROUP BY
  p.product_name,
  p.category
), ranked AS (
  SELECT 
    category, 
    product_name, 
    revenue,
  ROW_NUMBER () OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
  FROM prod
)
SELECT 
  category,
  product_name,
  revenue
FROM ranked
WHERE 
  rn = 1
ORDER BY
  revenue DESC;
-- [C27] 📒 연습 문제 — CTE와 윈도우 함수 (3/5)

-- 문제: 월별 매출과 누적 매출을 함께 조회합니다.

-- 아래에 SQL 쿼리를 작성하세요.
WITH monthly AS (
  SELECT 
    DATE_TRUNC(order_date, MONTH) AS month,
    SUM(amount) AS revenue
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
  amount IS NOT NULL
  GROUP BY 
    DATE_TRUNC(order_date, MONTH)
)
SELECT 
  month,
  SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS `누적매출`
FROM monthly
ORDER BY 
  month NULLS LAST;
-- [C28] 📒 연습 문제 — CTE와 윈도우 함수 (4/5)

-- 문제: 월별 매출에 전월 매출과 증감률(%)을 붙이세요. (LAG)

-- 아래에 SQL 쿼리를 작성하세요.
WITH monthly AS (
  SELECT 
    DATE_TRUNC(order_date, MONTH) AS month,
    SUM(amount) AS revenue
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
  amount IS NOT NULL
  GROUP BY 
    DATE_TRUNC(order_date, MONTH)
)
SELECT 
  month,
  LAG(revenue) OVER (ORDER BY month NULLS LAST) AS `전월매출`,
  ROUND(
    (
      revenue - LAG(revenue) OVER (ORDER BY month NULLS LAST)
    ) * 100.0 / NULLIF(NULLIF(LAG(revenue) OVER (ORDER BY month NULLS LAST), 0), 0),
    1
  ) AS `증감률_pct`
FROM monthly
ORDER BY 
  month NULLS LAST;
-- [C29] 📒 연습 문제 — CTE와 윈도우 함수 (5/5)

-- 문제: 고객별 총구매액을 NTILE(3)으로 상·중·하 등급으로 나누세요.

-- 아래에 SQL 쿼리를 작성하세요.
WITH cus AS (
  SELECT
  c.name,
  SUM(amount) AS total
FROM `your-project-id.ai_bootcamp_sql.customers` AS c
JOIN `your-project-id.ai_bootcamp_sql.orders` AS o
ON c.customer_id = o.customer_id
GROUP BY
  c.name
), tier AS (
  SELECT
    name,
    total,
    NTILE(3) OVER (ORDER BY total DESC) AS `구매력_3분위`,
  FROM cus
)
SELECT
  name,
  total,
  CASE `구매력_3분위` WHEN 1 THEN 'HIGH' WHEN 2 THEN 'MIDDLE' WHEN 3 THEN 'LOW' END AS `티어표`
FROM tier
ORDER BY
  total DESC;