"""
dirty_cafe_sales.csv 정제 파이프라인
노트북에서 `from pipeline import full_pipeline` 로 불러와 사용합니다.
"""
import pandas as pd
from pathlib import Path

# 파이프라인 실행 중 내려진 정제 결정들을 모아두는 전역 로그
DECISION_LOG = []


def log_decision(step: str, decision: str, reason: str, count=None) -> None:
    """정제 단계에서 내린 결정을 기록. count는 영향받은 행/값의 개수(선택)."""
    entry = {"step": step, "decision": decision, "reason": reason, "count": count}
    DECISION_LOG.append(entry)
    count_str = f" ({count}건)" if count is not None else ""
    print(f"[결정로그] {step}: {decision}{count_str} — {reason}")


def convert_types(df: pd.DataFrame) -> pd.DataFrame:
    """Quantity/Price Per Unit/Total Spent를 숫자형으로, Transaction Date를 datetime으로 변환."""
    num_cols = ["Quantity", "Price Per Unit", "Total Spent"]
    for col in num_cols:
        before_na = df[col].isna().sum()
        df[col] = pd.to_numeric(df[col], errors="coerce")
        new_na = df[col].isna().sum() - before_na
        log_decision(
            step="convert_types",
            decision=f"{col} → 숫자형 변환 (errors='coerce')",
            reason="ERROR/UNKNOWN 등 숫자로 변환 불가능한 문자열은 NaN 처리",
            count=new_na,
        )

    before_na = df["Transaction Date"].isna().sum()
    df["Transaction Date"] = pd.to_datetime(df["Transaction Date"], errors="coerce")
    new_na = df["Transaction Date"].isna().sum() - before_na
    log_decision(
        step="convert_types",
        decision="Transaction Date → datetime 변환 (errors='coerce')",
        reason="날짜 형식이 아닌 문자열은 NaT 처리",
        count=new_na,
    )
    return df


def clean_categorical(df: pd.DataFrame) -> pd.DataFrame:
    """Item / Payment Method / Location의 ERROR, UNKNOWN, 원래 NaN을 전부 'Unknown'으로 통일."""
    cat_cols = ["Item", "Payment Method", "Location"]
    for col in cat_cols:
        affected = (
            df[col].isin(["ERROR", "UNKNOWN"]).sum() + df[col].isna().sum()
        )
        df[col] = df[col].replace({"ERROR": "Unknown", "UNKNOWN": "Unknown"})
        df[col] = df[col].fillna("Unknown")
        log_decision(
            step="clean_categorical",
            decision=f"{col}: ERROR/UNKNOWN/NaN → 'Unknown' 통일",
            reason="표기 혼재를 하나의 결측 카테고리로 정리 (컬럼 유지가 삭제보다 정보 손실 적음)",
            count=int(affected),
        )
    return df


def fill_price_per_unit(df: pd.DataFrame) -> pd.DataFrame:
    """Item별 고정 가격으로 우선 채우고, 남은 결측치는 전체 중앙값으로 채움."""
    price_map = df[df["Item"] != "Unknown"].groupby("Item")["Price Per Unit"].median()
    mask = df["Price Per Unit"].isna() & df["Item"].isin(price_map.index)
    df.loc[mask, "Price Per Unit"] = df.loc[mask, "Item"].map(price_map)
    log_decision(
        step="fill_price_per_unit",
        decision="Item별 고정 가격으로 채움",
        reason="메뉴별 가격이 1개 값으로 고정되어 있음이 확인되어, 추정이 아닌 정확한 복원",
        count=int(mask.sum()),
    )

    remaining = df["Price Per Unit"].isna().sum()
    df["Price Per Unit"] = df["Price Per Unit"].fillna(df["Price Per Unit"].median())
    log_decision(
        step="fill_price_per_unit",
        decision="남은 결측치 → 전체 중앙값으로 채움",
        reason="Item도 Unknown이라 가격을 특정할 근거가 없는 경우",
        count=int(remaining),
    )
    return df


def fill_quantity(df: pd.DataFrame) -> pd.DataFrame:
    """Total Spent / Price Per Unit 역산으로 우선 채우고, 남은 결측치는 중앙값으로 채움."""
    mask_qty_na = df["Quantity"].isna()
    can_backcalc = (
        mask_qty_na
        & df["Total Spent"].notna()
        & df["Price Per Unit"].notna()
        & (df["Price Per Unit"] != 0)
    )
    df.loc[can_backcalc, "Quantity"] = (
        df.loc[can_backcalc, "Total Spent"] / df.loc[can_backcalc, "Price Per Unit"]
    ).round(0)
    log_decision(
        step="fill_quantity",
        decision="Total Spent / Price Per Unit 역산으로 채움",
        reason="세 컬럼의 곱셈 관계를 이용해 추정이 아닌 계산으로 복원",
        count=int(can_backcalc.sum()),
    )

    remaining = df["Quantity"].isna().sum()
    df["Quantity"] = df["Quantity"].fillna(df["Quantity"].median())
    log_decision(
        step="fill_quantity",
        decision="남은 결측치 → 중앙값으로 채움",
        reason="Total Spent도 결측이라 역산이 불가능한 경우",
        count=int(remaining),
    )
    return df


def fill_total_spent(df: pd.DataFrame) -> pd.DataFrame:
    """Quantity * Price Per Unit으로 결측치를 정확히 계산해서 채움."""
    mask_total_na = df["Total Spent"].isna()
    df.loc[mask_total_na, "Total Spent"] = (
        df.loc[mask_total_na, "Quantity"] * df.loc[mask_total_na, "Price Per Unit"]
    )
    log_decision(
        step="fill_total_spent",
        decision="Quantity * Price Per Unit으로 계산해서 채움",
        reason="Quantity/Price Per Unit이 이미 채워져 있어 추정 없이 정확히 계산 가능",
        count=int(mask_total_na.sum()),
    )
    return df


def add_derived_columns(df: pd.DataFrame) -> pd.DataFrame:
    """월(order_month), 요일(order_weekday) 파생 컬럼 추가. Transaction Date 결측은 자연스럽게 NaT로 남음."""
    df["order_month"] = df["Transaction Date"].dt.to_period("M").astype(str)
    df["order_weekday"] = df["Transaction Date"].dt.day_name()
    na_dates = df["Transaction Date"].isna().sum()
    log_decision(
        step="add_derived_columns",
        decision="Transaction Date 결측치는 채우지 않고 NaT 유지",
        reason="날짜는 대체할 논리적 근거가 없어, 채우기보다 분석 시 자동 제외되는 쪽이 왜곡이 적음",
        count=int(na_dates),
    )
    return df


def full_pipeline(input_path: Path, output_dir: Path) -> dict:
    """
    dirty_cafe_sales.csv 인제스트 → 정제 → 파생 → KPI 저장까지 전체 파이프라인.
    반환하는 dict에는 단계별 행 수, 결측치 현황, 저장 경로, 결정 로그가 들어갑니다.
    """
    DECISION_LOG.clear()
    log = {}

    # 1) 인제스트
    df = pd.read_csv(input_path)
    log["ingest_rows"] = len(df)

    # 2) 정제 (각 단계 함수 내부에서 log_decision이 자동 호출됨)
    df = (
        df
        .pipe(convert_types)
        .pipe(clean_categorical)
        .pipe(fill_price_per_unit)
        .pipe(fill_quantity)
        .pipe(fill_total_spent)
        .pipe(add_derived_columns)
    )
    log["missing_after"] = df.isna().sum().to_dict()

    # 3) KPI 집계
    pivot_month = df.pivot_table(
        index="order_month", values="Total Spent", aggfunc=["sum", "count", "mean"]
    ).round(2)
    pivot_month.columns = ["total_revenue", "n_orders", "avg_order_value"]

    pivot_item = df.pivot_table(
        index="Item", values=["Quantity", "Total Spent"], aggfunc="sum"
    ).round(1).rename(columns={"Quantity": "total_qty_sold", "Total Spent": "total_revenue"})

    pivot_weekday = df.pivot_table(
        index="order_weekday", values="Total Spent", aggfunc=["sum", "count", "mean"]
    ).round(2)
    pivot_weekday.columns = ["total_revenue", "n_orders", "avg_order_value"]

    # 4) 저장
    output_dir = Path(output_dir)
    df.to_csv(output_dir / "dirty_cafe_sales_cleaned.csv", index=False)
    pivot_month.to_csv(output_dir / "monthly_revenue.csv")
    pivot_item.to_csv(output_dir / "item_sales.csv")
    pivot_weekday.to_csv(output_dir / "weekday_revenue.csv")

    # 결정 로그도 파일로 저장 (감사/보고 목적)
    log_df = pd.DataFrame(DECISION_LOG)
    log_df.to_csv(output_dir / "decision_log.csv", index=False)

    log["final_rows"] = len(df)
    log["saved_to"] = str(output_dir)
    log["decision_log"] = DECISION_LOG

    return log