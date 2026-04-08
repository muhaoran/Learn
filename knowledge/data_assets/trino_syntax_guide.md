# Trino SQL 语法速查指南

> 本文档提供 Trino SQL 语法的快速参考，所有 ChatBI 生成的 SQL 必须遵循此语法规范。

---

## 重要说明

**ChatBI 系统使用 Trino 作为查询引擎，所有 SQL 必须使用 Trino 语法。**

**禁止使用其他数据库的语法**：
- ❌ MySQL 语法（如 `DATE_ADD(date, INTERVAL 1 DAY)`、`CURDATE()`）
- ❌ Hive 语法（如 `DATE_ADD(date, 1)`、`datediff(date1, date2)`）
- ❌ PostgreSQL 语法（如 `date + interval '1 day'`）

---

## 一、日期和时间函数

### 1.1 获取当前日期/时间

```sql
-- ✅ 当前日期（Trino）
current_date

-- ✅ 当前时间戳（Trino）
current_timestamp

-- ✅ 当前时间（Trino）
current_time

-- ❌ 错误：MySQL 语法
CURDATE()
CURRENT_DATE()
NOW()
```

### 1.2 日期加减

```sql
-- ✅ 日期加减（Trino）
date_add('day', 1, date_column)           -- 加 1 天
date_add('day', -1, date_column)          -- 减 1 天
date_add('week', 1, date_column)          -- 加 1 周
date_add('month', 1, date_column)         -- 加 1 月
date_add('year', 1, date_column)          -- 加 1 年

-- 示例：获取昨天的日期
date_add('day', -1, current_date)

-- 示例：获取 7 天前的日期
date_add('day', -7, current_date)

-- ❌ 错误：MySQL 语法
DATE_ADD(date_column, INTERVAL 1 DAY)
DATE_SUB(date_column, INTERVAL 1 DAY)

-- ❌ 错误：Hive 语法
DATE_ADD(date_column, 1)
DATE_SUB(date_column, 1)
```

### 1.3 日期差值

```sql
-- ✅ 日期差值（Trino）
date_diff('day', date1, date2)            -- 计算两个日期相差的天数
date_diff('month', date1, date2)          -- 计算两个日期相差的月数
date_diff('year', date1, date2)           -- 计算两个日期相差的年数

-- 示例：计算注册天数
date_diff('day', register_date, current_date)

-- ❌ 错误：MySQL 语法
DATEDIFF(date1, date2)

-- ❌ 错误：Hive 语法
datediff(date1, date2)
```

### 1.4 日期格式化

```sql
-- ✅ 日期格式化（Trino）
date_format(date_column, '%Y-%m-%d')      -- 格式化为 2024-01-01
date_format(date_column, '%Y%m%d')        -- 格式化为 20240101
date_format(date_column, '%Y-%m')         -- 格式化为 2024-01

-- 时间戳格式化
format_datetime(timestamp_col, 'yyyy-MM-dd HH:mm:ss')

-- ❌ 错误：MySQL 语法
DATE_FORMAT(date_column, '%Y-%m-%d')
```

### 1.5 字符串转日期

```sql
-- ✅ 字符串转日期（Trino）
date_parse('2024-01-01', '%Y-%m-%d')      -- 解析字符串为日期
cast('2024-01-01' as date)                -- 类型转换

-- 字符串转时间戳
date_parse('2024-01-01 10:30:00', '%Y-%m-%d %H:%i:%s')

-- ❌ 错误：MySQL 语法
STR_TO_DATE('2024-01-01', '%Y-%m-%d')
```

### 1.6 提取日期部分

```sql
-- ✅ 提取日期部分（Trino）
year(date_column)                         -- 提取年份：2024
month(date_column)                        -- 提取月份：1-12
day(date_column)                          -- 提取日期：1-31
day_of_week(date_column)                  -- 提取星期几：1-7（1=周一）
day_of_year(date_column)                  -- 提取一年中的第几天：1-366
quarter(date_column)                      -- 提取季度：1-4
week(date_column)                         -- 提取周数：1-53

-- 提取时间部分
hour(timestamp_column)                    -- 提取小时：0-23
minute(timestamp_column)                  -- 提取分钟：0-59
second(timestamp_column)                  -- 提取秒：0-59

-- ❌ 错误：MySQL 语法
YEAR(date_column)
MONTH(date_column)
DAY(date_column)
```

### 1.7 日期截断

```sql
-- ✅ 日期截断（Trino）
date_trunc('day', timestamp_column)       -- 截断到天
date_trunc('week', timestamp_column)      -- 截断到周
date_trunc('month', timestamp_column)     -- 截断到月
date_trunc('quarter', timestamp_column)   -- 截断到季度
date_trunc('year', timestamp_column)      -- 截断到年
```

---

## 二、字符串函数

### 2.1 字符串连接

```sql
-- ✅ 字符串连接（Trino）
concat(str1, str2, str3)                  -- 连接多个字符串
str1 || str2 || str3                      -- 使用 || 操作符

-- 示例
concat('用户ID:', cast(user_id as varchar))
'Hello' || ' ' || 'World'

-- ❌ 错误：MySQL 语法
CONCAT(str1, str2)                        -- Trino 也支持，但建议用小写
```

### 2.2 字符串截取

```sql
-- ✅ 字符串截取（Trino）
substr(str, start, length)                -- 截取子串（从 1 开始）
substring(str, start, length)             -- 同上

-- 示例：截取前 10 个字符
substr(content, 1, 10)

-- ❌ 错误：MySQL 语法（start 从 0 开始）
SUBSTRING(str, 0, length)
```

### 2.3 字符串长度

```sql
-- ✅ 字符串长度（Trino）
length(str)                               -- 字符串长度

-- 示例
WHERE length(username) > 5
```

### 2.4 字符串查找和替换

```sql
-- ✅ 字符串查找（Trino）
strpos(str, substring)                    -- 查找子串位置（从 1 开始，未找到返回 0）

-- ✅ 字符串替换（Trino）
replace(str, search, replacement)         -- 替换字符串

-- 示例
replace(phone, '-', '')                   -- 去除电话号码中的横线
```

### 2.5 大小写转换

```sql
-- ✅ 大小写转换（Trino）
upper(str)                                -- 转大写
lower(str)                                -- 转小写

-- 示例
WHERE lower(email) like '%@gmail.com'
```

### 2.6 去除空格

```sql
-- ✅ 去除空格（Trino）
trim(str)                                 -- 去除两端空格
ltrim(str)                                -- 去除左侧空格
rtrim(str)                                -- 去除右侧空格

-- 示例
WHERE trim(username) != ''
```

### 2.7 正则表达式

```sql
-- ✅ 正则匹配（Trino）
regexp_like(str, pattern)                 -- 正则匹配，返回 true/false

-- ✅ 正则提取（Trino）
regexp_extract(str, pattern, group)       -- 提取匹配的组

-- ✅ 正则替换（Trino）
regexp_replace(str, pattern, replacement) -- 正则替换

-- 示例：匹配手机号
WHERE regexp_like(phone, '^\d{11}$')

-- 示例：提取域名
regexp_extract(email, '@(.+)$', 1)
```

### 2.8 字符串分割

```sql
-- ✅ 字符串分割（Trino）
split(str, delimiter)                     -- 分割字符串为数组
split_part(str, delimiter, index)         -- 获取分割后的第 N 部分（从 1 开始）

-- 示例：获取邮箱用户名
split_part(email, '@', 1)

-- 示例：分割标签
split(tags, ',')
```

---

## 三、聚合函数

### 3.1 基础聚合

```sql
-- ✅ 基础聚合（Trino）
count(*)                                  -- 计数（包含 NULL）
count(column)                             -- 计数（不包含 NULL）
count(distinct column)                    -- 去重计数
sum(column)                               -- 求和
avg(column)                               -- 平均值
max(column)                               -- 最大值
min(column)                               -- 最小值

-- 示例：计算 DAU
count(distinct user_id)
```

### 3.2 近似聚合（性能优化）

```sql
-- ✅ 近似聚合（Trino，大数据量时推荐）
approx_distinct(column)                   -- 近似去重计数（误差约 2.3%）
approx_percentile(column, 0.5)            -- 近似中位数
approx_percentile(column, 0.95)           -- 近似 95 分位数

-- 示例：大数据量时计算 DAU
approx_distinct(user_id)                  -- 比 count(distinct) 快很多
```

### 3.3 数组聚合

```sql
-- ✅ 数组聚合（Trino）
array_agg(column)                         -- 聚合为数组

-- 示例：聚合用户的所有标签
array_agg(tag)
```

---

## 四、窗口函数

### 4.1 排名函数

```sql
-- ✅ 排名函数（Trino）
row_number() over (partition by field1 order by field2 desc)  -- 行号（1,2,3...）
rank() over (partition by field1 order by field2 desc)         -- 排名（1,2,2,4...）
dense_rank() over (partition by field1 order by field2 desc)   -- 密集排名（1,2,2,3...）

-- 示例：每个渠道的 TOP 10 用户
SELECT 
    user_id,
    channel,
    score,
    row_number() over (partition by channel order by score desc) as rank
FROM user_scores
WHERE rank <= 10;
```

### 4.2 累计函数

```sql
-- ✅ 累计函数（Trino）
sum(field) over (partition by field1 order by field2)          -- 累计求和
avg(field) over (partition by field1 order by field2)          -- 移动平均
count(*) over (partition by field1 order by field2)            -- 累计计数

-- 示例：累计新增用户数
sum(new_users) over (order by date)
```

### 4.3 偏移函数

```sql
-- ✅ 偏移函数（Trino）
lag(field, 1) over (order by date)                             -- 上一行的值
lead(field, 1) over (order by date)                            -- 下一行的值
first_value(field) over (partition by field1 order by field2)  -- 第一个值
last_value(field) over (partition by field1 order by field2)   -- 最后一个值

-- 示例：计算环比增长率
SELECT 
    date,
    dau,
    lag(dau, 1) over (order by date) as yesterday_dau,
    round((dau - lag(dau, 1) over (order by date)) * 100.0 / lag(dau, 1) over (order by date), 2) as growth_rate
FROM daily_metrics;
```

---

## 五、类型转换

### 5.1 基础类型转换

```sql
-- ✅ 类型转换（Trino）
cast(column as bigint)                    -- 转换为整数
cast(column as double)                    -- 转换为浮点数
cast(column as varchar)                   -- 转换为字符串
cast(column as date)                      -- 转换为日期
cast(column as timestamp)                 -- 转换为时间戳
cast(column as decimal(10,2))             -- 转换为定点数

-- 示例：计算百分比
cast(count(distinct user_id) as double) * 100.0 / total_users
```

### 5.2 安全类型转换

```sql
-- ✅ 安全类型转换（Trino）
try_cast(column as bigint)                -- 转换失败返回 NULL

-- 示例：处理可能包含非数字的字段
WHERE try_cast(user_input as bigint) is not null
```

---

## 六、条件函数

### 6.1 CASE 表达式

```sql
-- ✅ CASE 表达式（Trino）
case 
    when condition1 then result1
    when condition2 then result2
    else result3
end

-- 示例：用户分层
case 
    when score >= 90 then '高价值用户'
    when score >= 60 then '中等用户'
    else '低价值用户'
end as user_level
```

### 6.2 IF 函数

```sql
-- ✅ IF 函数（Trino）
if(condition, true_value, false_value)

-- 示例：判断是否活跃
if(login_days >= 7, '活跃', '不活跃')
```

### 6.3 COALESCE

```sql
-- ✅ COALESCE（Trino）
coalesce(column1, column2, default_value) -- 返回第一个非 NULL 值

-- 示例：提供默认值
coalesce(nickname, username, '匿名用户')
```

### 6.4 NULLIF

```sql
-- ✅ NULLIF（Trino）
nullif(column1, column2)                  -- 如果相等返回 NULL

-- 示例：避免除零错误
sum(amount) / nullif(count(*), 0)
```

---

## 七、数组函数

### 7.1 数组操作

```sql
-- ✅ 创建数组（Trino）
array[1, 2, 3]                            -- 创建数组

-- ✅ 数组长度（Trino）
cardinality(array_column)                 -- 数组长度（Trino 特有）
array_length(array_column)                -- 数组长度（别名）

-- ✅ 数组包含（Trino）
contains(array_column, value)             -- 是否包含元素

-- ✅ 数组去重（Trino）
array_distinct(array_column)              -- 数组去重

-- ✅ 数组转字符串（Trino）
array_join(array_column, delimiter)       -- 数组转字符串

-- 示例：判断用户是否有某个标签
WHERE contains(tags, '活跃用户')
```

---

## 八、常见查询模式

### 8.1 最近 N 天的数据

```sql
-- ✅ 最近 7 天（Trino）
WHERE date >= date_add('day', -6, current_date)
  AND date <= current_date

-- ✅ 最近 30 天（Trino）
WHERE date >= date_add('day', -29, current_date)
  AND date <= current_date

-- ❌ 错误：MySQL 语法
WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
```

### 8.2 本月/上月数据

```sql
-- ✅ 本月数据（Trino）
WHERE date >= date_trunc('month', current_date)
  AND date < date_add('month', 1, date_trunc('month', current_date))

-- ✅ 上月数据（Trino）
WHERE date >= date_add('month', -1, date_trunc('month', current_date))
  AND date < date_trunc('month', current_date)
```

### 8.3 去重计数

```sql
-- ✅ 精确去重（Trino）
count(distinct user_id)

-- ✅ 近似去重（Trino，大数据量推荐）
approx_distinct(user_id)
```

### 8.4 留存率计算

```sql
-- ✅ 留存率计算（Trino）
round(
    cast(count(distinct retention_users.user_id) as double) * 100.0 
    / count(distinct base_users.user_id), 
    2
) as retention_rate
```

---

## 九、性能优化技巧

### 9.1 使用近似聚合

```sql
-- ✅ 大数据量时使用近似聚合（Trino）
approx_distinct(user_id)                  -- 比 count(distinct) 快 10-100 倍
approx_percentile(response_time, 0.95)    -- 近似分位数
```

### 9.2 分区裁剪

```sql
-- ✅ 必须包含分区字段条件（Trino）
WHERE date >= date_add('day', -7, current_date)
  AND date <= current_date
```

### 9.3 提前过滤

```sql
-- ✅ 在 JOIN 前先过滤（Trino）
FROM (
    SELECT * FROM large_table 
    WHERE date = current_date
) t1
JOIN small_table t2 ON t1.id = t2.id
```

---

## 十、常见错误对照表

| 错误写法（MySQL/Hive） | 正确写法（Trino） | 说明 |
|----------------------|-----------------|------|
| `CURDATE()` | `current_date` | 当前日期 |
| `CURRENT_DATE()` | `current_date` | 当前日期 |
| `NOW()` | `current_timestamp` | 当前时间戳 |
| `DATE_ADD(date, INTERVAL 1 DAY)` | `date_add('day', 1, date)` | 日期加法 |
| `DATE_SUB(date, INTERVAL 1 DAY)` | `date_add('day', -1, date)` | 日期减法 |
| `DATEDIFF(date1, date2)` | `date_diff('day', date1, date2)` | 日期差值 |
| `DATE_FORMAT(date, '%Y-%m-%d')` | `date_format(date, '%Y-%m-%d')` | 日期格式化 |
| `STR_TO_DATE(str, format)` | `date_parse(str, format)` | 字符串转日期 |
| `CONCAT(str1, str2)` | `concat(str1, str2)` 或 `str1 \|\| str2` | 字符串连接 |
| `LENGTH(str)` | `length(str)` | 字符串长度 |
| `SUBSTRING(str, 0, 10)` | `substr(str, 1, 10)` | 字符串截取（注意起始位置） |

---

## 十一、快速检查清单

生成 SQL 后，检查以下 Trino 语法要点：

- [ ] 日期函数使用 `date_add('day', n, date)` 而不是 `DATE_ADD()`
- [ ] 当前日期使用 `current_date` 而不是 `CURDATE()`
- [ ] 日期差值使用 `date_diff('day', date1, date2)` 而不是 `DATEDIFF()`
- [ ] 类型转换使用 `cast(column as type)` 
- [ ] 字符串连接使用 `concat()` 或 `||`
- [ ] 数组长度使用 `cardinality()` 或 `array_length()`
- [ ] 大数据量时考虑使用 `approx_distinct()` 而不是 `count(distinct)`
- [ ] 字符串截取使用 `substr(str, 1, n)` （从 1 开始）

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建 Trino 语法速查指南 |

---

**重要提醒**: 所有 ChatBI 生成的 SQL 必须严格遵循 Trino 语法规范！
