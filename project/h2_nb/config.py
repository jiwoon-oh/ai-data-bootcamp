import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "data" / "raw"
PROC = ROOT / "data" / "processed"
FIG = ROOT / "outputs" / "figures"
for p in (RAW, PROC, FIG):
    p.mkdir(parents=True, exist_ok=True)

ENCODING = "cp949"

# ── 파일 탐색 ──────────────────────────────────
# 실제 파일명 패턴: "서울시 상권분석서비스(점포-상권)_2023년.csv"
# 공백/밑줄 표기가 파일마다 섞여 있어 정규화 후 비교한다.
def _normalize(name: str) -> str:
    # 괄호·하이픈까지 지운다. 내려받는 경로에 따라 "(점포-상권)" 이 "점포상권" 으로
    # 저장되는 경우가 있어서 양쪽을 같은 규칙으로 눌러 놓고 비교한다.
    # 지워도 상권/자치구 구분은 유지된다 ("점포상권" vs "점포자치구").
    for ch in " _()-":
        name = name.replace(ch, "")
    return name

# 괄호 안 테이블명으로 정확히 구분 (자치구 버전과 절대 안 겹침)
TABLE_MARKER = {
    "store":    "(점포-상권)",
    "sales":    "(추정매출-상권)",
    "area":     "(영역-상권)",
    "flow":     "(길단위인구-상권)",
    "facility": "(집객시설-상권)",
    "change":   "(상권변화지표-상권)",   # 기준선 전용 — 피처로는 절대 쓰지 않는다
}

# key → (테이블, 연도표기 또는 None=연도표기 없는 최신 파일)
FILE_SPEC = {
    "store_2023":  ("store", "2023년"),
    "store_2024":  ("store", "2024년"),
    "store_2025":  ("store", None),
    "sales_2023":  ("sales", "2023년"),
    "sales_2024":  ("sales", "2024년"),
    "sales_2025":  ("sales", "2025년"),
    "sales_late":  ("sales", None),
    "area":        ("area", None),
    "flow":        ("flow", None),
    "facility":    ("facility", None),
    "change":      ("change", None),
}

_YEAR_TOKENS = ["2023년", "2024년", "2025년", "2026년"]


def _find_file(key: str) -> Path:
    table, year = FILE_SPEC[key]
    marker = _normalize(TABLE_MARKER[table])

    candidates = []
    for f in RAW.glob("*.csv"):
        norm = _normalize(f.name)
        if marker not in norm:
            continue
        if year is None:
            # 연도 표기가 전혀 없는 파일만 (최신/누적 파일)
            if not any(_normalize(y) in norm for y in _YEAR_TOKENS):
                candidates.append(f)
        else:
            if _normalize(year) in norm:
                candidates.append(f)

    if len(candidates) == 0:
        all_files = "\n".join(f"    - {f.name}" for f in sorted(RAW.glob("*.csv"))) or "    (파일 없음)"
        raise FileNotFoundError(
            f"\n[{key}] 테이블마커={TABLE_MARKER[table]!r} 연도={year!r} 조건에 맞는 파일 없음.\n"
            f"  {RAW} 안의 실제 파일:\n{all_files}"
        )
    if len(candidates) > 1:
        names = "\n".join(f"    - {c.name}" for c in candidates)
        raise FileNotFoundError(f"\n[{key}] 후보가 여러 개입니다:\n{names}")
    return candidates[0]

class _FilePaths:
    def __getitem__(self, key):
        return _find_file(key).name

    def keys(self):
        return FILE_SPEC.keys()

    def items(self):
        for k in FILE_SPEC:
            try:
                yield k, self[k]
            except FileNotFoundError:
                yield k, None   # 못 찾은 파일은 None으로 표시


FILES = _FilePaths()

# ── 분석 범위 ──────────────────────────────────
# 적재 대상 13분기. 라벨 y(t) = [순증감(t+1) < 0] 은 t+1 이 이 목록에 있어야 만들어지므로
# 라벨이 붙는 구간은 20231~20254 (12분기), 20261 은 라벨 없음(예측 대상)이다.
QUARTERS = [
    20231, 20232, 20233, 20234,
    20241, 20242, 20243, 20244,
    20251, 20252, 20253, 20254,
    20261
]

# ── 시간 분할 ──────────────────────────────────
# 한 행은 (상권, 업종, 피처분기 t) 이고 라벨은 y(t) = [순감소 in t+1] 이다.
# 피처분기와 타깃분기가 한 칸 어긋나므로, 아래를 단일 진실 공급원으로 쓴다.
#
#   용도   피처분기 t        타깃분기 t+1     라벨
#   학습   20231 ~ 20253    20232 ~ 20254   있음
#   검증   20254            20261           있음
#   예측   20261            20262           없음
#
# ⚠️ 학습에 VALID_Q(20254) 를 넣으면 20261 결과를 미리 보게 되어 누수가 난다.
SCORE_Q = 20261                                    # 예측 대상 (라벨 없음)
VALID_Q = 20254                                    # 검증 (타깃 = SCORE_Q)
TRAIN_QUARTERS = [q for q in QUARTERS if q not in (VALID_Q, SCORE_Q)]
LABELED_QUARTERS = [q for q in QUARTERS if q != SCORE_Q]

# 롤링 오리진 검증 — 학습 종료 분기를 밀며 반복. 각 원소가 그 반복의 검증 피처분기.
ROLLING_VALID = [20243, 20244, 20251, 20252, 20253, 20254]

# 업종은 코드로 지정한다. 서울시가 표기명을 바꿔도 코드는 유지되므로
# 이름 기반 필터보다 안전하다. (2023~2026Q1 전 구간 대응 동일함을 확인)
SVC_CODES = {
    "CS100001": "한식음식점",
    "CS100002": "중식음식점",
    "CS100003": "일식음식점",
    "CS100004": "양식음식점",
    "CS100005": "제과점",
    "CS100006": "패스트푸드점",
    "CS100007": "치킨전문점",
    "CS100008": "분식전문점",
    "CS100009": "호프-간이주점",
    "CS100010": "커피-음료",
}
FOOD = list(SVC_CODES.values())

# ── 점포 테이블 스키마 통일 ─────────────────────
# 2023·2024 파일과 2025~ 파일은 컬럼명만 다른 게 아니라 '점포_수'의 의미가 다르다.
#
#   2023·2024 :  유사_업종_점포_수 = 점포_수     + 프랜차이즈_점포_수   (일치율 1.000)
#   2025~     :  전체_점포_수     = 일반_점포_수 + 프랜차이즈_점포_수   (일치율 1.000)
#
# 즉 구파일의 '점포_수'는 총 점포수가 아니라 비프랜차이즈 점포수다.
# 2025년 개편에서 이 컬럼이 '일반_점포_수'로 개명되고, 총수에 '전체_점포_수'라는
# 이름이 새로 붙었다. 아래 매핑으로 신파일 이름에 맞춘다.
STORE_RENAME_OLD = {
    "점포_수":           "일반_점포_수",
    "유사_업종_점포_수":  "전체_점포_수",
}

# 점포 테이블에서 남길 컬럼
STORE_KEEP = [
    "기준_년분기_코드", "상권_구분_코드_명", "상권_코드", "상권_코드_명",
    "서비스_업종_코드", "서비스_업종_코드_명",
    "전체_점포_수", "일반_점포_수", "프랜차이즈_점포_수",
    "개업_점포_수", "폐업_점포_수",
]
# 매출 테이블에서 남길 컬럼 (원본 55개 중)
SALES_KEEP = [
    "기준_년분기_코드", "상권_코드", "서비스_업종_코드",
    "당월_매출_금액", "당월_매출_건수",
]

TARGET_TYPE = "골목상권"
TREAT_SVC = "한식음식점"
MIN_STORES = 5
COVARIATES = ["log_점포수", "log_유동인구", "log_면적", "log_집객시설"]


# ── 예측 피처 (STEP 8·9 공용) ───────────────────
# 학습(STEP 8)과 예측(STEP 9)이 반드시 같은 코드로 피처를 만들어야 한다.
# 한쪽만 고치면 train/serve skew 가 생기고, 그건 조용히 틀린 예측을 만든다.
#
# ⚠️ 분기 더미는 넣지 않는다. 예측 대상 분기(20261)는 학습에 없는 분기라
#    더미를 만들 수 없고, 만들어도 전부 0 이 되어 의미가 없다.

PRED_NUM = [
    "log_점포수", "log_유동인구", "log_면적", "log_집객시설",
    "외식_비중", "프랜차이즈_비율",
    "개업률", "폐업률", "순증감률", "순감소_현재",
    "log_점포당매출", "매출_결측",
]


def build_features(f):
    """03_panel.pkl / 03_score.pkl 에 예측용 파생 변수를 붙인다."""
    import numpy as np
    f = f.copy()
    denom = f["전체_점포_수"].replace(0, np.nan)
    f["개업률"]   = f["개업_점포_수"] / denom
    f["폐업률"]   = f["폐업_점포_수"] / denom
    f["순증감률"] = (f["개업_점포_수"] - f["폐업_점포_수"]) / denom
    if "순감소_현재" not in f.columns:
        f["순감소_현재"] = ((f["개업_점포_수"] - f["폐업_점포_수"]) < 0).astype(int)
    f["log_점포당매출"] = np.log1p(f["당월_매출_금액"] / denom)
    f["매출_결측"]      = f["당월_매출_금액"].isna().astype(float)
    return f


def design_matrix(f, columns=None):
    """설계행렬. columns 를 주면 그 순서·구성에 맞춰 재정렬한다(없는 더미는 0)."""
    import pandas as pd
    X = pd.concat([
        f[PRED_NUM],
        pd.get_dummies(f["서비스_업종_코드_명"], prefix="svc").astype(float),
        pd.get_dummies(f["자치구"],             prefix="gu").astype(float),
        pd.get_dummies(f["상권유형"],           prefix="tp").astype(float),
    ], axis=1)
    return X if columns is None else X.reindex(columns=columns, fill_value=0.0)


def set_korean_font():
    import matplotlib.pyplot as plt
    from matplotlib import font_manager
    installed = {f.name for f in font_manager.fontManager.ttflist}
    for cand in ["Malgun Gothic", "AppleGothic", "NanumGothic",
                 "Noto Sans CJK KR", "Noto Sans CJK JP"]:
        if cand in installed:
            plt.rcParams["font.family"] = cand
            break
    else:
        print("[경고] 한글 폰트를 찾지 못했습니다.")
    plt.rcParams["axes.unicode_minus"] = False
    plt.rcParams["figure.dpi"] = 110