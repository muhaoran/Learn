# 计算模式（Pattern）

## 职责

定义**可复用的参数化 SQL 结构**，解决"怎么算"的问题。

每个 Pattern 是一个带参数的 SQL 模板，参数类型明确引用业务语义层（Entity / Event / Dimension / Dimension.NamedValue），由此实现"语义 → SQL"的标准化转换。

---

## Pattern 的本质

Pattern 不是具体指标，而是**计算方式**的抽象。

- `count_distinct` → 去重计数（DAU、MAU、发帖用户数、近N日活跃… 都是这个模式；滚动窗口通过 `time_window.window_days` 参数指定）
- `sum_metric` → 求和类指标（交易额、发帖数… 都是这个模式；同样支持滚动窗口）
- `cohort_retention` → 同期群留存（D1留存、D7留存… 都是这个模式）
- 比值类指标（转化率、渗透率…）不单独成模式：分子分母各走一次 `count_distinct` 或 `sum_metric`，同表内联计算，跨表用 CTE

---

## 目录结构

```
patterns/
├── README.md
├── TEMPLATE.yaml
├── count_distinct.yaml       # 去重计数（含滚动窗口）
├── cohort_retention.yaml     # 同期群留存
└── sum_metric.yaml           # 求和类指标（含滚动窗口）
```

---

## 参数类型说明

| 类型 | SQL 展开结果 | 对应语义层文件 |
|------|-------------|---------------|
| `Entity` | 展开为实体主键字段名，用于 `COUNT DISTINCT` | `semantics/entities/` |
| `Event[]` | 展开为事件表名 + 类型识别条件，用于 `FROM` 和 `WHERE`；多个取并集（OR） | `semantics/events/` |
| `Dimension[]` | 有 `sql_expr` 的展开为字段直接分组；有 `named_values` 的展开为 `CASE WHEN` 分组列；需要时自动 JOIN 维度表 | `semantics/dimensions/` |
| `list<{dimension_id, value}>` | 展开为 `WHERE sql_expr = 'value'`；需要时自动 JOIN 维度表 | `semantics/dimensions/` |
| `Dimension.NamedValue[]` | 展开为归属判断子查询，用于 `WHERE primary_key IN (...)`；多个取交集（AND） | `semantics/dimensions/` 中某维度的 `named_values` |
| `date_expr` | 日期过滤条件，直接嵌入 `WHERE`，如 `date = '2024-01-01'` | — |
| `{end_date, window_days}` | 滚动窗口时间条件，展开为 `date > date_add('day', -window_days, DATE 'end_date') AND date <= DATE 'end_date'` | — |
| `integer` | 整数字面量，直接替换模板变量 | — |
| `float` | 浮点数字面量，直接替换模板变量 | — |

---

## 维护规范

- 新增 Pattern 前先确认是否已有类似模式
- `sql_template` 中的变量用 `${variable_name}` 表示
- 每个 Pattern 必须有完整的 `example_usage` 示例
