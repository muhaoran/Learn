# Skill: 结果解释

---

## 目标

清晰地向用户解释生成的 SQL，包括技术方案、执行说明、结果字段等。

---

## 触发条件

SQL 验证通过后，输出给用户时触发。

---

## 输入

- 生成并验证通过的 SQL
- 需求信息
- 技术方案信息

---

## 处理步骤

### 步骤 1: 复述需求

**目标**: 确认理解正确。

**格式**:
```markdown
## 需求理解

您的需求是：[用标准术语复述需求]
```

**结构**:
```markdown
## 需求理解

您的需求是：查询 <时间范围> 内 <指标名>，按 <维度> 分组；<如有筛选条件，此处加一句>。
```

### 步骤 2: 展示 SQL

**格式**:
```markdown
## SQL 语句

```sql
[格式化的 SQL 代码]
```
```

**注意**:
- SQL 必须格式化（缩进、换行）
- 必须有注释
- 代码块使用 sql 语法高亮

### 步骤 3: 说明技术方案

**格式**:
```markdown
## 技术方案

### 使用的数据表
- **主表**: [表名] - [用途和选择理由]
- **关联表**: [表名] - [用途和关联方式]

### 计算逻辑
[用简单的语言说明计算逻辑]

### 关键技术点
- [技术点 1]
- [技术点 2]
```

**结构**（以 `cohort_retention` 类指标为例）:
```markdown
## 技术方案

### 使用的数据表
- **主表**: `<cohort_event.source_table>` - 提供 D0 基准队列与分组维度
- **关联表**: `<retain_event.source_table>` - 判定 D+N 留存

### 计算逻辑
1. 从 cohort_event 的来源表取 D0 队列（实体 + D0 日期 + group_by 字段）
2. 从 retain_event 的来源表取 D+N 的留存实体
3. 使用 `LEFT JOIN cohort → retained` 保留未留存成员，保证分母正确
4. 按 <group_by> 分组
5. 留存率 = `COUNT(DISTINCT retained)` / `NULLIF(COUNT(DISTINCT cohort), 0)`

### 关键技术点
- 使用 CTE 把 cohort 与 retained 分层
- LEFT JOIN 保证分母不丢失
- D+N 日期用 `date_add('day', N, cohort_date)` 计算
- 严格按照 `knowledge/patterns/cohort_retention.yaml` 的骨架展开
```

### 步骤 4: 说明执行信息

**格式**:
```markdown
## 执行说明

- **数据表**: [表名]
- **数据范围**: [时间范围、分区范围]
- **预计数据量**: [数据量估计]
- **预计耗时**: [时间估计]
```

**结构**:
```markdown
## 执行说明

- **数据表**: `<table_1>`, `<table_2>`
- **数据范围**: 
  - 主表分区: `<start_date>` 至 `<end_date>`（共 N 天）
  - JOIN 表分区: `<start_date>` 至 `<end_date>`（共 M 天）
- **预计数据量**: 按需从 schema 的表描述或历史跑数经验给出；无把握时写 "待评估"
- **预计耗时**: 根据所用表的层级给经验值（ADS / DWS 通常秒级；DWD 按分区范围给区间）
```

### 步骤 5: 说明结果字段

**格式**:
```markdown
## 结果字段说明

| 字段名 | 含义 | 示例值 | 单位 | 备注 |
|--------|------|--------|------|------|
| ... | ... | ... | ... | ... |
```

**结构**:
```markdown
## 结果字段说明

| 字段名 | 含义 | 单位 | 备注 |
|--------|------|------|------|
| <dimension_alias_1> | <维度业务含义> | - | 来自 `<dimension_id>` |
| <dimension_alias_2> | <维度业务含义> | - | 来自 `<dimension_id>` |
| <metric_alias> | <指标业务含义> | <单位> | 保留 <n> 位小数；来自 metric `<metric_id>` |
```

### 步骤 6: 提示注意事项

**格式**:
```markdown
## 注意事项

- ⚠️ [注意事项 1]
- ⚠️ [注意事项 2]
- ✅ [优点说明]
```

**结构**:
```markdown
## 注意事项

- ⚠️ <边界数据是否完整：如留存类指标末端日期依赖 D+N 数据更新>
- ⚠️ <性能提示：明细表范围、是否涉及大 JOIN>
- ⚠️ <口径提示：是否含特定客户分群 / 是否排除特定业务类型>
- ✅ 已使用所有相关表的 `partition_field` 过滤
- ✅ 计算逻辑与 `knowledge/metrics/<metric_id>.yaml` 定义一致
```

---

## 输出

完整的说明文档，包括：
1. 需求理解
2. SQL 语句
3. 技术方案
4. 执行说明
5. 结果字段说明
6. 注意事项

---

## 完整输出骨架

> 真实对话中把占位符替换为本次检索到的具体 metric / pattern / table / 字段。骨架本身不绑定任何业务场景。

```markdown
## 需求理解

您的需求是：查询 <时间范围> 内 <指标名>，按 <维度> 分组。

---

## SQL 语句

```sql
-- <指标名>，<时间范围>，按 <维度> 分组
SELECT 
    <group_by.sql_expr>,
    <pattern 定义的聚合表达式> AS <metric_alias>
FROM <event.source_table>
WHERE <partition_field> <时间过滤>
  AND <event.type_condition>
  AND <where_dimension_values.sql_expr = value>     -- 如有
  AND <where_named_values.sql_condition>            -- 如有
GROUP BY <group_by.sql_expr>
ORDER BY <group_by.sql_expr>;
```

---

## 技术方案

### 使用的数据表
- **主表**: `<event.source_table>` - <选择理由，如：ADS/DWS 层、已预聚合等>

### 计算逻辑
1. 从主表按分区过滤取出 <时间范围> 的数据
2. 应用 `<event.type_condition>` 与 `<where_named_values.sql_condition>` / `<where_dimension_values.sql_expr = value>`
3. 按 `<group_by.sql_expr>` 分组
4. 按 pattern `<pattern_id>` 的聚合方式计算 `<metric_alias>`

### 关键技术点
- 优先用 <汇总层/明细层> 的说明
- 时间函数使用 Trino 语法（`date_add`, `current_date`）
- 去重 / NULLIF / 分区过滤都按 pattern 与验证清单处理

---

## 执行说明

- **数据表**: `<table>`
- **数据范围**: <分区范围与天数>
- **预计耗时**: <按表层级给经验值>

---

## 结果字段说明

| 字段名 | 含义 | 单位 | 备注 |
|--------|------|------|------|
| <dimension_alias> | <维度含义> | - | 来自 `<dimension_id>` |
| <metric_alias> | <指标含义> | <单位> | 来自 metric `<metric_id>` |

---

## 注意事项

- ⚠️ <边界 / 数据延迟 / 口径>
- ✅ <已做的优化或约束：分区过滤、使用汇总层等>
```

---

## 注意事项

### 1. 语言风格

- 专业但不过度技术化
- 简洁清晰
- 使用业务术语而非技术术语（除非必要）

**对比**:
- ✅ "使用汇总层表，单次查询成本低"
- ❌ "用 DWS 宽表避免了 shuffle"（过度技术化）

### 2. 结构化输出

使用清晰的标题和列表，便于阅读。

### 3. 突出重点

使用 ⚠️ 和 ✅ 等符号突出重要信息。

### 4. 提供上下文

不要只给 SQL，要说明为什么这样写。

---

## 成功标准

- ✅ 需求复述准确
- ✅ SQL 清晰可读
- ✅ 技术方案说明清楚
- ✅ 结果字段含义明确
- ✅ 注意事项完整

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建文档 |
| 2026-04-20 | AI | 清理虚构示例；cohort_retention 技术方案说明改用 cohort_event/retain_event；WHERE 过滤文案拆分 filter_by 为 where_named_values/where_dimension_values |
