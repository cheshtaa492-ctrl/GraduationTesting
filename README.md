# Mortality Graduation & Term Assurance Pricing Model

A self-contained project simulating a mortality experience study, applying and statistically validating two graduation (smoothing) techniques, and using the results to price a term assurance product — demonstrating the practical, financial consequence of using raw versus graduated mortality data.

**Tools:** R (simulation, graduation, statistical testing), Excel (premium pricing, EPV calculations)

---

## 1. Objective

Raw ("crude") mortality experience is always subject to random sampling noise — the number of deaths observed at any given age is a random outcome, not a fixed truth. Actuaries address this through **graduation**: fitting a smooth curve through noisy crude rates to recover a more reliable estimate of the underlying mortality pattern.

This project:
1. Simulates a realistic mortality experience study with genuine sampling noise
2. Applies two independent graduation techniques and validates each statistically
3. Uses both the crude and graduated rates to price an actual insurance product, showing that graduation isn't just a smoothing exercise — it materially affects pricing outcomes

---

## 2. Methodology

### 2.1 Simulating the experience

- **Age range:** 20 to 60 (41 single ages)
- **Central exposed-to-risk (Ex):** simulated as a geometrically tapering population, starting at 1,000 lives at age 20 and decaying at a rate of 0.95 per age (`Ex = 1000 × 0.95^(age−20)`), mimicking a shrinking cohort with thin exposure at older ages — exactly the condition that makes crude rates at high ages unreliable
- **True force of mortality (μx):** defined by a Gompertz–Makeham law, `μx = a + b·c^x`
- **Deaths simulated via the Binomial model:** the force of mortality was first converted to an annual mortality probability using the standard CS2 relationship `qx = 1 − e^(−μx)` (valid under the assumption that μx is constant over the year of age), and deaths were then drawn as `deaths ~ Binomial(Ex, qx)` — reflecting genuine random variation in who actually dies each year, rather than a deterministic count
- **Reproducibility:** a fixed random seed was used so results are exactly repeatable

### 2.2 Crude mortality rates

Crude central rate at each age was calculated directly as:

```
crude_mortality = deaths / Ex
```

As expected, crude rates were visibly jagged across ages, with volatility increasing at older ages where exposure (Ex) was thinnest — illustrating why raw experience data is not used directly for pricing or reserving in practice.

### 2.3 Graduation methods

Two independent graduation approaches were applied and compared:

**a) Weighted parametric graduation**
The Makeham formula was refit directly to the crude rates using nonlinear least squares (`nls()` in R), weighted by exposure (Ex) at each age so that ages with more reliable data (larger exposure) are trusted more heavily in the fit.

**b) Graphical / spline graduation**
A weighted cubic smoothing spline (`smooth.spline()`) was fitted to the crude rates with no assumed functional form, as a non-parametric alternative to the parametric fit.

---

## 3. Statistical Validation

Both graduations were tested using the standard CS2 suite of tests, comparing observed deaths against expected deaths under each fitted curve.

| Test | Weighted (Parametric) | Spline |
|---|---|---|
| **Chi-square statistic** | 46.63 | 4.27 |
| **Critical value** (df = 38, 5% level) | 53.38 | 53.38 |
| **Result** | Passes (statistic < critical value) | Passes |
| **Signs test** (positive : negative deviations) | 20 : 21 | 21 : 20 |
| **Signs test p-value** | 1.00 | 1.00 |
| **Max cumulative deviation** | 0.0332 | 0.0509 |

**Interpretation:**
- Both graduations pass the chi-square goodness-of-fit test, indicating the smoothed rates are statistically consistent with the observed mortality experience.
- The signs test shows an almost perfectly balanced split of positive/negative deviations for both methods, confirming no systematic directional bias.
- The spline's chi-square statistic (4.27) is notably lower than the parametric fit's (46.63). This is expected: splines are highly flexible and can track the crude data closely, which produces a very low chi-square statistic almost by construction — it does not necessarily mean the spline is a "better" graduation, since it has less structural/theoretical grounding than the parametric fit. This trade-off (flexibility vs. theoretical justification) is a known consideration when choosing between graduation methods in practice.

*(Note: the chi-square test was run without clubbing thin age groups — i.e., without combining ages where expected deaths fall below the conventional threshold of 5 into single groups before testing. This is a simplification; a more rigorous implementation would club such groups before computing the test statistic and adjust the degrees of freedom accordingly.)*

---

## 4. From Graduation to Pricing: Term Assurance Premiums

To demonstrate the real-world consequence of graduation, the crude and graduated rates were each used to price a **10-year term assurance** policy (sum assured payable on death within the term) at 31 different starting ages (20 to 50), using the standard actuarial equivalence principle.

### 4.1 Approach

For each starting age *x* and fixed term *n* = 10:

- **Assurance factor** Ax:n̄| — expected present value of £1 payable on death within the term, derived from central exposed-to-risk and the mortality rate (crude or graduated) at each age
- **Annuity-due factor** äx:n̄| — expected present value of £1 payable at the start of each year the policyholder survives, over the same term
- **Net annual premium** — calculated via the equivalence principle: `Premium = (Sum Assured × Ax:n̄|) / äx:n̄|`

This was computed independently using crude mortality, the weighted-graduated mortality, and the spline-graduated mortality, at every starting age from 20 to 50.

### 4.2 Key finding

Premiums calculated from **crude** mortality rates were inconsistent across ages in a way that doesn't reflect genuine differences in risk — purely an artifact of sampling noise in a given age's observed deaths. Premiums calculated from **graduated** rates rose smoothly and consistently with age, as a real premium schedule should.

- **Largest single-age discrepancy:** at age 36, the crude-based premium was **10.6% higher** than the graduated (weighted) premium — a difference driven entirely by that age's random death count, not by any real underlying mortality difference
- **Average absolute deviation** between crude and graduated premiums across all 31 starting ages: **~3.9%**

This is the central practical insight of the project: **graduation is not merely a statistical smoothing exercise — pricing directly off ungraduated crude rates would expose an insurer to inconsistent, unjustifiable premiums driven by sampling noise rather than genuine risk differences.**

---

## 5. Limitations & Future Work

- **No clubbing of thin age groups** before the chi-square test (see Section 3) — a methodological simplification disclosed here rather than corrected, in the interest of transparency.
- **Single simulation run** (fixed seed) — repeating the simulation across many seeds would give a distribution of test outcomes and premium deviations, rather than one realization, and would be a natural robustness check.
- **Synthetic data** — the project uses simulated rather than real mortality data, chosen specifically so the "true" underlying law is known and graduation performance can be judged directly against it. A natural extension is to apply the same pipeline to real published mortality data (e.g., the Human Mortality Database).
- **Planned extensions:** a proportional hazards / survival analysis component, and porting the simulation and graduation pipeline to Python (NumPy/pandas) for comparison.

---

## 6. Repository Structure

```
├── graduation_testing.R       # Full R script: simulation, graduation, statistical tests
├── graduation_data.csv        # Exported simulation results (ages, exposure, deaths, crude &
│                                 graduated rates, test statistics)
├── graduation_data.xlsx        # Premium pricing workbook (assurance/annuity factors, EPV of
│                                 benefits, premium comparison by age)
└── README.md                   # This file
```

---

## 7. Summary

This project demonstrates, end to end, a core actuarial technique: starting from noisy simulated mortality experience, applying and statistically validating graduation methods (per CS2 methodology), and carrying the graduated rates through to an actual pricing calculation (per CM1 methodology). The 10.6% premium discrepancy found at age 36 is a concrete illustration of why graduation matters in practice, not just in theory.
