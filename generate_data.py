"""
生成模拟的 Superstore 销售数据集
包含完整的业务逻辑：季节性趋势、折扣影响、地域差异等
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

np.random.seed(42)
random.seed(42)

# ==================== 配置 ====================
N_ROWS = 5000
DATE_START = datetime(2020, 1, 1)
DATE_END = datetime(2023, 12, 31)

# ==================== 维度数据 ====================
categories = {
    'Furniture': ['Bookcases', 'Chairs', 'Tables', 'Furnishings'],
    'Office Supplies': ['Appliances', 'Art', 'Binders', 'Envelopes',
                         'Fasteners', 'Labels', 'Paper', 'Storage', 'Supplies'],
    'Technology': ['Accessories', 'Copiers', 'Machines', 'Phones'],
}

regions = {
    'West': ['California', 'Washington', 'Oregon', 'Arizona', 'Colorado', 'Utah'],
    'East': ['New York', 'Massachusetts', 'Pennsylvania', 'New Jersey', 'Connecticut'],
    'Central': ['Illinois', 'Ohio', 'Michigan', 'Indiana', 'Wisconsin', 'Minnesota'],
    'South': ['Texas', 'Florida', 'Georgia', 'North Carolina', 'Virginia', 'Tennessee'],
}

ship_modes = ['Standard Class', 'Second Class', 'First Class', 'Same Day']
segments = ['Consumer', 'Corporate', 'Home Office']

# 产品价格范围
product_prices = {
    'Bookcases': (100, 500), 'Chairs': (50, 800), 'Tables': (150, 2000),
    'Furnishings': (20, 300),
    'Appliances': (30, 600), 'Art': (5, 50), 'Binders': (3, 30),
    'Envelopes': (2, 15), 'Fasteners': (1, 10), 'Labels': (2, 20),
    'Paper': (5, 40), 'Storage': (10, 100), 'Supplies': (2, 25),
    'Accessories': (10, 300), 'Copiers': (500, 5000), 'Machines': (100, 3000),
    'Phones': (50, 1000),
}

# ==================== 生成数据 ====================

# 1. 产品列表
products = []
product_id = 1
for cat, subs in categories.items():
    for sub in subs:
        for i in range(1, 6):  # 每个子类别5个产品
            products.append({
                'Product ID': f'FUR-{cat[:3].upper()}-{product_id:04d}',
                'Category': cat,
                'Sub-Category': sub,
                'Product Name': f'{sub} Model {i}',
                'base_price': np.random.uniform(*product_prices[sub]),
            })
            product_id += 1

df_products = pd.DataFrame(products)

# 2. 客户列表（回头客会多次下单）
n_customers = 400
customers = []
for i in range(n_customers):
    region = random.choice(list(regions.keys()))
    state = random.choice(regions[region])
    seg = random.choice(segments)
    customers.append({
        'Customer ID': f'CG-{i+1:05d}',
        'Customer Name': f'Customer {i+1}',
        'Segment': seg,
        'Region': region,
        'State': state,
        'Country': 'United States',
    })
df_customers = pd.DataFrame(customers)

# 3. 订单 & 交易明细
orders = []
order_id_counter = 1
row_id = 1

# 订单数 (~1200 个订单)
n_orders = 1200

for _ in range(n_orders):
    order_date = DATE_START + timedelta(
        days=random.randint(0, (DATE_END - DATE_START).days)
    )
    # 季节性：Q4 订单更多
    month = order_date.month
    if month in [11, 12]:
        if random.random() < 0.5:
            continue  # 跳过一些订单让Q4密度更高已经体现在分布里
    # 实际上让Q4订单更密集
    if month in [11, 12]:
        if random.random() < 0.3:
            # 额外增加Q4订单
            pass

    ship_days = {'Standard Class': 5, 'Second Class': 3, 'First Class': 1, 'Same Day': 0}
    ship_mode = random.choices(
        ship_modes, weights=[0.4, 0.25, 0.25, 0.1], k=1
    )[0]
    ship_date = order_date + timedelta(days=ship_days[ship_mode] + random.randint(0, 2))

    customer = df_customers.sample(1).iloc[0]

    # 一个订单可能有多行（不同产品）
    n_lines = random.choices([1, 2, 3, 4, 5], weights=[0.5, 0.25, 0.15, 0.07, 0.03], k=1)[0]

    order_id = f'US-{order_id_counter:04d}'

    for _ in range(n_lines):
        product = df_products.sample(1).iloc[0]
        quantity = random.choices([1, 2, 3, 4, 5], weights=[0.4, 0.3, 0.15, 0.1, 0.05], k=1)[0]
        base_price = product['base_price']

        # 折扣逻辑：Technology 折扣少，Furniture 折扣多
        discount_rates = {
            'Technology': [0, 0, 0, 0.1, 0.2],
            'Furniture': [0, 0, 0.1, 0.2, 0.3],
            'Office Supplies': [0, 0, 0.05, 0.1, 0.15],
        }
        discount = random.choice(discount_rates[product['Category']])

        sales = base_price * quantity * (1 - discount)
        # 利润：Technology 利润率高，Furniture 利润率低，部分可能亏损
        profit_margins = {
            'Technology': (0.1, 0.5),
            'Furniture': (-0.05, 0.25),
            'Office Supplies': (0.05, 0.35),
        }
        margin = np.random.uniform(*profit_margins[product['Category']])
        profit = sales * margin

        # 高折扣导致负利润
        if discount > 0.2:
            profit = profit * 0.5 - np.random.uniform(0, 50)

        orders.append({
            'Row ID': row_id,
            'Order ID': order_id,
            'Order Date': order_date.strftime('%Y-%m-%d'),
            'Ship Date': ship_date.strftime('%Y-%m-%d'),
            'Ship Mode': ship_mode,
            'Customer ID': customer['Customer ID'],
            'Customer Name': customer['Customer Name'],
            'Segment': customer['Segment'],
            'Country': 'United States',
            'City': customer['State'],  # 简化
            'State': customer['State'],
            'Postal Code': f'{random.randint(10000, 99999)}',
            'Region': customer['Region'],
            'Product ID': product['Product ID'],
            'Category': product['Category'],
            'Sub-Category': product['Sub-Category'],
            'Product Name': product['Product Name'],
            'Sales': round(sales, 2),
            'Quantity': quantity,
            'Discount': discount,
            'Profit': round(profit, 2),
        })
        row_id += 1

    order_id_counter += 1

df = pd.DataFrame(orders)

# 确保 Sales、Profit 合理
df['Sales'] = df['Sales'].clip(lower=0.5)
df = df.sort_values('Order Date').reset_index(drop=True)
df['Row ID'] = range(1, len(df) + 1)

# ==================== 保存 ====================
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
df.to_csv(os.path.join(script_dir, 'data', 'Sample_Superstore.csv'), index=False)
print(f'[OK] Dataset generated: {len(df)} rows, {df["Order ID"].nunique()} orders')
print(f'[DATE] Range: {df["Order Date"].min()} ~ {df["Order Date"].max()}')
print(f'[SALES] Total Sales: ${df["Sales"].sum():,.0f}')
print(f'[PROFIT] Total Profit: ${df["Profit"].sum():,.0f}')
print(f'\nPreview:')
print(df.head(3).to_string())
print(f'\nColumns: {list(df.columns)}')
