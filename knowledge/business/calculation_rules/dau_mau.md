# DAU/MAU 计算规则

> 本文档详细说明 DAU、WAU、MAU 的计算方法和注意事项。

---

## DAU (Daily Active User)

### 标准计算规则

```sql
SELECT 
    DATE(behavior_time) as date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dwd_user_behavior
WHERE 
    DATE(behavior_time) = '2024-01-01'
GROUP BY 
    DATE(behavior_time);
```

### 使用汇总表（推荐）

```sql
SELECT 
    date,
    dau
FROM 
    dws_user_daily
WHERE 
    date = '2024-01-01';
```

### 按维度细分

```sql
-- 按渠道细分 DAU
SELECT 
    DATE(behavior_time) as date,
    platform as channel,
    COUNT(DISTINCT user_id) as dau
FROM 
    dwd_user_behavior
WHERE 
    DATE(behavior_time) = '2024-01-01'
GROUP BY 
    DATE(behavior_time),
    platform;
```

---

## WAU (Weekly Active User)

### 标准计算规则

```sql
SELECT 
    DATE_TRUNC('week', behavior_time) as week_start,
    COUNT(DISTINCT user_id) as wau
FROM 
    dwd_user_behavior
WHERE 
    DATE(behavior_time) >= '2024-01-01'
    AND DATE(behavior_time) <= '2024-01-07'
GROUP BY 
    DATE_TRUNC('week', behavior_time);
```

### 注意事项
- 一个用户在一周内多次活跃，只计数一次
- 周的定义: 周一到周日（需要确认雪球的周定义）

---

## MAU (Monthly Active User)

### 标准计算规则

```sql
SELECT 
    DATE_TRUNC('month', behavior_time) as month,
    COUNT(DISTINCT user_id) as mau
FROM 
    dwd_user_behavior
WHERE 
    DATE(behavior_time) >= '2024-01-01'
    AND DATE(behavior_time) < '2024-02-01'
GROUP BY 
    DATE_TRUNC('month', behavior_time);
```

### 使用汇总表（推荐）

```sql
SELECT 
    month,
    mau
FROM 
    dws_user_monthly
WHERE 
    month = '2024-01';
```

---

## DAU/MAU 比值（粘性指标）

### 定义
DAU 与 MAU 的比值，反映用户粘性。

### 计算规则
```
DAU/MAU = 月内平均 DAU / MAU
```

### SQL 示例

```sql
WITH daily_data AS (
    SELECT 
        date,
        dau
    FROM 
        dws_user_daily
    WHERE 
        date >= '2024-01-01'
        AND date < '2024-02-01'
),
monthly_data AS (
    SELECT 
        mau
    FROM 
        dws_user_monthly
    WHERE 
        month = '2024-01'
)
SELECT 
    AVG(dd.dau) as avg_dau,
    md.mau,
    ROUND(AVG(dd.dau) / md.mau, 4) as dau_mau_ratio
FROM 
    daily_data dd
CROSS JOIN 
    monthly_data md;
```

### 解读
- 比值越高，用户粘性越强
- 理想值: [待补充行业标准或雪球目标值]

---

## 活跃行为的定义

### 标准活跃行为

根据 `knowledge/business/glossary.md` 中"活跃用户"的定义，活跃行为包括：

- 登录
- 浏览内容
- 发布内容
- 互动行为（点赞、评论、转发、收藏）
- 交易行为
- [补充其他行为]

### 行为权重

**问题**: 是否所有行为权重相同？

**当前规则**: 
- 默认情况下，有任意行为即算活跃，不区分权重
- 如有特殊需求（如只统计深度活跃），需要在需求中明确

---

## 去重规则

### 基本原则
- 按 user_id 去重
- 同一用户在统计周期内多次行为，只计数一次

### SQL 实现
```sql
-- ✅ 正确
COUNT(DISTINCT user_id)

-- ❌ 错误：会重复计数
COUNT(user_id)
```

---

## 时间范围处理

### 完整周期 vs 不完整周期

**完整周期**:
- 统计已经结束的完整时间周期
- 如统计"昨天的 DAU"

**不完整周期**:
- 统计包含当前时间的周期
- 如统计"今天的 DAU"（今天还没结束）

**注意**: 不完整周期的数据会随时间变化，需要在输出时说明。

### SQL 示例

```sql
-- 完整周期：昨天的 DAU
WHERE date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)

-- 不完整周期：今天的 DAU（实时）
WHERE date = CURRENT_DATE()
```

---

## 同比/环比

### 同比
与去年同期对比。

```sql
-- 今年 1 月 vs 去年 1 月
SELECT 
    '2024-01' as period,
    mau as mau_2024
FROM dws_user_monthly
WHERE month = '2024-01'

UNION ALL

SELECT 
    '2023-01' as period,
    mau as mau_2023
FROM dws_user_monthly
WHERE month = '2023-01';
```

### 环比
与上一个周期对比。

```sql
-- 本月 vs 上月
SELECT 
    month,
    mau,
    LAG(mau, 1) OVER (ORDER BY month) as last_month_mau,
    ROUND((mau - LAG(mau, 1) OVER (ORDER BY month)) * 100.0 / LAG(mau, 1) OVER (ORDER BY month), 2) as mom_growth_rate
FROM 
    dws_user_monthly
WHERE 
    month >= '2024-01'
ORDER BY 
    month;
```

---

## 常见问题

### Q: 如何处理测试账号？

A: [待补充雪球的测试账号过滤规则]

```sql
-- 示例：排除测试账号
WHERE user_id NOT IN (SELECT user_id FROM dim_test_users)
-- 或
WHERE is_test_user = 0
```

### Q: 如何处理异常值（刷量）？

A: [待补充雪球的异常值处理规则]

### Q: 跨平台的用户如何去重？

A: 按 user_id 去重，不区分平台。同一用户在多个平台活跃，只计数一次。

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建模板 |
