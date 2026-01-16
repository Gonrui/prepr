# prepkit

R包，用于数据预处理、归一化和变换，针对老年学、数字健康和传感器分析领域。

## 核心算法

**M-Score (众数范围归一化)** - `norm_mode_range()`
- 创新算法，用于检测老年人行为异常（步数变化、跌倒风险等）
- 解决传统方法在"习惯性平台"数据上的失效问题
- 输出范围 [-1, 1]

## 主要函数

### 归一化 (norm_*)
- `norm_mode_range()` - M-Score（核心）
- `norm_zscore()` - Z-Score 标准化
- `norm_minmax()` - 最小-最大缩放
- `norm_robust()` - 鲁棒标准化（中位数-MAD）
- `norm_decimal()` - 小数缩放
- `norm_mean()` - 均值归一化
- `norm_l2()` - L2范数

### 变换 (trans_*)
- `trans_boxcox()` - Box-Cox 幂变换
- `trans_yeojohnson()` - Yeo-Johnson 变换（支持负值）
- `trans_log()` - 对数变换

### 可视化
- `pp_plot()` - 变换前后密度对比图

## 数据集
- `sim_gait_data` - 200天模拟老年人步数数据

## 开发命令

```r
devtools::document()
devtools::check()
devtools::test()
devtools::install()
covr::package_coverage()
```

## 项目信息
- 作者: Rui Gong (东京都老年研究所)
- 许可证: MIT
- 测试覆盖率: 100%
- 目标: 提交 CRAN
