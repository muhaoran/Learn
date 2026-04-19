# Skill: SQL 生成

---

## 目标

基于需求和检索到的知识，生成准确、高效、可读的 SQL 语句（使用 Trino 语法）。

**重要**: 所有 SQL 必须使用 Trino 语法规范，不能使用 MySQL、Hive、Presto 等其他数据库的语法。

---

## 触发条件

知识检索完成后触发。

---

## 输入

- 澄清后的需求
- 检索到的业务知识
- 检索到的数据资产信息
- 相似的 SQL 案例

---

## 处理步骤

### 步骤 1: 展开 Pattern 模板

**这是新架构下 SQL 生成的核心步骤。**

知识检索已经提供了：
- Pattern 的 `sql_template`
- 每个参数对应的语义解析结果（表名、字段名、SQL 条件）

现在按以下规则将参数代入模板：

| 参数类型 | 展开规则 |
|----------|----------|
| `Entity` | `${entity.primary_key}` → 实体的主键字段名（如 `user_id`） |
| `Event` | `${event.source_table}` → 事件的表名；`${event.type_condition}` → 类型过滤条件（如有） |
| `Dimension` | `${dimension.sql_expr}` → 字段名或表达式；需要 JOIN 时加入 JOIN 子句 |
| `NamedValue` | `${named_value.sql_condition}` → 展开为子查询条件 |
| `date_expr` | 直接替换为 Trino 日期表达式 |

**示例**（count_distinct Pattern，DAU 需求）：
```
参数代入前（模板）:
  COUNT(DISTINCT ${entity.primary_key}) FROM ${event.source_table} WHERE ${time_window}

参数代入后:
  COUNT(DISTINCT user_id) FROM dwd_user_behavior WHERE date = '2024-01-01'
```

### 步骤 2: 选择数据表

**原则**:
1. 优先使用汇总表（ADS > DWS > DWD > ODS），已由 Schema 层的 `layer` 字段标注
2. 如果 Pattern 需要的语义对象只存在于明细表，则使用明细表
3. **所有 SQL 必须使用 Trino 语法**

**决策流程**:
```
Event 对应的 source_table 是什么层？
├─ DWS/ADS → 直接使用，性能好 ✅
└─ DWD → 使用，但必须加分区条件 ⚠️
```

**示例**:
- 查询 DAU（active_behavior）→ `dwd_user_behavior`（明细），或改用 `dws_user_daily`（汇总，is_active=1）
- 查询新增用户数（registration）→ `dwd_user_register`
- 查询留存率（cohort_retention）→ `dwd_user_register` + `dwd_user_behavior`

### 步骤 3: 构建 WHERE 条件

**必须包含**:
1. **分区字段**: 必须有，避免全表扫描
2. **时间范围**: 根据需求设置
3. **筛选条件**: 根据需求设置

**示例**:
```sql
WHERE 
    -- 分区字段（必须）
    date >= '2024-01-01'
    AND date < '2024-01-08'
    
    -- 业务筛选条件
    AND is_active = 1
    AND platform = 'iOS'
```

**注意**:
- 时间范围使用左闭右开区间
- 字符串使用单引号
- 注意 NULL 值处理

### 步骤 4: 构建 SELECT 字段

**包含**:
1. **维度字段**: 用于分组的字段
2. **指标字段**: 计算的指标
3. **字段别名**: 清晰的别名

**示例**:
```sql
SELECT 
    -- 维度字段
    date,
    register_channel,
    
    -- 指标字段
    COUNT(DISTINCT user_id) as dau,
    SUM(post_count) as total_posts,
    
    -- 计算字段
    ROUND(SUM(post_count) * 1.0 / COUNT(DISTINCT user_id), 2) as avg_posts_per_user
```

**注意**:
- 避免 SELECT *
- 使用有意义的别名
- 计算字段要处理精度和 NULL

### 步骤 5: 构建 JOIN（如果需要）

**原则**:
1. 根据表关联关系文档确定 JOIN 条件
2. 选择正确的 JOIN 类型（LEFT/INNER）
3. 小表驱动大表

**JOIN 类型选择**:
- **LEFT JOIN**: 需要保留左表所有记录（如留存分析、转化分析）
- **INNER JOIN**: 只需要两表都有的记录

**示例**:
```sql
-- 留存分析：必须用 LEFT JOIN
FROM 
    dwd_user_register r
LEFT JOIN 
    dwd_user_behavior b
ON 
    r.user_id = b.user_id
    AND b.date = date_add('day', 1, r.register_date)
```

**注意**:
- JOIN 条件要完整
- 注意分区字段的过滤
- 避免笛卡尔积

### 步骤 6: 构建 GROUP BY

**原则**:
1. 包含所有维度字段
2. 不包含聚合字段

**示例**:
```sql
GROUP BY 
    date,
    register_channel
```

**注意**:
- GROUP BY 的字段必须在 SELECT 中（或在聚合函数中）
- 注意数据库的 GROUP BY 语法差异

### 步骤 7: 构建 ORDER BY

**原则**:
1. 时间维度通常升序（ASC）
2. 指标通常降序（DESC）
3. 多个排序字段注意优先级

**示例**:
```sql
ORDER BY 
    date ASC,           -- 时间升序
    dau DESC            -- 指标降序
```

### 步骤 8: 添加注释

**原则**:
1. 为整个 SQL 添加总体说明
2. 为 CTE 添加说明
3. 为复杂逻辑添加说明
4. 不要为显而易见的代码添加注释

**示例**:
```sql
-- 计算 2024 年 1 月新用户的次日留存率，按注册渠道分组

WITH new_users AS (
    -- 获取 1 月份的新注册用户
    SELECT ...
),
retention_users AS (
    -- 获取次日活跃的用户
    SELECT ...
)
-- 主查询：计算留存率
SELECT ...
```

---

## 输出

完整的 SQL 语句 + 说明文档。

**格式**:
```markdown
## SQL 语句

```sql
[SQL 代码]
```

## 技术方案说明

- **使用的表**: [表名] - [选择理由]
- **关联方式**: [关联说明]
- **计算逻辑**: [逻辑说明]

## 执行说明

- **数据范围**: [说明]
- **预计耗时**: [说明]
- **注意事项**: [说明]

## 结果字段说明

| 字段名 | 含义 | 示例值 |
|--------|------|--------|
| ... | ... | ... |
```

---

## 示例

### 示例 1: 简单查询

**需求**: 查询昨天的 DAU

**生成过程**:
1. Pattern: `count_distinct`，参数: entity=user, event=active_behavior, time_window=昨天
2. 语义展开: primary_key=user_id, source_table=dwd_user_behavior
3. 时间展开: `date = date_add('day', -1, current_date)`（Trino 语法）
4. 可优化：改用汇总表 dws_user_daily（is_active=1），性能更好

**生成的 SQL**:
```sql
-- 查询昨天的 DAU（使用汇总表，性能好）
SELECT 
    date,
    COUNT(DISTINCT user_id) AS dau
FROM 
    dws_user_daily
WHERE 
    date = date_add('day', -1, current_date)
    AND is_active = 1
GROUP BY 
    date;
```

### 示例 2: 复杂查询

**需求**: 计算 1 月份新用户的次日留存率，按渠道分

**生成过程**:
1. Pattern: `cohort_retention`，参数: entity=user, cohort_event=registration, retain_event=active_behavior, offset_days=1, group_by=user_register_channel
2. 展开模板：cohort 表 = dwd_user_register，retain 表 = dwd_user_behavior
3. group_by 展开：register_channel 来自 dwd_user_register，已在 cohort CTE 中，无需额外 JOIN

**生成的 SQL**:
```sql
-- 计算 2024 年 1 月新用户的次日留存率，按注册渠道分组

WITH cohort AS (
    -- 基准：1 月份新注册用户
    SELECT 
        user_id,
        register_date,
        register_channel
    FROM 
        dwd_user_register
    WHERE 
        register_date >= DATE '2024-01-01'
        AND register_date < DATE '2024-02-01'
),
retained AS (
    -- 留存：在注册后第 1 天有活跃行为
    SELECT DISTINCT b.user_id
    FROM 
        dwd_user_behavior b
    JOIN cohort c ON b.user_id = c.user_id
    WHERE 
        b.date = date_add('day', 1, c.register_date)
)
SELECT 
    c.register_date,
    c.register_channel,
    COUNT(DISTINCT c.user_id)                                         AS cohort_size,
    COUNT(DISTINCT r.user_id)                                         AS retained_count,
    ROUND(COUNT(DISTINCT r.user_id) * 100.0
        / NULLIF(COUNT(DISTINCT c.user_id), 0), 2)                   AS retention_rate
FROM 
    cohort c
LEFT JOIN 
    retained r ON c.user_id = r.user_id
GROUP BY 
    c.register_date,
    c.register_channel
ORDER BY 
    c.register_date,
    c.register_channel;
```

---

## 注意事项

### 1. 严格遵循业务定义

**错误示例**:
```sql
-- ❌ 错误：自己定义了 DAU 的计算方式
SELECT COUNT(user_id) as dau  -- 没有去重
```

**正确示例**:
```sql
-- ✅ 正确：按照业务定义
SELECT COUNT(DISTINCT user_id) as dau  -- 去重
```

### 2. 遵循 SQL 最佳实践

参考 `knowledge/schema/README.md` 中的 JOIN 编写原则：
- 必须使用分区字段
- 避免 SELECT *
- 正确去重
- 处理 NULL 值
- 使用 CTE 提高可读性

### 3. 参考但不照搬案例

相似案例可以参考，但要根据具体需求调整：
- 表名可能不同
- 字段名可能不同
- 筛选条件不同
- 时间范围不同

### 4. 考虑性能

- 优先使用汇总表
- 限制时间范围（明细表不超过 30 天）
- 避免全表扫描
- 合理使用索引

---

## SQL 生成检查清单

生成 SQL 后，自检：

- [ ] 是否使用了正确的表？
- [ ] 是否包含分区字段条件？
- [ ] 是否正确去重（DISTINCT）？
- [ ] 是否处理了 NULL 值？
- [ ] 时间范围是否正确？
- [ ] JOIN 类型是否正确？
- [ ] 计算逻辑是否符合业务定义？
- [ ] 是否有清晰的注释？
- [ ] 字段别名是否清晰？
- [ ] 是否有明显的性能问题？

如果有任何一项不满足，修改 SQL。

---

## 成功标准

- ✅ SQL 语法正确
- ✅ 完全符合需求
- ✅ 符合业务定义
- ✅ 遵循最佳实践
- ✅ 有清晰的注释
- ✅ 性能可接受

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建文档 |
