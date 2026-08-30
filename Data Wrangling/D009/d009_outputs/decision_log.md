# 정제 결정 로그

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
