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
│   │   ├── tables/              # 各表 YAML 定义
│   │   ├── TEMPLATE.yaml
│   │   ├── trino_syntax.md      # Trino 语法参考
│   │   └── README.md
│   ├── semantics/               # Layer B: 业务语义
│   │   ├── templates/           # 各类语义文件的模板（新增定义时从这里复制）
│   │   ├── entities/            # 实体（用户、帖子…）
│   │   ├── events/              # 业务过程（注册、活跃…）
│   │   ├── dimensions/          # 维度（实体属性 + 计算属性分群）
│   │   └── README.md
│   ├── patterns/                # Layer C: 计算模式
│   │   ├── count_distinct.yaml
│   │   ├── cohort_retention.yaml
│   │   ├── sum_metric.yaml
│   │   ├── TEMPLATE.yaml
│   │   └── README.md
│   ├── metrics/                 # Layer D: 指标目录
│   │   ├── dau.yaml
│   │   ├── mau.yaml
│   │   ├── new_user_count.yaml
│   │   ├── d1_retention_rate.yaml
│   │   ├── d7_retention_rate.yaml
│   │   ├── post_user_count.yaml
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
├── docs/                        # 系统文档（架构、实施指南等）
├── feedback/                    # 反馈收集（纠错、知识缺口）
└── tests/                       # 测试用例
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

## 快速示例

### 示例 1：简单查询

**用户**：查询昨天的 DAU

**AI 处理**：
- 匹配 `metrics/dau.yaml` → 使用 `count_distinct` pattern
- 语义参数展开：`subject=active_user`（活跃用户定义）、`anchor=dws_user_daily`
- 分区条件：`date = date_add('day', -1, current_date)`

```sql
-- DAU：昨天的日活跃用户数
SELECT
    date,
    COUNT(DISTINCT user_id) AS dau
FROM dws_user_daily
WHERE date = date_add('day', -1, current_date)
  AND is_active = 1
GROUP BY date
```

### 示例 2：需要澄清的查询

**用户**：帮我看下新用户的留存

**AI 澄清**：
1. 时间范围？最近 30 天 / 本月 / 上月 / 其他
2. 留存类型？次日留存（D1）/ 7 日留存（D7）/ 留存曲线
3. 是否分维度？按注册渠道 / 按日期 / 仅看整体

**用户**：最近 30 天，D1，按日期

**AI** 匹配 `metrics/d1_retention_rate.yaml` → `cohort_retention` pattern → 生成 SQL

---

## 知识库扩充

### 处理原始资料（最简单的方式）

1. 将原始文档（Word、Excel、SQL 文件、截图描述等）放入 `raw_knowledge/mixed/`
2. 告诉 AI："请处理 raw_knowledge/mixed/xxx"
3. AI 自动解析并写入对应的四层目录

> 详见 `raw_knowledge/README.md` 和 `skills/07_raw_knowledge_processing.md`

### 手动补充知识

| 要补充的内容 | 目标位置 |
|-------------|----------|
| 新的数据表 | `knowledge/schema/tables/新表名.yaml` |
| 新的业务实体/事件/维度 | `knowledge/semantics/`（模板在 `semantics/templates/`） |
| 新的计算逻辑 | `knowledge/patterns/新模式.yaml` |
| 新的指标 | `knowledge/metrics/新指标.yaml` |

语义层（entities/events/dimensions）的模板统一在 `knowledge/semantics/templates/`；其他层各目录内有 `TEMPLATE.yaml` 可参考。

---

## AI 行为规范

- 所有 SQL 使用 **Trino 语法**（禁止 MySQL / Hive / Presto 语法）
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
| `docs/architecture.md` | 系统架构设计 |
| `docs/implementation_guide.md` | 实施指南 |
