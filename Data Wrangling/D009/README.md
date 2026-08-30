# 가상 카페 매출 정제·집계 보고서

## 🚀 1. 데이터 개요
**출처**: (가상) Kaggle - Cafe Sales
**원본 데이터**: 10,000 * 8
**기간**: 2023-01-01 ~ 2023-12-31 (12개월)
**특이점**: 정제 전 데이터는 전부 str, 몇몇 칼럼들의 타입 교체 필요

## 📝 2. 발견한 품질 문제
**결측**: Item(3.33%), Quantity(1.38%), Price per Unit(1.79%), Total spendt(1.73%), Payment Method(25.79%), Location(32.65%), Transaction Date(1.59%)
**중복**: 0건
**이상치 비율**: Total Spent(2.73%)
**표기 혼재**: Item, Payment Method, Location 표기 혼재 및 결측 매우 높음(ERROR, UNKNOWN, NaN 전부 존재)

## 🛡️ 3. 처리 결정과 근거
**1. 중복 행** — 0건, 처리 불필요
**2. 이상치 (Total Spent)** — IQR 기준으로는 2.73%가 이상치로 잡히지만, 
`Quantity × Price Per Unit` 공식으로 검증한 결과 전부 정상적인 계산값임을 확인. 
통계적 극단값일 뿐 실제 오류가 아니므로 **제거하지 않고 유지**.

**3. 결측치 (Total Spent)** - quantity, price per unit과 연관되어 있는 값이라 두 칼럼의 결측처리를 한 후에 공식(`Quantity × Price Per Unit`)에 대입해서 결측을 처리했음

**4. 결측치 (Quantity, Price Per Unit)** - 먼저 분포를 그려 확인, 둘 다 이산분포
- `Quantity`: 특별한 연관 변수가 없어 **중앙값으로 대체**
- `Price Per Unit`: Item별로 가격이 고정되어 있음을 검증 후 확인 → **Item별 중앙값으로 대체**, 
  남은 54건(Item도 결측인 경우)은 **전체 중앙값으로 대체**

**5. 결측치 (Item)** - 기존 결측치들을 모두 Unknown 칼럼으로 대체, 결제는 진행되었는데 메뉴가 찍히지 않았을경우는 굉장히 희박함, 이 경우 정식메뉴가 아닌 계절에 따른 특별 메뉴일수도 있고, 신메뉴일 가능성도 있음. 따라서 결측을 **"Unknown"(미분류) 카테고리로 통일**.

**6. 결측치 (Payment Method, Location)**
- 처음 : 결측비율이 너무 높아 최빈값 대체나 칼럼 삭제 고민
- 결과 : 최빈값 대체를 해버리면 값이 한쪽으로 너무 쏠려 더 큰 노이즈를 일으킬 가능성이 높음
칼럼 삭제의 경우, 결측를 제외하고도 여전치 60%가까이 유효한 값이 남아있기 때문에 **Unknown**으로 통일하여 정보 손실을 막음

## 📄 4. 결정로그 테이블

| 단계 | 결정 내용 | 근거 | 영향 건수 |
|---|---|---|---|
| convert_types | Quantity → 숫자형 변환 (errors='coerce') | ERROR/UNKNOWN 등 숫자로 변환 불가능한 문자열은 NaN 처리 | 341건 |
| convert_types | Price Per Unit → 숫자형 변환 (errors='coerce') | ERROR/UNKNOWN 등 숫자로 변환 불가능한 문자열은 NaN 처리 | 354건 |
| convert_types | Total Spent → 숫자형 변환 (errors='coerce') | ERROR/UNKNOWN 등 숫자로 변환 불가능한 문자열은 NaN 처리 | 329건 |
| convert_types | Transaction Date → datetime 변환 (errors='coerce') | 날짜 형식이 아닌 문자열은 NaT 처리 | 301건 |
| clean_categorical | Item: ERROR/UNKNOWN/NaN → 'Unknown' 통일 | 표기 혼재를 하나의 결측 카테고리로 정리 (컬럼 유지가 삭제보다 정보 손실 적음) | 969건 |
| clean_categorical | Payment Method: ERROR/UNKNOWN/NaN → 'Unknown' 통일 | 표기 혼재를 하나의 결측 카테고리로 정리 (컬럼 유지가 삭제보다 정보 손실 적음) | 3178건 |
| clean_categorical | Location: ERROR/UNKNOWN/NaN → 'Unknown' 통일 | 표기 혼재를 하나의 결측 카테고리로 정리 (컬럼 유지가 삭제보다 정보 손실 적음) | 3961건 |
| fill_price_per_unit | Item별 고정 가격으로 채움 | 메뉴별 가격이 1개 값으로 고정되어 있음이 확인되어, 추정이 아닌 정확한 복원 | 479건 |
| fill_price_per_unit | 남은 결측치 → 전체 중앙값으로 채움 | Item도 Unknown이라 가격을 특정할 근거가 없는 경우 | 54건 |
| fill_quantity | Total Spent / Price Per Unit 역산으로 채움 | 세 컬럼의 곱셈 관계를 이용해 추정이 아닌 계산으로 복원 | 459건 |
| fill_quantity | 남은 결측치 → 중앙값으로 채움 | Total Spent도 결측이라 역산이 불가능한 경우 | 20건 |
| fill_total_spent | Quantity * Price Per Unit으로 계산해서 채움 | Quantity/Price Per Unit이 이미 채워져 있어 추정 없이 정확히 계산 가능 | 502건 |
| add_derived_columns | Transaction Date 결측치는 채우지 않고 NaT 유지 | 날짜는 대체할 논리적 근거가 없어, 채우기보다 분석 시 자동 제외되는 쪽이 왜곡이 적음 | 460건 |


## 📊 5. 주요 KPI 결과
- (월·이용방식 관점) 매출이 가장 컸던 조합: 2023년 6월 In-store (2,343.5)
- (상품 관점) 매출 1위 상품: Salad (17,375.0)
- 평일과 주말의 매출차이가 거의 없는 좋은 위치에 자리잡고 있음

## 🗂️ 6. 한계와 후속 작업
- Location(이용방식) 컬럼은 결측/표기혼재를 "Unknown"으로 통일한 결과, 전체의 약 39.6%가 Unknown으로 남아있어 월별·장소별 KPI가 실제보다 다소 축소되어 있을 가능성이 있음 → 원본 데이터의 Location 수집 로직 점검 필요
- Item "Unknown"(약 9.7%)이 매출 6위(8,537.5)를 차지할 정도로 비중이 커서, 실제로는 신메뉴/시즌 메뉴인지 별도 확인이 필요함
- Payment Method도 결측 비율이 높아(약 31.8%), 결제수단별 매출 분석의 신뢰도가 제한적임