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
- 状态: CRAN 提交准备完成 (2026-01-20)

## 最近更新
### 2026-01-20: CRAN 提交准备完成
- 修正 DESCRIPTION 符合 CRAN 标准（添加 DOI 引用，移除冗余词）
- 完成本地全面检查（R CMD check: 0/0/0）
- 重建 pkgdown 网站并添加网站 URL
- 更新拼写词典和构建忽略规则
- 生成最终提交包 `prepkit_0.1.0.tar.gz`
