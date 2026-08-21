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
    return name.replace(" ", "").replace("_", "")

# 괄호 안 테이블명으로 정확히 구분 (자치구 버전과 절대 안 겹침)
TABLE_MARKER = {
    "store":    "(점포-상권)",
    "sales":    "(추정매출-상권)",
    "area":     "(영역-상권)",
    "flow":     "(길단위인구-상권)",
    "facility": "(집객시설-상권)",
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

# ── 분석 상수 ──────────────────────────────────
FOOD = [
    "한식음식점", "중식음식점", "일식음식점", "양식음식점", "분식전문점",
    "패스트푸드점", "치킨전문점", "제과점", "커피-음료", "호프-간이주점",
]
TARGET_TYPE = "골목상권"
TREAT_SVC = "한식음식점"
MIN_STORES = 5
COVARIATES = ["log_점포수", "log_유동인구", "log_면적", "log_집객시설"]


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