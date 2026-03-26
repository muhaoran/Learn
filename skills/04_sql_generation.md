# Skill: SQL 生成

---

## 目标

基于需求和检索到的知识，生成准确、高效、可读的 SQL 语句。

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

### 步骤 1: 确定 SQL 结构

**根据需求复杂度选择结构**:

#### 简单查询（单表）
```sql
SELECT 
    [字段]
FROM 
    [表]
WHERE 
    [条件]
GROUP BY 
    [分组]
ORDER BY 
    [排序];
```

#### 中等复杂度（多表关联）
```sql
SELECT 
    [字段]
FROM 
    [主表]
LEFT JOIN 
    [关联表]
ON 
    [关联条件]
WHERE 
    [条件]
GROUP BY 
    [分组]
ORDER BY 
    [排序];
```

#### 高复杂度（使用 CTE）
```sql
WITH cte1 AS (
    [子查询1]
),
cte2 AS (
    [子查询2]
)
SELECT 
    [字段]
FROM 
    cte1
LEFT JOIN 
    cte2
ON 
    [关联条件]
GROUP BY 
    [分组]
ORDER BY 
    [排序];
```

### 步骤 2: 选择数据表

**原则**: 
1. 优先使用汇总表（ADS > DWS > DWD > ODS）
2. 如果需要自定义逻辑，使用明细表
3. 参考相似案例的表选择

**决策流程**:
```
是否有现成的汇总表？
├─ 是 → 汇总表是否满足需求？
│  ├─ 是 → 使用汇总表 ✅
│  └─ 否 → 使用明细表
└─ 否 → 使用明细表
```

**示例**:
- 查询 DAU → 使用 `dws_user_daily`（有预计算的 DAU）
- 查询特定行为的用户数 → 使用 `dwd_user_behavior`（需要筛选 behavior_type）
- 查询留存率 → 使用 `dwd_user_register` + `dwd_user_behavior`

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
    AND b.date = DATE_ADD(r.register_date, INTERVAL 1 DAY)
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
1. 确定结构: 简单查询（单表）
2. 选择表: `dws_user_daily`
3. 构建 WHERE: `date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)`
4. 构建 SELECT: `COUNT(DISTINCT user_id) as dau`
5. 不需要 GROUP BY（只要总数）

**生成的 SQL**:
```sql
-- 查询昨天的 DAU
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    AND is_active = 1
GROUP BY 
    date;
```

### 示例 2: 复杂查询

**需求**: 计算 1 月份新用户的次日留存率，按渠道分

**生成过程**:
1. 确定结构: 高复杂度（使用 CTE）
2. 选择表: `dwd_user_register` + `dwd_user_behavior`
3. CTE1: 获取新用户
4. CTE2: 获取留存用户
5. 主查询: 关联计算留存率

**生成的 SQL**:
```sql
-- 计算 2024 年 1 月新用户的次日留存率，按注册渠道分组

WITH new_users AS (
    -- 获取 1 月份的新注册用户
    SELECT 
        user_id,
        DATE(register_time) as register_date,
        register_channel
    FROM 
        dwd_user_register
    WHERE 
        register_date >= '2024-01-01'
        AND register_date < '2024-02-01'
),
retention_users AS (
    -- 获取次日活跃的用户
    SELECT 
        nu.user_id,
        nu.register_date,
        nu.register_channel
    FROM 
        new_users nu
    INNER JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        -- 关键: D1 = D0 + 1 天
        AND ub.date = DATE_ADD(nu.register_date, INTERVAL 1 DAY)
)
SELECT 
    nu.register_date,
    nu.register_channel,
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
    AND nu.register_channel = ru.register_channel
GROUP BY 
    nu.register_date,
    nu.register_channel
ORDER BY 
    nu.register_date,
    nu.register_channel;
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

参考 `knowledge/data_assets/best_practices.md`：
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
