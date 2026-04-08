# SQL 编写最佳实践

> 本文档定义雪球公司 SQL 编写的规范和最佳实践。

---

## 重要说明

**数据库类型**: Trino

**所有 SQL 必须使用 Trino 语法规范**，不能使用 MySQL、Hive、Presto 等其他数据库的语法。

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

## 五、Trino 语法规范

### 5.1 日期函数（Trino）

**重要**: 必须使用 Trino 的日期函数，不能使用 MySQL/Hive 等其他语法。

```sql
-- ✅ 当前日期（Trino）
current_date

-- ✅ 日期加减（Trino）
date_add('day', 1, date_column)           -- 加 1 天
date_add('day', -1, date_column)          -- 减 1 天
date_add('month', 1, date_column)         -- 加 1 月
date_add('year', 1, date_column)          -- 加 1 年

-- ✅ 日期差值（Trino）
date_diff('day', date1, date2)            -- 计算两个日期相差的天数

-- ✅ 日期格式化（Trino）
date_format(date_column, '%Y-%m-%d')      -- 格式化为字符串
format_datetime(timestamp_col, 'yyyy-MM-dd HH:mm:ss')

-- ✅ 字符串转日期（Trino）
date_parse('2024-01-01', '%Y-%m-%d')      -- 解析字符串为日期
cast('2024-01-01' as date)                -- 类型转换

-- ✅ 提取日期部分（Trino）
year(date_column)                         -- 提取年份
month(date_column)                        -- 提取月份
day(date_column)                          -- 提取日期
day_of_week(date_column)                  -- 提取星期几（1-7）
day_of_year(date_column)                  -- 提取一年中的第几天

-- ❌ 错误：不要使用 MySQL 语法
DATE_ADD(date, INTERVAL 1 DAY)            -- MySQL 语法，禁止使用
DATE_SUB(date, INTERVAL 1 DAY)            -- MySQL 语法，禁止使用
CURDATE()                                 -- MySQL 语法，禁止使用
CURRENT_DATE()                            -- MySQL 语法，禁止使用

-- ❌ 错误：不要使用 Hive 语法
DATE_ADD(date, 1)                         -- Hive 语法，禁止使用
DATE_SUB(date, 1)                         -- Hive 语法，禁止使用
datediff(date1, date2)                    -- Hive 语法，禁止使用
```

### 5.2 字符串函数（Trino）

```sql
-- ✅ 字符串连接（Trino）
concat(str1, str2, str3)                  -- 连接多个字符串
str1 || str2 || str3                      -- 使用 || 操作符

-- ✅ 字符串截取（Trino）
substr(str, start, length)                -- 截取子串（从 1 开始）
substring(str, start, length)             -- 同上

-- ✅ 字符串长度（Trino）
length(str)                               -- 字符串长度

-- ✅ 字符串查找和替换（Trino）
strpos(str, substring)                    -- 查找子串位置（从 1 开始）
replace(str, search, replace)             -- 替换字符串

-- ✅ 大小写转换（Trino）
upper(str)                                -- 转大写
lower(str)                                -- 转小写

-- ✅ 去除空格（Trino）
trim(str)                                 -- 去除两端空格
ltrim(str)                                -- 去除左侧空格
rtrim(str)                                -- 去除右侧空格

-- ✅ 正则表达式（Trino）
regexp_like(str, pattern)                 -- 正则匹配
regexp_extract(str, pattern, group)       -- 正则提取
regexp_replace(str, pattern, replacement) -- 正则替换

-- ✅ 字符串分割（Trino）
split(str, delimiter)                     -- 分割字符串为数组
split_part(str, delimiter, index)         -- 获取分割后的第 N 部分
```

### 5.3 聚合函数（Trino）

```sql
-- ✅ 基础聚合（Trino）
count(*)                                  -- 计数
count(distinct column)                    -- 去重计数
sum(column)                               -- 求和
avg(column)                               -- 平均值
max(column)                               -- 最大值
min(column)                               -- 最小值

-- ✅ 近似聚合（Trino，性能更好）
approx_distinct(column)                   -- 近似去重计数（大数据量时推荐）
approx_percentile(column, 0.5)            -- 近似中位数

-- ✅ 数组聚合（Trino）
array_agg(column)                         -- 聚合为数组
```

### 5.4 窗口函数（Trino）

```sql
-- ✅ 排名函数（Trino）
row_number() over (partition by field1 order by field2 desc)  -- 行号
rank() over (partition by field1 order by field2 desc)         -- 排名（有并列）
dense_rank() over (partition by field1 order by field2 desc)   -- 密集排名

-- ✅ 累计函数（Trino）
sum(field) over (partition by field1 order by field2)          -- 累计求和
avg(field) over (partition by field1 order by field2)          -- 移动平均

-- ✅ 偏移函数（Trino）
lag(field, 1) over (order by date)                             -- 上一行
lead(field, 1) over (order by date)                            -- 下一行
first_value(field) over (partition by field1 order by field2)  -- 第一个值
last_value(field) over (partition by field1 order by field2)   -- 最后一个值
```

### 5.5 类型转换（Trino）

```sql
-- ✅ 类型转换（Trino）
cast(column as bigint)                    -- 转换为整数
cast(column as double)                    -- 转换为浮点数
cast(column as varchar)                   -- 转换为字符串
cast(column as date)                      -- 转换为日期
cast(column as timestamp)                 -- 转换为时间戳

-- ✅ 安全类型转换（Trino）
try_cast(column as bigint)                -- 转换失败返回 NULL
```

### 5.6 条件函数（Trino）

```sql
-- ✅ CASE 表达式（Trino）
case 
    when condition1 then result1
    when condition2 then result2
    else result3
end

-- ✅ IF 函数（Trino）
if(condition, true_value, false_value)

-- ✅ COALESCE（Trino）
coalesce(column1, column2, default_value) -- 返回第一个非 NULL 值

-- ✅ NULLIF（Trino）
nullif(column1, column2)                  -- 如果相等返回 NULL
```

### 5.7 数组函数（Trino）

```sql
-- ✅ 数组操作（Trino）
array[1, 2, 3]                            -- 创建数组
array_length(array_column)                -- 数组长度
contains(array_column, value)             -- 是否包含元素
array_distinct(array_column)              -- 数组去重
array_join(array_column, delimiter)       -- 数组转字符串
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

**Trino** - 分布式 SQL 查询引擎

### Trino 语法要点

1. **日期函数**: 使用 `date_add('day', n, date)` 而不是 `DATE_ADD(date, INTERVAL n DAY)`
2. **当前日期**: 使用 `current_date` 而不是 `CURDATE()` 或 `CURRENT_DATE()`
3. **日期差值**: 使用 `date_diff('day', date1, date2)` 而不是 `DATEDIFF(date1, date2)`
4. **字符串连接**: 使用 `concat()` 或 `||` 操作符
5. **类型转换**: 使用 `cast(column as type)` 或 `try_cast(column as type)`
6. **近似聚合**: 大数据量时使用 `approx_distinct()` 提升性能

### 连接信息
[待补充: 如何连接 Trino 数据库]

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
