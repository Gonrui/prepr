# prepkit: Robust preprocessing for Digital Health <img src="man/figures/logo.png" align="right" height="139" />


[![CRAN status](https://www.r-pkg.org/badges/version/prepkit)](https://CRAN.R-project.org/package=prepkit)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/prepkit)](https://CRAN.R-project.org/package=prepkit)
[![R-CMD-check](https://github.com/Gonrui/prepkit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Gonrui/prepkit/actions)
[![Codecov test coverage](https://codecov.io/gh/Gonrui/prepkit/branch/main/graph/badge.svg)](https://codecov.io/gh/Gonrui/prepkit)
[![Documentation](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://gonrui.github.io/prepkit/)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Full Documentation & Tutorials:** [https://gonrui.github.io/prepkit/](https://gonrui.github.io/prepkit/)


> **"When Z-Score fails, use M-Score."**

**`prepkit`** is a comprehensive R package designed for the preprocessing of longitudinal behavioral data, with a specific focus on **gerontology, digital health, and sensor analytics**.

Its flagship feature is the **M-Score (Mode-Range Normalization)**, a novel algorithm designed to detect anomalies in data characterized by "habitual plateaus" (e.g., daily step counts, heart rate), where traditional methods like Z-Score or Min-Max scaling often fail due to skewed distributions and high-frequency routine noise.

## 📦 Installation

`prepkit` is rigorously tested on **Linux, macOS, and Windows**, with compatibility verified up to **R 4.5 (development version)**.

Install the stable version from CRAN:

```r
install.packages("prepkit")
```

You can install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("Gonrui/prepkit")
```

## 🚀 Key Algorithms

| Function | Algorithm / Description | Use Case |
| :--- | :--- | :--- |
| **`norm_mode_range`** | **M-Score (New!)** | Detects frailty/falls in elderly behavioral data by suppressing routine noise. |
| **`trans_boxcox`** | **Robust Box-Cox** | MLE-optimized power transform. Auto-handles non-positive values. |
| **`trans_yeojohnson`**| **Yeo-Johnson** | Power transform natively supporting negative values. |
| **`norm_l2`** | **Spatial Sign** | Projects data onto a unit hypersphere (L2 Norm). Ideal for high-dim clustering. |
| **`pp_plot`** | **Density Visualizer** | Instant "Before vs. After" visualization for normality checks. |

## 📊 Quick Start: The Power of M-Score

Real-world sensor data often contains **routine plateaus** (e.g., an older adult consistently walking 3000 steps) and **sensor noise** (floating-point jitter).

**M-Score** handles both elegantly:

```r
library(prepkit)

# 1. Simulate Sensor Data
# - Routine: ~3000 steps (with sensor jitter like 3000.1, 2999.9)
# - Anomaly: 200 steps (Fall/Frailty)
# - Anomaly: 6000 steps (Hyperactivity)
steps <- c(3000.1, 3000.2, 2999.8, 200.0, 3000.0, 6000.0)

# 2. Apply M-Score (with precision protection)
# The 'digits' parameter rounds values internally to identify the semantic mode,
# while preserving the precision of the anomalies.
m_scores <- norm_mode_range(steps, digits = 0)

# 3. View Results
print(data.frame(Raw = steps, M_Score = m_scores))
```

## 📐 Mathematical Foundation

The M-Score transforms data based on its **Mode Interval** (the routine plateau). Unlike Z-Score which penalizes stability (low variance), M-Score treats the most frequent range as the "Safe Zone" (Score = 0).

The transformation function $M(x)$ is defined as:

$$
M(x) = 
\begin{cases} 
   -\frac{k_L - x}{k_L - k_{min}} & \text{if } x < k_L \quad (\text{Left Tail / Frailty}) \\ 
   0 & \text{if } k_L \le x \le k_R \quad (\text{Routine Plateau}) \\ 
   \frac{x - k_R}{k_{max} - k_R} & \text{if } x > k_R \quad (\text{Right Tail / Hyper}) 
\end{cases}
$$

*Validated via symbolic computation (Wolfram Mathematica) for strict monotonicity.*

## 📚 Citation

If you use `prepkit` or the M-Score algorithm in your research, please cite:

> **Gong, R. (2026).** M-Score: A Robust Normalization Method for Detecting Anomalies in Longitudinal Behavioral Data. *arXiv preprint*.

## 📄 License

MIT © Rui Gong (Tokyo Metropolitan Institute of Gerontology)
