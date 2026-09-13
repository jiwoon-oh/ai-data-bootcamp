# 🛒 Dunnhumby — Customer Revenue Concentration & High-Value Customer Retention

> **Team project.** This page documents **H4**, the hypothesis I owned end to end — from methodology design through statistical testing to exploratory modeling. Other hypotheses were handled by other team members and are not described here.

---

## ⚡ Executive Summary

> **The hypothesis was that revenue growth came from heavy spenders spending more. The data says the opposite: the gap between heavy and light spenders narrowed.**

**The hypothesis under test.** Revenue growth is concentrated in a small group of high-value households — the top spenders are pulling the total up.

**What the tests returned.**

| Test | Result | What it means |
| ---- | ------ | ------------- |
| Wilcoxon · top 20% absolute spend | **median −131.45**, p = 0.00002 | Heavy spenders **shrank**, not grew |
| Wilcoxon · remaining 80% | **median +36.49**, p ≈ 0.0000 | The growth came from everyone else |
| Bootstrap · revenue share of top 20% | **54.87% → 41.96%** (−12.91 pp) | The concentration itself fell |

**The hypothesis is rejected in both framings — absolute spend and revenue share.** What replaces it is a *convergence* pattern: households that spent heavily early declined, households that spent lightly early grew, and the distribution de-concentrated.

### Key findings

- **The direction is stable, not an artifact of where the baseline window was drawn.** Re-running with 8-, 10- and 12-week baselines never flips the sign — the gap widens instead, which is the opposite of what a regression-to-the-mean artifact would produce.
- **New/reactivated households are strongly associated with the growing group** (Cramér's V = 0.246) — 43.5% of the remaining 80% are new or reactivated, against 13.6% of the top 20%.
- **But association is not contribution.** New/reactivated households are 43.5% of the headcount and only **30.0%** of the net revenue increase. The real driver of growth is organic spending increase among **existing active households**, not acquisition.
- **Exploratory modeling identified who drops out of the top tier.** Demographic-survey participation is the strongest protective signal; visit frequency is, counterintuitively, a *risk* factor once spend is controlled for.

### At a glance

| | |
| --- | --- |
| **Data** | Dunnhumby "The Complete Journey" — 2,500 households, 83-week stable period (weeks 17–99) |
| **My scope** | H4 (H4-1 concentration, H4-2 contribution structure) + exploratory retention modeling |
| **Methods** | Lorenz/Gini concentration · Spearman rank-stability elbow · Wilcoxon · Mann-Whitney U · bootstrap CI · chi-square · contribution decomposition · logistic regression · random forest + SHAP |
| **Headline result** | Original hypothesis **rejected**; de-concentration documented instead |

---

## 👤 My Contribution

This was a team project covering several hypotheses. **H4 was mine**, and this document covers only that work:

* Designed the methodology, including the anti-circularity rule that governs the whole analysis
* Determined the baseline window length and the top-X% threshold from the data rather than by convention
* Ran and interpreted every statistical test reported below
* Discovered that the result ran opposite to the hypothesis, and escalated the sensitivity check to rule out a statistical artifact before reporting it
* Reframed H4-2 from an association claim into a **contribution decomposition**, and reported the gap between the two
* Built the exploratory retention-risk model and its validation suite

---

## 🎯 Hypothesis

**H4 — Revenue growth is concentrated in a small group of high-spending households.**

| Sub-hypothesis | Claim |
| -------------- | ----- |
| **H4-1** | For the top X% of households *fixed on the early window*, both (a) revenue share and (b) absolute spend increased in the later period |
| **H4-2** | Top-spender status is associated with new / reactivated status |

---

## 🧭 Design Principle — Preventing Circular Reasoning

**The definition of "top X%" must be fixed using early-window data only.**

If later-period data is mixed into the definition, the question stops being *"did households that were already heavy spenders grow?"* and silently becomes *"did the households that grew get classified as heavy spenders?"* — which answers itself.

A second decision follows from the same logic: **the value of X was not set to the conventional 20% by default.** The actual concentration of the spending distribution was measured first, and the threshold chosen from it.

---

## 📏 Step 1 — How Long Should the Baseline Window Be?

A baseline window that is too short ranks households on noise; one that is too long eats into the period being measured.

**Method.** For each candidate length *N*, split the first *N* weeks into odd and even weeks, rank households by spend within each half independently, and compute the Spearman correlation between the two rankings. Plot the correlation against *N* and detect the elbow.

**Constraint.** The stable period runs weeks 17–99 (83 weeks), so the baseline was capped at **10–15% of the total (roughly 8–12 weeks)** to leave the observation period intact.

| | |
| --- | --- |
| Elbow (kneed) | **N = 10 weeks** |
| Rank correlation at that point | **ρ = 0.697** |
| Within the 10–15% rule | ✅ (10 of 83 weeks) |

![Spearman rank correlation between odd-week and even-week household rankings, plotted against baseline window length. The curve rises and flattens, with the detected elbow at N = 10 weeks.](/project-dunnhumby/src/image.png)

*Rank stability against baseline length. The elbow sits at 10 weeks (ρ = 0.697) — and the curve is smooth rather than sharply bent, which is why sensitivity checks at 8 and 12 weeks were planned from the start.*

> ⚠️ **Reported honestly: there was no sharp elbow.** ρ = 0.697 is moderate, meaning the top-X% membership is defined under a non-trivial amount of noise. N = 10 was adopted as the primary specification, with 8 and 12 weeks planned as sensitivity checks — which is exactly what made the later sensitivity check decisive.

---

## 📊 Step 2 — How Concentrated Is Spending? (Lorenz Curve)

Households were sorted by early-window spend and plotted as cumulative household share (x) against cumulative revenue share (y). A perfectly equal distribution (y = x) would make the hypothesis meaningless; an extremely concentrated one would bend sharply.

| Measure | Value |
| ------- | ----- |
| **Gini coefficient** | **0.532** (0 = perfectly equal, 1 = fully concentrated) |
| Top 10% of households | 36.1% of revenue |
| **Top 20% of households** | **55.4% of revenue** |
| Top 30% of households | 68.9% of revenue |
| Top 1% of households | 6.1% of revenue |

![Lorenz curve of household spending: cumulative share of households on the x-axis against cumulative share of revenue on the y-axis, bowed below the line of equality.](/project-dunnhumby/src/image1.png)

*Lorenz curve of early-window spending. The gap between the curve and the diagonal is the Gini coefficient, 0.532.*

![Cumulative revenue share by household decile, showing a smooth decline with no sharp break point.](/project-dunnhumby/src/image2.png)

*Concentration by decile. The decline is smooth — there is no natural cut-off, so the threshold was set by elbow detection at 18% and rounded to 20%.*

**This is not the textbook Pareto distribution.** The conventional 80/20 rule would put 80% of revenue in the top 20%; here it is 55.4%. Spending is meaningfully concentrated, but the middle of the distribution still carries substantial weight — worth stating, because it bounds how much the hypothesis could have explained even if it had held.

The curve declines smoothly with no visually obvious break, so the threshold was set by elbow detection: **top 18%**, which sits close enough to convention that **X = 20%** was adopted.

---

## 🧹 Step 3 — Outlier Policy

An IQR rule flagged **7.34%** of `SALES_VALUE` as outliers. That figure was read not as *"this data has many outliers"* but as *"IQR is the wrong tool for a right-skewed spending distribution."*

More decisively: **H4 is a hypothesis about high-spending transactions.** Removing them would delete the very signal the test is meant to detect.

> **Decision — keep all observations, and use rank-based non-parametric tests that do not assume normality.**

---

## 🔍 Step 4 — First Signal, Pointing the Wrong Way

Comparing per-household spend change (late window − early window):

| Group | Mean diff |
| ----- | --------: |
| Remaining 80% | **+102.74** |
| Top 20% | **−111.49** |

This is the opposite of what H4-1 predicts. Before reporting it, the obvious alternative explanation had to be ruled out: **regression to the mean.** Households selected for being extreme in one period tend to look less extreme in the next, purely as a statistical artifact.

The sensitivity check was therefore pulled forward ahead of schedule.

---

## 🔁 Step 5 — Sensitivity Check (N = 8, 10, 12 weeks)

| Baseline (weeks) | Remaining 80% mean diff | Top X% mean diff |
| ---------------: | ----------------------: | ---------------: |
| 8  | +92.42  | −97.16  |
| 10 | +102.74 | −111.49 |
| 12 | +117.85 | −120.21 |

![Mean spending change for the top X% and the remaining 80%, plotted for baseline windows of 8, 10 and 12 weeks. The two lines diverge further as the window lengthens.](/project-dunnhumby/src/image3.png)

*Sensitivity to baseline length. The lines separate rather than converge — the opposite of what regression to the mean would produce.*

**Two things to read here.**

1. **The sign never flips.** More importantly, the gap *widens* as the baseline lengthens. A regression-to-the-mean artifact would behave the opposite way — a longer, more reliable baseline should shrink the apparent reversal, not grow it.
2. **Group membership itself is stable.** Jaccard overlap between the top-X% rosters across the three specifications is **0.76–0.86**, so the three runs are largely describing the same households.

> **Conclusion, stated at the strength the evidence supports:** the result is stable across baseline-window definitions and is not explicable by the choice of threshold alone. The pattern is a **convergence of spending levels** — early heavy spenders decline, early light spenders grow.

---

## 🧪 Step 6 — Assumption Checks

| Check | Test | Result |
| ----- | ---- | ------ |
| Normality | Shapiro-Wilk | **Rejected** for both top 20% and remaining 80% |
| Equal variance | Levene | **Rejected** — top-20% variance is more than 3× that of the remaining 80% |

> **Non-parametric tests confirmed: Wilcoxon signed-rank for within-group change, Mann-Whitney U for between-group comparison.**

---

## 📈 Step 7 — Testing H4-1

Three related tests, so a **Bonferroni correction** applies: α = 0.05 / 3 ≈ **0.0167**.

### Test A — Did the top 20% change? (Wilcoxon signed-rank)

| | |
| --- | --- |
| p-value | **0.00002** |
| Effect size (r) | **−0.209** |
| Median diff | **−131.45** |
| 95% CI | Entirely below zero |

→ The top 20% **decreased significantly**.

### Test B — Did the remaining 80% change? (Wilcoxon signed-rank, control group)

| | |
| --- | --- |
| p-value | **≈ 0.0000** |
| Median diff | **+36.49** |
| 95% CI | (24.3, 50.1) |

→ The remaining 80% **increased significantly**.

### Test C — Do the two groups differ in how much they changed? (Mann-Whitney U)

| | |
| --- | --- |
| p-value | **≈ 0.0000** |
| Effect size (r) | **0.290** — the largest of the three |
| Common-language effect size | **0.355** (0.5 would mean no difference) |
| 95% CI | (−227.7, −116.0), excludes zero |

![Distribution of spending change for the top 20% versus the remaining 80%, showing the top group shifted toward negative change and the remaining group toward positive.](/project-dunnhumby/src/image4.png)

*The two distributions of change, side by side. This is the comparison Test C formalises.*

The common-language figure is the most readable: pick one household from each group at random, and the remaining-80% household grew more than the top-20% household far more often than chance would produce.

### Test D — Did the revenue *share* of the top 20% change? (Bootstrap, 5,000 resamples)

Share is a single value per time point rather than a per-household value, so rank-based tests do not apply. A bootstrap CI was constructed by resampling with replacement.

| | |
| --- | --- |
| Early-window share | **54.87%** |
| Late-window share | **41.96%** |
| Change | **−12.91 pp** |
| 95% CI | (−14.74 pp, −11.09 pp), excludes zero |

![Bootstrap distribution of the change in revenue share held by the top 20%, centred near −12.9 percentage points with the entire 95% interval below zero.](/project-dunnhumby/src/image5.png)

*Bootstrap distribution over 5,000 resamples. The entire interval sits below zero — the share decline is not a sampling artifact.*

---

## ✅ H4-1 Conclusion

**Both framings — absolute spend and revenue share — show the top 20% contracting. H4-1 is rejected.**

What the data supports instead is **de-concentration**: the gap between high- and low-spending households narrowed over the observation period.

This is deliberately left open in one respect. De-concentration is consistent with two different stories — attrition or slowdown among high-value households, *or* genuine growth among the middle and lower tiers — and H4-1 alone cannot distinguish them. That is what H4-2 was built to address.

---

## 🔗 Step 8 — H4-2, Association Test

Since H4-1 established that the **remaining 80%** actually drove revenue growth, the next question is whether that growth came from (1) organic growth among existing active households or (2) an inflow of new and reactivated households.

### Label definitions

| Label | Definition |
| ----- | ---------- |
| **New** | First purchase date falls after the start of the stable period (week 17) |
| **Reactivated** | Not new, but has at least one purchase gap of **13 weeks (91 days)** or more |
| **Existing** | Neither of the above |

Label counts: Existing **1,565** · Reactivated **726** · New **209** — summing to 2,500, matching the total household count.

### 2 × 2 contingency table

| | Existing | New / Reactivated |
| --- | ---: | ---: |
| **Remaining 80%** | 1,127 (56.5%) | **866 (43.5%)** |
| **Top 20%** | 431 (86.4%) | 68 (13.6%) |

| | |
| --- | --- |
| Minimum expected frequency | 187 (> 5, assumption satisfied) |
| Chi-square p-value | **≈ 0.000000** |
| **Effect size (Cramér's V)** | **0.246** — moderate |

> **H4-2 is supported as an association:** top-spender status and new/reactivated status are related. The group that drove growth is 43.5% new or reactivated; the group that contracted is 86.4% existing customers.

---

## 🧮 Step 9 — H4-2, Contribution Structure

> **A 2 × 2 table is an association. It does not establish that new and reactivated households *caused* the revenue growth.**

Two competing readings had to be separated:

| Scenario | Claim |
| -------- | ----- |
| **A** | New/reactivated households entered and genuinely generated the additional revenue |
| **B** | New/reactivated households simply spend less on average, so they cluster in the lower group — their actual revenue contribution is small |

To distinguish them, new and reactivated households were isolated and their **actual share of the net revenue increase** was computed directly.

### Net-increase contribution within the remaining 80%

| Cohort | Share of headcount | **Share of net increase** | Median diff |
| ------ | -----------------: | ------------------------: | ----------: |
| Existing | 56.5% | **70.0%** | 51.78 |
| New / Reactivated | 43.5% | **30.0%** | 10.26 |

![Side-by-side bars comparing each cohort's share of headcount against its share of the net revenue increase. Existing households contribute more than their headcount share; new and reactivated contribute less.](/project-dunnhumby/src/image6.png)

*Headcount share against contribution share. The bars crossing over is the whole finding — new and reactivated households are the larger group but the smaller contributor.*

**Contribution (30.0%) is lower than headcount (43.5%).** New and reactivated households are numerous but contribute less per head — the median existing household grew about **5×** more than the median new/reactivated one.

### Mann-Whitney U within the remaining 80% (new/reactivated vs existing)

| | |
| --- | --- |
| p-value | **0.000928** (passes Bonferroni) |
| Effect size (rank-biserial) | **0.086** — very small |
| Common-language effect size | **0.457** (0.5 = no difference) |
| n | 1,993 |

> **A textbook case of statistically significant ≠ practically important.** With a sample this large the test reaches significance, but the effect size is small enough to be ignorable — and reporting only the p-value here would have been misleading.

---

## ✅ H4-2 Conclusion

| | |
| --- | --- |
| **Association — confirmed** | New/reactivated households cluster overwhelmingly in the remaining 80%, not the top 20% (Cramér's V = 0.246) |
| **Contribution — limited** | 70% of the actual revenue increase in that group still came from existing households; new/reactivated contributed 30%, below their headcount share |

![Summary diagram of the H4 result: the top 20% shrinking in both absolute spend and revenue share, the remaining 80% growing, and existing households driving most of that growth.](/project-dunnhumby/src/image7.png)

*H4 in one picture — rejection of the original hypothesis, and the convergence pattern that replaces it.*

> **The real driver of revenue growth was organic spending increase among existing active households — not acquisition or reactivation.**

---

## 🤖 Step 10 — Exploratory Retention-Risk Modeling

Statistical testing establishes **what happened**. It does not say **who it will happen to next**. This stage is positioned as **exploratory modeling**, not as a deployed predictive system — the sample is small and the intent is to surface risk factors, not to ship a scorer.

### Problem setup

| | |
| --- | --- |
| **Population** | Households in the top 20% during the early window (weeks 17–26) — **499 households** |
| **Target** | Still in the top 20% during the late window (weeks 90–99) = 0, dropped out = 1 — defined by **recomputed rank**, not simply by diff < 0 |
| **Models** | Logistic regression (interpretability first) + random forest with SHAP (non-linearity and interactions) |
| **Metrics** | **PR-AUC and Recall** — missing an at-risk household is the costly error; accuracy is reference only |
| **Validation** | **StratifiedKFold, 5 folds** — with only 499 households a single train/test split would be unstable |

> 🔒 **No temporal leakage.** All features were constructed **only from the early observation window (weeks 17–26)**, while the target was defined **only from the later window (weeks 90–99)**. No later-period information enters the feature set at any point.

### Data exploration on the auxiliary tables

| Table | Finding |
| ----- | ------- |
| `hh_demographic` | Present for 32.1% of the stable period overall, but **63.9%** among top-20% households — survey respondents tend to be heavier spenders. The 36.1% missing (180 households) was encoded as an explicit "no information" category |
| `causal_data` | No missing values or duplicates. DISPLAY/MAILER codes verified (0 = no exposure) |
| `product` | 1:1 mapping on `product_id` confirmed; joins clean |
| `coupon_redempt` | All activity begins after DAY 225 — **zero overlap with the early window (DAY 111–180)**, so it was dropped as a feature source |
| `campaign_table` / `campaign_desc` | Likewise no overlap with the early window — dropped |

### Feature engineering

* **Demographic missingness** was filled as "no information" — kept conceptually distinct from the source data's own `Unknown` value, which means *"responded to the survey but skipped this item."* Conflating the two would have been a silent labelling error.
* **Label balance:** 44.7% dropped out vs 55.3% retained — no class-imbalance handling required.
* **Outlier handling:** households 13 and 17 showed `QUANTITY` sums of 7,660 and 2,559, implausible for a basket count and likely weight- or volume-priced items. `avg_qty_per_basket` was therefore replaced with **`avg_items_per_basket`** (distinct product count), which is immune to the unit problem.
* **A counterintuitive univariate signal:** `exposure_ratio` was *higher* in the drop-out group than the retained group — flagged for re-checking under multivariate control.

### Encoding

| Type | Treatment |
| ---- | --------- |
| Numeric (5) | `sales_early`, `n_baskets`, `avg_items_per_basket`, `category_diversity`, `exposure_ratio` — standardized for logistic regression |
| Demographic presence | Split out as a single binary `has_demo`, to avoid the same missingness being represented redundantly across several columns |
| Ordinal (4) | Integer encoding preserving order; "no information" imputed with the mode before encoding |
| Nominal (2) | One-hot with the mode as reference — except `HH_COMP_DESC`'s `Unknown`, kept as its own category because it may proxy for non-standard household types such as extended families |

### Multicollinearity (VIF)

| Feature | VIF |
| ------- | --: |
| `KID_CATEGORY_DESC_encoded` | **26.68** |
| `HOUSEHOLD_SIZE_DESC_encoded` | **26.49** |

The two encode essentially the same information (number of children ↔ household size). Dropping `KID_CATEGORY_DESC_encoded` brought every remaining feature below VIF 5 (`HOUSEHOLD_SIZE_DESC_encoded`: 26.49 → 4.8). **Final feature set: 18.**

![VIF values for all candidate features before and after removing the redundant child-category variable. Two bars exceed 25 before removal; all bars fall below 5 after.](/project-dunnhumby/src/image8.png)

*VIF before and after dropping the redundant variable. Household size and child category were encoding the same information.*

### Model 1 — Logistic regression (interpretability first)

| | |
| --- | --- |
| Random baseline PR-AUC | ≈ 0.447 (equal to the positive rate) |
| **Model PR-AUC** | **0.674** |
| Confusion matrix | Of 223 actual drop-outs, **86 (~39%) were predicted as retained** |

![Precision-recall curve for the logistic regression across five cross-validation folds, sitting above the random baseline of 0.447 with visible fold-to-fold spread.](/project-dunnhumby/src/image9.png)

*Precision-recall across folds. Clearly above the 0.447 baseline, with spread that reflects the 499-household sample.*

![Confusion matrix for the logistic regression, showing 86 of 223 actual drop-outs classified as retained.](/project-dunnhumby/src/image10.png)

*Confusion matrix. The 86 missed drop-outs in the lower-left are the errors that matter for this use case.*

Clear improvement over baseline, though fold-to-fold variance is visible — a direct consequence of the small sample.

**Odds-ratio reading**

| Feature | Direction | Note |
| ------- | --------- | ---- |
| `has_demo` | **Strongest protective factor (OR ≈ 0.35)** | Survey participation itself may be a retention signal — engagement rather than demographics |
| `sales_early` | Protective | Consistent with the univariate group comparison |
| `category_diversity` | Protective | Consistent with the univariate group comparison |
| `exposure_ratio` | **Protective after controls** | Reverses its univariate direction — a genuine multivariate-control effect |
| `n_baskets` (visit frequency) | **Risk factor** | At equal spend, households visiting often with small baskets appear more likely to fall out of the top tier than households visiting rarely with large ones |
| `HOMEOWNER_DESC_Unknown`, `Probable Owner` | — | Small cell sizes; estimates unstable, treated as indicative only |

![Odds ratios with confidence intervals for each feature, plotted on a log scale against the neutral line at 1.0. Demographic presence sits furthest to the protective side.](/project-dunnhumby/src/image11.png)

*Odds ratios with intervals. Anything left of 1.0 is protective; note how far `has_demo` sits from the rest.*

### Model 2 — Random forest + SHAP

**Recall is markedly lower than logistic regression** — the forest is conservative, defaulting to "retained" on ambiguous cases, which is exactly the wrong failure mode for this problem. With 499 households the tree ensemble is working against its own sample requirements.

![Precision-recall curve for the random forest, comparable in area to the logistic regression but with lower recall at usable thresholds.](/project-dunnhumby/src/image12.png)

*Random forest precision-recall. The area is similar; the usable operating region is not.*

![Confusion matrix for the random forest, showing more actual drop-outs classified as retained than the logistic model produced.](/project-dunnhumby/src/image13.png)

*The forest's conservatism made visible — it pushes ambiguous households into the 'retained' column.*

> **For this dataset and sample size, logistic regression is the better choice** — both for performance on the metric that matters and for interpretability.

**SHAP importance ranking:** `has_demo` > `sales_early` > `category_diversity` > `INCOME_DESC` > `avg_items_per_basket` — nearly identical to the logistic odds-ratio ordering. **The two model families cross-validate each other's key features.**

![SHAP summary plot ranking features by mean absolute contribution, with demographic presence at the top.](/project-dunnhumby/src/image14.png)

*SHAP feature importance. The ordering reproduces the logistic odds-ratio ranking almost exactly.*

![SHAP beeswarm plot showing the direction and magnitude of each feature's contribution per household.](/project-dunnhumby/src/image15.png)

*Per-household SHAP values. Colour shows the feature value, so direction as well as importance is readable here.*

**One thing only the forest could see:** both `sales_early` and `category_diversity` show a **saturation region** — beyond a certain level, more adds nothing. Logistic regression assumes linearity and cannot represent this. The practical implication is that retention budget should target households **near the boundary**, not households already spending heavily.

![SHAP dependence plot for early-window spend, rising steeply at low values and flattening beyond a threshold.](/project-dunnhumby/src/image16.png)

*Early spend saturates. Past the flat region, additional spend stops reducing drop-out risk.*

![SHAP dependence plot for category diversity, showing the same flattening pattern beyond a threshold.](/project-dunnhumby/src/image17.png)

*Category diversity behaves the same way — which is why retention budget belongs near the boundary, not above it.*

### Cost asymmetry — why Recall over Precision

| Error | Consequence |
| ----- | ----------- |
| **False negative** (at-risk household predicted as retained) | A high-value customer churns unnoticed. The statistical tests above show this group is not the current growth driver — but retaining high-value customers still matters to the business over a longer horizon |
| **False positive** (retained household predicted as at-risk) | One extra retention message to a customer who was fine — near-zero cost |

> The cost structure of this domain supports optimizing for **Recall**.

### Model validation — is this just noise?

| Check | Result |
| ----- | ------ |
| Permutation test | **p = 0.001** — the learned pattern is not chance |
| Dummy classifier comparison | Clearly better than trivial baselines |
| Learning curve | **No overfitting** — train and validation performance are close |

![Permutation test null distribution of model scores with the observed score far in the right tail, p = 0.001.](/project-dunnhumby/src/image18.png)

*Permutation test. The observed score sits outside the null distribution — the learned pattern is not chance.*

![Learning curve showing training and validation scores converging but still trending upward at the maximum available sample size.](/project-dunnhumby/src/image19.png)

*Learning curve. Train and validation converge — no overfitting — but the curve has not flattened, so more data would likely help.*

> ⚠️ **But the learning curve has not flattened.** These results should be read as **preliminary findings with room to improve given more data**, not as the ceiling of what this sample can yield.

---

## ⚠️ Limitations

**Sample size in the modeling stage.** 499 households is small for a random forest, and fold-to-fold variance is visible even in logistic regression. This is why the stage is framed as exploratory rather than predictive.

**Moderate baseline reliability.** The odd/even rank correlation at the chosen window was ρ = 0.697 — the top-X% roster is defined under real noise. The sensitivity check mitigates this concern but does not remove it.

**Contribution analysis is not causal inference.** Step 9 decomposes where the revenue increase came from. It does not establish a counterfactual, and nothing here identifies what *would* have happened absent new and reactivated households.

**Observational data throughout.** No randomization, no assignment mechanism. Every result is an adjusted association.

**Unexplained convergence mechanism.** The de-concentration pattern is documented but not explained. Whether it reflects high-value attrition, competitive substitution, or broad-based growth in the lower tiers cannot be separated with this dataset.

---

## 🛠 Tools & Skills

**Programming & data handling** — Python · pandas · NumPy · SciPy

**Statistics & experimentation** — Wilcoxon Signed-Rank · Mann-Whitney U · Shapiro-Wilk · Levene's Test · Chi-Square Test · Bootstrap Confidence Intervals · Bonferroni Correction · Effect Size (r, rank-biserial, Cramér's V) · Common-Language Effect Size · Sensitivity Analysis

**Concentration & distribution analysis** — Lorenz Curve · Gini Coefficient · Pareto Analysis · Spearman Rank Stability · Elbow Detection (kneed) · Jaccard Similarity

**Modeling** — scikit-learn · Logistic Regression · Random Forest · SHAP · StratifiedKFold Cross-Validation · VIF Multicollinearity Diagnostics · Ordinal & One-Hot Encoding

**Model evaluation** — PR-AUC · Recall · Confusion Matrix · Permutation Test · Dummy Classifier Baseline · Learning Curve

**Practices** — Leakage prevention through strict temporal windowing · Circular-definition prevention · Contribution decomposition · Effect-size reporting alongside p-values
