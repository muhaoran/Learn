# 留存率计算规则

> 本文档详细说明各类留存率的计算方法。

---

## 基本概念

### 留存的定义
用户在某个时间点发生了某个行为（如注册、首次购买），在之后的某个时间点仍然活跃，则称该用户"留存"。

### 留存率的计算
```
留存率 = 留存用户数 / 基准用户数 * 100%
```

---

## 次日留存（D1 Retention）

### 定义
D0 日发生基准行为的用户中，在 D1 日活跃的用户占比。

### 计算规则

**分子**: D1 活跃的用户数
```sql
COUNT(DISTINCT user_id)
WHERE 用户在 D0 发生基准行为
  AND 用户在 D1 有活跃行为
```

**分母**: D0 发生基准行为的用户数
```sql
COUNT(DISTINCT user_id)
WHERE 用户在 D0 发生基准行为
```

**留存率**:
```sql
分子 / 分母 * 100%
```

### 时间计算

- **D0**: 基准日期（如注册日期）
- **D1**: D0 + 1 天（自然日）

**示例**:
- 用户 A 在 2024-01-01 注册 → D0 = 2024-01-01
- D1 = 2024-01-02
- 如果用户 A 在 2024-01-02 有活跃行为 → 留存
- 如果用户 A 在 2024-01-02 无活跃行为 → 未留存

### SQL 模板

```sql
-- 计算次日留存率
WITH base_users AS (
    -- D0: 基准用户（如新注册用户）
    SELECT 
        user_id,
        DATE(register_time) as d0_date
    FROM 
        dwd_user_register
    WHERE 
        DATE(register_time) = '2024-01-01'
),
retention_users AS (
    -- D1: 留存用户
    SELECT 
        bu.user_id,
        bu.d0_date
    FROM 
        base_users bu
    INNER JOIN 
        dwd_user_behavior ub
    ON 
        bu.user_id = ub.user_id
        AND DATE(ub.behavior_time) = DATE_ADD(bu.d0_date, INTERVAL 1 DAY)
)
SELECT 
    COUNT(DISTINCT bu.user_id) as base_users_count,
    COUNT(DISTINCT ru.user_id) as retention_users_count,
    ROUND(COUNT(DISTINCT ru.user_id) * 100.0 / COUNT(DISTINCT bu.user_id), 2) as retention_rate
FROM 
    base_users bu
LEFT JOIN 
    retention_users ru
ON 
    bu.user_id = ru.user_id;
```

### 注意事项
- 使用 LEFT JOIN 而非 INNER JOIN，避免遗漏未留存用户
- D1 的数据必须完整（等到 D1 结束后再统计）
- 注意时区处理

---

## 7日留存（D7 Retention）

### 定义
D0 日发生基准行为的用户中，在 D7 日活跃的用户占比。

### 计算规则
与次日留存类似，只是时间间隔改为 7 天。

### 时间计算
- **D7**: D0 + 7 天

### SQL 模板
```sql
-- 将次日留存的 SQL 中的 INTERVAL 1 DAY 改为 INTERVAL 7 DAY
DATE_ADD(bu.d0_date, INTERVAL 7 DAY)
```

---

## 30日留存（D30 Retention）

### 定义
D0 日发生基准行为的用户中，在 D30 日活跃的用户占比。

### 时间计算
- **D30**: D0 + 30 天

---

## N日留存（通用）

### 参数化实现

```sql
-- N 日留存（N 为参数）
DATE_ADD(bu.d0_date, INTERVAL {N} DAY)
```

---

## 区间留存

### 定义
D0 日发生基准行为的用户中，在 [D_start, D_end] 区间内有活跃的用户占比。

### 示例: 7日内留存

**含义**: D0-D7 任意一天活跃即算留存

```sql
WHERE DATE(ub.behavior_time) >= bu.d0_date
  AND DATE(ub.behavior_time) <= DATE_ADD(bu.d0_date, INTERVAL 7 DAY)
```

### 与"D7留存"的区别
- **D7留存**: 必须在第7天活跃
- **7日内留存**: D0-D7 任意一天活跃即可

**澄清策略**: 如果用户说"7日留存"，需要确认是哪种理解。

---

## 留存曲线

### 定义
展示 D1, D3, D7, D15, D30 等多个时间点的留存率变化。

### SQL 示例

```sql
-- 留存曲线
WITH base_users AS (
    SELECT 
        user_id,
        DATE(register_time) as d0_date
    FROM 
        dwd_user_register
    WHERE 
        DATE(register_time) = '2024-01-01'
)
SELECT 
    '次日留存' as retention_type,
    COUNT(DISTINCT CASE 
        WHEN DATE(ub.behavior_time) = DATE_ADD(bu.d0_date, INTERVAL 1 DAY)
        THEN bu.user_id 
    END) * 100.0 / COUNT(DISTINCT bu.user_id) as retention_rate
FROM 
    base_users bu
LEFT JOIN 
    dwd_user_behavior ub
ON 
    bu.user_id = ub.user_id
    AND DATE(ub.behavior_time) BETWEEN bu.d0_date AND DATE_ADD(bu.d0_date, INTERVAL 30 DAY)

UNION ALL

SELECT 
    '7日留存' as retention_type,
    COUNT(DISTINCT CASE 
        WHEN DATE(ub.behavior_time) = DATE_ADD(bu.d0_date, INTERVAL 7 DAY)
        THEN bu.user_id 
    END) * 100.0 / COUNT(DISTINCT bu.user_id) as retention_rate
FROM 
    base_users bu
LEFT JOIN 
    dwd_user_behavior ub
ON 
    bu.user_id = ub.user_id
    AND DATE(ub.behavior_time) BETWEEN bu.d0_date AND DATE_ADD(bu.d0_date, INTERVAL 30 DAY)

-- 可继续添加 D3, D15, D30 等
```

---

## 同期群留存分析（Cohort Retention）

### 定义
按注册日期分组，分析每个同期群的留存表现。

### SQL 示例

```sql
-- 同期群留存分析
WITH cohorts AS (
    -- 定义同期群（按注册日期）
    SELECT 
        user_id,
        DATE(register_time) as cohort_date
    FROM 
        dwd_user_register
    WHERE 
        DATE(register_time) >= '2024-01-01'
        AND DATE(register_time) < '2024-02-01'
),
retention_data AS (
    -- 计算每个用户在各个时间点的活跃情况
    SELECT 
        c.cohort_date,
        c.user_id,
        DATE(ub.behavior_time) as active_date,
        DATEDIFF(DATE(ub.behavior_time), c.cohort_date) as days_since_register
    FROM 
        cohorts c
    LEFT JOIN 
        dwd_user_behavior ub
    ON 
        c.user_id = ub.user_id
        AND DATE(ub.behavior_time) >= c.cohort_date
        AND DATE(ub.behavior_time) <= DATE_ADD(c.cohort_date, INTERVAL 30 DAY)
)
SELECT 
    cohort_date,
    COUNT(DISTINCT user_id) as cohort_size,
    COUNT(DISTINCT CASE WHEN days_since_register = 1 THEN user_id END) as d1_retention,
    COUNT(DISTINCT CASE WHEN days_since_register = 7 THEN user_id END) as d7_retention,
    COUNT(DISTINCT CASE WHEN days_since_register = 30 THEN user_id END) as d30_retention,
    ROUND(COUNT(DISTINCT CASE WHEN days_since_register = 1 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as d1_retention_rate,
    ROUND(COUNT(DISTINCT CASE WHEN days_since_register = 7 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as d7_retention_rate,
    ROUND(COUNT(DISTINCT CASE WHEN days_since_register = 30 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as d30_retention_rate
FROM 
    retention_data
GROUP BY 
    cohort_date
ORDER BY 
    cohort_date;
```

---

## 常见错误

### 错误 1: 使用 INNER JOIN
```sql
-- ❌ 错误：会遗漏未留存的用户
FROM base_users bu
INNER JOIN retention_users ru ON bu.user_id = ru.user_id
```

```sql
-- ✅ 正确：使用 LEFT JOIN
FROM base_users bu
LEFT JOIN retention_users ru ON bu.user_id = ru.user_id
```

### 错误 2: 时间计算错误
```sql
-- ❌ 错误：D1 应该是 +1 天，不是 +0 天
WHERE DATE(ub.behavior_time) = bu.d0_date
```

```sql
-- ✅ 正确
WHERE DATE(ub.behavior_time) = DATE_ADD(bu.d0_date, INTERVAL 1 DAY)
```

### 错误 3: 重复计数
```sql
-- ❌ 错误：可能重复计数
COUNT(user_id)
```

```sql
-- ✅ 正确：去重
COUNT(DISTINCT user_id)
```

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建模板 |
