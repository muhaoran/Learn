# 业务语义（Semantics）

## 职责

将**业务语言翻译为数据条件**，是 AI 理解需求的核心。

数据字典（Schema）告诉 AI "有什么"，业务语义（Semantics）告诉 AI "什么意思"。

---

## 三个子层

### 实体（Entity）`entities/`

业务中的核心对象，是大多数指标的统计主体。

- 定义"统计谁"：明确主键字段，让 AI 知道 `COUNT DISTINCT` 用哪个字段
- 通常对应现实业务中一类对象（具体类型由业务决定）

### 业务过程（Event）`events/`

某类业务动作**发生了**的事实，不包含筛选和评价。

- 定义"什么叫做 X 发生了"：映射到具体的表和条件
- 只描述事件类型的识别条件（如某张多事件共存表里通过 `event_type = '...'` 区分），**不包含属性过滤**
- 必填字段：
  - `source_table`：事件记录在哪张表
  - `date_field`：业务日期字段（事件发生日），供 `cohort_retention` 等 pattern 对齐 D0/D+N；与 `schema/tables/*.yaml` 的 `storage.partition_field` 是两回事（业务日期不一定等于分区字段）
  - `type_condition`（可选）：多事件共存表中用于区分本事件的类型条件

### 维度（Dimension）`dimensions/`

实体的属性，值必须是有限离散的分类值，用于 GROUP BY 或 WHERE 过滤。

两种业务场景：
- **实体属性**：实体本身具备这个属性，值可从表中直接读取或计算 → 填 `source_table` + `join_key` + `sql_expr`，用 `known_values` 记录枚举含义
- **计算属性**：属性值无法从字段直接读取，需通过行为或关联数据计算 → 用 `named_values` 的自包含子查询定义每个取值的归属条件

**字段说明**：

| 字段 | 属于 | 含义 |
|------|------|------|
| `dimension_id` | 通用 | 维度英文标识，全小写下划线，文件名与之一致 |
| `entity` | 通用 | 该维度描述的实体（对应 `entities/` 中的 `entity_id`） |
| `aliases` | 通用 | 别名列表（黑话识别用） |
| `source_table` | 实体属性 | 维度字段所在的表（带 schema 的完整名） |
| `join_key` | 实体属性 | 与实体主键连接的字段名（用于 JOIN 时对齐） |
| `sql_expr` | 实体属性 | SELECT / GROUP BY / WHERE 里使用的表达式（可以是字段名或 CASE WHEN 表达式） |
| `known_values` | 实体属性 | 可选，记录该字段已知枚举值及业务含义 |
| `named_values` | 计算属性 | 命名取值列表（每项代表一个分群定义） |
| `named_values[].value_id` | 计算属性 | 该取值的英文标识，供指标通过 `where_named_values` 引用 |
| `named_values[].depends_on_events` | 计算属性 | 该取值的归属逻辑依赖的 `event_id` 列表；对应事件如有变更需同步更新 |
| `named_values[].parameters` | 计算属性 | 该取值的可变参数（如时间窗口天数），`sql_condition` 中通过 `${param_name}` 引用 |
| `named_values[].sql_condition` | 计算属性 | 自包含子查询，形如 `<entity.primary_key> IN (SELECT ... WHERE ...)` |

---

## 目录结构

```
semantics/
├── README.md
├── templates/                  # ← 新增定义时从这里复制
│   ├── entity.yaml
│   ├── event.yaml
│   └── dimension.yaml
├── entities/
│   └── {entity_id}.yaml        # 一个实体一个文件，文件名 = entity_id
├── events/
│   └── {event_id}.yaml         # 一个事件一个文件，文件名 = event_id
└── dimensions/
    └── {dimension_id}.yaml     # 一个维度一个文件，文件名 = dimension_id
```

> 文件命名约定：`{xxx_id}` 与 YAML 文件中的 `entity_id` / `event_id` / `dimension_id` 字段保持一致，便于交叉引用。

---

## 边界说明

| 放在 Semantics | 不放在 Semantics |
|----------------|-----------------|
| 业务术语的口径定义（"X 行为"包含哪些动作） | 具体的 SQL 查询逻辑（放在 Pattern） |
| 业务概念的判定规则（"X 类用户"如何判定） | 有名字的指标如何计算（放在 Metric） |
| 维度的取值枚举与含义 | 字段的物理类型（放在 Schema） |
| 跨表的概念归属规则 | 多个指标之间的组合关系（放在 Metric） |
