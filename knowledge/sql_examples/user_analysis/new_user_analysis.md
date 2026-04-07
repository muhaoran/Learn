# SQL 案例: 新增用户分析

---

## 业务需求（原始）

"看下最近一个月的新增用户情况，按渠道分"

---

## 需求分析

### 关键要素提取

| 要素 | 内容 |
|------|------|
| **指标** | 新增用户数 |
| **维度** | 日期、渠道 |
| **筛选条件** | 无 |
| **时间范围** | 最近一个月 |
| **聚合方式** | 按日期和渠道聚合 |

---

## 需求澄清

### 澄清的问题

1. **问题**: "最近一个月" 是指最近 30 天还是本自然月？
   - **答案**: 最近 30 天
   - **影响**: 时间范围为 [今天-29, 今天]

2. **问题**: "渠道" 是指注册渠道吗？
   - **答案**: 是的，注册渠道
   - **影响**: 使用 register_channel 字段

3. **问题**: 需要每天的明细还是整体汇总？
   - **答案**: 每天的明细
   - **影响**: 按 date 和 channel 分组

### 最终确认的需求

查询最近 30 天每天各注册渠道的新增用户数。

---

## 技术方案

### 数据表选择

| 表名 | 用途 | 选择理由 |
|------|------|----------|
| `dwd_user_register` | 获取注册数据 | 有注册时间和渠道信息 |

或者

| 表名 | 用途 | 选择理由 |
|------|------|----------|
| `dws_user_daily` | 获取新增数据 | 汇总表，性能更好（如果有新增用户字段） |

### 计算逻辑

```
1. 从注册表筛选最近 30 天的数据
2. 按注册日期和渠道分组
3. 统计去重用户数
4. 按日期和渠道排序
```

---

## SQL 语句

### 方案 1: 使用注册明细表

```sql
-- 查询最近 30 天各渠道的新增用户数（Trino 语法）
SELECT 
    register_date,
    register_channel,
    COUNT(DISTINCT user_id) as new_users
FROM 
    dwd_user_register
WHERE 
    register_date >= date_add('day', -29, current_date)
    AND register_date <= current_date
GROUP BY 
    register_date,
    register_channel
ORDER BY 
    register_date,
    register_channel;
```

### 方案 2: 使用汇总表（推荐）

```sql
-- 如果 dws_user_daily 表中有新增用户标识（Trino 语法）
SELECT 
    date,
    register_channel,
    COUNT(DISTINCT user_id) as new_users
FROM 
    dws_user_daily
WHERE 
    date >= date_add('day', -29, current_date)
    AND date <= current_date
    AND is_new_user = 1  -- 只统计新用户
GROUP BY 
    date,
    register_channel
ORDER BY 
    date,
    register_channel;
```

---

## 执行说明

### 数据范围
- **扫描表**: `dwd_user_register` 或 `dws_user_daily`
- **扫描分区**: 最近 30 天
- **预计数据量**: 约 150 万行（假设日均 5 万新增）

### 性能预估
- **预计执行时间**: < 5 秒
- **资源消耗**: 低

---

## 结果说明

### 结果字段

| 字段名 | 含义 | 示例值 | 备注 |
|--------|------|--------|------|
| register_date | 注册日期 | 2024-01-01 | |
| register_channel | 注册渠道 | app_store | |
| new_users | 新增用户数 | 5000 | 去重后的用户数 |

### 结果解读

- 每行代表某天某渠道的新增用户数
- 可以对比不同渠道的新增能力
- 可以观察新增趋势

---

## 变体需求

### 变体 1: 只看总量（不按日期细分）

**SQL 调整**:
```sql
SELECT 
    register_channel,
    COUNT(DISTINCT user_id) as new_users
FROM 
    dwd_user_register
WHERE 
    register_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY)
    AND register_date <= CURRENT_DATE()
GROUP BY 
    register_channel
ORDER BY 
    new_users DESC;  -- 按新增数降序
```

### 变体 2: 增加占比

**SQL 调整**:
```sql
WITH daily_channel AS (
    SELECT 
        register_date,
        register_channel,
        COUNT(DISTINCT user_id) as new_users
    FROM 
        dwd_user_register
    WHERE 
        register_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY)
        AND register_date <= CURRENT_DATE()
    GROUP BY 
        register_date,
        register_channel
),
daily_total AS (
    SELECT 
        register_date,
        SUM(new_users) as total_new_users
    FROM 
        daily_channel
    GROUP BY 
        register_date
)
SELECT 
    dc.register_date,
    dc.register_channel,
    dc.new_users,
    dt.total_new_users,
    ROUND(dc.new_users * 100.0 / dt.total_new_users, 2) as channel_ratio
FROM 
    daily_channel dc
LEFT JOIN 
    daily_total dt
ON 
    dc.register_date = dt.register_date
ORDER BY 
    dc.register_date,
    dc.new_users DESC;
```

### 变体 3: 增加同比数据

**SQL 调整**:
```sql
SELECT 
    register_date,
    register_channel,
    COUNT(DISTINCT user_id) as new_users
FROM 
    dwd_user_register
WHERE 
    (
        -- 今年最近 30 天
        (register_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY) 
         AND register_date <= CURRENT_DATE())
        OR
        -- 去年同期
        (register_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 394 DAY)
         AND register_date <= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY))
    )
GROUP BY 
    register_date,
    register_channel
ORDER BY 
    register_date,
    register_channel;
```

---

## 相关案例

- 新增用户留存: `knowledge/sql_examples/user_analysis/retention.md`
- 渠道质量分析: `knowledge/sql_examples/user_analysis/channel_quality.md`

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建案例 |
