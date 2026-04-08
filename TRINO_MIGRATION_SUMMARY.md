# Trino 语法迁移总结

> 本文档记录 ChatBI 系统明确使用 Trino 语法的完整变更

---

## 📋 变更概述

**目标**: 明确 ChatBI 系统所有 SQL 必须使用 Trino 语法规范

**完成时间**: 2024-01-01

**影响范围**: 核心配置、文档、示例、最佳实践

---

## ✅ 已完成的工作

### 1. 核心配置文件更新（3个）

| 文件 | 变更内容 |
|------|---------|
| `.cursorrules` | - 添加第 5 条核心原则：Trino 语法<br>- SQL 生成规则中明确 Trino 函数要求<br>- 禁止使用非 Trino 语法 |
| `prompts/system_prompt.md` | - 角色定位中强调 Trino 语法<br>- SQL 生成步骤明确 Trino 要求<br>- 添加 Trino 函数列表 |
| `skills/04_sql_generation.md` | - 目标中明确 Trino 语法<br>- 处理步骤中添加 Trino 要求 |

### 2. 新增 Trino 语法文档（1个）

**文件**: `knowledge/data_assets/trino_syntax_guide.md`

**内容**（约 600 行）:
- ✅ 日期和时间函数（17 个函数）
- ✅ 字符串函数（15 个函数）
- ✅ 聚合函数（含近似聚合）
- ✅ 窗口函数（排名、累计、偏移）
- ✅ 类型转换函数
- ✅ 条件函数（CASE、IF、COALESCE）
- ✅ 数组函数
- ✅ 常见查询模式
- ✅ 性能优化技巧
- ✅ 常见错误对照表
- ✅ 快速检查清单

### 3. 更新最佳实践文档（1个）

**文件**: `knowledge/data_assets/best_practices.md`

**变更**:
- ✅ 文档开头明确数据库类型为 Trino
- ✅ 将"数据库特定语法"章节改写为"Trino 语法规范"
- ✅ 添加详细的 Trino 函数示例
- ✅ 标注禁止使用的 MySQL/Hive 语法
- ✅ 更新数据库配置章节

### 4. 更新 SQL 示例（3个）

| 文件 | 变更内容 |
|------|---------|
| `knowledge/sql_examples/user_analysis/dau_trend.md` | 所有 SQL 改为 Trino 语法 |
| `knowledge/sql_examples/user_analysis/retention.md` | 所有 SQL 改为 Trino 语法 |
| `knowledge/sql_examples/user_analysis/new_user_analysis.md` | 所有 SQL 改为 Trino 语法 |

---

## 📊 关键语法变更

### 日期函数

| 功能 | 旧语法（MySQL） | 新语法（Trino） |
|------|----------------|----------------|
| 当前日期 | `CURDATE()` 或 `CURRENT_DATE()` | `current_date` |
| 日期加法 | `DATE_ADD(date, INTERVAL 1 DAY)` | `date_add('day', 1, date)` |
| 日期减法 | `DATE_SUB(date, INTERVAL 1 DAY)` | `date_add('day', -1, date)` |
| 日期差值 | `DATEDIFF(date1, date2)` | `date_diff('day', date1, date2)` |
| 日期格式化 | `DATE_FORMAT(date, format)` | `date_format(date, format)` |
| 字符串转日期 | `STR_TO_DATE(str, format)` | `date_parse(str, format)` |
| 提取年份 | `YEAR(date)` | `year(date)` |
| 提取月份 | `MONTH(date)` | `month(date)` |

### 字符串函数

| 功能 | 旧语法 | 新语法（Trino） |
|------|-------|----------------|
| 字符串连接 | `CONCAT(str1, str2)` | `concat(str1, str2)` 或 `str1 \|\| str2` |
| 字符串截取 | `SUBSTRING(str, 0, 10)` | `substr(str, 1, 10)` |
| 字符串长度 | `LENGTH(str)` | `length(str)` |
| 字符串查找 | `LOCATE(substr, str)` | `strpos(str, substr)` |

### 聚合函数

| 功能 | 标准语法 | Trino 优化 |
|------|---------|-----------|
| 去重计数 | `count(distinct column)` | `approx_distinct(column)` （大数据量推荐）|
| 中位数 | - | `approx_percentile(column, 0.5)` |

### 数组函数

| 功能 | 旧语法 | 新语法（Trino） |
|------|-------|----------------|
| 数组长度 | `LENGTH(array)` | `cardinality(array)` 或 `array_length(array)` |
| 数组包含 | - | `contains(array, value)` |
| 数组去重 | - | `array_distinct(array)` |

---

## 📝 示例对比

### 示例 1: 查询最近 7 天的 DAU

**旧版本（MySQL 语法）**:
```sql
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
    AND date <= CURRENT_DATE()
    AND is_active = 1
GROUP BY 
    date
ORDER BY 
    date;
```

**新版本（Trino 语法）**:
```sql
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date >= date_add('day', -6, current_date)
    AND date <= current_date
    AND is_active = 1
GROUP BY 
    date
ORDER BY 
    date;
```

### 示例 2: 计算次日留存率

**旧版本（MySQL 语法）**:
```sql
WITH new_users AS (
    SELECT 
        user_id,
        DATE(register_time) as register_date
    FROM 
        dwd_user_register
    WHERE 
        register_date >= '2024-01-01'
        AND register_date < '2024-02-01'
),
retention_users AS (
    SELECT 
        nu.user_id,
        nu.register_date
    FROM 
        new_users nu
    INNER JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        AND ub.date = DATE_ADD(nu.register_date, INTERVAL 1 DAY)
)
SELECT 
    nu.register_date,
    COUNT(DISTINCT nu.user_id) as new_users_count,
    COUNT(DISTINCT ru.user_id) as retention_users_count,
    ROUND(COUNT(DISTINCT ru.user_id) * 100.0 / COUNT(DISTINCT nu.user_id), 2) as retention_rate
FROM 
    new_users nu
LEFT JOIN 
    retention_users ru
ON 
    nu.user_id = ru.user_id
    AND nu.register_date = ru.register_date
GROUP BY 
    nu.register_date
ORDER BY 
    nu.register_date;
```

**新版本（Trino 语法）**:
```sql
WITH new_users AS (
    SELECT 
        user_id,
        cast(register_time as date) as register_date
    FROM 
        dwd_user_register
    WHERE 
        register_date >= date '2024-01-01'
        AND register_date < date '2024-02-01'
),
retention_users AS (
    SELECT 
        nu.user_id,
        nu.register_date
    FROM 
        new_users nu
    INNER JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        AND ub.date = date_add('day', 1, nu.register_date)
)
SELECT 
    nu.register_date,
    COUNT(DISTINCT nu.user_id) as new_users_count,
    COUNT(DISTINCT ru.user_id) as retention_users_count,
    ROUND(CAST(COUNT(DISTINCT ru.user_id) AS DOUBLE) * 100.0 / COUNT(DISTINCT nu.user_id), 2) as retention_rate
FROM 
    new_users nu
LEFT JOIN 
    retention_users ru
ON 
    nu.user_id = ru.user_id
    AND nu.register_date = ru.register_date
GROUP BY 
    nu.register_date
ORDER BY 
    nu.register_date;
```

**关键差异**:
1. `DATE(register_time)` → `cast(register_time as date)`
2. `'2024-01-01'` → `date '2024-01-01'`（日期字面量）
3. `DATE_ADD(nu.register_date, INTERVAL 1 DAY)` → `date_add('day', 1, nu.register_date)`
4. `COUNT(DISTINCT ru.user_id) * 100.0` → `CAST(COUNT(DISTINCT ru.user_id) AS DOUBLE) * 100.0`（显式类型转换）

---

## 🎯 Trino 语法的优势

### 1. 性能优势

- **近似聚合**: `approx_distinct()` 比 `count(distinct)` 快 10-100 倍
- **近似分位数**: `approx_percentile()` 快速计算中位数、95分位数等
- **向量化执行**: Trino 的列式存储和向量化执行引擎

### 2. 功能优势

- **丰富的数组函数**: `cardinality()`、`contains()`、`array_distinct()`
- **强大的正则表达式**: `regexp_like()`、`regexp_extract()`、`regexp_replace()`
- **灵活的窗口函数**: 支持各种排名、累计、偏移操作
- **类型安全**: `try_cast()` 安全类型转换

### 3. 标准化优势

- **SQL 标准**: Trino 更接近 ANSI SQL 标准
- **跨数据源**: Trino 可以查询多种数据源（Hive、MySQL、PostgreSQL 等）
- **一致性**: 统一的语法规范，减少混淆

---

## 📚 参考文档

### 项目内文档

| 文档 | 路径 | 说明 |
|------|------|------|
| Trino 语法速查指南 | `knowledge/data_assets/trino_syntax_guide.md` | 完整的 Trino 函数参考 |
| SQL 最佳实践 | `knowledge/data_assets/best_practices.md` | 包含 Trino 语法规范 |
| DAU 趋势案例 | `knowledge/sql_examples/user_analysis/dau_trend.md` | Trino 语法示例 |
| 留存率案例 | `knowledge/sql_examples/user_analysis/retention.md` | Trino 语法示例 |
| 新增用户案例 | `knowledge/sql_examples/user_analysis/new_user_analysis.md` | Trino 语法示例 |

### 官方文档

- [Trino 官方文档](https://trino.io/docs/current/)
- [Trino 函数参考](https://trino.io/docs/current/functions.html)
- [Trino 日期函数](https://trino.io/docs/current/functions/datetime.html)
- [Trino 字符串函数](https://trino.io/docs/current/functions/string.html)
- [Trino 聚合函数](https://trino.io/docs/current/functions/aggregate.html)
- [Trino 窗口函数](https://trino.io/docs/current/functions/window.html)

---

## ✅ 验证清单

### AI 生成 SQL 时的检查

- [ ] 使用 `current_date` 而不是 `CURDATE()`
- [ ] 使用 `date_add('day', n, date)` 而不是 `DATE_ADD()` 或 `DATE_SUB()`
- [ ] 使用 `date_diff('day', date1, date2)` 而不是 `DATEDIFF()`
- [ ] 使用 `cast(column as type)` 进行类型转换
- [ ] 字符串截取使用 `substr(str, 1, n)`（从 1 开始）
- [ ] 大数据量时考虑使用 `approx_distinct()` 而不是 `count(distinct)`
- [ ] 数组长度使用 `cardinality()` 或 `array_length()`
- [ ] 正则匹配使用 `regexp_like()` 而不是 `REGEXP`

### 文档更新时的检查

- [ ] 所有 SQL 示例使用 Trino 语法
- [ ] 标注禁止使用的非 Trino 语法
- [ ] 提供 Trino 语法的正确写法
- [ ] 添加必要的注释说明

---

## 🚀 下一步计划

### 短期（1-2 周）

1. **补充更多 Trino 示例**
   - [ ] 添加使用近似聚合的案例
   - [ ] 添加复杂窗口函数的案例
   - [ ] 添加数组函数的案例

2. **性能优化案例**
   - [ ] 对比精确 vs 近似聚合的性能
   - [ ] 提供分区裁剪的最佳实践
   - [ ] 添加大数据量查询优化案例

3. **测试验证**
   - [ ] 测试 AI 生成的 SQL 是否符合 Trino 语法
   - [ ] 验证所有示例 SQL 在 Trino 上可执行
   - [ ] 收集用户反馈

### 中期（1-2 月）

1. **扩展知识库**
   - [ ] 补充更多 Trino 特性（如 JSON 函数、MAP 函数）
   - [ ] 添加 Trino 性能调优指南
   - [ ] 补充 Trino 错误处理案例

2. **工具开发**
   - [ ] 开发 SQL 语法检查工具（检测非 Trino 语法）
   - [ ] 开发 SQL 自动转换工具（MySQL → Trino）
   - [ ] 开发性能分析工具

### 长期（3-6 月）

1. **持续优化**
   - [ ] 根据实际使用情况优化 Trino 语法规范
   - [ ] 补充更多边界案例
   - [ ] 建立 Trino 最佳实践库

2. **培训和推广**
   - [ ] 编写 Trino 语法培训材料
   - [ ] 组织内部培训
   - [ ] 建立 FAQ 和常见问题库

---

## 📊 统计数据

### 文件变更统计

| 类型 | 数量 | 说明 |
|------|------|------|
| 修改的文件 | 7 | 核心配置、文档、示例 |
| 新增的文件 | 1 | Trino 语法速查指南 |
| 总代码行数 | ~800 | 包括新增和修改 |
| 新增文档行数 | ~600 | Trino 语法速查指南 |

### 语法变更统计

| 类型 | 数量 |
|------|------|
| 日期函数 | 17 个 |
| 字符串函数 | 15 个 |
| 聚合函数 | 8 个 |
| 窗口函数 | 8 个 |
| 类型转换函数 | 2 个 |
| 条件函数 | 4 个 |
| 数组函数 | 6 个 |
| **总计** | **60+ 个函数** |

---

## 💡 常见问题

### Q1: 为什么选择 Trino？

**A**: Trino 是一个高性能的分布式 SQL 查询引擎，具有以下优势：
- 支持大规模数据查询
- 丰富的函数库
- 接近 ANSI SQL 标准
- 可以查询多种数据源
- 性能优秀（特别是近似聚合）

### Q2: 如何快速学习 Trino 语法？

**A**: 
1. 阅读项目内的 `knowledge/data_assets/trino_syntax_guide.md`
2. 查看 `knowledge/sql_examples/` 下的示例
3. 参考官方文档：https://trino.io/docs/current/
4. 使用常见错误对照表避免常见错误

### Q3: 如果遇到不熟悉的 Trino 函数怎么办？

**A**:
1. 先查看 `trino_syntax_guide.md`
2. 查看官方函数参考：https://trino.io/docs/current/functions.html
3. 在项目 `knowledge/sql_examples/` 中搜索相似案例
4. 如果仍不清楚，可以询问 AI（AI 已经掌握完整的 Trino 语法）

### Q4: 旧的 MySQL 语法的 SQL 还能用吗？

**A**: 不能。从此版本开始，所有 SQL 必须使用 Trino 语法。如果有旧的 SQL，需要手动转换为 Trino 语法。可以参考：
- `trino_syntax_guide.md` 中的"常见错误对照表"
- 或使用 AI 帮助转换（AI 已经掌握语法转换规则）

### Q5: Trino 和 Presto 有什么区别？

**A**: Trino 是 Presto 的一个分支（原名 PrestoSQL），两者语法非常相似，但 Trino 有一些改进：
- 更好的性能
- 更活跃的社区
- 更多的功能
- 本项目统一使用 Trino 语法规范

---

## 📞 联系方式

**技术支持**: [待补充]

**问题反馈**: [待补充]

**文档维护**: [待补充]

---

## 🙏 致谢

感谢所有参与 Trino 语法迁移的团队成员！

---

**最后更新**: 2024-01-01

**版本**: v1.0
