-- [C8]
CREATE OR REPLACE TABLE `your-project-id.ai_bootcamp_sql.customer_mart` AS
WITH order_stats AS (
  SELECT
    customer_id,
    COUNT(*) AS order_count,
    SUM(amount) AS total_spent,
    MAX(order_date) AS last_order_date
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
    AND amount IS NOT NULL
  GROUP BY
    customer_id
), web_stats AS (
  SELECT
    customer_id,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS web_purchased,
    DATE_TRUNC(DATE(MIN(event_at)), MONTH) AS cohort_month
  FROM `your-project-id.ai_bootcamp_sql.name_events`
  GROUP BY
    customer_id
)
SELECT
  c.customer_id,
  c.name,
  c.country,
  c.grade,
  COALESCE(os.order_count, 0) AS order_count,
  COALESCE(os.total_spent, 0) AS total_spent,
  os.last_order_date,
  DATE_DIFF(DATE '2024-03-01', os.last_order_date, DAY) AS recency_days,
  CASE WHEN COALESCE(os.order_count, 0) > 0 THEN 1 ELSE 0 END AS ever_purchased,
  COALESCE(ws.web_purchased, 0) AS web_purchased,
  ws.cohort_month
FROM `your-project-id.ai_bootcamp_sql.customers` AS c
LEFT JOIN order_stats AS os
  ON c.customer_id = os.customer_id
LEFT JOIN web_stats AS ws
  ON c.customer_id = ws.customer_id;

-- [C9]
CREATE OR REPLACE TABLE `your-project-id.ai_bootcamp_sql.customer_mart` AS
SELECT
  *,
  CASE
    WHEN total_spent >= 300000 AND recency_days <= 90
    THEN '핵심 고객'
    WHEN order_count = 0
    THEN '미구매'
    WHEN recency_days > 120
    THEN '이탈 위험'
    ELSE '일반 고객'
  END AS segment
FROM `your-project-id.ai_bootcamp_sql.customer_mart`;

SELECT 
  name,
  total_spent,
  segment
FROM `your-project-id.ai_bootcamp_sql.customer_mart`
WHERE
  segment = '핵심 고객'
ORDER BY
  total_spent;

SELECT
  name,
  country,
  segment
FROM `your-project-id.ai_bootcamp_sql.customer_mart`
WHERE
  order_count=0;

-- [C12]
CREATE OR REPLACE TABLE `your-project-id.ai_bootcamp_sql.daily_sales` AS
SELECT
  order_date,
  COUNT(*) AS order_count,
  SUM(amount) AS revenue
FROM `your-project-id.ai_bootcamp_sql.orders`
WHERE
  status NOT IN ('Cancelled', 'Returned')
  AND amount IS NOT NULL
GROUP BY
  order_date
ORDER BY
  order_date NULLS LAST;

-- [C13]
SELECT
  DATE_TRUNC(order_date, DAY) AS month,
  SUM(order_count) AS orders,
  SUM(revenue) AS revenue
FROM `your-project-id.ai_bootcamp_sql.daily_sales`
GROUP BY
  month
ORDER BY
  month NULLS LAST;

-- [문제] daily_sales를 이용해 하루 매출이 가장 컸던 날 TOP 3를 구합니다. (날짜·매출)
SELECT
  revenue,
  order_date
FROM `your-project-id.ai_bootcamp_sql.daily_sales`
ORDER BY
  revenue DESC
LIMIT 3;

-- [문제] daily_sales(또는 orders)를 이용해, 주(week) 단위 매출을 집계합니다. (주별 매출 합, 주 순서대로)
SELECT
  SUM(revenue) AS revenue,
  DATE_TRUNC(order_date, WEEK) AS order_week
FROM `your-project-id.ai_bootcamp_sql.daily_sales`
GROUP BY
  order_week
ORDER BY
  revenue DESC;

-- [C16]
SELECT
  segment,
  COUNT(*) AS `고객수`,
  ROUND(AVG(total_spent), 0) AS `평균구매액`
FROM `your-project-id.ai_bootcamp_sql.customer_mart`
GROUP BY
  segment
ORDER BY
  `평균구매액` DESC;

-- [C17]
SELECT
  country,
  COUNT(*) AS total,
  SUM(CASE WHEN segment = '핵심 고객' THEN 1 ELSE 0 END) AS `핵심고객수`,
  ROUND(
    SUM(CASE WHEN segment = '핵심 고객' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0),
    1
  ) AS `핵심비율_pct`
FROM `your-project-id.ai_bootcamp_sql.customer_mart`
WHERE
  country IS NOT NULL
GROUP BY
  country
ORDER BY
  `핵심비율_pct` DESC;

-- [C18]
SELECT
  name,
  total_spent,
  recency_days,
  segment
FROM `your-project-id.ai_bootcamp_sql.customer_mart`
WHERE
  segment = '이탈 위험'
ORDER BY
  total_spent DESC;

-- [C19]
SELECT
  grade,
  COUNT(*) AS `인원`,
  ROUND(AVG(total_spent), 0) AS `평균구매액`
FROM `your-project-id.ai_bootcamp_sql.customer_mart`
WHERE
  grade IS NOT NULL
GROUP BY
  grade
ORDER BY
  `평균구매액` DESC;

-- [C20]
SELECT
  COUNT(*) AS `전체고객`,
  SUM(CASE WHEN ever_purchased = 1 THEN 1 ELSE 0 END) AS `구매고객`,
  ROUND(SUM(total_spent), 0) AS `총매출`,
  ROUND(AVG(CASE WHEN order_count > 0 THEN total_spent END), 0) AS `구매자_ARPU`
FROM `your-project-id.ai_bootcamp_sql.customer_mart`;

-- [C21]
CREATE OR REPLACE TABLE `your-project-id.ai_bootcamp_sql.product_mart` AS
WITH sales AS (
  SELECT
    oi.product_id,
    SUM(oi.quantity) AS total_qty,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    COUNT(DISTINCT oi.order_id) AS order_count
  FROM `your-project-id.ai_bootcamp_sql.order_item` AS oi
  JOIN `your-project-id.ai_bootcamp_sql.orders` AS o
    ON oi.order_id = o.order_id
  WHERE
    o.status NOT IN ('Cancelled', 'Returned')
  GROUP BY
    oi.product_id
),
returned AS (
  SELECT
    oi.product_id,
    COUNT(DISTINCT oi.order_id) AS returned_orders
  FROM `your-project-id.ai_bootcamp_sql.order_item` AS oi
  JOIN `your-project-id.ai_bootcamp_sql.orders` AS o
    ON oi.order_id = o.order_id
  WHERE
    o.status IN ('Cancelled', 'Returned')
  GROUP BY
    oi.product_id
)
SELECT
  p.product_id,
  p.product_name,
  p.category,
  p.price,
  COALESCE(s.total_qty, 0) AS total_qty,
  COALESCE(s.revenue, 0) AS revenue,
  COALESCE(s.order_count, 0) AS order_count,
  COALESCE(r.returned_orders, 0) AS returned_orders,
  CASE WHEN COALESCE(s.order_count, 0) = 0 THEN 0 ELSE 1 END AS ever_sold
FROM `your-project-id.ai_bootcamp_sql.products` AS p
LEFT JOIN sales AS s
  ON p.product_id = s.product_id
LEFT JOIN returned AS r
  ON p.product_id = r.product_id;

-- [C22]
SELECT
  category,
  COUNT(*) AS `상품수`,
  SUM(revenue) AS `매출`,
  SUM(returned_orders) AS `취소반품건수`,
  ROUND(
    SUM(returned_orders) * 100.0 / NULLIF(SUM(order_count) + SUM(returned_orders), 0),
    1
  ) AS `취소반품율_pct`
FROM `your-project-id.ai_bootcamp_sql.product_mart`
GROUP BY
  category
ORDER BY
  `매출` DESC;

-- [문제] [C21]에서 만든 product_mart로 카테고리별 판매수량과 매출을 집계합니다. (카테고리·판매수량·매출, 매출이 큰 순)
-- 원천 테이블(order_items·products)을 다시 JOIN하지 않는 것이 이 문제의 핵심입니다.
SELECT
  category,
  SUM(total_qty) AS category_qty,
  SUM(revenue) AS total_revenue
FROM `your-project-id.ai_bootcamp_sql.product_mart`
GROUP BY
  category
ORDER BY
  total_revenue DESC;

-- [C24]
CREATE OR REPLACE VIEW `your-project-id.ai_bootcamp_sql.v_active_customers` AS
SELECT
  customer_id,
  name,
  country,
  grade
FROM `your-project-id.ai_bootcamp_sql.customers`
WHERE
  country IS NOT NULL;

-- [C25]
SELECT
  country,
  COUNT(*) AS `고객수`
FROM `your-project-id.ai_bootcamp_sql.v_active_customers`
GROUP BY
  country
ORDER BY
  `고객수` DESC;

-- [C26] 📒 연습 문제 — 데이터 마트 활용 (1/5)

-- 문제: customer_mart에서 recency_days 구간별(0~30일·31~90일·91일 이상) 고객 수와 평균 구매액을 구합니다. (recency_days가 NULL인 고객은 '주문 없음'으로 묶습니다)

-- 아래에 SQL 쿼리를 작성하세요.
SELECT
  COUNT(*) AS customer,
  ROUND(AVG(total_spent),0) AS AVG_spent,
  CASE WHEN
    recency_days IS NULL THEN 'no_order'
  WHEN recency_days <= 30 THEN '0~30'
  WHEN recency_days <= 90 THEN '31~90'
  ELSE 'more 91'
  END AS period
FROM `your-project-id.ai_bootcamp_sql.customer_mart`
GROUP BY
  period
ORDER BY
  customer DESC;
-- [C27] 📒 연습 문제 — 데이터 마트 활용 (2/5)

-- 문제: product_mart에서 한 번도 팔리지 않은 상품을 찾습니다.

-- 아래에 SQL 쿼리를 작성하세요.
SELECT
  product_name,
  order_count
FROM `your-project-id.ai_bootcamp_sql.product_mart`
WHERE
  order_count = 0;
-- [C28] 📒 연습 문제 — 데이터 마트 활용 (3/5)

-- 문제: daily_sales에서 월별 매출과, 첫 달부터 그 달까지 더한 누적 매출을 함께 구합니다.

-- 아래에 SQL 쿼리를 작성하세요.
WITH monthly AS (
  SELECT
    DATE_TRUNC(order_date, MONTH) AS month,
    SUM(revenue) AS monthly_revenue
  FROM `your-project-id.ai_bootcamp_sql.daily_sales`
  GROUP BY 
    month
)
SELECT
  month,
  monthly_revenue,
  SUM(monthly_revenue) OVER(ORDER BY month) AS total_revenue
FROM monthly
ORDER BY
  month NULLS LAST;
-- [C29] 📒 연습 문제 — 데이터 마트 활용 (4/5)

-- 문제: 카테고리별 매출과, 팔린 상품 1개당 평균 매출을 구합니다. (한 번도 팔리지 않은 상품은 분모에서 제외)

-- 아래에 SQL 쿼리를 작성하세요.
WITH cat AS (
  SELECT
  category,
  SUM(total_qty) AS total_qty,
  SUM(revenue) AS total_revenue
FROM `your-project-id.ai_bootcamp_sql.product_mart`
WHERE
  order_count IS NOT NULL
GROUP BY
  category
ORDER BY
  total_qty DESC
)
SELECT
  category,
  total_qty,
  ROUND(total_revenue/total_qty,0) AS avg_of_category
FROM cat
ORDER BY
  avg_of_category DESC;

-- [4] 카테고리별 매출과 팔린 상품당 평균
SELECT
  category,
  COUNT(*) AS `상품수`,
  SUM(CASE WHEN ever_sold = 1 THEN 1 ELSE 0 END) AS `판매상품수`,
  SUM(revenue) AS `총매출`,
  ROUND(SUM(revenue) / NULLIF(SUM(CASE WHEN ever_sold = 1 THEN 1 ELSE 0 END), 0), 0) AS `판매상품당_평균매출`
FROM `your-project-id.ai_bootcamp_sql.product_mart`
GROUP BY category
ORDER BY `판매상품당_평균매출` DESC;
-- [C30] 📒 연습 문제 — 데이터 마트 활용 (5/5)

-- 문제: 등급(grade)이 비어 있지 않은 고객만 담는 뷰 v_graded_customers를 만들고 조회합니다.

-- 아래에 SQL 쿼리를 작성하세요.
CREATE OR REPLACE VIEW `your-project-id.ai_bootcamp_sql.v_graded_customers` AS
SELECT *
FROM `your-project-id.ai_bootcamp_sql.customers`
WHERE
  grade IS NOT NULL