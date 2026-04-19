# Skill: 知识检索

---

## 目标

从知识库中检索与当前需求相关的信息，为 SQL 生成提供完整依据。

新架构下，检索遵循**四层依次展开**的顺序：
指标目录（Metric）→ 计算模式（Pattern）→ 业务语义（Semantics）→ 数据字典（Schema）

---

## 触发条件

需求澄清完成后，在生成 SQL 之前触发。

---

## 输入

- 澄清后的需求（结构化信息，包含指标名、维度、时间范围、筛选条件）

---

## 处理步骤

### 步骤 1: 检索指标目录（Metric）

**目标**: 判断用户提到的指标是否已有锁定的口径定义。

**检索范围**: `knowledge/metrics/`

**方法**:
1. 用需求解析中识别出的指标名，匹配各 yaml 文件的 `name` 和 `aliases`
2. 如果找到匹配项，读取其 `pattern` 和 `pattern_params`
3. 如果没有找到，该指标可以即时推导（跳到步骤 2 直接根据需求确定 Pattern）

**输出示例**:
```
指标: DAU
找到: knowledge/metrics/dau.yaml
  pattern: count_distinct
  pattern_params:
    entity: user
    event: "active_behavior"
    time_window: date = ${target_date}
```

---

### 步骤 2: 检索计算模式（Pattern）

**目标**: 获取 SQL 模板结构，理解"怎么算"。

**检索范围**: `knowledge/patterns/`

**方法**:
1. 根据步骤 1 中的 `pattern` 字段（或需求推导出的计算方式），找到对应的 Pattern 文件
2. 读取 `sql_template` 和 `parameters` 定义
3. 核对步骤 1 传入的参数是否满足 Pattern 的所有 required 参数

**常见映射**:
- 统计去重数量 → `count_distinct`
- 近 N 日去重（滚动窗口）→ `count_distinct`，`time_window` 使用 `{end_date, window_days}` 形态
- 留存率 → `cohort_retention`
- 求和 → `sum_metric`
- 比值类指标 → 分子分母各走一次 `count_distinct` / `sum_metric`，同表内联或跨表 CTE

**输出示例**:
```
Pattern: count_distinct
sql_template: 读取自 knowledge/patterns/count_distinct.yaml
需要参数: entity, event, time_window, group_by(可选), where_dimension_values(可选), where_named_values(可选)
当前参数: entity=user, event=active_behavior, time_window=date='2024-01-01'
```

---

### 步骤 3: 检索业务语义（Semantics）

**目标**: 将 Pattern 参数中的语义 ID 展开为具体的表名、字段名、SQL 条件。

**检索范围**: `knowledge/semantics/`

**按参数类型分别检索**:

#### Entity 参数
- 读取 `knowledge/semantics/entities/{entity_id}.yaml`
- 获取 `primary_key`（COUNT DISTINCT 的字段）和 `anchor_table`

#### Event 参数
- 读取 `knowledge/semantics/events/{event_id}.yaml`
- 获取 `source_table` 和 `type_condition`（如果有）

#### Dimension 参数（group_by）
- 读取 `knowledge/semantics/dimensions/{dimension_id}.yaml`
- 获取 `sql_expr`、`source_table`、`join_key`

#### NamedValue 参数（where_named_values）
- 读取 `knowledge/semantics/dimensions/*.yaml` 中对应的 `named_values` 条目
- 获取 `sql_condition`（可能含参数）和 `depends_on_events`

**输出示例**:
```
Entity(user):
  primary_key: user_id
  anchor_table: dim_user

Event(active_behavior):
  source_table: dwd_user_behavior
  type_condition: (无，全表都是活跃行为)

Dimension(user_register_channel) [group_by]:
  source_table: dwd_user_register
  join_key: user_id
  sql_expr: register_channel
```

---

### 步骤 4: 检索数据字典（Schema）

**目标**: 确认表名和字段名在数据仓库中真实存在，获取字段类型和性能注意事项。

**检索范围**: `knowledge/schema/tables/`

**方法**:
1. 根据步骤 3 中识别出的所有 `source_table`，找到对应的 yaml 文件
2. 验证需要用到的字段名是否存在
3. 确认分区字段（用于 WHERE 条件）
4. 读取 `notes` 中的性能注意事项

**输出示例**:
```
表: dwd_user_behavior
  分区字段: date（必须在 WHERE 中指定）
  用到的字段: user_id ✅, date ✅
  注意: 数据量极大，必须加 date 分区条件

表: dwd_user_register（group_by 需要 JOIN）
  分区字段: register_date
  用到的字段: user_id ✅, register_channel ✅
```

---

### 步骤 5: 整合检索结果

将四层检索结果汇总，交给 SQL 生成步骤使用。

**输出结构**:
```
retrieval_result:
  metric: dau（来自 metrics/dau.yaml）
  pattern: count_distinct（来自 patterns/count_distinct.yaml）
  semantic_resolution:
    entity: {id: user, primary_key: user_id}
    event: {id: active_behavior, source_table: dwd_user_behavior}
    group_by: [{id: user_register_channel, sql_expr: register_channel, source_table: dwd_user_register, join_key: user_id}]
  schema:
    dwd_user_behavior: {partition: date, notes: [必须加 date 分区条件]}
    dwd_user_register: {partition: register_date}
  ready_for_generation: true
```

---

## 知识缺失处理

### 情况 1: 指标在 metrics/ 中不存在

不一定是问题，可能是即时推导的指标。进入步骤 2 根据需求描述推导 Pattern。

如果连推导都不明确，主动询问用户：
```
"您想统计的是哪类指标？以下哪个最接近您的需求：
A. 去重用户数（COUNT DISTINCT）
B. 求和（SUM）
C. 留存率（同期群分析）"
```

### 情况 2: 语义 ID 在 semantics/ 中不存在

说明该实体/事件/维度尚未定义，告知用户：
```
"知识库中暂无「XX维度」的定义。请告知：
1. 这个维度对应哪张表的哪个字段？
2. 需要我将其加入知识库吗？"
```

### 情况 3: 表或字段在 schema/ 中不存在

```
"知识库中暂无表 XXX 的文档。请确认：
1. 表名是否正确？
2. 这张表的分区字段是什么？"
```

---

## 成功标准

- ✅ 指标对应的 Pattern 已确认
- ✅ 所有 Pattern 参数已展开为具体表名、字段名、SQL 条件
- ✅ 所有用到的表在 schema/ 中都有记录
- ✅ 分区字段已确认（避免全表扫描）
- ✅ 知识缺口已标注并告知用户

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建文档 |
| 2026-04-09 | AI | 按新四层架构重构检索流程 |
