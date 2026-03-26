# SQL 编写最佳实践

> 本文档定义雪球公司 SQL 编写的规范和最佳实践。

---

## 一、性能优化

### 1.1 必须使用分区字段

**规则**: 查询分区表时，WHERE 条件必须包含分区字段。

```sql
-- ✅ 正确
SELECT * FROM dwd_user_behavior
WHERE date = '2024-01-01'
  AND user_id = 123456;

-- ❌ 错误：会全表扫描
SELECT * FROM dwd_user_behavior
WHERE user_id = 123456;
```

### 1.2 优先使用汇总表

**规则**: 能用汇总表就不用明细表。

```sql
-- ✅ 推荐：使用汇总表
SELECT date, dau 
FROM dws_user_daily
WHERE date = '2024-01-01';

-- ❌ 不推荐：从明细表聚合（除非有特殊需求）
SELECT date, COUNT(DISTINCT user_id) as dau
FROM dwd_user_behavior
WHERE date = '2024-01-01'
GROUP BY date;
```

**汇总表优先级**: ADS > DWS > DWD > ODS

### 1.3 限制查询时间范围

**规则**: 明细表查询时间范围不超过 30 天。

```sql
-- ✅ 正确：限制在 7 天
WHERE date >= '2024-01-01' AND date < '2024-01-08'

-- ⚠️ 谨慎：30 天，数据量大
WHERE date >= '2024-01-01' AND date < '2024-02-01'

-- ❌ 错误：超过 30 天，可能超时
WHERE date >= '2024-01-01' AND date < '2024-03-01'
```

### 1.4 避免 SELECT *

**规则**: 只查询需要的字段。

```sql
-- ✅ 正确
SELECT user_id, behavior_type, behavior_time
FROM dwd_user_behavior
WHERE date = '2024-01-01';

-- ❌ 错误
SELECT * FROM dwd_user_behavior
WHERE date = '2024-01-01';
```

### 1.5 使用合适的 JOIN 类型

**规则**: 根据业务需求选择 JOIN 类型。

- **LEFT JOIN**: 需要保留左表所有记录（如留存分析）
- **INNER JOIN**: 只需要两表都有的记录
- **避免 CROSS JOIN**: 除非确实需要笛卡尔积

### 1.6 提前过滤

**规则**: 在 JOIN 之前先过滤数据。

```sql
-- ✅ 推荐：先过滤再关联
FROM (
    SELECT * FROM dwd_user_register 
    WHERE register_date = '2024-01-01'
) r
LEFT JOIN dwd_user_behavior b 
ON r.user_id = b.user_id AND b.date = '2024-01-01';

-- ❌ 不推荐：关联后再过滤
FROM dwd_user_register r
LEFT JOIN dwd_user_behavior b ON r.user_id = b.user_id
WHERE r.register_date = '2024-01-01' AND b.date = '2024-01-01';
```

---

## 二、正确性保证

### 2.1 正确去重

**规则**: 统计用户数时必须去重。

```sql
-- ✅ 正确
COUNT(DISTINCT user_id)

-- ❌ 错误：会重复计数
COUNT(user_id)
```

### 2.2 NULL 值处理

**规则**: 注意 NULL 值的影响。

```sql
-- ✅ 正确：处理 NULL
COALESCE(field_name, 0)

-- ✅ 正确：排除 NULL
WHERE field_name IS NOT NULL

-- ❌ 错误：NULL 会影响计算
AVG(field_name)  -- 如果有 NULL，结果可能不符合预期
```

### 2.3 时间边界处理

**规则**: 使用左闭右开区间。

```sql
-- ✅ 推荐：左闭右开
WHERE date >= '2024-01-01' AND date < '2024-01-08'

-- ⚠️ 可以但不推荐：左闭右闭
WHERE date >= '2024-01-01' AND date <= '2024-01-07'
```

**原因**: 避免 timestamp 的边界问题。

### 2.4 除法运算

**规则**: 注意除零错误和精度。

```sql
-- ✅ 正确：避免除零，保留精度
CASE 
    WHEN denominator = 0 THEN 0
    ELSE ROUND(numerator * 100.0 / denominator, 2)
END as rate

-- ❌ 错误：可能除零
numerator / denominator

-- ❌ 错误：整数除法，丢失精度
numerator * 100 / denominator
```

---

## 三、可读性规范

### 3.1 使用 CTE

**规则**: 复杂查询使用 CTE (Common Table Expression) 提高可读性。

```sql
-- ✅ 推荐：使用 CTE
WITH new_users AS (
    SELECT user_id, register_date
    FROM dwd_user_register
    WHERE register_date = '2024-01-01'
),
active_users AS (
    SELECT DISTINCT user_id
    FROM dwd_user_behavior
    WHERE date = '2024-01-02'
)
SELECT 
    COUNT(DISTINCT n.user_id) as new_users,
    COUNT(DISTINCT a.user_id) as retention_users
FROM new_users n
LEFT JOIN active_users a ON n.user_id = a.user_id;

-- ❌ 不推荐：嵌套子查询
SELECT 
    COUNT(DISTINCT n.user_id),
    COUNT(DISTINCT a.user_id)
FROM (
    SELECT user_id FROM dwd_user_register WHERE register_date = '2024-01-01'
) n
LEFT JOIN (
    SELECT DISTINCT user_id FROM dwd_user_behavior WHERE date = '2024-01-02'
) a ON n.user_id = a.user_id;
```

### 3.2 添加注释

**规则**: 为复杂逻辑添加注释。

```sql
-- 计算次日留存率
-- 分子: D1 活跃用户数
-- 分母: D0 新增用户数
WITH new_users AS (
    -- 获取 D0 新增用户
    SELECT user_id, register_date
    FROM dwd_user_register
    WHERE register_date = '2024-01-01'
),
retention_users AS (
    -- 获取 D1 活跃用户
    SELECT DISTINCT nu.user_id
    FROM new_users nu
    INNER JOIN dwd_user_behavior ub
    ON nu.user_id = ub.user_id
    AND ub.date = DATE_ADD(nu.register_date, INTERVAL 1 DAY)
)
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

### 3.3 格式规范

**规则**: 统一的格式风格。

```sql
-- ✅ 推荐格式
SELECT 
    field1,
    field2,
    COUNT(DISTINCT field3) as cnt
FROM 
    table_name
WHERE 
    date >= '2024-01-01'
    AND date < '2024-01-08'
    AND status = 'active'
GROUP BY 
    field1,
    field2
ORDER BY 
    field1;

-- 格式要点：
-- 1. 关键字大写
-- 2. 字段名小写
-- 3. 每个字段单独一行
-- 4. WHERE 条件每个单独一行
-- 5. 适当的缩进
```

### 3.4 字段别名

**规则**: 为计算字段添加有意义的别名。

```sql
-- ✅ 正确：清晰的别名
COUNT(DISTINCT user_id) as dau
SUM(amount) as total_amount
AVG(duration) as avg_duration

-- ❌ 错误：没有别名或别名不清晰
COUNT(DISTINCT user_id)
SUM(amount) as sum
AVG(duration) as avg
```

---

## 四、安全规范

### 4.1 只读查询

**规则**: 只能生成 SELECT 查询，不能修改数据。

```sql
-- ✅ 允许
SELECT ...

-- ❌ 禁止
UPDATE ...
DELETE ...
INSERT ...
DROP ...
TRUNCATE ...
```

### 4.2 避免敏感信息

**规则**: 不查询敏感字段（如密码、身份证号等）。

```sql
-- ❌ 禁止
SELECT password, id_card FROM ...
```

---

## 五、数据库特定语法

### 5.1 日期函数

**请根据雪球使用的数据库类型（MySQL/PostgreSQL/Hive/ClickHouse 等）补充具体语法**

#### MySQL 示例

```sql
-- 当前日期
CURRENT_DATE() 或 CURDATE()

-- 日期加减
DATE_ADD(date, INTERVAL 1 DAY)
DATE_SUB(date, INTERVAL 1 DAY)

-- 日期格式化
DATE_FORMAT(date, '%Y-%m-%d')

-- 日期截取
DATE(timestamp)
```

#### Hive 示例

```sql
-- 当前日期
CURRENT_DATE

-- 日期加减
DATE_ADD(date, 1)
DATE_SUB(date, 1)

-- 日期格式化
FROM_UNIXTIME(unix_timestamp, 'yyyy-MM-dd')
```

### 5.2 字符串函数

[待补充常用字符串函数]

### 5.3 窗口函数

```sql
-- 排名
ROW_NUMBER() OVER (PARTITION BY field1 ORDER BY field2 DESC)

-- 累计
SUM(field) OVER (PARTITION BY field1 ORDER BY field2)

-- 同比/环比
LAG(field, 1) OVER (ORDER BY date)
LEAD(field, 1) OVER (ORDER BY date)
```

---

## 六、常见错误

### 错误 1: 忘记分区条件
```sql
-- ❌ 错误
SELECT COUNT(*) FROM dwd_user_behavior WHERE user_id = 123;

-- ✅ 正确
SELECT COUNT(*) FROM dwd_user_behavior 
WHERE date = '2024-01-01' AND user_id = 123;
```

### 错误 2: 重复计数
```sql
-- ❌ 错误
SELECT COUNT(user_id) FROM ...

-- ✅ 正确
SELECT COUNT(DISTINCT user_id) FROM ...
```

### 错误 3: JOIN 类型错误
```sql
-- ❌ 错误：计算留存率时使用 INNER JOIN 会遗漏未留存用户
FROM base_users INNER JOIN retention_users ON ...

-- ✅ 正确
FROM base_users LEFT JOIN retention_users ON ...
```

### 错误 4: 时间计算错误
```sql
-- ❌ 错误：次日留存应该是 +1 天
WHERE b.date = r.register_date

-- ✅ 正确
WHERE b.date = DATE_ADD(r.register_date, INTERVAL 1 DAY)
```

---

## 七、SQL 审查清单

生成 SQL 后，请检查：

- [ ] 是否包含分区字段过滤条件？
- [ ] 是否只查询需要的字段（避免 SELECT *）？
- [ ] 是否正确去重（DISTINCT）？
- [ ] 是否处理了 NULL 值？
- [ ] 时间范围是否合理（不超过 30 天）？
- [ ] JOIN 类型是否正确？
- [ ] 是否有清晰的注释？
- [ ] 字段别名是否清晰？
- [ ] 是否符合业务定义？
- [ ] 是否有明显的性能问题？

---

## 八、数据库配置

### 数据库类型
[待补充: MySQL/PostgreSQL/Hive/ClickHouse/Presto 等]

### 连接信息
[待补充: 如何连接数据库]

### 权限说明
[待补充: 权限范围，哪些表可以访问]

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建文档 |

---

## 使用说明

**For AI**:
- 生成 SQL 前必须阅读本文档
- 严格遵循最佳实践
- 生成后使用审查清单自检

**For Human**:
- 请补充雪球的数据库类型和特定语法
- 请补充性能优化的具体要求
- 如有新的最佳实践，请及时补充
