# Tableau 仪表板搭建指南

> 把 Python 分析结果变成**交互式可视化仪表板**——面试时可以直接展示链接或截图。

---

## 数据准备

将以下文件导入 Tableau：
- `data/Superstore_Cleaned.csv` — 主数据集
- `data/Superstore_RFM.csv` — 客户 RFM 分群（可选，用于客户分析页）

Tableau 可以直接读取 CSV，拖拽即可。

---

## 建议搭建的仪表板（3 页）

### 📄 第 1 页：销售总览 (Executive Dashboard)

**受众**: 管理层 | **目标**: 一眼看清全局

| 图表 | 类型 | Tableau 操作 |
|------|------|-------------|
| KPIs（总销售额、总利润、利润率、订单量） | 数字卡片 | 拖 Sales → 文本，Profit → 文本，创建计算字段 `SUM(Profit)/SUM(Sales)*100` |
| 月度销售趋势 | 折线图 | 列：Order Date (连续/月)，行：SUM(Sales)，颜色：SUM(Profit) |
| 品类占比 | 饼图/环形图 | 标记：Category，角度：SUM(Sales) |
| 区域地图 | 填充地图 | 双击 State → 自动生成地图，颜色：SUM(Sales) |

### 📄 第 2 页：产品分析 (Product Deep Dive)

| 图表 | 类型 | 操作 |
|------|------|------|
| 子品类销售排名 | 条形图 | 行：Sub-Category，列：SUM(Sales)，排序降序 |
| 品类利润树状图 | 矩形树图 | 拖 Category + Sub-Category，大小：Sales，颜色：Profit |
| 折扣 vs 利润率散点 | 散点图 | 列：Discount，行：Profit Margin (计算字段)，颜色：Category |
| 子品类利润率热力图 | 突出显示表 | 行：Sub-Category，列：Region，颜色：AVG(Profit Margin) |

### 📄 第 3 页：客户分析 (Customer Analytics)

| 图表 | 类型 | 操作 |
|------|------|------|
| RFM 客群数量分布 | 条形图 | 如导入了 RFM 数据，行：Segment，列：COUNT(Customer ID) |
| 客群收入贡献 | 堆积条形图 | 列：Region，行：SUM(Monetary)，颜色：Segment |
| 客单价分布 | 直方图 | 列：AVG(Sales per Order)，行：COUNT(Customer) |
| 客户分群 × 区域矩阵 | 交叉表 | 行：Segment，列：Region，标记：SUM(Monetary) |

---

## 重点计算字段

在 Tableau 中创建以下计算字段，让仪表板更专业：

```tableau
-- 1. 利润率
SUM([Profit]) / SUM([Sales]) * 100

-- 2. YoY 增长
(SUM([Sales]) - LOOKUP(SUM([Sales]), -12)) / ABS(LOOKUP(SUM([Sales]), -12)) * 100

-- 3. 折扣层级
IF [Discount] = 0 THEN 'No Discount'
ELSEIF [Discount] <= 0.1 THEN 'Low'
ELSEIF [Discount] <= 0.3 THEN 'Medium'
ELSE 'High'
END

-- 4. 是否盈利
IF [Profit] > 0 THEN 'Profitable' ELSE 'Loss' END

-- 5. 每订单平均价值
SUM([Sales]) / COUNTD([Order ID])
```

---

## 快速美化技巧

1. **配色**: 统一使用一个调色板（建议 Tableau 内置的 "Tableau 10" 或 "Color Blind 10"）
2. **字体**: 标题用 14pt Bold，轴标签 10pt Regular
3. **布局**: 
   - 顶部放 KPI 数字卡片（一行 4 个）
   - 中间放主图表（占 60% 面积）
   - 底部/侧边放辅助图表
4. **交互**: 
   - 设置筛选器联动（点击区域 → 其他图表自动过滤）
   - 添加工具提示（悬浮显示详细信息）
   - 使用"用作筛选器"功能

---

## 导出 & 分享

1. **Tableau Public**（免费）: 
   - 下载 [Tableau Public](https://public.tableau.com/)
   - 发布仪表板 → 获得公开链接
   - 链接直接放在简历上 📌

2. **截图**：
   - 导出为 PNG/PDF → 放入 `reports/` 目录
   - 关键页面截图放在 README 中

3. **Power BI 替代**：
   - 如果你更熟悉 Power BI，同样的逻辑可以用 Power BI 实现
   - 免费版 Power BI Desktop 即可完成

---

## 面试时怎么说

> "除了 Python 分析，我还用 Tableau 搭建了交互式仪表板。管理层可以直接看到各个维度的数据——点击某个区域，所有图表自动联动过滤。仪表板已发布到 Tableau Public，这是链接..."

**效果**: 证明了你能把分析结果**产品化、可视化交付**，而不只是交一份 Notebook。
