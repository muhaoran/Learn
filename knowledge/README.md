# 知识库总览

本知识库是 ChatBI 系统的 AI 推理基础，按**可组合知识架构**组织，分为四个相互独立、逐层调用的层级。

架构设计详见：`design_philosophy/02_composable_knowledge_architecture.md`

---

## 目录结构

```
knowledge/
├── schema/          # 数据字典（Schema）  ← 有什么
├── semantics/       # 业务语义（Semantics）← 什么意思
├── patterns/        # 计算模式（Pattern） ← 怎么算
├── metrics/         # 指标目录（Metric）  ← 哪个组合有名字
└── sql_examples/    # SQL 案例库          ← 验证参考
```

---

## 各层职责

### 数据字典（Schema）`schema/`

描述数据仓库的**物理事实**：表、字段、类型、分区、表间关联。

AI 在生成 SQL 时，从这里获取：字段名、数据类型、分区字段、枚举值、JOIN 字段。

### 业务语义（Semantics）`semantics/`

将**业务语言翻译为数据条件**，是理解需求的核心。

- `entities/`：业务对象（用户、帖子…），定义统计主键
- `events/`：业务过程（注册、活跃…），定义事件对应的表和识别条件
- `dimensions/`：实体的属性（值必须是有限离散分类值），分两种场景：
  - **实体属性**：值可从表中直接读取或 CASE WHEN 计算（渠道、平台）→ 有 `sql_expr`
  - **计算属性**：值需通过子查询计算归属（活跃状态、首购状态）→ 有 `named_values`

### 计算模式（Pattern）`patterns/`

**可复用的参数化 SQL 模板**，定义"怎么算"。

参数类型直接引用语义层：
- `Entity` → `semantics/entities/` 中的 `entity_id`，取 `primary_key` 用于 COUNT DISTINCT
- `Event[]` → `semantics/events/` 中的 `event_id`，展开为事件表 + 类型条件，多个取并集（OR）
- `Dimension[]` → `semantics/dimensions/` 中的 `dimension_id`，取 `sql_expr` 用于 GROUP BY + SELECT
- `map<Dimension, value>` → dimension_id 到具体值的映射，展开为 `WHERE sql_expr = 'value'`
- `Dimension.NamedValue[]` → 某维度 `named_values[].value_id`，展开为归属子查询，多个取交集（AND）

### 指标目录（Metric）`metrics/`

**有名字的指标**，是语义原子 + 计算模式的具名组合。

只登记有独立命名、口径有历史争议或高频使用的指标。即时推导的查询不需要登记。

---

## AI 使用流程

```
用户需求
    ↓
1. 解析需求 → 识别实体/事件/维度/时间（查 semantics/）
2. 确认口径 → 检查是否有已登记指标（查 metrics/）
3. 选择模式 → 匹配计算方式（查 patterns/）
4. 补充字段 → 确认表名和字段名（查 schema/）
5. 生成 SQL → 套入模板，展开参数
6. 验证 SQL → 参考 sql_examples/ 对比
```

---

## 维护分工

| 变化类型 | 修改位置 |
|----------|----------|
| 新增或修改数据表 | `schema/tables/` |
| 新增业务概念（新的实体/事件/维度） | `semantics/` |
| 发现新的计算模式 | `patterns/` |
| 需要固化指标口径 | `metrics/` |
| AI 生成了典型 SQL | `sql_examples/` |

