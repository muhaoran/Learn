# Skill: SQL 验证

---

## 目标

验证生成的 SQL 是否正确、是否符合需求、是否有性能问题。

---

## 触发条件

SQL 生成后，输出给用户前触发。

---

## 输入

- 生成的 SQL 语句
- 原始需求
- 业务定义

---

## 处理步骤

### 步骤 1: 语法验证

**检查项**:
- [ ] SQL 语法是否正确
- [ ] 关键字拼写是否正确
- [ ] 括号是否匹配
- [ ] 逗号是否正确

**方法**:
- 如果可以连接数据库，使用 EXPLAIN 验证
- 否则，进行静态语法检查

### 步骤 2: 表和字段验证

**检查项**:
- [ ] 表名是否存在于数据字典中
- [ ] 字段名是否存在于表结构中
- [ ] 字段类型是否匹配使用方式

**方法**:
1. 提取 SQL 中的所有表名
2. 在 `knowledge/schema/tables/` 中查找对应的 yaml 文件
3. 提取 SQL 中的所有字段名
4. 在表 yaml 的 `columns` 列表中验证字段是否存在

**做法**:
- 用正则提取 SQL 中的 `FROM <table>` 和 `JOIN <table>` 得到表清单，再对每个表的 `columns` 列表核对 SELECT / WHERE / JOIN ON / GROUP BY 里出现的每个字段。
- 含 `<schema>.<table>` 的完整引用可以和 `full_name` 字段匹配；短名用 `table_id` 字段匹配。

### 步骤 3: 逻辑验证

**检查项**:
- [ ] SQL 逻辑是否符合需求
- [ ] 计算逻辑是否正确
- [ ] 去重逻辑是否合理
- [ ] JOIN 类型是否正确
- [ ] 时间范围是否正确

**验证方法**:

#### 3.1 指标计算验证

对照 `knowledge/metrics/<metric>.yaml` 和 `knowledge/patterns/<pattern>.yaml` 的定义，检查：
- SQL 是否用了该 metric 绑定的 pattern 的骨架；
- pattern 的必填参数是否都已代入；
- `event` / `where_named_values` / `where_dimension_values` / `group_by` 的展开结果是否与 metric 里声明的一致（早期文档中统称 `filter_by`，现已拆成事件与 where_* 过滤两类）。

#### 3.2 去重验证

**检查**:
- 计数类指标（pattern = `count_distinct`）是否使用了 `COUNT(DISTINCT <primary_key>)`；
- GROUP BY 是否覆盖了所有 SELECT 中的非聚合字段。

```sql
-- ✅ 正确
COUNT(DISTINCT <entity.primary_key>)

-- ❌ 错误：pattern 要求去重，但 SQL 漏写 DISTINCT
COUNT(<entity.primary_key>)
```

#### 3.3 JOIN 类型验证

**检查**: JOIN 类型是否符合 pattern 语义。

```sql
-- ✅ cohort_retention 要求保留 base 队列的所有实体
FROM <base> LEFT JOIN <retained> ON ...

-- ❌ 用 INNER JOIN 会把未留存的实体从分母中剔除，导致留存率计算错误
FROM <base> INNER JOIN <retained> ON ...
```

#### 3.4 时间范围验证

**检查**:
- 时间范围是否符合需求
- 时间计算是否正确（如 D1 = D0 + 1）
- 是否使用了正确的时间函数

**示例**（字段名用占位 `<partition_field>`，实际按表的 `storage.partition_field` 填）:
```sql
-- 需求: 最近 7 天（含今天）
-- ✅ 正确（Trino 语法）
WHERE <partition_field> >= date_add('day', -6, current_date)
  AND <partition_field> <= current_date

-- ❌ 错误：少了一天
WHERE <partition_field> >= date_add('day', -7, current_date)
  AND <partition_field> < current_date

-- ❌ 错误：MySQL 语法，不能用
WHERE <partition_field> >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
```

### 步骤 4: 口径验证

**检查项**:
- [ ] 是否符合业务定义
- [ ] 计算规则是否一致
- [ ] 数据范围是否正确

**方法**:
1. 对照指标定义文档
2. 检查计算公式
3. 检查数据口径

**做法**：逐项对账
- 业务定义（取自 metric yaml 中的 `definition` / `pattern_params`）
- SQL 中分子 / 分母 / 过滤条件 / JOIN 类型
- 是否用 `NULLIF(denominator, 0)` 防除零

### 步骤 5: 性能验证

**检查项**:
- [ ] 是否使用了分区字段
- [ ] 时间范围是否合理（明细表不超过 30 天）
- [ ] 是否避免了全表扫描
- [ ] 是否使用了合适的表（汇总表 vs 明细表）

**性能风险评估**:

| 风险等级 | 特征 | 处理 |
|----------|------|------|
| 🔴 高风险 | 明细表无分区条件 | 必须修改 |
| 🟡 中风险 | 明细表查询超过 30 天 | 建议优化 |
| 🟢 低风险 | 使用汇总表，有分区条件 | 可以接受 |

**示例**（字段名用占位）:
```sql
-- 🔴 高风险：没有分区条件，DWD 明细表会全扫
SELECT COUNT(*) FROM <dwd_table> WHERE <non_partition_field> = <value>;

-- 🟢 低风险：有分区条件，使用汇总表
SELECT <metric_alias> FROM <ads_or_dws_table> WHERE <partition_field> = <date_value>;
```

---

## 输出

验证结果 + 修改建议（如果有问题）。

**格式**:
```json
{
  "validation_result": {
    "syntax": {"pass": true, "issues": []},
    "tables_fields": {"pass": true, "issues": []},
    "logic": {"pass": true, "issues": []},
    "caliber": {"pass": true, "issues": []},
    "performance": {"pass": true, "issues": [], "risk_level": "low"}
  },
  "overall": "pass",
  "suggestions": []
}
```

如果有问题:
```json
{
  "validation_result": {
    "logic": {
      "pass": false, 
      "issues": ["<具体问题描述，例如：cohort_retention 应该 LEFT JOIN，不能 INNER JOIN>"]
    }
  },
  "overall": "fail",
  "suggestions": ["<修复建议>"]
}
```

---

## 常见错误模式

> 以下列出的是验证阶段最需要警惕的错误类型，每类给出错因与修复方向，具体 SQL 以真实需求为准。

| 错误类型 | 典型表现 | 后果 | 修复方向 |
|---------|---------|-----|---------|
| 去重漏 DISTINCT | `count_distinct` pattern 指标写成 `COUNT(<field>)` | 指标被放大 | 加 `DISTINCT`，或直接按 pattern 展开 |
| JOIN 类型错配 | `cohort_retention` 写成 `INNER JOIN` | 分母丢失未留存成员，留存率偏高 | 改为 `LEFT JOIN base → retained` |
| JOIN 表缺分区 | 主表分区过滤了，JOIN 表没过滤 | JOIN 表全表扫描 | 在 `ON` 或 `WHERE` 补 JOIN 表的 `partition_field` 过滤 |
| 比值类缺 NULLIF | `numerator / denominator` | 分母为 0 时报错或产出 NULL | `NULLIF(<denominator>, 0)` |
| 时间边界偏差 | "最近 N 天（含今天）"误写成 `[-N, -1]` 区间 | 比需求少一天 | `>= date_add('day', -(N-1), current_date) AND <= current_date` |
| 非 Trino 语法 | 出现 `DATE_SUB` / `CURRENT_DATE()` / Hive `datediff` 等 | 执行失败 | 改为 `date_add` / `date_diff` / `current_date` |
| 明细表无分区过滤 | 明细表 `WHERE` 只有业务过滤，没有 `partition_field` | 全表扫描 | 必须加分区条件 |

---

## 注意事项

### 1. 验证要全面

不能只检查语法，必须检查逻辑、口径、性能。

### 2. 对照业务定义

计算逻辑必须严格对照 `knowledge/metrics/` 和 `knowledge/patterns/` 中的定义，不能自行修改口径。

### 3. 性能优先

如果发现性能问题，必须修改，不能输出有性能风险的 SQL。

### 4. 自动修复

如果发现问题，尝试自动修复，而不是只告诉用户有问题。

---

## 错误处理

### 情况 1: 验证失败但无法修复

如果发现问题但无法自动修复：
1. 说明问题
2. 给出修改建议
3. 或请求用户提供更多信息

### 情况 2: 多个问题

如果发现多个问题：
1. 按优先级排序（性能 > 逻辑 > 格式）
2. 逐个修复
3. 修复后重新验证

---

## 成功标准

- ✅ 所有验证项都通过
- ✅ 没有明显的性能风险
- ✅ 完全符合业务定义
- ✅ 符合 SQL 最佳实践

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建文档 |
| 2026-04-20 | AI | 清理虚构示例；将 `filter_by` 校验条目扩展为 `event`/`where_named_values`/`where_dimension_values`/`group_by` 四项一致性 |
