SELECT * 
FROM `my-project.ai_bootcamp_sql.amazon_sales` 
LIMIT 10;

SELECT 
  column_name, data_type
FROM `my-project.ai_bootcamp_sql.INFORMATION_SCHEMA.COLUMNS`
WHERE 
  table_name = 'amazon_sales'
ORDER BY 
  ordinal_position;

SELECT
  COUNTIF(product_id IS NULL) AS product_id_null,
  COUNTIF(product_name IS NULL) AS product_name_null,
  COUNTIF(category IS NULL) AS category_null,
  COUNTIF(discounted_price IS NULL) AS discounted_price_null,
  COUNTIF(actual_price IS NULL) AS actual_price_null,
  COUNTIF(discount_percentage IS NULL) AS discount_percentage_null,
  COUNTIF(rating IS NULL) AS rating_null,
  COUNTIF(rating_count IS NULL) AS rating_count_null,
  COUNTIF(about_product IS NULL) AS about_product_null,
  COUNTIF(user_id IS NULL) AS user_id_null,
  COUNTIF(user_name IS NULL) AS user_name_null,
  COUNTIF(review_id IS NULL) AS review_id_null,
  COUNTIF(review_title IS NULL) AS review_title_null,
  COUNTIF(review_content IS NULL) AS review_content_null,
  COUNTIF(img_link IS NULL) AS img_link_null,
  COUNTIF(product_link IS NULL) AS product_link_null
FROM `my-project.ai_bootcamp_sql.amazon_sales`;

-- 타입별로 나눠서 결측치 확인
SELECT
  -- STRING 컬럼: NULL과 빈 문자열 둘 다 체크
  COUNTIF(rating IS NULL OR rating = '') AS rating_missing,
  COUNTIF(product_name IS NULL OR product_name = '') AS product_name_missing,
  COUNTIF(category IS NULL OR category = '') AS category_missing,

  -- 숫자 컬럼(FLOAT64, INT64): NULL만 체크
  COUNTIF(discounted_price IS NULL) AS discounted_price_missing,
  COUNTIF(actual_price IS NULL) AS actual_price_missing,
  COUNTIF(discount_percentage IS NULL) AS discount_percentage_missing,
  COUNTIF(rating_count IS NULL) AS rating_count_missing
FROM `my-project.ai_bootcamp_sql.amazon_sales`;

SELECT *
FROM `my-project.ai_bootcamp_sql.amazon_sales`
WHERE product_id = 'B08L12N5H1';

CREATE OR REPLACE TABLE `my-project.ai_bootcamp_sql.amazon_sales_clean` AS
WITH casted AS (
  SELECT
    * EXCEPT(rating, rating_count),
    SAFE_CAST(rating AS FLOAT64) AS rating, -- 문자열,이상값을 숫자타입으로 변환/아니면 NULL
    rating_count
  FROM `my-project.ai_bootcamp_sql.amazon_sales`
),
medians AS (
  SELECT
    APPROX_QUANTILES(rating, 2)[OFFSET(1)] AS rating_median,    -- 중앙값 계산(데이터를 2등분한 지점)
    APPROX_QUANTILES(rating_count, 2)[OFFSET(1)] AS rating_count_median
  FROM casted
)
SELECT
  c.* EXCEPT(rating, rating_count),
  COALESCE(c.rating, m.rating_median) AS rating,    -- 결측치를 중앙값으로 대체
  COALESCE(c.rating_count, m.rating_count_median) AS rating_count
FROM casted AS c
CROSS JOIN medians AS m;

-- 결측치 잘 처리 되었는지 확인
SELECT *
FROM `my-project.ai_bootcamp_sql.amazon_sales_clean`
WHERE product_id IN ('B08L12N5H1', 'B0B94JPY2N', 'B0BQRJ3C47');

-- 추천 시스템 1
WITH product_agg AS (
  SELECT
    product_id,
    ANY_VALUE(product_name) AS product_name,
    ANY_VALUE(category) AS category,
    MAX(rating) AS rating,
    MAX(rating_count) AS rating_count
  FROM `my-project.ai_bootcamp_sql.amazon_sales_clean`
  GROUP BY product_id
),
threshold AS (
  SELECT APPROX_QUANTILES(rating_count, 2)[OFFSET(1)] AS median_rating_count
  FROM product_agg
)
SELECT
  p.product_id,
  p.product_name,
  p.category,
  p.rating,
  p.rating_count,
  ROUND(p.rating * LOG(p.rating_count + 1), 3) AS trust_score
FROM product_agg p
CROSS JOIN threshold t
WHERE p.rating_count >= t.median_rating_count
ORDER BY trust_score DESC
LIMIT 100;

-- 추천 시스템 2
WITH product_agg AS (
  SELECT
    product_id,
    ANY_VALUE(product_name) AS product_name,
    SPLIT(ANY_VALUE(category), '|')[OFFSET(0)] AS main_category,
    MAX(rating) AS rating,
    MAX(rating_count) AS rating_count
  FROM `my-project.ai_bootcamp_sql.amazon_sales_clean`
  GROUP BY product_id
),
ranked AS (
  SELECT
    product_id,
    product_name,
    main_category,
    rating,
    rating_count,
    ROW_NUMBER() OVER (
      PARTITION BY main_category
      ORDER BY rating_count DESC
    ) AS category_rank
  FROM product_agg
)
SELECT
  main_category,
  category_rank,
  product_id,
  product_name,
  rating,
  rating_count
FROM ranked
WHERE category_rank <= 3
ORDER BY main_category, category_rank;

SELECT product_id, product_name, rating, rating_count, discounted_price, actual_price
FROM `my-project.ai_bootcamp_sql.amazon_sales_clean`
WHERE rating_count = 426973
ORDER BY product_id;

SELECT
  rating_count,
  COUNT(DISTINCT product_id) AS product_variants,
  STRING_AGG(DISTINCT product_name, ' | ' LIMIT 3) AS sample_names
FROM `my-project.ai_bootcamp_sql.amazon_sales_clean`
WHERE rating_count > 0
GROUP BY rating_count
HAVING COUNT(DISTINCT product_id) > 1
ORDER BY product_variants DESC
LIMIT 20;

-- 추천 시스템 3
WITH product_reviewers AS (
  SELECT DISTINCT
    product_id,
    reviewer_id
  FROM `my-project.ai_bootcamp_sql.amazon_sales_clean`,
       UNNEST(SPLIT(user_id, ',')) AS reviewer_id
),
pairs AS (
  SELECT
    a.product_id AS product_a,
    b.product_id AS product_b,
    COUNT(DISTINCT a.reviewer_id) AS shared_reviewers
  FROM product_reviewers AS a
  JOIN product_reviewers AS b
    ON a.reviewer_id = b.reviewer_id
   AND a.product_id != b.product_id
  GROUP BY product_a, product_b
  HAVING shared_reviewers >= 2
),
ranked AS (
  SELECT
    product_a,
    product_b,
    shared_reviewers,
    ROW_NUMBER() OVER (PARTITION BY product_a ORDER BY shared_reviewers DESC) AS rn
  FROM pairs
)
SELECT
  pa.product_name AS base_product,
  pb.product_name AS recommended_product,
  pa.category,
  r.shared_reviewers,
FROM ranked AS r
JOIN `my-project.ai_bootcamp_sql.amazon_sales_clean` AS pa 
ON r.product_a = pa.product_id
JOIN `my-project.ai_bootcamp_sql.amazon_sales_clean` AS pb 
ON r.product_b = pb.product_id
WHERE r.rn <= 3
GROUP BY base_product, category, recommended_product, r.shared_reviewers
ORDER BY base_product, r.shared_reviewers DESC;

-- 추천 시스템 4
WITH product_agg AS (
  SELECT
    product_id,
    ANY_VALUE(product_name) AS product_name,
    MAX(discounted_price) AS discounted_price,
    MAX(actual_price) AS actual_price,
    MAX(discount_percentage) AS stated_discount
  FROM `my-project.ai_bootcamp_sql.amazon_sales_clean`
  GROUP BY product_id
),
calc AS (
  SELECT
    product_id,
    product_name,
    discounted_price,
    actual_price,
    stated_discount,
    ROUND(SAFE_DIVIDE(actual_price - discounted_price, actual_price), 3) AS real_discount,
    ROUND(ABS(stated_discount - SAFE_DIVIDE(actual_price - discounted_price, actual_price)), 3) AS discrepancy
  FROM product_agg
  WHERE actual_price > 0
),
dedup AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY product_name
      ORDER BY product_id
    ) AS name_rn
  FROM calc
  WHERE discrepancy <= 0.02
)
SELECT
  product_id, product_name, discounted_price, actual_price,
  stated_discount, real_discount, discrepancy
FROM dedup
WHERE name_rn = 1
ORDER BY real_discount DESC
LIMIT 100;

-- 추천 시스템 5
WITH product_agg AS (
  SELECT
    product_id,
    ANY_VALUE(product_name) AS product_name,
    MAX(rating) AS rating,
    MAX(rating_count) AS rating_count,
    STRING_AGG(DISTINCT review_content, ' ') AS review_content_all,
    STRING_AGG(DISTINCT review_title, ' ') AS review_title_all
  FROM `my-project.ai_bootcamp_sql.amazon_sales_clean`
  GROUP BY product_id
),
threshold AS (
  SELECT APPROX_QUANTILES(rating_count, 4)[OFFSET(1)] AS q1_rating_count
  FROM product_agg
),
flags AS (
  SELECT
    p.product_id,
    p.product_name,
    p.rating,
    p.rating_count,
    (p.rating >= 4.0 AND p.rating_count <= t.q1_rating_count) AS flag_low_review_count,
    ARRAY_LENGTH(
      REGEXP_EXTRACT_ALL(
        LOWER(CONCAT(IFNULL(p.review_content_all, ''), ' ', IFNULL(p.review_title_all, ''))),
        r'\b(bad|worst|waste|defective|broke|broken|poor|disappointed|return|refund|fake|damaged|useless|cheap quality|stopped working|not working|faulty|leak|leaking|noisy|slow|late delivery|wrong item|misleading|scam|regret|junk|flimsy|died|dead|malfunction)\b'
      )
    ) AS negative_keyword_count
  FROM product_agg p
  CROSS JOIN threshold t
),
scored AS (
  SELECT
    *,
    -- 부정 키워드 개수를 3단계로 나눠서 점수화 (0~3점)
    CASE
      WHEN negative_keyword_count >= 6 THEN 3
      WHEN negative_keyword_count >= 3 THEN 2
      WHEN negative_keyword_count >= 1 THEN 1
      ELSE 0
    END AS keyword_severity,
    CAST(flag_low_review_count AS INT64) AS review_count_severity
  FROM flags
),
final AS (
  SELECT
    *,
    keyword_severity + review_count_severity AS warning_score
  FROM scored
)
SELECT
  product_id,
  product_name,
  rating,
  rating_count,
  negative_keyword_count,
  flag_low_review_count,
  keyword_severity,
  warning_score,
  CASE
    WHEN warning_score >= 4 THEN '🔴 위험'
    WHEN warning_score >= 2 THEN '🟡 주의'
    ELSE '🟢 안전'
  END AS risk_level
FROM final
WHERE warning_score >= 2
ORDER BY warning_score DESC, negative_keyword_count DESC, adjusted_keyword_ratio DESC
LIMIT 100;