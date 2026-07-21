# 모두마켓 "분기 성과 요약 보고서"

## 1. 데이터 개요
- 행/열: orders: 1500 * 10 / customers : 200 * 7 / products : 30 * 7
- 초기 구성 주요 컬럼: order_id, customer_id, product_id, quantity, amount, order_date, region, membership, category, price, age, gender, brand, payment_method, channel

## 2. 키 검증
- 검증 : 중복, 미매칭 수행 결과 중복 또는 미매칭 결과 0건
--> 따라서 m:1 병합이 안전하다. 

## 3. 병합
1. validate를 m:1을 주어 병합
2. 세 테이블을 모두 합친 테이블 생성 (1500 * 22)

## 4. 집계
1. 첫달 매출없음으로 잘 도출됨
2. 지역 X 회원등급 매출표
3. 카테고리별 KPI 요약표

## 5. 합계 추가
- transform 메서드로 지역별 각 주문이 차지하는 비중 계산
- 검산도 진행 

## 6. 후속제안
- 최대 매출을 기록한 3월이후 한달만에 최소 매출을 기록하였다. 이에 따른 전략 재수립 필요
- 최대 매출 지역을 기록한 지역(인천)을 중심으로 안정적으로 매출을 늘려가야함
- app에서 card로 결제를 하는 고객수가 가장 많이 보고되었으니 온라인 결제를 더욱 활성화 시켜야함
- 추가로 등급별 구매력을 확인, premium등급이 1인당 소비가 가장 높았음. VIP의 수를 늘리기보다 premium등급 고객을 더 유치시켜야하며 기존의 premium등급 고객을 VIP로 승격시키는것도 고려해볼만 함.
