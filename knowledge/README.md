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
└── metrics/         # 指标目录（Metric）  ← 哪个组合有名字
```

---

## 各层职责

### 数据字典（Schema）`schema/`

描述数据仓库的**物理事实**：表、字段、类型、分区、表间关联。

AI 在生成 SQL 时，从这里获取：字段名、数据类型、分区字段、枚举值、JOIN 字段。

### 业务语义（Semantics）`semantics/`

将**业务语言翻译为数据条件**，是理解需求的核心。

- `entities/`：业务对象，定义统计主键
- `events/`：业务过程，定义事件对应的表和识别条件
- `dimensions/`：实体的属性（值必须是有限离散分类值），分两种场景：
  - **实体属性**：值可从表中直接读取或 CASE WHEN 计算 → 有 `sql_expr`
  - **计算属性**：值需通过子查询计算归属 → 有 `named_values`

### 计算模式（Pattern）`patterns/`

**可复用的参数化 SQL 模板**，定义"怎么算"。

参数类型直接引用语义层：
- `Entity` → `semantics/entities/` 中的 `entity_id`，取 `primary_key` 用于 COUNT DISTINCT
- `Event[]` → `semantics/events/` 中的 `event_id`，展开为事件表 + 类型条件，多个取并集（OR）
- `Dimension[]` → `semantics/dimensions/` 中的 `dimension_id`，取 `sql_expr` 用于 GROUP BY + SELECT
- `list<{dimension_id, value}>` → 维度字段值过滤，展开为 `WHERE sql_expr = 'value'`
- `Dimension.NamedValue[]` → 某维度 `named_values[].value_id`，展开为归属子查询，多个取交集（AND）

### 指标目录（Metric）`metrics/`

**有名字的指标**，是语义原子 + 计算模式的具名组合。

只登记有独立命名、口径有历史争议或高频使用的指标。即时推导的查询不需要登记。

---

## AI 使用流程（与 `.cursorrules` 六步对齐）

```
用户需求
    ↓
【1. 需求解析】查 semantics/ 识别实体/事件/维度；查 metrics/ 识别有名字的指标
    ↓
【2. 需求澄清】对模糊 / 多义项给出选项，并给推荐
    ↓
【3. 知识检索】依次展开：metrics → patterns → semantics → schema/tables
    - metrics/：拿到 pattern 和参数
    - patterns/：拿到 SQL 模板结构
    - semantics/：将参数（entity/event/dimension/named_value）解析为表名、字段名、SQL 片段
    - schema/tables/：核对字段存在性、获取 storage.partition_field
    ↓
【4. SQL 生成】套入 pattern 模板、展开参数；所有表都必须带分区条件
    ↓
【5. SQL 验证】对照知识库自检：语法 / 表&字段存在性 / 逻辑 / 口径 / 性能
    ↓
【6. 结果输出】复述需求 → SQL → 技术方案 → 执行说明 → 结果字段说明 → 注意事项
```

> 阶段术语约定：步骤 1 把用户的"过滤条件"统称 `filter_by`；落到步骤 3-4 的 pattern 契约时展开为 `event` / `where_named_values` / `where_dimension_values` 三个字段。

---

## 维护分工

| 变化类型 | 修改位置 |
|----------|----------|
| 新增或修改数据表 | `schema/tables/` |
| 新增业务概念（新的实体/事件/维度） | `semantics/` |
| 发现新的计算模式 | `patterns/` |
| 需要固化指标口径 | `metrics/` |

---

## 占位符写法约定

本仓库的文档与 TEMPLATE.yaml 使用以下约定的占位符，统一风格，便于复制后替换：

| 占位符 | 含义 | 示例 |
|--------|------|------|
| `<xxx>` | 必填值，复制时替换为真实内容 | `<entity_id>`、`<schema>.<table_name>` |
| `<xxx_col>` / `<xxx_field>` | 某个具体字段 | `<partition_field>`、`<metric_col>` |
| `${var}` | 运行期参数（由 Pattern / Metric 实例化时代入） | `${target_date}`、`${window_days}` |
| `<...>` 在 SQL 示例中 | 等同 `${var}`，表示"运行期展开"的骨架位 | `WHERE <partition_field> = ${target_date}` |

**避免**：

- 不要在知识库文档中使用会被 Trino 识别为标识符的占位符（如直接写 `user_id` 当作示例字段），容易和真实字段混淆；
- 不要把 `{xxx}` 和 `${xxx}` 混用，后者专指运行期变量。
