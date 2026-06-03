# Superstore 销售数据分析项目

> 🎯 **定位**: 数据分析岗位求职作品集项目 #1  
> 🛠️ **技术栈**: Python (Pandas, Matplotlib, Seaborn, Plotly) + SQL + Tableau

---

## 项目概述

基于美国 Superstore 4 年销售数据（2020-2023），从**数据清洗 → 探索性分析 → 客户分群 → 业务建议**的完整分析流程，展示从原始数据到商业洞察的全链路能力。

### 核心业务问题

| # | 问题 | 分析维度 |
|---|------|---------|
| 1 | 公司整体经营状况如何？ | 销售额、利润、同比增长趋势 |
| 2 | 哪些产品/品类贡献最大利润？ | 品类 & 子品类帕累托分析 |
| 3 | 哪个区域/州表现最好/最差？ | 地理热力图、区域对比 |
| 4 | 折扣策略是否有效？ | 折扣 vs 利润率散点分析 |
| 5 | 谁是我们的高价值客户？ | RFM 模型客户分群 |
| 6 | 什么运输方式最受欢迎？ | 运输方式分布 & 时效分析 |

---

## 项目结构

```
superstore-analysis/
├── README.md                          # 本文件
├── requirements.txt                   # Python 依赖
├── generate_data.py                   # 数据生成脚本
├── data/
│   └── Sample_Superstore.csv          # 数据集 (~2000 行交易记录)
├── notebooks/
│   ├── 01_data_cleaning.ipynb         # 数据清洗 & 预处理
│   ├── 02_eda.ipynb                   # 探索性数据分析
│   └── 03_rfm_analysis.ipynb          # RFM 客户分群
├── sql/
│   └── analysis_queries.sql           # 等效 SQL 分析查询
├── tableau/
│   └── dashboard_guide.md             # Tableau 仪表板搭建指南
└── reports/                           # 最终报告（PPT/PDF）
```

---

## 快速开始

```bash
# 1. 安装依赖
pip install -r requirements.txt

# 2. 生成数据（如 data/ 目录为空）
python generate_data.py

# 3. 启动 Jupyter
jupyter notebook notebooks/
```

---

## 关键发现（示例结论）


1. **Technology 品类贡献了 ~35% 的利润**，但只占 ~25% 的销售额——高利润率的品类值得重点投入
2. **高折扣 (>20%) 的订单中，15% 出现亏损**——折扣策略需要优化
3. **RFM 分析识别出 Top 20% 客户贡献了 ~60% 收入**——精准营销机会明显
4. **Same Day 运输虽然占比小，但客户复购率最高**

