# 🏙️ Seoul Neighborhood Commercial District Restaurant Decline Analysis

🔗 **[View the interactive case study →](https://jiwoon-oh.github.io/portfolio/projects/seoul-closure-risk/)**

---

## ⚡ Executive Summary

> **Seoul allocates small-business support using a metric that ranks district size, not business risk.**

**The headline that started it.** Korean restaurants top Seoul's net-decline ranking every quarter — **25.3%** against **22.9%** for the other nine food categories.

**Two tests dismantled it.**

| Test | Result | What it means |
| ---- | ------ | ------------- |
| Permutation test · 1,000 shuffles | **p = 0.344** | **88%** of the +2.4 pp gap is the act of picking the highest of ten |
| Propensity matching · 7,042 pairs | **ATT = −5.77 pp** | Once cells are comparable, the sign **reverses** |
| Woolf homogeneity test | **p < 0.0001** | …but the average is a blend, not a summary — see below |

**The reversal is not uniform.** Split by store count, the effect runs from **−13.0 pp** in the smallest cells to **+2.4 pp** in the largest, changing sign. −5.77 pp should never be quoted alone.

### Key findings

- **Store count alone reproduces the entire reversal** (−5.74 pp of −5.79 pp). Foot traffic contributes nothing (p = .078) — it raises openings **and** closures alike, so it cancels in the subtraction.
- **The indicator decomposes exactly:** `P(decline) = P(event) × P(decline | event)`. The store-count coefficient is **+1.483** at stage 1 and **+0.046** at stage 2 — the metric measures *how often something happens*, not *how badly it goes*.
- **Seoul's own contraction indicator scores Lift 0.937** — worse than random at predicting the next quarter.
- **The model earns its place at the operating point, not on the leaderboard.** Top-50 precision **0.760** vs **0.380** for a store-count rule, with only **6%** list overlap — 47 of 50 flagged cells are districts the current process never reaches.
- **Two results were measured and thrown out.** A rank correlation of 0.515 exceeded the target's own reliability ceiling of 0.444, so it was removed from the reported results.

### Recommendation

> **Stop ranking industries by net decline.** Publish closures per store beside it — the two rank categories at **−0.406** correlation — and allocate at the **cell level**: one micro commercial district × one category.

### At a glance

| | |
| --- | --- |
| **Data** | 67,475 cells · 13 quarters (2023 Q1 – 2026 Q1) · 10 food categories |
| **Methods** | Propensity score matching · doubly robust estimation · permutation testing · negative binomial regression · gradient boosting |
| **Reported performance** | Rolling AUC **0.666 ± 0.010** over 6 quarters |
| **Output** | **2,737** scored cells for 2026 Q2 |
| **Scope** | Neighborhood commercial districts, cells with 5+ stores. Results are adjusted associations, not proven causal effects. |

---

## 📌 Overview

This project investigates whether Seoul's current **net business decline indicator** accurately identifies high-risk restaurant sectors in neighborhood commercial districts.

The Seoul commercial district analysis system commonly defines a business category as being in decline when:

> **Business openings < Business closures**

However, a key question remains:

> **Does a high net-decline rate actually indicate business risk, or is it simply associated with the size of the commercial district?**

Using 13 quarters of commercial district data from Seoul, this project examines the relationship between restaurant categories, commercial scale, foot traffic, and future business decline.

The analysis combines:

* Exploratory Data Analysis
* Non-parametric statistical testing
* Permutation testing
* Propensity Score Matching
* Doubly Robust Estimation
* Counterfactual analysis
* Sensitivity analysis
* Two-stage decomposition of the outcome definition
* Predictive modeling
* Split-half reliability testing of the target itself

---

# 🎯 Business Problem

Local governments and small-business support organizations need to identify commercial districts and business categories that may require intervention.

A common approach is to prioritize industries with high net-decline rates.

However, this approach may contain a structural bias.

For example:

> Korean restaurants frequently ranked among the highest categories for net business decline.

But Korean restaurants also tend to have significantly more stores per commercial district than other restaurant categories — a median of **16 stores per cell** against **6–10** for every other category.

This raises an important question:

> **Are Korean restaurants actually more vulnerable, or does their large number of stores simply make net decline more likely?**

---

# 🔍 Research Questions

### Main Question

> **Does controlling for commercial scale and foot traffic change the apparent difference in net-decline risk between Korean restaurants and other restaurant categories?**

### Secondary Question

> **Which commercial characteristics are most strongly associated with future net business decline?**

---

# 📊 Dataset

### Data Source

## 📊 Dataset

### Data Source

This project uses publicly available data from the **Seoul Open Data Plaza** and the **Seoul Metropolitan Government Commercial District Analysis Service**.

**Source:** Seoul Open Data Plaza  
https://data.seoul.go.kr/

**Period:** 2023 Q1 – 2026 Q1

The analysis integrates the following datasets:

- Stores by Commercial District
- Street-Level Population by Commercial District
- Commercial District Boundaries
- Attraction Facilities by Commercial District
- Estimated Sales by Commercial District
- Commercial District Change Indicators

The analysis uses **13 quarters of Seoul commercial district data from 2023 Q1 to 2026 Q1**.

Data sources include five major commercial district datasets:

* Store and business information
* Estimated sales
* Commercial district characteristics
* Street-level population and foot traffic
* Attraction facilities

The analysis focuses on:

> **10 restaurant and food-service categories**

### A note on two similar terms

Two different geographic units appear throughout, and English blurs them:

| Term used here | Korean | What it is | Count |
| -------------- | ------ | ---------- | ----- |
| **Commercial district** | 상권 | A micro trade area — a few blocks | ~2,800 |
| **City district** | 자치구 | An administrative borough of Seoul | 25 |
| **Cell** | 상권 × 업종 × 분기 | **The unit of analysis** — one commercial district × one restaurant category × one quarter | 67,475 |

Wherever this document says *cell*, it means the micro-level commercial district × category unit — **not** the city district.

### Final Analytical Dataset

| Stage                                               | Observations |
| --------------------------------------------------- | -----------: |
| Original store dataset                              |      995,377 |
| 10 restaurant categories across 13 quarters         |      160,352 |
| Observations with future labels available           |      147,138 |
| Commercial district × industry cells with 5+ stores |       67,495 |
| Final analytical sample                             |   **67,475** |

The final positive rate for net business decline was:

> **25.5%**

---

# 🧹 Data Preparation and Validation

Several preprocessing decisions were made to improve the reliability of the analysis.

## Commercial Districts with Fewer Than 5 Stores Were Excluded

**The primary reason is the instability of the label, not the availability of sales data.**

In a district with only three stores, the closure of one business immediately represents a 33% net decline. That figure reflects sample size rather than commercial deterioration — and leaving those rows in teaches any model to identify *small* cells rather than *risky* ones.

A second, weaker signal points the same way. Sales missingness falls sharply with store count:

| Store count in cell | Sales missing |
| ------------------- | ------------: |
| All cells           |         45.4% |
| 5 or more stores    |          7.1% |
| 2 or fewer stores   |      **100%** |

A missingness rate of exactly 100% indicates a rule rather than attrition. **The rule itself could not be confirmed.** No published suppression threshold was located, and a competing explanation exists — the smallest cells may simply have no card-sales record to begin with. This is reported here as an observation, not as a cause.

### Two details worth stating explicitly

**The filter is applied to store count — a covariate — and not to missingness.** The label is observed for every cell regardless of whether sales are present, so this restricts the population rather than selecting on the outcome. Filtering on missingness itself would have introduced exactly the bias the rest of the design works to remove.

**The cost is large.** The filter removes 147,138 → 67,495 rows, or **54.1% of the data**. Every conclusion in this project therefore carries the scope note:

> **Applies to neighborhood commercial districts with five or more stores per cell.**

---

## Historical Store Count Definitions Were Corrected

A major schema issue was identified across different years.

In older datasets, the `store_count` field represented:

> **Non-franchise stores**

rather than total stores.

After a schema revision, total store count was represented differently.

The historical mapping was validated using identity checks between franchise and non-franchise store counts (match rate **1.0000**).

Correcting this issue increased the analytical sample from:

> **55,795 → 67,475 observations (+20.9%)**

The increase was highly uneven across categories — **chicken +390%** against **Korean +2%**. Without this correction, industries with high franchise penetration would have been systematically undercounted in precisely the comparison this project is about.

---

# 🎯 Target Variable

The analysis predicts whether a commercial district × restaurant category would experience **net business decline in the following quarter**.

Conceptually:

> **Net Decline = Openings < Closures**

The dataset was structured as a panel:

> **Commercial District × Industry × Quarter**

Future labels were created only when the following quarter existed.

Temporal leakage was explicitly prevented by separating:

* Training periods
* Validation periods
* Future prediction periods

### An important property of this definition

> **43.7% of cells recorded a zero because nothing happened at all — not because nothing bad happened.**

A cell with five stores has a **71%** chance that neither an opening nor a closure occurs in the following quarter. With nothing on either side of the comparison, that cell is filed as safe. A cell with 51 or more stores has a **98%** chance that something happens.

This property is quantified in a later section and turns out to explain a large part of the headline result.

---

# 🧪 Statistical Method Selection

Before comparing groups, the distribution of net-decline rates was examined.

Running a normality test on a 0/1 label is meaningless, so each commercial district × category cell was collapsed to its **net-decline rate across 12 quarters** — a continuous value on [0,1]. Cells observed fewer than six quarters were dropped as unstable (5,687 cells retained, 735 dropped, median 0.250, skew +0.592).

### Assumption Checks

| Comparison axis    | Groups | Normality rejected | Levene p | Equal variance |
| ------------------ | -----: | -----------------: | -------: | -------------- |
| Commercial district type |  4 |              4 / 4 |   < .0001 | Violated |
| Restaurant category      | 10 |            10 / 10 |   < .0001 | Violated |
| City district (gu)       | 25 |            25 / 25 |    .0727 | Met |

Normality failed in **all 39 groups**. The distribution piles up near zero — 7.1% of cells never declined once in twelve quarters — and trails right.

Therefore:

> **Kruskal-Wallis was selected as the primary group comparison method.**

Levene's test was run on medians rather than means, since a mean-centred Levene is itself distorted under skew.

The results of this test appear in the **Location Sensitivity** section below.

---

# 🔍 Key Finding 1 — The Apparent Industry Difference Was Mostly a Selection Effect

At first glance:

* Korean restaurants: **25.3% net-decline rate**
* Other restaurant categories: **22.9%**

This suggested a difference of:

> **+2.4 percentage points**

However, selecting the highest-ranked of ten categories can itself create an apparent gap. With ten finite samples, one of them is always lucky.

To evaluate this, a **permutation test** was performed. Industry labels were randomly shuffled 1,000 times while preserving group sizes.

### Result

The permutation test operates on a different scale from the headline gap, so both are reported:

| Quantity | Value | Scale |
| -------- | ----: | ----- |
| Observed — top category minus overall mean | **+1.70 pp** | top vs grand mean |
| Null — what "best of ten" produces by itself | **+1.49 pp** | top vs grand mean |
| Permutation p-value | **0.344** | — |
| Selection effect, rescaled to "vs the other nine" | **+2.10 pp** | top vs rest |
| **Residual real difference** | **+0.29 pp** | top vs rest |

The conversion between the two scales is `selection effect ÷ (1 − treated share)`, which puts the null on the same footing as the observed **+2.4 pp** gap.

Approximately:

> **88% of the observed +2.4 pp difference (2.10 ÷ 2.38) is explained by the act of selecting the maximum.**

### Conclusion

> **The claim that Korean restaurants were uniquely at higher risk was not statistically supported.**

This strengthens rather than weakens what follows. There was never a phenomenon called "Korean restaurants are risky" to explain — the only real signal is what appears *after* conditioning, and the matched estimate is immune to this bias because it is computed inside matched pairs.

---

# 🔄 Simpson's Paradox

The analysis revealed a pattern consistent with **Simpson's Paradox**.

In the aggregated data, Korean restaurants appeared to have a higher net-decline rate. After stratifying cells by store count, the sign reverses in every band:

| Store count band | Korean | Other 9 categories (mean) | Difference | Cells |
| ---------------- | -----: | ------------------------: | ---------: | ----: |
| 5–7   | 12.68% | 17.14% | **−4.46 pp** | 13,778 |
| 8–10  | 16.26% | 23.11% | **−6.85 pp** |  6,858 |
| 11–15 | 22.31% | 30.44% | **−8.13 pp** |  5,481 |
| 16–25 | 29.86% | 36.71% | **−6.85 pp** |  4,641 |
| 26+   | 35.75% | 40.11% | **−4.36 pp** |  3,889 |

The apparent aggregate difference was largely explained by the fact that:

* Korean restaurants were concentrated in larger commercial cells
* Larger commercial cells experienced more business openings and closures
* Higher business activity mechanically increased the probability of net decline

This suggested that:

> **Commercial scale was a major confounding factor.**

> ⚠️ **This table and the stratified ATT table further below are different objects and must not be read as one series.** This one compares Korean cells against the *average of the other nine categories* inside raw store-count bands. The later one compares Korean cells against their *individually matched control cells*, split into quintiles of matched pairs. The two answer different questions and — as shown below — do not give the same answer in the largest band.

---

# ⚖️ Causal Analysis — Propensity Score Matching

To compare similar commercial environments, Propensity Score Matching (PSM) was used.

### Treatment Group

> Korean restaurant commercial cells

### Control Group

> Comparable commercial cells from other restaurant categories

Each Korean cell was paired 1:1 with the nearest non-Korean cell on the propensity-score logit, exact-matched on quarter, without replacement and inside a caliper. Quarter has to be fixed because overall risk moves between quarters; sampling without replacement prevents one lucky control cell from being reused into the result.

The matching process controlled for:

* Store count
* Foot traffic
* Commercial area
* Attraction facilities

### Balance Check

| Covariate | SMD before | SMD after | Reduction |
| --------- | ---------: | --------: | --------: |
| log store count | 0.999 | **0.037** | 96.3% |
| log foot traffic | −0.447 | 0.022 | 95.2% |
| log area | −0.473 | 0.031 | 93.4% |
| log attraction facilities | −0.461 | 0.032 | 93.2% |

All matching covariates achieved:

> **|SMD| < 0.1**

This indicated acceptable covariate balance, and only then was the outcome examined.

### Why matching rather than regression adjustment

**The overlap problem is the point of the exercise.** The two groups differed by a full standard deviation in store count. A regression would report a coefficient for that comparison by extrapolating a fitted surface into the region where no comparable control cell exists. Matching cannot do that — a treated cell with no partner inside the caliper is dropped and counted, which turns the failure into a visible number (29.3%) rather than a silent extrapolation.

**Balance is checkable before the outcome is read.** The table above is computed without touching the label, so the design can be judged on its own terms.

Regression was not discarded — it runs as the **doubly robust** estimator alongside the match, which is why both numbers are reported.

---

# 📊 Average Treatment Effect on the Treated (ATT)

After matching:

> **ATT = −5.77 percentage points**

95% Confidence Interval:

> **−7.23 to −4.23 percentage points**

McNemar Test:

> **p = 5.0 × 10⁻¹⁵**  ·  **7,042 matched pairs**

The interval comes from a **city-district-level cluster bootstrap** — cells inside one district are not independent, and resampling cells individually would produce a falsely narrow interval.

### Interpretation

When commercial cells with similar characteristics were compared:

> **Korean restaurant cells experienced approximately 5.77 fewer net-decline events per 100 comparable cells than other restaurant categories.**

This was the opposite direction of the original unadjusted comparison.

### What this number is an estimate of

This is an **ATT** — the average effect *on the treated* — not an ATE. The question being answered is "for the Korean-restaurant cells that exist, what would their net-decline rate have been had they been another category," not "what would happen if every cell switched category." That is the correct estimand here because the decision it informs concerns the cells currently topping the ranking.

It is also an ATT **restricted to the region of common support**: 70.7% of treated cells were matched, and the unmatched 29.3% — mostly very large Korean cells — are excluded rather than extrapolated over.

---

# 🔄 Robustness Checks

The result was evaluated using multiple analytical approaches.

| Method                    |       Estimated Effect |
| ------------------------- | ---------------------: |
| Unadjusted comparison     | +2.4 percentage points |
| Propensity Score Matching |           **−5.77 pp** |
| Doubly Robust Estimation  |           **−6.15 pp** |
| Counterfactual — all four covariates fixed | **−5.79 pp** |
| Counterfactual — **store count only** fixed | **−5.74 pp** |
| Alternative Outcome Label |           **−8.73 pp** |

The fifth row is the informative one: **fixing store count alone reproduces the entire reversal.** Adding the other three covariates changes the estimate by 0.05 pp.

Sensitivity analysis across different matching calipers, sampling settings and random seeds produced effects consistently within:

> **−6.0 to −4.0 percentage points**

### Conclusion

The direction of the adjusted effect remained consistent across multiple analytical approaches.

---

# ⚠️ Treatment Effects Were Not Uniform

The overall ATT should not be interpreted as a single universal effect.

After stratifying the 7,042 matched pairs into store-count quintiles:

| Band | Pairs | Mean stores | Korean | Control | Stratum ATT | Odds ratio |
| ---- | ----: | ----------: | -----: | ------: | ----------: | ---------: |
| Q1 | 1,409 |  5.9 | 12.5% | 25.5% | **−13.0 pp** | 0.42 |
| Q2 | 1,408 |  8.7 | 16.4% | 26.8% | **−10.4 pp** | 0.54 |
| Q3 | 1,408 | 12.8 | 22.1% | 28.7% |  **−6.6 pp** | 0.70 |
| Q4 | 1,408 | 19.6 | 27.9% | 29.2% |  **−1.3 pp** | 0.94 |
| Q5 | 1,409 | 38.5 | 36.5% | 34.1% |  **+2.4 pp** | 1.11 |

The heterogeneity test showed:

> **Woolf Test: Q = 78.686, df = 4, p < 0.0001**  ·  pooled OR 0.741

Woolf's test asks whether the stratum odds ratios can be treated as one number. This is a test where a *large* p-value is the desirable outcome, and that is not what came back.

### Key Insight

> **The relationship between restaurant category and net business decline depends strongly on commercial scale.**

A more accurate interpretation is:

> **Korean restaurant cells tend to be relatively safer in smaller commercial areas, but this advantage disappears past roughly twenty stores and inverts near forty.**

## Why the sign flips

The obvious answer — "Korean cells are bigger" — cannot be it. Matching already fixed store count, so 38.5 stores is the mean on *both* sides of every Q5 pair. Something else must change across the bands.

**First candidate — the control mix shifts with size.** Checked, and only weakly supported. Cafés dominate the control pool in every band (46.0% at Q1 → 54.9% at Q5) and pubs stay flat near 21%. What does move is the small-format group — snack bars, chicken, fast food, bakeries — from 22.7% of controls at Q1 to 6.8% at Q5. A real shift, but not a change of comparison.

**Second candidate — it lines up almost exactly.** Korean restaurants run a median of **16 stores per cell** against 6–10 for every other category. Matching on the *absolute* count therefore pairs a cell that is small *for a Korean cell* with one that is large *for its own category* — and that mismatch inverts as the bands climb:

| Band | Mean stores | Korean cell's percentile *among Korean cells* | Control's percentile *within its own category* | Difference | Stratum ATT |
| ---- | ----------: | ----: | ----: | -----: | ----------: |
| Q1 |  5.9 | 0.08 | 0.55 | −0.47 | −13.0 pp |
| Q2 |  8.7 | 0.23 | 0.61 | −0.38 | −10.4 pp |
| Q3 | 12.8 | 0.40 | 0.66 | −0.26 |  −6.6 pp |
| Q4 | 19.6 | 0.59 | 0.71 | −0.12 |  −1.3 pp |
| Q5 | 38.5 | 0.83 | 0.76 | **+0.07** | **+2.4 pp** |

The percentile difference crosses zero in the same band the effect does, and the two columns track each other at **r = 0.994** across the five bands. The reading that follows is uncomfortable and worth stating plainly: part of −5.77 pp is not "Korean is safer" but **"a cell far below its own category's norm is safer than one sitting at or above its own"** — and matching on absolute counts does not remove that.

> ⚠️ **This is a hypothesis, not a settled result.** Five strata give five points, so r = 0.994 is descriptive rather than a test. Confirming it means re-matching on within-category percentile instead of absolute count and checking whether the flip survives.

---

# 🔍 Key Finding 2 — Store Count Was the Strongest Predictor

The secondary analysis examined which commercial characteristics were associated with future net business decline. Average marginal effects on 67,475 cells with district-clustered errors:

| Variable | AME | p-value | Verdict |
| -------- | --: | ------: | ------- |
| **log store count** | **+14.28 pp** | 2.8e−164 | Dominant |
| food-category share | −13.84 pp | 5.2e−06 | Significant |
| log area | −1.39 pp | .032 | Marginal |
| log attraction facilities | −1.24 pp | .0097 | Marginal |
| log foot traffic | +0.72 pp | **.078** | **Not significant** |

### Key Insight

> **Commercial scale explained substantially more of the observed risk than restaurant category or foot traffic.**

## Why foot traffic is null — two separate reasons

Foot traffic being null is the interesting part, and the mechanism was traced twice.

**Reason 1 — it cancels in the subtraction.** Openings and closures were modelled separately with negative-binomial regressions using a log-store-count offset:

> openings **+0.098** (p = 7.0e−5) · closures **+0.053** (p = .0095)

Foot traffic raises both. Roughly 70% of the effect disappears in the difference. Busy districts are not dangerous — they are **high-turnover**, and net decline cannot see the distinction.

**Reason 2 — it is a proxy for location.** With cell fixed effects, foot traffic loses significance entirely:

> openings **p = .865** · closures **p = .963**

Within the same cell over time, foot traffic moves and opening/closure rates do not. The cross-sectional association was produced by time-invariant location traits — rent, access, district age — not by foot traffic itself.

**Why not ordinary regression here.** The outcome is a count floored at zero and strongly skewed; least squares would predict negative openings and assume constant variance. And the quantity of interest is a *rate* (events per store), so store count belongs in the model as an **offset** with its coefficient fixed at 1. Poisson does not fit either — variance ÷ mean is **1.81** for openings and **1.65** for closures against the 1.0 Poisson assumes — so the negative binomial, which carries its own dispersion parameter, is the honest choice.

---

# 🔎 Why the Current Net-Decline Indicator Can Be Misleading

The analysis suggests that net decline is partly determined by the arithmetic structure of the metric itself. This is not an interpretation — it is an exact identity that was verified on the data.

Net decline is a strict subset of "an event occurred": a cell with no openings and no closures cannot post a negative net. So the probability decomposes exactly:

> **P(decline) = P(event) × P(decline | event)**
> 0.5153 × 0.4582 = 0.2361  ·  observed P(decline) = **0.2361**
> P(decline | no event) = **0.0000** across 15,451 cells — zero positives, not a rounding artifact

Estimating the store-count coefficient at each stage separately shows where the size dependence lives:

| Stage | log store-count coefficient | p-value |
| ----- | --------------------------: | ------: |
| Stage 1 · P(event) | **+1.483** | < .0001 |
| Stage 2 · P(decline \| event) | **+0.046** | .114 |

**The size dependence is almost entirely trapped in stage 1.** Once an event has occurred, store count no longer predicts the *direction* of the net change. The honest statement is therefore not "bigger cells are safer" but:

> **"Conditional on comparable circumstances, bigger cells are not riskier — the indicator is measuring how often something happens, not how badly it goes."**

Therefore, ranking industries solely by net-decline rate systematically prioritizes:

> **Large industries rather than genuinely high-risk industries.**

---

# 🧭 Location Sensitivity — Not Every Category Depends on Where It Is

Applying the Kruskal-Wallis test selected earlier, each category was fixed and commercial district types compared within it. Ten repeats means Bonferroni correction (α = .0050), and with thousands of cells p-values go significant on trivial differences — so the ranking is by effect size, not by p.

| Category | n | ε² | Effect |
| -------- | --: | ---: | ------ |
| **Pub / bar** | 709 | **0.1202** | Medium |
| Cafe / beverage | 1,006 | 0.0652 | Medium |
| Korean | 1,306 | 0.0607 | Medium |
| Western | 352 | 0.0483 | Small |
| Snack bar | 637 | 0.0481 | Small |
| Japanese | 307 | 0.0448 | Small |
| Bakery | 347 | 0.0318 | Small |
| Chinese | 302 | 0.0300 | Small |
| Fast food | 322 | 0.0161 | Not significant |
| **Chicken** | 341 | **0.0002** | **None** |

Effect sizes read as 0.01 small, 0.06 medium, 0.14 large. 8 of 10 were significant.

The spread between pub/bar and chicken is **600×**.

> **"All restaurant categories are sensitive to location" is not a true statement.**

Chicken shops carry the same risk wherever they sit, which means **district-level intervention cannot move them**. A plausible read is high delivery share reducing location dependence, though nothing in this dataset measures delivery.

---

# 🤖 Predictive Modeling

**Two separate models run in this project**, and their numbers are easy to confuse:

| Model | Target | Family | Reported metric |
| ----- | ------ | ------ | --------------- |
| **Binary classifier** | Does this cell post a net decline next quarter? | Gradient boosting | Rolling AUC, PR-AUC, Brier |
| **Count model** | How many closures does this cell record next quarter? | Negative binomial with log-store-count offset | AUC (≥1 closure), Poisson deviance |

The 2026 Q2 forecast is built from the count model.

## Binary classifier — candidate comparison

Six candidates were evaluated on the held-out quarter:

| Candidate | AUC | PR-AUC | Brier |
| --------- | --: | -----: | ----: |
| Random — the positive rate itself | 0.500 | 0.260 | 0.192 |
| Previous-quarter state | 0.531 | 0.274 | 0.218 |
| Category mean (best rule baseline) | 0.554 | 0.291 | 0.191 |
| Logistic regression | **0.670** | 0.407 | 0.180 |
| **HistGradientBoosting** | 0.668 | **0.417** | **0.179** |
| Random forest | 0.662 | 0.412 | 0.180 |

Selection was on **PR-AUC**, not accuracy — always predicting "safe" scores 74.0% — and not F1, which fixes an operating point and so lets the threshold decide the conclusion. PR-AUC has no fixed scale: its random baseline is the positive rate, **0.260**, so 0.417 reads as **1.61× baseline** and never as "42% of something."

**The deciding reason was not the score.** 7.1% of cells still carry no sales figure, and HistGradientBoosting splits on missing values natively. Logistic regression and random forest would need imputation — and missingness varies by category, which is the treatment variable, so imputing would reinject the very bias the matching design exists to remove.

**The margin between model families is within noise.** Across six rolling quarters boosting averages AUC 0.6661 against logistic 0.6645, winning four of six. Boosting's own PR-AUC ranges 0.392–0.445 over those quarters, so quarter-to-quarter variation is roughly five times the gap between families.

### Reported performance, without the flattering framing

> **Rolling AUC = 0.666 ± 0.010 over 6 quarters** ← this is the number to quote

The single-quarter validation AUC is 0.668, but the model was *selected* on that quarter, so it is optimistic by construction. The rolling figure is reported instead. That the two figures agree to 0.002 is itself evidence that the optimism is small.

## Count model — and what "+0.012" actually measures

Performance is stated against a three-rung ladder rather than against zero, because an absolute score means nothing until you know what a trivial rule already achieves:

| Rung | What it uses | AUC (≥1 closure) | Poisson deviance | MAE |
| ---- | ------------ | ---------------: | ---------------: | --: |
| B1 · mean closure rate × stores | store count only | 0.7047 | 1.0018 | 0.592 |
| B2 · category mean × stores | + category — "last year again" | 0.7069 | 0.9966 | 0.592 |
| **B3 · negative binomial** | everything | **0.7169** | **0.9761** | 0.582 |

**+0.012 is B1 → B3** — everything the whole feature set adds over sorting by store count, measured on the validation quarter's 2,772 cells. Most of that gain comes from three **momentum** features: the cell's own opening rate, closure rate and net-change rate, read at quarter *t* rather than *t+1*, so they are the cell's history rather than a look at the answer.

Poisson deviance sits beside AUC because for a count target the magnitude has to be right as well as the ordering; below 1.0 means beating the store-count-only prediction outright.

> **Overall ranking performance improved only modestly beyond commercial scale.** Model performance was therefore not evaluated using AUC alone.

---

# 🎯 Practical Value — Risk Prioritization

Aggregate ranking ability is roughly what store count alone delivers. That reads as failure until you look at where the flags actually go — because no support programme contacts every cell. It contacts the few dozen an officer can reach.

| Cells flagged | Model precision | Store-count rule | Overlap between the two lists |
| ------------: | --------------: | ---------------: | ----------------------------: |
| **50**    | **0.760** | 0.380 | **6%** |
| 100   | 0.620 | 0.460 | 16% |
| 200   | 0.555 | 0.520 | 32% |
| 2,000 | 0.393 | 0.385 | 85% |

In caseload terms: **of 50 cells contacted, 38 are cells that actually decline, against 19 under the store-count rule** — the same officer time reaches twice as many. Because the top-50 lists overlap by only 6%, **47 of the 50 cells the model names are commercial districts the current rule would never have flagged.**

Precision decays as the list grows, which is why the cutoff has to be set from real capacity rather than chosen for the headline.

The advantage also persists **within** size bands, where store count can no longer discriminate at all — in the smallest quintile the model reaches lift **1.345** against **1.100** for the store-count rule.

This suggests that the model may be more useful for:

> **Targeted early-warning and resource prioritization**

than for precise individual business-level prediction.

---

# 🏛️ External Benchmark

The model was also compared with Seoul's existing commercial district change indicator, which assigns each commercial district one of four states each quarter.

| Indicator | Cells | Net-decline rate | Lift |
| --------- | ----: | ---------------: | ---: |
| **HL — "district contraction"** | 974 | 24.3% | **0.937** |
| HH | 1,452 | 23.3% | 0.899 |
| LH | 790 | 22.9% | 0.882 |
| LL | 2,263 | 29.4% | 1.133 |

A Lift below 1 indicates performance worse than random selection for identifying future risk. Districts flagged as *contracting* decline **less** than average in the following quarter.

> **The existing indicator summarises what has already happened; it is not aimed at the following quarter.**

It is used here strictly as a baseline — being built from closure records, it would be leakage as a feature.

---

# 🧪 What Was Measured — and Thrown Out

A distinguishing feature of this project is that results were tested for reproducibility before being reported, and two were discarded.

## A result that was discarded

An early check produced a rank correlation of **0.915** between predicted and actual category risk, which looked like a strong result. Two follow-ups killed it.

First, the baseline ladder showed that **store count alone reproduced 0.915**. Second — and more decisively — instead of measuring the model, the *target* was measured. Splitting the data in half, ranking categories independently in each half and correlating the two rankings gives the reliability of the answer key itself:

| Quantity | Value |
| -------- | ----: |
| Split-half correlation | 0.110 |
| Spearman-Brown corrected | 0.198 |
| **Theoretical ceiling √r for any predictor** | **0.444** |
| Our model's value | **0.515** |

A perfect predictor cannot exceed 0.444 against a target this noisy. Scoring 0.515 is not skill — it is noise clearing a bar it should not have been able to reach.

> **The metric was removed from the reported results, and performance is stated only in cell-level terms.**

## Which aggregation levels can be reported at all

The same reliability test was applied to the net-decline target at each aggregation level:

| Level | Units | Single quarter | Pooled over 6 quarters | Verdict |
| ----- | ----: | -------------: | ---------------------: | ------- |
| Food category | 10 | 0.212 | 0.617 | Usable pooled |
| City district (gu) | 25 | 0.086 | 0.537 | Pooled only |
| **City district × category** | 240 / 243 | **0.035** | **0.223** | **Do not rank** |

At the finest level the answer key reshuffles when re-measured. Only 23% of the top-20% list survives from one quarter to the next, and the interaction component — "which category is *specifically* at risk in *this* district" — has a split-half reliability of just **0.147**. Cell-level predictions are stored so this table *can* be aggregated, but it cannot be validated, so no ranking is published at that level.

> **Declining to answer is part of the result.**

*Note on the two reliability blocks above: the 0.110 / 0.444 figures measure the category ranking on the **closure-rate** target (count model), while the table measures the **net-decline** target (binary classifier). They are different targets and are not directly comparable. The pooled district × category figure is reported unfiltered across all 243 units; restricting to the 97 best-sampled units raises it to 0.259, which would flatter the result.*

---

# 📅 Deliverable — 2026 Q2 Forecast

The final output is a scored list rather than a report:

> **2,737 neighborhood commercial district × category cells, each with a predicted closure rate and predicted net-decline probability for 2026 Q2.**

Intervals are city-district-level cluster bootstraps over 500 resamples, so they widen for categories with fewer cells. They capture sampling variation only — model error is not included, and true uncertainty is wider.

The forecast also surfaces the project's central problem in a single number:

> **Rank correlation between the two metrics — predicted closure rate and net-decline rate — is −0.406.**

The category that Seoul's current metric ranks most at risk finishes **ninth of ten** on predicted closure rate. The choice of metric, not the analysis behind it, decides who receives support.

---

# 💡 Business Insights

## 1️⃣ Industry Rankings Can Be Misleading

A category ranking first in net-decline rate does not necessarily mean that it is the most vulnerable. Selection effects and commercial scale can create misleading rankings. Seoul's other instrument, the commercial district change indicator, does not work either (lift 0.937).

> **Both current decision tools are broken, in different ways.**

---

## 2️⃣ "Open Where the Foot Traffic Is" Is Half of a Sentence

Foot traffic raises openings and closures alike. A busy district is not a safe one — it is a **fast-turnover** one. And within a cell over time it predicts nothing at all, so it stands in for fixed location traits rather than acting on its own.

---

## 3️⃣ A Single Average Effect Can Hide Important Differences

The adjusted effect varied substantially across commercial-scale groups — from −13.0 pp to +2.4 pp, changing sign. Therefore:

> **Neither "Korean is safe" nor "Korean is risky" is a true sentence.**

The signal lives in the category-by-size combination, and one-size-fits-all industry-level conclusions should be avoided.

---

## 4️⃣ The Finest Unit This Data Can Support Is the Cell

City district × category has a single-quarter split-half reliability of 0.035 — re-measure and the ranking reshuffles. Cell-level scores are stored so the aggregation is possible, but publishing that ranking would be publishing noise.

Rather than:

> "Which industry should receive support?"

A more actionable question is:

> **"Which commercial district × industry cells show elevated future risk?"**

---

## 5️⃣ The Model Earns Its Place on Small Districts, Not on the Leaderboard

On aggregate ranking it adds +0.012 over store count. Hold size constant and store count stops discriminating entirely while the model keeps working — and small districts are exactly where early warning is needed.

> **Reading the aggregate number alone would lead to scrapping the model for the wrong reason.**

---

# 📌 Recommendations

### 🔹 Use Scale-Adjusted Risk Measures

Raw net-decline rankings should not be used as standalone measures of business vulnerability. Commercial scale should be incorporated into risk assessment, and closures per store should be published alongside the net-decline rate — the two rank categories at **−0.406** correlation, so either one alone yields the opposite conclusion.

---

### 🔹 Prioritize Neighborhood Commercial District × Industry Cells

Support programs should move toward **cell-level targeting** — one micro commercial district × one category — rather than allocating resources by industry ranking.

Set the cutoff from the caseload an officer can actually contact: precision runs from **0.760 at 50 cells** to **0.498 at 500**.

> ⚠️ **This means the micro commercial district (sanggwon), not the city district (gu).** City district × category rankings were tested and are not reportable — see the reliability section above.

---

### 🔹 Segment Interventions by Industry Characteristics

Location sensitivity varies by a factor of **600×** across categories — pub/bar ε² = **0.1202** against chicken ε² = **0.0002**.

**Location-sensitive categories** (pub/bar, cafe, Korean) may benefit from:

* Location diagnostics
* Commercial district consulting
* Market-specific interventions

**Location-insensitive categories** (chicken, fast food) cannot be helped by district-level measures at all, and require interventions focused on:

* Cost structures
* Delivery platform fees
* Franchise conditions
* Operational efficiency

---

### 🔹 Rewrite the Foot-Traffic Line in Startup Counselling

Replace "choose a district with heavy foot traffic" with:

> **"Heavy foot traffic raises both your revenue ceiling and your closure risk — it means fast turnover, so carry more working capital."**

Current guidance states half of the effect: openings +0.098 and closures +0.053 are both significant, and only the first is being mentioned.

---

# ⚠️ Limitations

## Observational Data

The analysis uses observational commercial data. Although matching and doubly robust estimation reduce bias from observed confounders:

> **Unobserved confounding may remain.**

Examples include rent, business owner characteristics, business age, and capital availability. Therefore the results should be interpreted as **adjusted associations rather than definitive causal effects**.

---

## Matching Coverage

Only **70.7% of treatment observations** were successfully matched. The remaining observations, primarily very large Korean restaurant commercial cells, were outside the common support region.

> **The ATT applies primarily to comparable commercial-scale ranges.**

---

## Sales Missingness Was Not Diagnosed

The handling is conservative — sales was excluded from the matching covariates and never imputed — but four checks were skipped:

1. Whether the residual 7.1% missingness among 5+ store cells correlates with the outcome
2. Whether those are true NaNs or rows absent from the source entirely
3. What the 100% suppression rule actually is (the "anonymization" reading is an inference, not a confirmed fact)
4. How much the score moves without the sales feature

The ATT does not use sales, so the exposure is confined to the prediction model.

---

## Aggregated Data

The analysis uses **commercial district × industry-level aggregated data**. Individual business histories were not available, so the analysis cannot determine which specific businesses closed, how long they operated, or individual survival patterns.

---

## Heterogeneous Treatment Effects

The treatment effect varied substantially by commercial scale and changed sign in the largest band.

> **The overall ATT should not be interpreted as a universal effect, and −5.77 pp should never be quoted without the stratum table beside it.**

---

## No Sealed Test Quarter

The validation quarter was also used to choose the model. Six-quarter rolling validation stands in, and the two figures agree to 0.002 — but a genuinely sealed quarter would be better practice.

---

## Prediction Performance

Although the count model achieved an AUC of 0.717, much of the ranking ability was already explained by store count alone (0.705). The additional predictive value of the full model was therefore modest at the overall ranking level, and concentrated in the top of the list and the smaller size bands.

---

## Known Non-Determinism

Nearest-neighbour matching is greedy and therefore order-dependent. Re-running the upstream steps holds the pair count at 7,042 but changes *which* pairs are selected, moving the ATT in the second decimal. Conclusions are unaffected; pinning the treated-unit sort order before matching would make it bit-reproducible.

---

# 🚀 Future Improvements

### Re-match on Within-Category Percentile *(no new data required)*

Tests whether the sign flip in the largest band is an artefact of matching on *absolute* store count. This is the cheapest open item and the one most likely to change how −5.77 pp has to be described.

---

### Business-Level Survival Data

Individual business opening and closure histories would allow survival analysis, hazard modeling, and business lifecycle analysis.

---

### Commercial-District-Level Rent Data

Rent may explain why commercial scale is associated with business decline — a large cell likely means expensive frontage and a heavier fixed-cost floor. Currently available rent data is city-district level and has no discriminating power between commercial districts.

---

### Average Months in Operation

Already present in the change-indicator file and not leakage, since it is built from operating rather than closed businesses. Univariate AUC 0.538: weak, directional, and uncorrelated with size (−0.085).

---

### Delivery Platform Data

Restaurant closures may be influenced by delivery dependence, platform commissions, and online competition. These variables were not available in the current dataset, which is why the delivery explanation for chicken's location-indifference remains an inference.

---

### Quasi-Experimental Policy Evaluation

Future work could evaluate business-support policies using Difference-in-Differences or Event Studies, which is the only route here to ruling out unobserved confounding rather than merely naming it.

---

# 🛠 Tools & Skills

### Data Analysis

* Python
* Pandas
* NumPy

### Statistical Analysis

* Kruskal-Wallis Test
* Levene's Test (median-centred)
* Permutation Testing
* Effect Size Analysis (ε²)
* Simpson's Paradox Analysis
* Woolf Homogeneity Test
* Split-Half Reliability & Spearman-Brown Correction

### Causal Inference

* Propensity Score Matching
* Standardized Mean Difference
* Average Treatment Effect on the Treated (ATT)
* Stratified ATT & Heterogeneity Testing
* Doubly Robust Estimation
* Counterfactual Analysis
* Cluster Bootstrap
* Sensitivity Analysis

### Modeling

* Gradient Boosting Classification
* Negative Binomial Regression with Offset
* Cell Fixed Effects
* Two-Stage Outcome Decomposition
* Baseline Ladder Construction
* Rolling Temporal Validation
* Model Calibration

### Model Evaluation

* ROC-AUC
* PR-AUC
* Brier Score
* Poisson Deviance
* Lift
* Precision at Operating Points

---

# 👤 My Contribution

I was responsible for:

* Defining the analytical research questions
* Designing the data preprocessing pipeline
* Identifying and correcting historical schema inconsistencies
* Creating future net-decline labels
* Preventing temporal data leakage
* Building a three-layer guard against silent join failures
* Performing exploratory and statistical analysis
* Investigating selection effects using permutation testing
* Identifying Simpson's Paradox
* Designing and evaluating the matching strategy
* Performing Propensity Score Matching and balance diagnostics
* Conducting robustness checks with multiple estimation methods
* Investigating heterogeneous effects across commercial-scale groups
* Decomposing the outcome definition to separate event frequency from conditional risk
* Measuring the reliability of the target itself and discarding results that exceeded it
* Building and evaluating predictive models
* Comparing the model against existing external benchmarks
* Translating statistical findings into policy and business recommendations

---

# 📊 Final Conclusion

> **The apparent risk of Korean restaurants was largely a statistical illusion created by selection effects and commercial scale.**

After controlling for comparable commercial characteristics:

> **The direction of the relationship reversed.**

The analysis found that:

* Commercial scale was a major driver of net business decline
* Raw industry rankings can be misleading, and 88% of the headline gap was a selection effect
* The published indicator measures **how often an event occurs** rather than **how risky the district is** — an exact decomposition, not an interpretation
* The overall adjusted effect varied substantially by commercial scale and changed sign in the largest band
* Future risk assessment should move from industry-level rankings toward neighborhood commercial district × industry-level targeting

### Final Recommendation

> **Do not use raw net-decline rankings as a standalone measure of business vulnerability.**

Instead:

> **Adjust for commercial scale, publish closures per store alongside the net-decline rate, and evaluate risk at the neighborhood commercial district × industry level.**
