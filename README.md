# ChatBI 系统

> 智能数据分析助手 —— 用自然语言描述需求，AI 自动生成准确的 Trino SQL

---

## 项目目标

**业务方提交数据需求（自然语言）→ AI 自动生成完全符合业务口径的 SQL**

核心价值：
- **效率**：10-20 倍提升（从 10-30 分钟到 10-30 秒）
- **准确**：基于知识库，严格遵循业务定义和数据口径
- **知识沉淀**：将业务语义、计算逻辑、数据资产系统化

---

## 知识库架构

采用**四层可组合架构**，每层职责单一、互相解耦：

```
Layer A  schema/       数据字典   ——  表名、字段、类型、分区（物理层）
Layer B  semantics/    业务语义   ——  实体、业务过程、维度（语义层）
Layer C  patterns/     计算模式   ——  可复用的参数化 SQL 模板（逻辑层）
Layer D  metrics/      指标目录   ——  有名字的指标 = Pattern + 语义参数（指标层）
```

> Layer A/B/C/D 仅为**文字助记**，按"物理 → 语义 → 逻辑 → 指标"的抽象层级升序；与 AI 查询顺序（D → C → B → A）正好相反，互不冲突。

> 详细设计见 `design_philosophy/02_composable_knowledge_architecture.md`

**AI 生成 SQL 的检索顺序**：
1. `knowledge/metrics/` — 找到指标，获取所用 Pattern 和参数
2. `knowledge/patterns/` — 展开 SQL 模板
3. `knowledge/semantics/` — 将语义参数解析为表名、字段、SQL 条件
4. `knowledge/schema/tables/` — 确认字段存在，获取分区信息

---

## 目录结构

```
/
├── README.md                    # 本文档
├── GETTING_STARTED.md           # 使用指南
├── .cursorrules                 # AI 行为规则
│
├── knowledge/                   # 结构化知识库（核心）
│   ├── schema/                  # Layer A: 数据字典
│   │   ├── tables/              # 各表 YAML 定义（按真实业务表名命名）
│   │   ├── TEMPLATE.yaml
│   │   ├── trino_syntax.md      # Trino 语法参考
│   │   └── README.md
│   ├── semantics/               # Layer B: 业务语义
│   │   ├── templates/           # 各类语义文件的模板（新增定义时从这里复制）
│   │   ├── entities/            # 实体定义
│   │   ├── events/              # 业务过程定义
│   │   ├── dimensions/          # 维度定义（实体属性 + 计算属性）
│   │   └── README.md
│   ├── patterns/                # Layer C: 计算模式
│   │   ├── count_distinct.yaml  # 去重计数
│   │   ├── cohort_retention.yaml # 同期群留存
│   │   ├── sum_metric.yaml      # 求和类指标
│   │   ├── TEMPLATE.yaml
│   │   └── README.md
│   ├── metrics/                 # Layer D: 指标目录
│   │   ├── TEMPLATE.yaml
│   │   └── README.md
│   └── README.md
│
├── raw_knowledge/               # 原始知识资料（待 AI 处理）
│   ├── mixed/                   # 放原始资料（乱序混杂均可）
│   ├── processed/               # 处理完毕后归档
│   └── README.md
│
├── skills/                      # AI 技能定义
│   ├── 01_requirement_parsing.md
│   ├── 02_requirement_clarification.md
│   ├── 03_knowledge_retrieval.md
│   ├── 04_sql_generation.md
│   ├── 05_sql_validation.md
│   ├── 06_result_explanation.md
│   └── 07_raw_knowledge_processing.md
│
├── design_philosophy/           # 设计哲学文档
└── feedback/                    # 反馈收集（纠错、知识缺口、新案例）
```

---

## 工作流程

```
用户需求（自然语言）
    ↓
1. 需求解析    提取指标、维度（group_by）、时间范围、筛选条件
    ↓
2. 需求澄清    识别歧义，提供选项，主动提问
    ↓
3. 知识检索    按四层顺序：metrics → patterns → semantics → schema
    ↓
4. SQL 生成    展开 Pattern 模板，填入语义参数，输出 Trino SQL
    ↓
5. SQL 验证    语法 / 字段存在 / 业务口径 / 性能
    ↓
6. 结果输出    SQL + 技术方案 + 字段说明 + 注意事项
```

---

## 基本用法

### 直接提需求

向 AI 用自然语言描述要查询的指标，AI 会基于 `knowledge/` 中已登记的指标、模式、语义和表结构生成 Trino SQL。

一个完整的需求建议包含四要素：

| 要素 | 说明 |
|------|------|
| **指标** | 查什么（已登记指标的名字或别名） |
| **时间** | 什么时间段（具体日期、最近 N 天、某月份等） |
| **维度** | 如何分组（按某业务维度，如已定义的维度名） |
| **筛选** | 是否限定特定子集（特定分群、特定状态等） |

如果需求模糊，AI 会主动澄清，给出可选项让你选择。

### 处理原始资料（推荐入门方式）

1. 把原始文档（Word、Excel、SQL 文件、需求文档等）放入 `raw_knowledge/mixed/`
2. 告诉 AI："请处理 raw_knowledge/mixed/xxx"
3. AI 自动解析并写入对应的四层目录

> 详见 `raw_knowledge/README.md` 和 `skills/07_raw_knowledge_processing.md`

### 手动补充知识

| 要补充的内容 | 目标位置 |
|-------------|----------|
| 新的数据表 | `knowledge/schema/tables/{表名}.yaml` |
| 新的业务实体/事件/维度 | `knowledge/semantics/`（模板在 `semantics/templates/`） |
| 新的计算逻辑 | `knowledge/patterns/{模式名}.yaml` |
| 新的指标 | `knowledge/metrics/{指标名}.yaml` |

语义层（entities/events/dimensions）的模板统一在 `knowledge/semantics/templates/`；其他层各目录内有 `TEMPLATE.yaml` 可参考。

---

## AI 行为规范

- 所有 SQL 使用 **Trino 语法**（禁止 MySQL / Hive 专属语法；Trino 与 PrestoSQL 兼容，但遇 PrestoDB 专属函数时以 Trino 文档为准）
- 优先使用汇总表（ADS > DWS > DWD > ODS）
- WHERE 条件必须包含分区字段
- 不能使用知识库之外的表或字段
- 不能自行定义指标口径

> 详见 `.cursorrules` 和 `design_philosophy/03_cursorrules_design.md`

---

## 相关文档

| 文档 | 说明 |
|------|------|
| `GETTING_STARTED.md` | 面向使用者的操作指南 |
| `knowledge/README.md` | 知识库整体说明 |
| `design_philosophy/02_composable_knowledge_architecture.md` | 四层架构设计详解 |
| `design_philosophy/03_cursorrules_design.md` | AI 行为规范设计依据 |
