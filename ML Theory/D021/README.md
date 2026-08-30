## 모델 카드 v5 — 구매 전환 예측

- 데이터: UCI Online Shoppers (12,330세션, 원본 예측 피처 17개 검토)
- 검증 방식: StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
- 주 지표: AP(`average_precision`) · F1 (정확도는 참고)
- **전처리: ColumnTransformer — 수치 { 10 }개 passthrough / 범주 { 7 }개 One-Hot(min_frequency={ 20 })**
  - **변환 후 피처 { 66 }개**
- **파생변수(가설 → 결과)**
  - 가설 A `has_page_value`: { 가설 } → Δf1 { 0.0701 } · ΔAP { 0.0127 } → **{ 채택 }**
  - 가설 B `total_pages`: { 가설 } → Δf1 { 0.0033 } · ΔAP { 0.0027 } → **{ 보류 }**
- **누수 점검: { 만들어 본 누수와 부풀림 폭: +0.0426 } → 교차 적합 버전은 기준 대비 { -0.0231 }**
  - **학습되는 전처리의 `fit`이 `Pipeline` 안에서 일어나는가: { 예 }**
- **튜닝: GridSearchCV(scoring="average_precision"), 격자 { } → best { }**
- 내부 CV 추정: AP { 0.7545 } ± { 0.0120 } / F1 { 0.6543 } ± { }
- 최종 평가: { 별도 테스트셋 또는 Nested CV 결과 }
- **산출물: purchase_pipeline.joblib (Pipeline 통째, compress=3) · experiment_log_v5.csv**
- 한계 & 다음 단계: { 예 — `PageValues`의 예측 시점 가용성 확인, 외부 검증, 피처 해석 }
- AI 사용 내역: 전체적인 코드 흐름, gridsearchCV의 작동방식