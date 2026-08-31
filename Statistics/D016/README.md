# 🍔 Fast-Food Promotion Experiment Analysis

## 📌 Overview

A fast-food chain planned to introduce a new menu item and tested three different promotional strategies across multiple stores.

The company had not yet determined which promotion was the most effective. Each store was assigned one of three promotions, and sales data was collected over a four-week period.

This project evaluates whether the promotional strategies produced statistically significant differences in sales and provides a data-driven recommendation for the business.

---

# 🎯 Business Question

> **Which of the three promotional strategies generated the strongest sales performance?**

More specifically:

* Did average sales differ significantly between the three promotions?
* Which promotion performed significantly better or worse than the others?
* Could differences in market characteristics explain the results?
* Were the findings robust to outliers and multiple statistical tests?

---

# 📊 Dataset

### Data Source

This project uses the Fast Food Marketing Campaign A/B Test dataset obtained from Kaggle.

Source: Kaggle
Dataset: Fast Food Marketing Campaign A\B Test

The dataset contains sales observations from multiple fast-food restaurant locations assigned to one of three promotional campaigns over a four-week period.

This dataset was used for educational and portfolio purposes. The analysis, statistical methodology, interpretations, and business recommendations presented in this project are my own.

### Dataset Size

* **548 observations**
* **7 variables**
* **137 stores**
* **4 weeks of sales data per store**

Each store was assigned a single promotion and observed for four weeks.

### Key Variables

| Variable           | Description                                             |
| ------------------ | ------------------------------------------------------- |
| `MarketID`         | Geographic market where stores are located              |
| `LocationID`       | Individual store identifier                             |
| `MarketSize`       | Market size category (Small, Medium, Large)             |
| `Promotion`        | Promotional strategy assigned to the store (1, 2, or 3) |
| `Week`             | Observation week                                        |
| `SalesInThousands` | Weekly sales revenue in thousands of dollars            |
| `AgeOfStore`       | Store age                                               |

Although `Promotion` was stored numerically as `1`, `2`, and `3`, it was treated as a **categorical variable** during the analysis.

---

# 🔍 Data Quality Checks

The dataset was examined before conducting statistical tests.

### Validation Results

* Missing values: **0**
* Duplicate rows: **0**
* Duplicate store-week observations: **0**
* Stores assigned to multiple promotions: **0**
* Stores assigned to multiple markets: **0**
* Each store contained the expected **4 weeks of observations**

These checks confirmed that the experimental structure was internally consistent.

---

# 🎲 Sample Ratio Mismatch (SRM) Check

Because the experiment was assigned at the **store level**, SRM was evaluated using the 137 unique stores rather than the 548 weekly observations.

Each store was collapsed into a single experimental assignment record for this check.

### Result

**p = 0.8898**

The observed allocation was consistent with what could reasonably occur under random assignment.

> **Conclusion: No evidence of Sample Ratio Mismatch (SRM).**

---

# 🔎 Outlier Analysis

Outliers were examined using the **IQR method**.

Most high-value observations were concentrated in:

* `MarketID = 3`
* `MarketSize = Large`

This suggested that many apparent outliers reflected genuine differences in market characteristics rather than data errors.

One store required additional investigation:

### Store `LocationID = 507`

One weekly observation showed unusually low sales compared with other stores.

Possible explanations included:

1. Data entry error
2. A genuine temporary decline caused by operational factors such as inventory shortages, temporary closure, or other unobserved events

The observation was retained because:

* Only one weekly observation was unusually low
* There was no clear evidence of a data-entry error
* The value was not extreme enough to justify automatic removal
* A later sensitivity analysis was conducted to evaluate its impact

---

# ⚠️ Independence of Observations

The original dataset contained four weekly observations for each store.

This creates a potential violation of the independence assumption because sales from the same store across multiple weeks are likely correlated.

For example:

> A store with high sales in Week 1 is likely to have relatively high sales in Week 2.

Two approaches were considered:

### Option 1 — Aggregate Sales by Store

Calculate the average sales across four weeks for each store.

* One observation per store
* 137 independent store-level observations
* Suitable for One-Way ANOVA

### Option 2 — Repeated Measures ANOVA / Mixed Effects Model

Preserve weekly observations while modeling within-store correlation.

This approach retains more temporal information but requires a more complex modeling framework.

---

# 📅 Does Week Affect Sales?

Before aggregating the data, the potential effect of week was examined.

### Result

**p = 0.9935**

There was no evidence that the observation week significantly affected sales.

Additionally, the analysis showed that:

> **Between-store variation was approximately 3.4 times larger than within-store weekly variation.**

This suggested that weekly variation contributed relatively little compared with persistent differences between stores.

### Decision

The dataset was aggregated to:

> **One average sales value per store**

This produced **137 store-level observations** for the main analysis.

---

# 📈 Exploratory Distribution Analysis

The overall sales distribution appeared somewhat bimodal.

However, this pattern was largely explained by differences between promotional groups and market characteristics.

Normality was therefore evaluated formally before relying solely on parametric methods.

---

# 🧪 Statistical Hypotheses

### Null Hypothesis (H₀)

> The mean sales are equal across all three promotions.

### Alternative Hypothesis (H₁)

> At least one promotion has a different mean sales level.

### Significance Level

**α = 0.05**

---

# 📊 Normality Check

## Part 1 — Q-Q Plots

The Q-Q plots showed similar overall patterns across the three promotional groups.

However, deviations were observed in the upper tail, largely associated with high-sales stores in large markets.

The distributions were therefore not perfectly normal.

---

## Part 2 — Shapiro-Wilk Test

The Shapiro-Wilk test indicated that the normality assumption was violated.

Rather than relying exclusively on ANOVA, both:

* **One-Way ANOVA**
* **Kruskal-Wallis Test**

were conducted to determine whether the conclusion remained consistent across parametric and non-parametric approaches.

---

# ⚖️ Homogeneity of Variance

Because normality was not fully satisfied, **Levene's Test** was used to evaluate equality of variances.

### Hypotheses

**H₀:** Variances are equal across promotional groups.

**H₁:** At least one group has a different variance.

### Result

**p = 0.6272**

The null hypothesis could not be rejected.

> **Conclusion: The group variances were statistically similar.**

---

# 🧪 One-Way ANOVA

### Result

* **F = 5.8458**
* **p = 0.0037**

The null hypothesis was rejected.

> **Average sales differed significantly between at least two promotional groups.**

However, ANOVA alone does not identify which specific groups differ.

Therefore, a post-hoc comparison was required.

---

# 📊 Kruskal-Wallis Test

Because the normality assumption was violated, a non-parametric robustness check was also performed.

### Result

* **H = 17.3274**
* **p = 0.0002**

With:

* Degrees of freedom = 2
* Critical value at α = 0.05 = **5.9915**

The observed H statistic was substantially larger than the critical value.

> **Conclusion: Sales distributions differed significantly between promotional groups.**

Both ANOVA and Kruskal-Wallis produced the same overall conclusion.

---

# 🔍 Post-Hoc Analysis — Tukey's HSD

Tukey's HSD was used to identify which promotions differed significantly.

## Promotion 1 vs Promotion 2

* Promotion 2 generated approximately **$10,769 lower average weekly sales per store**
* **p = 0.004**
* Cohen's d = **0.706**

> Statistically significant difference with a medium-to-large effect.

---

## Promotion 1 vs Promotion 3

* Promotion 3 generated approximately **$2,734 lower average weekly sales per store**
* **p = 0.6862**
* Cohen's d = **0.169**

> No statistically significant difference.

---

## Promotion 2 vs Promotion 3

* Promotion 3 generated approximately **$8,035 higher average weekly sales per store**
* **p = 0.037**
* Cohen's d = **-0.519**

> Statistically significant difference with a medium effect.

---

# 📏 Effect Size

### Eta Squared (η²)

**η² = 0.0802**

Promotion explained approximately:

> **8% of the variance in store sales.**

Using common interpretation guidelines:

* 0.01 → Small effect
* 0.06 → Medium effect
* 0.14 → Large effect

The promotional effect was therefore approximately **medium in magnitude**.

The remaining variation was likely influenced by factors such as:

* Market size
* Store characteristics
* Store age
* Other unobserved business factors

---

# 🔄 Sensitivity Analysis

The potentially unusual observation from `LocationID = 507` was removed temporarily to evaluate its influence.

### Before Removing the Observation

* F = **5.8458**
* p = **0.0037**

### After Removing the Observation

* F = **5.7780**
* p = **0.0039**

The results changed very little.

> **Conclusion: The outlier did not materially affect the statistical conclusion.**

The original dataset was therefore retained.

---

# 🔍 Could Market Size Explain Promotion 2's Poor Performance?

Promotion 2 produced the lowest average sales.

The next question was whether this result could be explained by biased assignment across different market sizes.

---

## Promotion × Market Size

A statistical test was conducted to evaluate whether promotion assignment was associated with market size.

### Result

**p = 0.8800**

> Promotion assignment and market size appeared statistically independent.

This suggests that Promotion 2 was not disproportionately assigned to weaker or smaller markets.

---

## Promotion × Store Age

Store age was also compared across promotional groups.

### Result

* **F = 0.4499**
* **p = 0.6387**

There was no statistically significant difference in store age across promotions.

---

# 🧮 Two-Way ANOVA

A two-way ANOVA was performed to evaluate the promotion effect while accounting for market size.

### Key Results

* **Market Size: F = 96.13**
* **Promotion: F = 16.03**

Market size had a very strong relationship with sales.

However, the promotional effect remained statistically meaningful after accounting for market size.

> **Conclusion: Market size influenced sales strongly, but it did not explain the poor performance of Promotion 2.**

The evidence suggests that Promotion 2's weaker performance was primarily associated with the promotion itself rather than biased market allocation.

---

# ⚠️ Multiple Testing Robustness Check

Additional analyses were conducted to determine whether the observed findings could be explained by false positives caused by multiple statistical comparisons.

Both methods were used:

* **Bonferroni correction**
* **Benjamini-Hochberg correction**

The results remained statistically significant after correction.

This provides additional confidence that the findings were not simply the result of multiple-testing error.

### Note

The Small Market segment contained only **15 observations**, so conclusions for this segment should be interpreted more cautiously.

---

# 💰 Estimated Revenue Impact of Promotion 2

The difference in average sales was translated into estimated business impact.

## Compared with Promotion 1

* Average weekly difference per store: **approximately $10,770**
* Estimated impact across 47 stores over 4 weeks:

> **≈ $2,024,700 in lower sales**

---

## Compared with Promotion 3

* Average weekly difference per store: **approximately $8,035**
* Estimated impact across 47 stores over 4 weeks:

> **≈ $1,510,600 in lower sales**

These estimates demonstrate that the statistical differences may also be economically meaningful.

---

# 💡 Key Findings

### 🥇 Promotion 2 performed the worst

Promotion 2 generated significantly lower sales compared with both Promotion 1 and Promotion 3.

### 📊 Promotion 1 and Promotion 3 were not significantly different

The overall comparison found:

> **p = 0.6862**

Therefore, the available sales data does not provide strong evidence that one is superior to the other.

### 🏪 Market Size strongly influenced sales

Market size explained substantial variation in sales.

However, the promotion effect remained meaningful after controlling for market size.

### 🔄 Results were robust

The main conclusion remained consistent across:

* ANOVA
* Kruskal-Wallis
* Tukey's HSD
* Sensitivity analysis
* Market size controls
* Multiple-testing corrections

---

# ✅ Business Recommendation

## 🚫 Do Not Continue Promotion 2

Promotion 2 should be paused or reconsidered.

The analysis found:

* Statistically significant underperformance
* Meaningful effect sizes
* No evidence that market size caused the difference
* Consistent results across market segments
* Robustness to potential outliers
* Estimated revenue losses large enough to be economically meaningful

---

## 🤔 Choosing Between Promotion 1 and Promotion 3

Promotion 1 and Promotion 3 did not show a statistically significant difference in sales.

Therefore, the final decision should consider additional factors not available in the dataset, including:

* Promotion implementation cost
* Marketing cost
* Operational complexity
* Inventory requirements
* Logistics burden
* Customer retention
* Long-term sales performance

---

# ⚠️ Limitations

This analysis has several limitations.

### Short Observation Period

The experiment lasted only four weeks.

Long-term effects could not be evaluated.

---

### Weekly Information Was Aggregated

Sales were averaged at the store level to address within-store dependence.

This improved the independence of observations but reduced information about weekly variation.

---

### Missing Cost Information

The dataset contains sales but does not include:

* Promotion costs
* Labor costs
* Marketing expenses
* Operational costs

Therefore, this analysis evaluates **revenue performance**, not full profitability.

---

### Potential Novelty Effects

The short observation period makes it difficult to determine whether the observed effects would persist after the initial novelty of the promotion fades.

Future analysis should examine longer-term sales trends.

---

# 🚀 Future Improvements

Future versions of this analysis could include:

* Mixed-effects models to explicitly account for repeated weekly observations
* Longer observation periods
* Profit and cost data
* Customer-level behavioral analysis
* Customer retention metrics
* Long-term promotion effects
* Interaction effects between promotion and market characteristics

---

# 🛠 Tools & Skills

### Programming & Data Analysis

* Python
* Pandas
* NumPy

### Statistics & Experimentation

* Hypothesis Testing
* A/B Testing
* One-Way ANOVA
* Kruskal-Wallis Test
* Tukey's HSD
* Levene's Test
* Shapiro-Wilk Test
* Effect Size Analysis
* Multiple Testing Correction

### Analytical Methods

* Exploratory Data Analysis (EDA)
* Outlier Analysis
* Sensitivity Analysis
* Confounding Variable Analysis
* Two-Way ANOVA

### Data Visualization

* Matplotlib
* Seaborn

---

# 👤 My Contribution

* Defining the business question
* Validating the experimental dataset
* Checking assignment consistency and SRM
* Identifying potential outliers
* Evaluating statistical assumptions
* Selecting appropriate statistical methods
* Conducting ANOVA and non-parametric robustness checks
* Performing post-hoc comparisons
* Investigating potential confounding variables
* Conducting sensitivity and multiple-testing analyses
* Translating statistical results into estimated business impact
* Developing the final business recommendation

---

# 📌 Final Conclusion

> **Promotion 2 consistently underperformed the other promotional strategies and produced statistically significant and economically meaningful lower sales.**

Promotion 1 and Promotion 3 showed no statistically significant difference in average sales.

Based on the available evidence:

### 🚫 Pause Promotion 2

### ✅ Select between Promotion 1 and Promotion 3 based on operational cost, implementation complexity, and long-term business considerations.
