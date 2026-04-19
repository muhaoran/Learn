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

**示例**:
```sql
SELECT user_id, dau FROM dws_user_daily
```
- 验证 `dws_user_daily` 表是否存在
- 验证 `user_id` 字段是否存在
- 验证 `dau` 字段是否存在

### 步骤 3: 逻辑验证

**检查项**:
- [ ] SQL 逻辑是否符合需求
- [ ] 计算逻辑是否正确
- [ ] 去重逻辑是否合理
- [ ] JOIN 类型是否正确
- [ ] 时间范围是否正确

**验证方法**:

#### 3.1 指标计算验证

对照业务定义，检查计算逻辑。

**示例**: 验证 DAU 计算
- 业务定义: `COUNT(DISTINCT user_id) WHERE is_active = 1`
- SQL: `COUNT(DISTINCT user_id) ... WHERE is_active = 1` ✅

#### 3.2 去重验证

**检查**:
- 统计用户数时是否使用了 DISTINCT
- GROUP BY 是否合理

**示例**:
```sql
-- ✅ 正确
COUNT(DISTINCT user_id)

-- ❌ 错误
COUNT(user_id)  -- 会重复计数
```

#### 3.3 JOIN 类型验证

**检查**: JOIN 类型是否符合业务逻辑

**示例**: 留存分析
```sql
-- ✅ 正确：使用 LEFT JOIN，保留所有新增用户
FROM new_users LEFT JOIN retention_users ON ...

-- ❌ 错误：使用 INNER JOIN，会遗漏未留存用户
FROM new_users INNER JOIN retention_users ON ...
```

#### 3.4 时间范围验证

**检查**:
- 时间范围是否符合需求
- 时间计算是否正确（如 D1 = D0 + 1）
- 是否使用了正确的时间函数

**示例**:
```sql
-- 需求: 最近 7 天（含今天）
-- ✅ 正确（Trino 语法）
WHERE date >= date_add('day', -6, current_date)
  AND date <= current_date

-- ❌ 错误：少了一天
WHERE date >= date_add('day', -7, current_date)
  AND date < current_date

-- ❌ 错误：MySQL 语法，不能用
WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
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

**示例**: 验证次日留存率
- 业务定义: `D1活跃用户数 / D0新增用户数`
- SQL: 
  - 分子: `COUNT(DISTINCT retention_users.user_id)` ✅
  - 分母: `COUNT(DISTINCT new_users.user_id)` ✅
  - 使用 LEFT JOIN ✅

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

**示例**:
```sql
-- 🔴 高风险：没有分区条件
SELECT COUNT(*) FROM dwd_user_behavior WHERE user_id = 123;

-- 🟢 低风险：有分区条件，使用汇总表
SELECT dau FROM dws_user_daily WHERE date = '2024-01-01';
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
      "issues": ["应该使用 LEFT JOIN 而非 INNER JOIN"]
    }
  },
  "overall": "fail",
  "suggestions": ["修改 JOIN 类型为 LEFT JOIN"]
}
```

---

## 示例

### 示例 1: 验证通过

**SQL**:
```sql
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date = '2024-01-01'
    AND is_active = 1
GROUP BY 
    date;
```

**验证结果**:
- ✅ 语法正确
- ✅ 表和字段都存在
- ✅ 逻辑正确（符合 DAU 定义）
- ✅ 口径正确（使用 DISTINCT，筛选 is_active）
- ✅ 性能良好（使用汇总表，有分区条件）

**结论**: 验证通过，可以输出。

### 示例 2: 发现问题

**SQL**:
```sql
-- 计算留存率
SELECT 
    COUNT(DISTINCT r.user_id) as new_users,
    COUNT(DISTINCT b.user_id) as retention_users
FROM 
    dwd_user_register r
INNER JOIN 
    dwd_user_behavior b
ON 
    r.user_id = b.user_id
WHERE 
    r.register_date = '2024-01-01'
    AND b.date = '2024-01-02';
```

**验证结果**:
- ✅ 语法正确
- ✅ 表和字段存在
- ❌ 逻辑错误: 使用了 INNER JOIN
  - **问题**: INNER JOIN 会遗漏未留存的用户，导致分母错误
  - **应该**: 使用 LEFT JOIN
- ✅ 口径基本正确
- ⚠️ 性能一般（使用明细表，但时间范围小）

**修改建议**:
```sql
-- 修改 INNER JOIN 为 LEFT JOIN，并修正为 Trino 语法
FROM 
    dwd_user_register r
LEFT JOIN 
    dwd_user_behavior b
ON 
    r.user_id = b.user_id
    AND b.date = date_add('day', 1, r.register_date)
```

### 示例 3: 性能问题

**SQL**:
```sql
SELECT 
    COUNT(DISTINCT user_id) as dau
FROM 
    dwd_user_behavior
WHERE 
    user_id = 123456;  -- 没有分区条件！
```

**验证结果**:
- ✅ 语法正确
- ✅ 表和字段存在
- ✅ 逻辑正确
- 🔴 性能高风险: 没有分区条件，会全表扫描

**修改建议**:
```sql
-- 必须添加 date 分区条件
WHERE 
    date >= '2024-01-01'  -- 添加时间范围
    AND date < '2024-01-08'
    AND user_id = 123456;
```

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
