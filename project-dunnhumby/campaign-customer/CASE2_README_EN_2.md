# 📣 Dunnhumby — Heterogeneous Campaign Response by Customer Spending Tier

> **Team project.** This page documents the campaign-response analysis I owned: a two-way fixed-effects study of whether marketing campaigns move spending differently across baseline customer tiers.

---

## ⚡ Executive Summary

> **Pooled and uncontrolled, spending in campaign-active weeks runs +242% above inactive weeks in the lowest-spending tier. Household fixed effects erase that result completely — and the only signal that survives correction points downward, in the highest tier.**

| Tier | Pooled comparison<br><span style="font-weight:400">active vs inactive weeks, no FE</span> | Fixed-effects model |
| --- | --- | --- |
| Low-spending | **+242%** | Not significant (TypeC p = 0.163) |
| Mid-spending | **+60%** | Not significant |
| High-spending | **+23%** | **TypeC: β = −6.25 (≈ −8.6%)** |

Campaigns were sent overwhelmingly to households that already spent a lot — reach was **94.1%** in the high tier against **25.2%** in the low tier. With assignment that lopsided, no comparison that leaves the household uncontrolled can be read as a campaign effect.

**After multiple-comparison correction, exactly one of nine tier × type combinations survives:** TypeC × high-spending, β = −6.25, BH-adjusted **p = 0.0033**, n = 295 households.

> ⚠️ **This is reported as a statistically stable association, not a confirmed causal effect.** A placebo test on non-recipients was too underpowered to rule out reverse targeting — the company may have sent TypeC *to* households whose spending was already falling.

### At a glance

| | |
| --- | --- |
| **Panel** | 2,500 households × weeks 33–101 — **172,500 household-week observations** |
| **Design** | Two-way fixed effects (household + week) with household-clustered standard errors |
| **Campaigns** | 30 campaigns across 3 types, weeks 33–102 |
| **Result** | 1 of 9 combinations stable after Benjamini-Hochberg correction |
| **Causal claim** | **None.** Parallel trends imperfect, placebo underpowered, staggered adoption, targeting rule unknown |

---

## 1. 🎯 Research Question

> **Does campaign response differ by a household's baseline spending tier?**

Put concretely: when a campaign is running, does a household's weekly spend move — and does that movement depend on whether the household was already a light, medium or heavy spender before any campaign began?

---

## 2. 🧭 Identification Strategy

Four design choices carry the entire analysis.

### Baseline tiers fixed **before** any campaign ran

Tiers were computed from **weeks 17–32 only**, using average weekly spend. The first campaign starts in **week 33**, so there is zero overlap.

This is the anti-circularity rule. Defining tiers with post-campaign data would produce the chain *campaign → spending rises → household classified as high-spending → "high-spending households spent more"*, which proves nothing.

| Tier | Households | Mean weekly spend | Range |
| ---- | ---------: | ----------------: | ----- |
| Low  | 834 | $3.85  | $0.00 – $10.03 |
| Mid  | 834 | $20.36 | $10.05 – $33.88 |
| High | 832 | $72.75 | $33.88 – $378.60 |

*Note:* 142 households (5.7%) had no transactions at all in weeks 17–32 and were assigned $0, placing them in the low tier — a floor-effect risk tracked throughout.

### Household fixed effects

Each household is compared **against itself** in campaign weeks versus non-campaign weeks. This removes the permanent, individual-level difference of "this household simply spends more" — which is precisely the confounder that makes the naive comparison wrong.

### Week fixed effects

Christmas, Thanksgiving and other calendar effects hit every household at once. Week fixed effects absorb them so they are not mistaken for campaign response.

### Household-clustered standard errors

An 84-week repeated-observation panel has serial correlation within households. Ordinary OLS standard errors ignore it and understate p-values.

**This was verified rather than assumed:** the model F-statistic is **11.544 (p = 0.0000)** without clustering and **2.313 (p = 0.0135)** with it. Without clustering, the analysis would have reported inflated significance.

### One more design decision

The main analysis uses **three tiers**, with quintiles as a secondary check. Splitting into five made several cells too small to estimate stably — TypeC's bottom two quintiles held only 16 and 25 households — which confirmed the three-tier design was the right call.

---

## 3. 📉 What the Naive Comparison Suggested

Within each tier, household-week observations were split by whether **any campaign was active that week**, and the two pooled means compared — with no household or week fixed effects applied:

| Tier | Inactive weeks | Active weeks | Apparent change |
| ---- | -------------- | ------------ | --------------: |
| **Low-spending** | $11.54 &nbsp;<span style="color:#888">(n = 54,622)</span> | $39.49 &nbsp;<span style="color:#888">(n = 2,924)</span> | **+242%** |
| Mid-spending | — | — | **+60%** |
| High-spending | — | — | **+23%** |

Read at face value this looks like a clean heterogeneous effect, with the lightest spenders gaining several times more than the heaviest.

**Two things make it unreadable as a campaign effect.**

**First, the comparison is pooled across households.** Even inside the low-spending tier, the households that received campaigns may simply be different households from those that did not — the comparison never holds the household constant, so selection sits inside it untouched.

**Second, the active-week sample is tiny.** Those 2,924 active-week observations are only **5.1%** of the tier's 57,546 household-weeks — the same fact the reach rate shows from the other direction.

| Tier | Campaign reach |
| ---- | -------------: |
| Low-spending | **25.2%** |
| High-spending | **94.1%** |

![Campaign reach rate by baseline spending tier, rising steeply from about 25% in the low tier to about 94% in the high tier.](/project-dunnhumby/src/01_reach_rate_by_tier_1.png)

*Campaign reach by tier. Assignment was not spread across tiers — it was concentrated in one, which is what makes any uncontrolled tier comparison unreadable.*

Campaigns went almost universally to households that were already heavy spenders, and barely at all to light ones. Whatever an uncontrolled comparison picks up, it is entangled with that assignment — which is the reason the design below compares each household against itself rather than against other households.

There is also substantial **simultaneous exposure**: of the 1,008 households receiving more than one campaign type, **86.2% received them in the same week**. This was flagged as a multicollinearity risk and checked — VIF ran **1.02–1.12** across all interaction dummies, because simultaneously-active rows are only 4.1% of the 172,500-row panel and the remaining 95.9% dilute the correlation.

---

## 4. 📊 What the Fixed-Effects Model Found

```
spend ~ Σ(campaign type × baseline tier)  +  household FE  +  week FE
        clustered SE at household level
```

### Model diagnostics

| Diagnostic | Value | Reading |
| ---------- | ----- | ------- |
| Within R² | 0.0004 | Expected — campaigns explain a sliver of weekly spending variance. With 172,500 observations, small signals are still detectable |
| F-test for poolability | 38.138 (p < 0.0001) | Household and week fixed effects were genuinely necessary |

### Raw results — 2 of 9 combinations significant at p < 0.05

| Combination | β | p | n | Relative size |
| ----------- | -: | -: | -: | ------------- |
| **TypeC × High-spending** | **−6.25** | 0.0004 | 295 | ≈ **−8.6%** vs baseline |
| TypeB × High-spending | −2.43 | 0.0118 | 628 | ≈ −3.3% vs baseline |

![Forest plot of all nine campaign type by spending tier interaction coefficients with confidence intervals. Only the two high-spending combinations sit clearly below zero.](/project-dunnhumby/src/02_forest_plot_stage6.png)

*All nine interaction terms with intervals. Seven cross zero; the two that do not are both in the high-spending tier, and both point downward.*

**The sign is the opposite of the pooled comparison.** The pooled view showed gains in every tier; the fixed-effects model shows *reductions* in the high tier and nothing at all in the low tier — **TypeC × low-spending returns p = 0.163**, despite that being the cell where the uncontrolled +242% came from.

That reversal is the clearest evidence in this analysis that household fixed effects removed real selection bias rather than merely shrinking estimates.

### After multiple-comparison correction (Benjamini-Hochberg)

Nine combinations were tested simultaneously, so FDR control applies.

| Rank | Combination | raw p | BH threshold | p-adjusted | Verdict |
| ---: | ----------- | ----: | -----------: | ---------: | ------- |
| 1 | **TypeC × High-spending** | 0.000371 | 0.00556 | **0.0033** | ✅ Survives |
| 2 | TypeB × High-spending | 0.011832 | 0.01111 | 0.0532 | ❌ Fails, narrowly |

![Benjamini-Hochberg correction plot showing raw p-values against the rank-based threshold line. One point falls below the line and one sits just above it.](/project-dunnhumby/src/03_bh_correction.png)

*Benjamini-Hochberg thresholds. TypeB × high-spending misses by a small margin — close enough to report as exploratory, not close enough to claim.*

> **One of nine combinations is statistically stable: TypeC × high-spending.** TypeB × high-spending misses the threshold by a small margin and is downgraded to an **exploratory signal** rather than reported as a finding.

### Robustness — first exposure vs repeat exposure

With 30 campaigns rolling out across weeks 33–101, this is a **staggered adoption** design, where households already treated by earlier campaigns can be wrongly used as controls for later ones — a known source of bias in two-way fixed effects.

Splitting the TypeC × high-spending effect by exposure history:

| | Households | β | p |
| --- | --: | -: | -: |
| First exposure | 295 | −4.89 | 0.009 |
| Repeat exposure | 131 | −9.09 | 0.003 |

> **These two counts are nested, not additive.** 295 is every high-tier TypeC recipient — matching the tier decomposition of the 397 TypeC recipients overall (28 low + 74 mid + 295 high). 131 of those 295 received TypeC more than once; the other 164 received it exactly once. The split is applied to **week-level observations of the same households**, so adding 295 and 131 would double-count.

Both splits remain significant, so the headline result is **not an artifact of repeat-exposure households dominating the estimate**. Whether the larger repeat-exposure effect reflects a learning effect (discount-waiting behaviour reinforced by repetition) or targeting bias (campaigns repeatedly concentrated on households already declining) cannot be separated here.

---

## 5. ❓ Can We Call It Causal?

> **No.**

A placebo test was run on the **916 households that received no campaigns at all**, comparing the same high-tier late-period pattern. If the effect appears there too, it is not the campaign.

| | β | p | 95% CI | n |
| --- | -: | -: | ------ | -: |
| **Actual** — TypeC × high-spending | −6.25 | 0.0004 | ≈ (−9.7, −2.8) | 295 |
| **Placebo** — high-spending × late period | −4.74 | 0.261 | **(−13.00, +3.52)** | **49** |

![Comparison of the actual TypeC high-spending effect against the placebo estimate, with the placebo confidence interval wide enough to span zero, the actual effect, and twice the actual effect.](/project-dunnhumby/src/04_placebo_comparison.png)

*Actual against placebo. The placebo interval is wide enough to contain every answer at once — which is the finding, not a failure to read it.*

**The placebo test cannot decide anything.** With only 49 comparison households, the confidence interval is wide enough to contain zero, the actual effect (−6.25), *and* twice the actual effect (−13.0) simultaneously.

The clearest evidence that the placebo itself is unstable: computing it descriptively gives −1.0%, while the regression gives −4.74. Two methods on the same question disagreeing that sharply is a sample-size problem, not a result.

### Two explanations the data cannot separate

| | Explanation |
| --- | --- |
| **1** | TypeC coupons induce discount-waiting behaviour, genuinely reducing spend in that week |
| **2** | The company concentrated TypeC on high-spending households whose spending was *already* declining — the campaign is a response to the trend, not its cause |

### Why the design cannot rule explanation 2 out

**Parallel trends are not cleanly satisfied.** A pre-campaign test on weeks 17–32:

| Sample | Interaction coefficient | p | Verdict |
| ------ | ----------------------: | -: | ------- |
| Full sample | 0.296 | 0.087 | Passes at 5%, borderline at 10% |
| Low tier | 0.025 | 0.764 | Clean |
| Mid tier | 0.308 | 0.053 | Borderline — just under 5% |
| High tier | 0.333 | 0.613 | Passes, but only 49 comparison households — the test has little power |

Only the low tier is genuinely clean. The high tier — exactly where the result lives — has too few comparison households for "passing" to mean much.

**The targeting rule is unknown.** Nothing in the data records how the company selected campaign recipients, so *"why did this household receive this campaign at this moment"* is unanswerable. This is the root cause of the placebo test's failure.

**Small samples recur throughout.** Low-tier × TypeC has 28 households; the high-tier placebo comparison group has 49. The same instability pattern appears at every point where a subgroup conclusion is needed.

**Observational data.** Household and week fixed effects plus a placebo test control a great deal, but none of it substitutes for randomized assignment.

---

## ✅ Final Conclusion

Of nine campaign-type × spending-tier combinations, **one — TypeC × high-spending — shows a statistically stable association after multiple-comparison correction** (β = −6.25, roughly −8.6% against baseline, BH-adjusted p = 0.0033, n = 295, robust to first- versus repeat-exposure splitting).

Whether that association reflects a campaign *effect* or a campaign *targeting* decision could not be resolved. The placebo test built to distinguish them was too underpowered to do so.

> **Reported as a statistically stable association. Not claimed as a causal effect.**

The most useful output of this analysis may be the negative one: **the naive comparison that suggested campaigns drive +242% gains among light spenders does not survive controlling for who receives campaigns.** Any campaign evaluation built on unadjusted before/after comparisons in this dataset would reach the wrong conclusion, in the wrong direction, in every tier.

---

## 🛠 Tools & Skills

**Programming & data handling** — Python · pandas · NumPy · linearmodels

**Causal & panel methods** — Two-Way Fixed Effects · Household Fixed Effects · Week Fixed Effects · Clustered Standard Errors · Parallel-Trends Pre-Testing · Placebo Testing · Staggered-Adoption Robustness Checks · Interaction-Term Modeling

**Statistics** — Benjamini-Hochberg FDR Correction · F-test for Poolability · VIF Multicollinearity Diagnostics · Confidence-Interval Interpretation · Power Assessment

**Practices** — Circular-definition prevention through pre-period tier fixing · Selection-bias diagnosis via reach comparison · Cell-size verification before subgroup inference · Reporting association separately from causation
