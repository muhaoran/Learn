# 计算规则模板

> 计算规则提供复杂指标的详细计算方法和 SQL 模板

---

## 📋 什么是计算规则？

- ✅ 复杂指标的详细实现（如"次日留存率"）
- ❌ 不是简单指标（简单指标直接在 metrics/ 中定义）

**何时需要计算规则**：
- 需要多表关联
- 有复杂时间计算
- 有多个计算步骤
- 容易出错
- SQL > 30行

---

## 📝 标准模板

## [计算规则名称]

**规则名称**: [名称]

**适用指标**: 
- [指标1](../metrics/xxx.md#指标1)

**复杂度**: [简单/中等/复杂/非常复杂]

**引用关系**:
- **引用的术语**: [术语1](../glossary.md#术语1)
- **引用的维度**: [维度1](../dimensions/xxx.md#维度1)
- **引用的指标**: [指标1](../metrics/xxx.md#指标1)

**计算公式**:
[指标] = [数学表达式]

其中:
- [变量1]: [说明]
- [变量2]: [说明]

**计算步骤**: ⭐核心

> 将复杂计算分解为清晰的步骤

**步骤1**: [第一步做什么]
- 输入: [输入数据]
- 操作: [具体操作]
- 输出: [输出结果]
- SQL 片段:
  ```sql
  WITH step1 AS (
      SELECT ... FROM ... WHERE ...
  )
  ```

**步骤2**: [第二步做什么]
- 输入: [步骤1的输出]
- 操作: [具体操作]
- 输出: [输出结果]
- SQL 片段:
  ```sql
  step2 AS (
      SELECT ... FROM step1 ...
  )
  ```

**步骤3**: [最终计算]
- 输入: [前面步骤的输出]
- 操作: [计算比率/聚合]
- 输出: [最终指标]
- SQL 片段:
  ```sql
  SELECT 
      COUNT(DISTINCT ...) / COUNT(DISTINCT ...) * 100.0
  FROM ...
  ```

**完整 SQL 模板** (Trino 语法):
```sql
-- [计算规则名称]
-- 业务含义: [一句话说明]

WITH step1 AS (
    -- 步骤1: [说明]
    SELECT ...
    FROM ...
    WHERE ...
),
step2 AS (
    -- 步骤2: [说明]
    SELECT ...
    FROM step1
    ...
)
-- 最终计算
SELECT 
    [维度],
    COUNT(DISTINCT ...) as [分子],
    COUNT(DISTINCT ...) as [分母],
    ROUND(
        CAST(COUNT(DISTINCT ...) AS DOUBLE) * 100.0 
        / NULLIF(COUNT(DISTINCT ...), 0),
        2
    ) as [指标]
FROM step1
[LEFT/INNER] JOIN step2
  ON [关联条件]
GROUP BY [维度]
ORDER BY [维度];
```

**关键技术点**: ⭐核心

> 最重要、最容易出错的地方

**技术点1**: [技术点名称]
- 说明: [为什么重要]
- ✅ 正确: [应该怎么做]
- ❌ 错误: [不应该怎么做]
- 后果: [做错了会怎样]

**技术点2**: [...]

**常见错误**: ⭐核心

> 实际使用中经常出现的错误

| 错误 | 表现 | 后果 | 正确做法 |
|------|------|------|---------|
| [错误1] | [如何表现] | [导致什么] | [应该怎么做] |
| [错误2] | [...] | [...] | [...] |

**变体场景**:

**变体1**: [变体名称]
- 需求变化: [相比基础场景的变化]
- SQL 调整: [需要修改哪些部分]

**变体2**: [...]

**性能说明**:
- 数据量: [预估]
- 执行时间: [预估]
- 优化建议: [建议]

**维护信息**:
- 负责人: [xxx]
- 更新时间: [YYYY-MM-DD]
```

---

## 🔑 核心说明

### ⭐ 关键技术点（必须说"为什么"）

**不仅说"怎么做"，还要说"为什么"**

**示例**：
```
技术点: 必须使用 LEFT JOIN

✅ 好的说明:
- 为什么: 需要保留所有基准用户（包括未留存的）
- 正确: LEFT JOIN
- 错误: INNER JOIN
- 后果: 遗漏未留存用户，分母变小，留存率从30%变成100%

❌ 不好的说明:
- 使用 LEFT JOIN（没有说为什么）
```

### ⭐ 常见错误（必须说"后果"）

**不仅说"不要这样"，还要说"后果是什么"**

**示例**：
```
错误: 使用 INNER JOIN

✅ 好的说明:
- 表现: FROM base INNER JOIN retention
- 后果: 遗漏未留存用户，留存率虚高（30% → 100%）
- 正确: 使用 LEFT JOIN

❌ 不好的说明:
- 不要使用 INNER JOIN（没有说后果）
```

---

## 📊 完整示例

```markdown
## 次日留存率计算规则

**规则名称**: 次日留存率计算规则

**适用指标**: 
- [次日留存率](../metrics/user_metrics.md#次日留存率)

**复杂度**: 非常复杂 ⭐⭐⭐⭐⭐

**引用关系**:
- **引用的术语**: [新增用户](../glossary.md#新增用户)、[活跃用户](../glossary.md#活跃用户)
- **引用的维度**: [日](../dimensions/time_dimensions.md#日)

**计算公式**:
```
次日留存率 = (D1活跃用户数 / D0新增用户数) × 100%

其中:
- D0: 注册日
- D1: 注册日 + 1天
```

**计算步骤**:

**步骤1**: 获取 D0 新增用户
- 输入: dwd_user_register
- 操作: 筛选指定日期注册的用户
- 输出: user_id, register_date
- SQL:
  ```sql
  WITH base_users AS (
      SELECT user_id, cast(register_time as date) as register_date
      FROM dwd_user_register
      WHERE register_date = date '2024-01-01'
  )
  ```

**步骤2**: 找到 D1 活跃用户
- 输入: base_users + dwd_user_behavior
- 操作: 关联行为表，筛选 D1 的行为
- 输出: 留存的 user_id
- SQL:
  ```sql
  retention_users AS (
      SELECT bu.user_id
      FROM base_users bu
      INNER JOIN dwd_user_behavior ub
        ON bu.user_id = ub.user_id
        AND ub.date = date_add('day', 1, bu.register_date)
  )
  ```

**步骤3**: 计算留存率
- 输入: base_users + retention_users
- 操作: LEFT JOIN，计算比率
- 输出: 留存率
- SQL:
  ```sql
  SELECT 
      COUNT(DISTINCT bu.user_id) as new_users,
      COUNT(DISTINCT ru.user_id) as retention_users,
      ROUND(
          CAST(COUNT(DISTINCT ru.user_id) AS DOUBLE) * 100.0 
          / COUNT(DISTINCT bu.user_id), 
          2
      ) as retention_rate
  FROM base_users bu
  LEFT JOIN retention_users ru
    ON bu.user_id = ru.user_id
  ```

**完整 SQL 模板** (Trino):
```sql
WITH base_users AS (
    SELECT user_id, cast(register_time as date) as register_date
    FROM dwd_user_register
    WHERE register_date = date '2024-01-01'
),
retention_users AS (
    SELECT bu.user_id
    FROM base_users bu
    INNER JOIN dwd_user_behavior ub
      ON bu.user_id = ub.user_id
      AND ub.date = date_add('day', 1, bu.register_date)
)
SELECT 
    COUNT(DISTINCT bu.user_id) as new_users,
    COUNT(DISTINCT ru.user_id) as retention_users,
    ROUND(
        CAST(COUNT(DISTINCT ru.user_id) AS DOUBLE) * 100.0 
        / COUNT(DISTINCT bu.user_id), 
        2
    ) as retention_rate
FROM base_users bu
LEFT JOIN retention_users ru
  ON bu.user_id = ru.user_id;
```

**关键技术点**:

**技术点1**: JOIN 类型选择
- 说明: 必须保留所有基准用户
- ✅ 正确: LEFT JOIN
- ❌ 错误: INNER JOIN
- 后果: 遗漏未留存用户，留存率虚高（30% → 100%）

**技术点2**: 时间计算
- 说明: D1 必须精确等于 D0+1天
- ✅ 正确: date_add('day', 1, register_date)
- ❌ 错误: date = register_date（这是D0）
- 后果: 统计错误的日期

**技术点3**: 去重
- 说明: 分子分母都要去重
- ✅ 正确: COUNT(DISTINCT user_id)
- ❌ 错误: COUNT(user_id)
- 后果: 重复计数，数值错误

**常见错误**:

| 错误 | 表现 | 后果 | 正确做法 |
|------|------|------|---------|
| 使用 INNER JOIN | FROM base INNER JOIN retention | 留存率虚高 | 使用 LEFT JOIN |
| 时间计算错误 | date = register_date | 统计的是D0不是D1 | date_add('day', 1, ...) |
| 忘记去重 | COUNT(user_id) | 重复计数 | COUNT(DISTINCT user_id) |

**变体场景**:

**变体1**: 按渠道分组
- 需求变化: 对比各渠道留存率
- SQL 调整: 添加 register_channel 字段，GROUP BY register_channel

**变体2**: 7日留存
- 需求变化: 计算 D7 留存
- SQL 调整: date_add('day', 1, ...) 改为 date_add('day', 7, ...)

**性能说明**:
- 数据量: 注册表5万/天，行为表5000万/天
- 执行时间: 单日10-30秒，单月1-3分钟
- 优化: 必须包含分区字段条件

**维护信息**:
- 负责人: 数据部门
- 更新时间: 2024-01-01
```

---

## ✅ 检查清单

**必填项**:
- [ ] 规则名称、适用指标
- [ ] 计算公式和步骤
- [ ] 完整 SQL 模板（Trino 语法）
- [ ] 关键技术点（说"为什么"）
- [ ] 常见错误（说"后果"）

**推荐项**:
- [ ] 变体场景（至少2个）
- [ ] 性能说明
- [ ] 验证方法

**质量检查**:
- [ ] SQL 是否完整可执行？
- [ ] 关键技术点是否说明"为什么"？
- [ ] 常见错误是否说明"后果"？

---

## 维护日志

| 日期 | 修改内容 |
|------|---------|
| 2024-01-01 | 创建计算规则模板 |
