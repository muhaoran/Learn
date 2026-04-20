# Skill: SQL 生成

---

## 目标

基于需求和检索到的知识，生成准确、高效、可读的 SQL 语句（使用 Trino 语法）。

**重要**: 所有 SQL 必须使用 Trino 语法规范。Trino 是 PrestoSQL 的继承版本，多数 Presto 语法可直接使用；但必须以 Trino 官方文档为准，不得使用 MySQL、Hive 专属语法，也不得使用 PrestoDB（Facebook 分支）与 Trino 已不兼容的函数。

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
| `Entity` | `${entity.primary_key}` → 实体定义中的主键字段名 |
| `Event` | `${event.source_table}` → 事件的表名；`${event.type_condition}` → 类型过滤条件（如有） |
| `Dimension` | `${dimension.sql_expr}` → 字段名或表达式；需要 JOIN 时加入 JOIN 子句 |
| `NamedValue` | `${named_value.sql_condition}` → 展开为子查询条件 |
| `date_expr` | 直接替换为 Trino 日期表达式 |

**展开示意**（以 count_distinct Pattern 为例）：
```
参数代入前（模板）:
  COUNT(DISTINCT ${entity.primary_key}) FROM ${event.source_table} WHERE ${time_window}

参数代入后:
  COUNT(DISTINCT <entity.primary_key>) FROM <event.source_table> WHERE <time_window 的实际表达式>
```

### 步骤 2: 选择数据表

**原则**:
1. 优先使用汇总表（ADS > DWS > DWD > ODS），已由 Schema 层的 `layer` 字段标注
2. 如果 Pattern 需要的语义对象只存在于明细表，则使用明细表
3. **所有 SQL 必须使用 Trino 语法**

**决策流程**:
```
Event 对应的 source_table 是什么层？
├─ ADS/DWS → 直接使用，性能好 ✅
└─ DWD → 使用，但必须加分区条件 ⚠️
```

**做法**：
- 读取 Event 定义中的 `source_table`，再对应到 `knowledge/schema/tables/<table>.yaml` 的 `layer` 字段选择最高层级。
- 如果同一业务含义在 DWS 和 DWD 都存在（Event 定义会指明），按上表优先级选择。

### 步骤 3: 构建 WHERE 条件

**必须包含**:
1. **分区字段**: 必须有，避免全表扫描
2. **时间范围**: 根据需求设置
3. **筛选条件**: 根据需求设置

**结构**:
```sql
WHERE 
    -- 分区字段（必须，字段名来自对应表的 storage.partition_field）
    <partition_field> >= <start_date>
    AND <partition_field> < <end_date>
    
    -- 业务筛选条件（来自需求 + 维度命名取值的 sql_condition）
    AND <filter_condition_1>
    AND <filter_condition_2>
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

**结构**:
```sql
SELECT 
    -- 维度字段（来自 group_by 维度的 sql_expr）
    <dimension_expr_1>,
    <dimension_expr_2>,
    
    -- 指标字段（来自 pattern 定义的聚合字段）
    <aggregate_expr> AS <metric_alias>,
    
    -- 比值类计算字段：必须用 NULLIF 防除零
    ROUND(<numerator> * 1.0 / NULLIF(<denominator>, 0), <precision>) AS <ratio_alias>
```

**注意**:
- 避免 SELECT *
- 别名使用指标定义中的 `metric_id` 或 `name` 对应的英文名
- 比值类必须 `NULLIF(denominator, 0)`

### 步骤 5: 构建 JOIN（如果需要）

**原则**:
1. 根据表关联关系文档确定 JOIN 条件
2. 选择正确的 JOIN 类型（LEFT/INNER）
3. 小表驱动大表

**JOIN 类型选择**:
- **LEFT JOIN**: 需要保留左表所有记录（如 `cohort_retention` 的 base/retained 关联）
- **INNER JOIN**: 只需要两表都有的记录

**结构**:
```sql
FROM <left_table> <l>
LEFT JOIN <right_table> <r>
  ON  <l>.<join_key> = <r>.<join_key>
  AND <r>.<partition_field> <时间关系>       -- JOIN 表自己的分区过滤也必须加
```

**注意**:
- JOIN 条件要完整
- **JOIN 表自己的分区字段也必须在 ON 或 WHERE 中过滤**（主表分区无法下推到 JOIN 表）
- 避免笛卡尔积

### 步骤 6: 构建 GROUP BY

**原则**:
1. 包含所有维度字段
2. 不包含聚合字段

**结构**:
```sql
GROUP BY 
    <dimension_expr_1>,
    <dimension_expr_2>
```

**注意**:
- GROUP BY 的字段必须与 SELECT 中的非聚合字段完全一致
- 使用字段表达式或字段别名都可以，但在同一份 SQL 中保持一致风格

### 步骤 7: 构建 ORDER BY

**原则**:
1. 时间维度通常升序（ASC）
2. 指标通常降序（DESC）
3. 多个排序字段注意优先级

**结构**:
```sql
ORDER BY 
    <time_dimension> ASC,
    <metric_alias> DESC
```

### 步骤 8: 添加注释

**原则**:
1. 为整个 SQL 添加总体说明（指标 + 时间范围 + 分组维度）
2. 为 CTE 添加说明（这个 CTE 做了什么）
3. 为复杂逻辑添加说明（比值计算、窗口函数等）
4. 不要为显而易见的代码添加注释

**结构**:
```sql
-- <指标名>，<时间范围>，按 <维度> 分组

WITH <cte_1> AS (
    -- <cte_1 的业务含义>
    SELECT ...
),
<cte_2> AS (
    -- <cte_2 的业务含义>
    SELECT ...
)
-- 主查询：<做什么>
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

## 技术方案

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

## 生成模板

> 下列结构是各 Pattern 的 SQL 骨架，真实使用时 `<...>` 占位由步骤 1-3 检索到的语义展开填充。具体指标如何落地请参考 `knowledge/metrics/` 下的 yaml 与 `knowledge/patterns/` 下的 `example_usage` 段。

### 骨架 1: count_distinct（去重计数）

```sql
-- <指标名>，<时间范围>，按 <维度> 分组

SELECT 
    <group_by.sql_expr>,
    COUNT(DISTINCT <entity.primary_key>) AS <metric_alias>
FROM <event.source_table>
WHERE <partition_field> <时间过滤>
  AND <event.type_condition>                                -- 如有
  AND <where_dimension_values.sql_expr = value>             -- 如有
  AND <where_named_values.sql_condition>                    -- 如有
GROUP BY <group_by.sql_expr>;
```

### 骨架 2: cohort_retention（队列留存）

```sql
-- <基准事件> 后 <offset_days> 天的留存率，按 <维度> 分组

WITH cohort AS (
    -- 基准队列：cohort_date 这天触发了 cohort_event 的实体及 D0 日期
    SELECT 
        <entity.primary_key>,
        <cohort_event.date_field> AS cohort_date,
        <group_by.sql_expr>            -- 如果分组维度在 cohort 表中
    FROM <cohort_event.source_table>
    WHERE <cohort_date>                -- 参数 cohort_date 展开的 SQL 条件
      AND <partition_field> <时间过滤>
),
retained AS (
    -- 留存判定：D+N 天仍活跃 / 再次触发 retain_event
    SELECT DISTINCT <entity.primary_key>
    FROM <retain_event.source_table OR entity.anchor_tables[<key>]>
    WHERE <retain_event.type_condition>  -- 如有
      AND <retain_where_dimension_values.sql_expr = value>  -- 如有
      AND <retain_where_named_values.sql_condition>         -- 如有
      AND date IN (SELECT date_add('day', <offset_days>, cohort_date) FROM cohort)
)
SELECT 
    <group_by.sql_expr>,
    COUNT(DISTINCT c.<entity.primary_key>)                          AS cohort_size,
    COUNT(DISTINCT r.<entity.primary_key>)                          AS retained_count,
    ROUND(COUNT(DISTINCT r.<entity.primary_key>) * 100.0
        / NULLIF(COUNT(DISTINCT c.<entity.primary_key>), 0), 2)    AS retention_rate
FROM cohort c
LEFT JOIN retained r USING (<entity.primary_key>)
GROUP BY <group_by.sql_expr>
ORDER BY <group_by.sql_expr>;
```

### 骨架 3: sum_metric（聚合求和）

```sql
-- <指标名>，<时间范围>，按 <维度> 分组

SELECT 
    <group_by.sql_expr>,
    SUM(<sum_field>) AS <metric_alias>
FROM <event.source_table | entity.anchor_tables[<key>]>     -- 事件型 / 快照型二选一
WHERE <partition_field> <时间过滤>
  AND <event.type_condition>                                -- 事件型时展开
  AND <where_dimension_values.sql_expr = value>             -- 如有
  AND <where_named_values.sql_condition>                    -- 如有
GROUP BY <group_by.sql_expr>;
```

---

## 注意事项

### 1. 严格遵循业务定义

**错误示例**:
```sql
-- ❌ 错误：对去重类指标忘记加 DISTINCT
SELECT COUNT(<entity.primary_key>) AS <metric_alias>
```

**正确示例**:
```sql
-- ✅ 正确：按 pattern 定义（count_distinct 要求 DISTINCT）
SELECT COUNT(DISTINCT <entity.primary_key>) AS <metric_alias>
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
| 2026-04-20 | AI | cohort_retention 骨架参数统一为 cohort_event/retain_event/cohort_date；count_distinct 与 sum_metric 骨架将 filter_by 拆为 event+where_named_values+where_dimension_values；结果输出小节标题统一为"技术方案" |
