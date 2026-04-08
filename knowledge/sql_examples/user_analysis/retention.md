# SQL 案例: 次日留存率分析

---

## 业务需求（原始）

"帮我算一下 1 月份新用户的次留"

---

## 需求分析

### 关键要素提取

| 要素 | 内容 |
|------|------|
| **指标** | 次日留存率 |
| **维度** | 日期（注册日期） |
| **筛选条件** | 新用户 |
| **时间范围** | 1 月份 |
| **聚合方式** | 按注册日期聚合 |

---

## 需求澄清

### 澄清的问题

1. **问题**: "1 月份" 是指 2024 年 1 月吗？
   - **答案**: 是的，2024 年 1 月
   - **影响**: 时间范围为 2024-01-01 到 2024-01-31

2. **问题**: "次留" 是指次日留存率吗？
   - **答案**: 是的
   - **影响**: 计算 D1 留存率

3. **问题**: 是否需要按渠道等维度细分？
   - **答案**: 暂时不需要，先看整体
   - **影响**: 只按注册日期分组

4. **问题**: "活跃" 的定义是？
   - **答案**: 有任意行为即算活跃
   - **影响**: 使用标准的活跃定义

### 最终确认的需求

查询 2024 年 1 月每天注册的新用户，在次日（D1）的留存率。

---

## 技术方案

### 数据表选择

| 表名 | 用途 | 选择理由 |
|------|------|----------|
| `dwd_user_register` | 获取新增用户 | 有注册时间和用户信息 |
| `dwd_user_behavior` | 获取活跃数据 | 有用户行为明细 |

### 计算逻辑

```
1. 从 dwd_user_register 获取 1 月份注册的用户（D0）
2. 从 dwd_user_behavior 获取这些用户在 D1 的活跃情况
3. 关联两表（LEFT JOIN，保留所有新增用户）
4. 按注册日期分组
5. 计算: 留存率 = D1 活跃用户数 / D0 新增用户数
```

### 关键技术点

- **LEFT JOIN**: 必须使用 LEFT JOIN，不能用 INNER JOIN（否则会遗漏未留存用户）
- **时间计算**: D1 = D0 + 1 天（使用 Trino 的 date_add 函数）
- **去重**: 两边都要 DISTINCT

---

## SQL 语句

```sql
-- 计算 2024 年 1 月新用户的次日留存率（Trino 语法）
-- 按注册日期分组展示

WITH new_users AS (
    -- D0: 获取 1 月份的新注册用户
    SELECT 
        user_id,
        cast(register_time as date) as register_date
    FROM 
        dwd_user_register
    WHERE 
        register_date >= date '2024-01-01'
        AND register_date < date '2024-02-01'
),
retention_users AS (
    -- D1: 获取次日活跃的用户
    SELECT 
        nu.user_id,
        nu.register_date
    FROM 
        new_users nu
    INNER JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        -- 关键: D1 = D0 + 1 天（Trino 语法）
        AND ub.date = date_add('day', 1, nu.register_date)
)
SELECT 
    nu.register_date,
    COUNT(DISTINCT nu.user_id) as new_users_count,
    COUNT(DISTINCT ru.user_id) as retention_users_count,
    ROUND(CAST(COUNT(DISTINCT ru.user_id) AS DOUBLE) * 100.0 / COUNT(DISTINCT nu.user_id), 2) as retention_rate
FROM 
    new_users nu
LEFT JOIN 
    retention_users ru
ON 
    nu.user_id = ru.user_id
    AND nu.register_date = ru.register_date
GROUP BY 
    nu.register_date
ORDER BY 
    nu.register_date;
```

---

## 执行说明

### 数据范围
- **扫描表**: `dwd_user_register`, `dwd_user_behavior`
- **扫描分区**: 
  - 注册表: 2024-01-01 到 2024-01-31
  - 行为表: 2024-01-02 到 2024-02-01（D1 数据）
- **预计数据量**: 
  - 新增用户: 约 150 万（假设日均 5 万）
  - 行为数据: 约 1.5 亿行（假设日均 5000 万）

### 性能预估
- **预计执行时间**: 10-30 秒
- **资源消耗**: 中等

### 注意事项
- ⚠️ 1 月 31 日的次日留存需要 2 月 1 日的数据，确保数据已更新
- ⚠️ 行为表数据量大，查询可能需要一些时间
- ✅ 已使用分区条件，性能可接受

---

## 结果说明

### 结果字段

| 字段名 | 含义 | 示例值 | 备注 |
|--------|------|--------|------|
| register_date | 注册日期 | 2024-01-01 | D0 日期 |
| new_users_count | 新增用户数 | 50000 | 当天注册的用户数 |
| retention_users_count | 留存用户数 | 20000 | D1 活跃的用户数 |
| retention_rate | 次日留存率 | 40.00 | 百分比，保留 2 位小数 |

### 结果解读

- 每行代表一个注册日期的留存情况
- retention_rate 越高，说明用户质量越好
- 可以观察不同日期的留存率差异（如周末 vs 工作日）
- 注意: 最后一天（1月31日）的留存率需要等 2 月 1 日数据完整后才准确

---

## 变体需求

### 变体 1: 按渠道细分

**需求变化**: 需要看各渠道新用户的留存率

**SQL 调整**:
```sql
-- 在 new_users CTE 中增加 register_channel
WITH new_users AS (
    SELECT 
        user_id,
        DATE(register_time) as register_date,
        register_channel  -- 新增
    FROM 
        dwd_user_register
    WHERE 
        register_date >= '2024-01-01'
        AND register_date < '2024-02-01'
),
-- retention_users CTE 也要加 register_channel
retention_users AS (
    SELECT 
        nu.user_id,
        nu.register_date,
        nu.register_channel  -- 新增
    FROM 
        new_users nu
    INNER JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        AND ub.date = DATE_ADD(nu.register_date, INTERVAL 1 DAY)
)
SELECT 
    nu.register_date,
    nu.register_channel,  -- 新增
    COUNT(DISTINCT nu.user_id) as new_users_count,
    COUNT(DISTINCT ru.user_id) as retention_users_count,
    ROUND(COUNT(DISTINCT ru.user_id) * 100.0 / COUNT(DISTINCT nu.user_id), 2) as retention_rate
FROM 
    new_users nu
LEFT JOIN 
    retention_users ru
ON 
    nu.user_id = ru.user_id
    AND nu.register_date = ru.register_date
    AND nu.register_channel = ru.register_channel  -- 新增
GROUP BY 
    nu.register_date,
    nu.register_channel  -- 新增
ORDER BY 
    nu.register_date,
    nu.register_channel;
```

### 变体 2: 7 日留存

**需求变化**: 改为计算 7 日留存率

**SQL 调整**:
```sql
-- 只需修改时间间隔
AND ub.date = DATE_ADD(nu.register_date, INTERVAL 7 DAY)  -- 改为 7
```

### 变体 3: 整体留存率（不按日期细分）

**需求变化**: 只要 1 月份整体的留存率，不按每天展示

**SQL 调整**:
```sql
-- 去掉 GROUP BY 中的 register_date
SELECT 
    COUNT(DISTINCT nu.user_id) as new_users_count,
    COUNT(DISTINCT ru.user_id) as retention_users_count,
    ROUND(COUNT(DISTINCT ru.user_id) * 100.0 / COUNT(DISTINCT nu.user_id), 2) as retention_rate
FROM 
    new_users nu
LEFT JOIN 
    retention_users ru
ON 
    nu.user_id = ru.user_id;
```

---

## 相关案例

- 7 日留存: `knowledge/sql_examples/user_analysis/retention_d7.md`
- 留存曲线: `knowledge/sql_examples/user_analysis/retention_curve.md`
- 同期群留存: `knowledge/sql_examples/user_analysis/cohort_retention.md`

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建案例 |
