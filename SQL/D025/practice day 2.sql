-- [C5]
SELECT
  COUNT(*) AS `PV_상품조회수`,
  COUNT(DISTINCT customer_id) AS `UV_고유방문자`
FROM `your-project-id.ai_bootcamp_sql.name_events`
WHERE
  event_type = 'view';

-- [C6]
WITH revenue AS (
  SELECT
    SUM(amount) AS total_revenue
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
    AND amount IS NOT NULL
), active AS (
  SELECT
    COUNT(DISTINCT customer_id) AS active_users
  FROM `your-project-id.ai_bootcamp_sql.name_events`
), paying AS (
  SELECT
    COUNT(DISTINCT customer_id) AS paying_users
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
    AND amount IS NOT NULL
)
SELECT
  total_revenue AS `총매출`,
  active_users AS `활성사용자수`,
  paying_users AS `구매사용자수`,
  ROUND(total_revenue * 1.0 / NULLIF(active_users, 0), 0) AS ARPU,
  ROUND(total_revenue * 1.0 / NULLIF(paying_users, 0), 0) AS ARPPU
FROM revenue
CROSS JOIN active
CROSS JOIN paying;

-- [C8]
SELECT
  page,
  COUNT(*) AS PV,
  COUNT(DISTINCT customer_id) AS UV
FROM `your-project-id.ai_bootcamp_sql.name_events`
GROUP BY
  page
ORDER BY
  PV DESC;

SELECT
  event_type,
  COUNT(DISTINCT customer_id) AS UV
FROM `your-project-id.ai_bootcamp_sql.name_events`
GROUP BY
  event_type
ORDER BY
  UV DESC;  

-- [문제] 리포트의 마지막 장표로, 국가별 구매 고객 수와 ARPPU를 구합니다.
-- 1) orders와 customers를 JOIN 합니다.
-- 2) 국가별로 묶어 구매 고객 수(COUNT(DISTINCT customer_id))와 ARPPU(SUM(amount)/COUNT(DISTINCT customer_id))를 구합니다.
-- 3) 국가 정보가 없는(NULL) 고객과 취소·반품 주문을 제외합니다.
-- 4) ARPPU가 높은 순으로 정렬합니다.


SELECT
  SUM(amount) AS revenue,
  c.country,
  COUNT(DISTINCT o.customer_id) AS UV,
  ROUND(SUM(o.amount) * 1.0 / NULLIF(COUNT(DISTINCT o.customer_id), 0), 0) AS ARPPU
FROM `your-project-id.ai_bootcamp_sql.orders` AS o
JOIN `your-project-id.ai_bootcamp_sql.customers` AS c
ON o.customer_id = c.customer_id
WHERE
  amount IS NOT NULL AND
  status NOT IN ('Cancelled', 'Returned')
  AND country IS NOT NULL
GROUP BY
  country
ORDER BY
  ARPPU;

-- [C11]
WITH funnel AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'visit' THEN customer_id END) AS visit,
    COUNT(DISTINCT CASE WHEN event_type = 'view' THEN customer_id END) AS view,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN customer_id END) AS add_to_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN customer_id END) AS purchase
  FROM `your-project-id.ai_bootcamp_sql.name_events`
)
SELECT
  visit,
  view,
  add_to_cart,
  purchase,
  ROUND(view * 100.0 / NULLIF(visit, 0), 1) AS `방문대비_조회도달률`,
  ROUND(add_to_cart * 100.0 / NULLIF(visit, 0), 1) AS `방문대비_장바구니도달률`,
  ROUND(purchase * 100.0 / NULLIF(visit, 0), 1) AS `방문대비_구매도달률`,
  ROUND(purchase * 100.0 / NULLIF(add_to_cart, 0), 1) AS `장바구니_구매도달률`
FROM funnel;

-- [C14]
WITH funnel AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'visit' THEN customer_id END) AS visit,
    COUNT(DISTINCT CASE WHEN event_type = 'view' THEN customer_id END) AS view,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN customer_id END) AS cart,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN customer_id END) AS purchase
  FROM `your-project-id.ai_bootcamp_sql.name_events`
)
SELECT
  visit - view AS `방문후_이탈`,
  view - cart AS `조회후_이탈`,
  cart - purchase AS `장바구니후_이탈`
FROM funnel;

-- [C15]
WITH first_seen AS (
  SELECT
    customer_id,
    DATE_TRUNC(DATE(MIN(event_at)), MONTH) AS cohort_month
  FROM `your-project-id.ai_bootcamp_sql.name_events`
  GROUP BY
    customer_id
)
SELECT
  cohort_month,
  COUNT(*) AS `코호트_고객수`
FROM first_seen
GROUP BY
  cohort_month
ORDER BY
  cohort_month NULLS LAST;

-- [C16]
WITH first_seen AS (
  SELECT
    customer_id,
    DATE_TRUNC(DATE(MIN(event_at)), MONTH) AS cohort_month
  FROM `your-project-id.ai_bootcamp_sql.name_events`
  GROUP BY
    customer_id
), activity AS (
  SELECT DISTINCT
    customer_id,
    DATE_TRUNC(DATE(event_at), MONTH) AS active_month
  FROM `your-project-id.ai_bootcamp_sql.name_events`
), joined AS (
  SELECT
    f.cohort_month,
    DATE_DIFF(a.active_month, f.cohort_month, MONTH) AS month_offset,
    a.customer_id
  FROM first_seen AS f
  JOIN activity AS a
    ON f.customer_id = a.customer_id
)
SELECT
  cohort_month,
  COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END) AS `경과0개월`,
  COUNT(DISTINCT CASE WHEN month_offset = 1 THEN customer_id END) AS `경과1개월`,
  COUNT(DISTINCT CASE WHEN month_offset = 2 THEN customer_id END) AS `경과2개월`
FROM joined
GROUP BY
  cohort_month
ORDER BY
  cohort_month NULLS LAST;

-- [C17] ⌨️ 백문이 불여일타 (5) — 코호트 1개월 리텐션율(%)

-- 여기에 SQL 쿼리를 작성하세요.

WITH first_seen AS (
  SELECT 
     DATE_TRUNC(DATE(MIN(event_at)), MONTH) AS cohort_month,
    customer_id
  FROM `your-project-id.ai_bootcamp_sql.name_events`
  GROUP BY
    customer_id
), active AS (
  SELECT 
    DATE_TRUNC(DATE(event_at), MONTH) AS active_month,
    customer_id
  FROM `your-project-id.ai_bootcamp_sql.name_events`
), joined AS (
  SELECT
    f.cohort_month,
    DATE_DIFF(a.active_month, f.cohort_month, MONTH) AS month_offset,
    a.customer_id
  FROM first_seen AS f
  JOIN active AS a
    ON f.customer_id = a.customer_id
), m AS (
  SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END) AS m0,
    COUNT(DISTINCT CASE WHEN month_offset = 1 THEN customer_id END) AS m1,
  FROM joined
  GROUP BY
    cohort_month
)
SELECT 
  cohort_month,
  m0,
  m1,
  ROUND(m1 * 100.0 / NULLIF(m0, 0), 1) AS `리텐션율_1개월`
FROM m
ORDER BY
  cohort_month;

-- [C18]
SELECT
  customer_id,
  DATE_DIFF(DATE '2024-03-01', MAX(order_date), DAY) AS `recency_일`,
  COUNT(*) AS `frequency_횟수`,
  SUM(amount) AS `monetary_총액`
FROM `your-project-id.ai_bootcamp_sql.orders`
WHERE
  status NOT IN ('Cancelled', 'Returned')
  AND amount IS NOT NULL
GROUP BY
  customer_id
ORDER BY
  `monetary_총액` DESC;

-- [C19]
WITH rfm AS (
  SELECT
    customer_id,
    DATE_DIFF(DATE '2024-03-01', MAX(order_date), DAY)AS recency,
    COUNT(*) AS frequency,
    SUM(amount) AS monetary
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
    AND amount IS NOT NULL
  GROUP BY
    customer_id
)
SELECT
  customer_id,
  recency,
  frequency,
  monetary,
  CASE
    WHEN monetary >= 300000 AND recency <= 90
    THEN '핵심 고객'
    WHEN recency > 120
    THEN '이탈 위험'
    ELSE '일반 고객'
  END AS `고객등급`
FROM rfm
ORDER BY
  monetary DESC;

WITH rfm AS (
  SELECT
    DATE_DIFF(DATE '2024-03-01', MAX(order_date), DAY) AS recency,
    COUNT(*) AS frequency,
    SUM(amount) AS monetary
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    amount IS NOT NULL
    AND status NOT IN ('Cancelled', 'Returned')
  GROUP BY
    customer_id
), mon_rank AS (
  SELECT
    recency,
    frequency,
    monetary,
    ROW_NUMBER() OVER(ORDER BY monetary DESC) AS cus_rank
  FROM rfm
)
SELECT *
FROM mon_rank
WHERE
  cus_rank <= 3;

-- [C21]
WITH rfm AS (
  SELECT
    customer_id,
    DATE_DIFF(DATE '2024-03-01', MAX(order_date), DAY) AS recency,
    COUNT(*) AS frequency,
    SUM(amount) AS monetary
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
    AND amount IS NOT NULL
  GROUP BY
    customer_id
)
SELECT
  customer_id,
  recency,
  frequency,
  monetary,
  NTILE(4) OVER (ORDER BY recency DESC NULLS FIRST) AS `R점수`,
  NTILE(4) OVER (ORDER BY frequency ASC) AS `F점수`,
  NTILE(4) OVER (ORDER BY monetary ASC) AS `M점수`
FROM rfm
ORDER BY
  monetary DESC;

-- [C22]
SELECT
  COUNT(*) AS `전체주문`,
  SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS `취소`,
  SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS `반품`,
  ROUND(
    SUM(CASE WHEN status IN ('Cancelled', 'Returned') THEN 1 ELSE 0 END) * 100.0
      / NULLIF(COUNT(*), 0),
    1
  ) AS `취소반품율_pct`
FROM `your-project-id.ai_bootcamp_sql.orders`;

-- [C23]
SELECT
  status,
  COUNT(*) AS `건수`,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS `건수비중_pct`,
  SUM(amount) AS `금액`,
  ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER (), 1) AS `금액비중_pct`
FROM `your-project-id.ai_bootcamp_sql.orders`
GROUP BY
  status
ORDER BY
  `건수` DESC;

-- [C24]
WITH cust AS (
  SELECT
    customer_id,
    COUNT(*) AS `구매횟수`,
    SUM(amount) AS `총구매액`,
    MAX(order_date) AS `최근구매일`,
    DATE_DIFF(DATE '2024-03-01', MAX(order_date), DAY) AS `경과일`
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
    AND amount IS NOT NULL
  GROUP BY
    customer_id
)
SELECT
  customer_id,
  `구매횟수`,
  `총구매액`,
  `최근구매일`,
  `경과일`,
  CASE
    WHEN `경과일` > 90 AND `구매횟수` >= 2 THEN '⚠️ 이탈 위험 (단골이었음)'
    WHEN `경과일` > 90 THEN '😐 휴면'
    WHEN `구매횟수` >= 2 THEN '✅ 우량'
    ELSE '🙂 신규·1회'
  END AS `상태`
FROM cust
ORDER BY
  `경과일` DESC;

-- [C25] 📒 연습 문제 — 고객 행동 지표 (1/5)

-- 문제: 전체 이벤트 수(PV)와 고유 사용자 수(UV)를 한 번에 구합니다.

-- 아래에 SQL 쿼리를 작성하세요.
SELECT
  COUNT(*) AS pv,
  COUNT(DISTINCT customer_id) AS uv
FROM `your-project-id.ai_bootcamp_sql.name_events`
WHERE
  event_type = 'view';
-- [C26] 📒 연습 문제 — 고객 행동 지표 (2/5)

-- 문제: event_type별 사용자 수를 구하고 많은 순으로 정렬합니다.

-- 아래에 SQL 쿼리를 작성하세요.
SELECT
  event_type,
  COUNT(DISTINCT customer_id) AS user
FROM `your-project-id.ai_bootcamp_sql.name_events`
GROUP BY
  event_type
ORDER BY
  user DESC;
-- [C27] 📒 연습 문제 — 고객 행동 지표 (3/5)

-- 문제: 정상 주문(취소·반품 제외)만으로 ARPPU(구매 사용자 1인당 평균 매출)를 구합니다.

-- 아래에 SQL 쿼리를 작성하세요.
SELECT
  SUM(amount) AS revenue,
  ROUND(SUM(o.amount) * 1.0 / NULLIF(COUNT(DISTINCT o.customer_id), 0), 0) AS ARPPU
FROM `your-project-id.ai_bootcamp_sql.orders` AS o
JOIN `your-project-id.ai_bootcamp_sql.name_events` AS n
ON o.customer_id = n.customer_id
WHERE
  amount IS NOT NULL
  AND status NOT IN ('Cancelled', 'Returned');

-- [C28] 📒 연습 문제 — 고객 행동 지표 (4/5)

-- 문제: 고객별 마지막 구매일과 그날로부터 2024-03-01까지 경과일을 구합니다.

-- 아래에 SQL 쿼리를 작성하세요.
SELECT
  customer_id,
  MAX(order_date) AS last_order,
  DATE_DIFF(DATE '2024-03-01', MAX(order_date), DAY) AS diff
FROM `your-project-id.ai_bootcamp_sql.orders`
WHERE
  amount IS NOT NULL
  AND status NOT IN ('Cancelled', 'Returned')
GROUP BY
  customer_id
ORDER BY
  diff DESC;
-- [C29] 📒 연습 문제 — 고객 행동 지표 (5/5)

-- 문제: 정상 주문의 고객별 총구매액을 NTILE(3)으로 나누세요. 1은 하, 3은 상으로 해석합니다.

-- 아래에 SQL 쿼리를 작성하세요.
WITH normal AS (
  SELECT
    customer_id,
    SUM(amount) AS total
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    amount IS NOT NULL
    AND status NOT IN ('Cancelled', 'Returned')
  GROUP BY
    customer_id
)
SELECT
  customer_id,
  total,
  NTILE(3) OVER (ORDER BY total ASC NULLS FIRST) AS score,
FROM normal
ORDER BY
  total DESC;

-- 질문 1. 퍼널 전환율을 막대그래프로 그려, 어디서 가장 많이 이탈하는지 한눈에 봅니다.
WITH funnel AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'visit' THEN customer_id END) AS visit,
    COUNT(DISTINCT CASE WHEN event_type = 'view' THEN customer_id END) AS view,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN customer_id END) AS cart,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN customer_id END) AS purchase,
  FROM `your-project-id.ai_bootcamp_sql.name_events`
)
SELECT
  visit - view AS stay,
  view - cart AS action,
  cart - purchase AS buy
FROM funnel;

SELECT
  'visit' AS stage,
  COUNT(DISTINCT CASE WHEN event_type = 'visit' THEN customer_id END) AS users
FROM `your-project-id.ai_bootcamp_sql.name_events`
UNION ALL
SELECT
  'view',
  COUNT(DISTINCT CASE WHEN event_type = 'view' THEN customer_id END)
FROM `your-project-id.ai_bootcamp_sql.name_events`
UNION ALL
SELECT
  'add_to_cart',
  COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN customer_id END)
FROM `your-project-id.ai_bootcamp_sql.name_events`
UNION ALL
SELECT
  'purchase',
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN customer_id END)
FROM `your-project-id.ai_bootcamp_sql.name_events`;

-- [C31] 🧪 종합 실습 — 퍼널·코호트·RFM 종합 리포트 (2/2)
WITH rfm AS (
  SELECT
    customer_id,
    DATE_DIFF(DATE '2024-03-01', MAX(order_date), DAY) AS recency,
    COUNT(*) AS frequency,
    SUM(amount) AS monetary
  FROM `your-project-id.ai_bootcamp_sql.orders`
  WHERE
    amount IS NOT NULL
    AND status NOT IN ('Cancelled', 'Returned')
  GROUP BY
    customer_id
)
SELECT
  CASE WHEN monetary >= 300000 AND recency <=90 THEN 'VIP'
  WHEN recency > 120 THEN 'alart'
  ELSE 'BASIC'
  END AS grade,
  COUNT(*) AS count_cus
FROM rfm
GROUP BY
  1
ORDER BY
  count_cus DESC