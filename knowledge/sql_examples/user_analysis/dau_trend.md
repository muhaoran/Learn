# SQL 案例: DAU 趋势分析

---

## 业务需求（原始）

"帮我查一下最近 7 天的 DAU 趋势"

---

## 需求分析

### 关键要素提取

| 要素 | 内容 |
|------|------|
| **指标** | DAU (日活跃用户数) |
| **维度** | 日期 |
| **筛选条件** | 无 |
| **时间范围** | 最近 7 天 |
| **聚合方式** | 按日聚合 |

### 业务术语翻译

| 原始表达 | 标准术语 | 定义来源 |
|----------|----------|----------|
| DAU | 日活跃用户数 | `knowledge/business/metrics/user_metrics.md` |

---

## 需求澄清

### 澄清的问题

1. **问题**: "最近 7 天" 是否包含今天？
   - **答案**: 包含今天
   - **影响**: 时间范围为 [今天-6, 今天]

2. **问题**: 是否需要按其他维度细分（如渠道、平台）？
   - **答案**: 不需要，只看整体趋势
   - **影响**: 只按日期分组

### 最终确认的需求

查询过去 7 天（含今天）每天的活跃用户数（去重），按日期升序排列。

---

## 技术方案

### 数据表选择

| 表名 | 用途 | 选择理由 |
|------|------|----------|
| `dws_user_daily` | 获取 DAU | 汇总表，性能好，已经计算好 DAU |

### 计算逻辑

```
1. 从 dws_user_daily 表查询
2. 筛选最近 7 天的数据
3. 按日期聚合，统计去重用户数
4. 按日期升序排列
```

### 关键技术点

- 使用汇总表而非明细表，性能更好
- 时间范围: `>= DATE_SUB(CURRENT_DATE(), 6)`

---

## SQL 语句

```sql
-- 查询最近 7 天的 DAU 趋势
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

### 简化版本（如果表中已有 DAU 字段）

```sql
-- 如果 dws_user_daily 表中已经有预计算的 dau 字段
SELECT 
    date,
    dau
FROM 
    dws_user_daily
WHERE 
    date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
    AND date <= CURRENT_DATE()
ORDER BY 
    date;
```

---

## 执行说明

### 数据范围
- **扫描表**: `dws_user_daily`
- **扫描分区**: 最近 7 天
- **预计数据量**: 约 700 万行（假设日均 100 万用户）

### 性能预估
- **预计执行时间**: < 1 秒
- **资源消耗**: 低

### 注意事项
- ⚠️ 今天的数据可能不完整（T+1 更新）
- ✅ 使用汇总表，性能很好

---

## 结果说明

### 结果字段

| 字段名 | 含义 | 示例值 | 备注 |
|--------|------|--------|------|
| date | 日期 | 2024-01-01 | |
| dau | 日活跃用户数 | 1500000 | 去重后的用户数 |

### 结果解读

- 每行代表一天的 DAU
- 可以观察 DAU 的变化趋势
- 注意周末和工作日的差异

---

## 变体需求

### 变体 1: 按渠道细分

**需求变化**: 需要看各渠道的 DAU

**SQL 调整**:
```sql
SELECT 
    date,
    platform as channel,  -- 新增维度
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
    AND date <= CURRENT_DATE()
    AND is_active = 1
GROUP BY 
    date,
    platform  -- 新增分组字段
ORDER BY 
    date,
    platform;
```

### 变体 2: 同比对比

**需求变化**: 需要与去年同期对比

**SQL 调整**:
```sql
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    (
        -- 今年最近 7 天
        (date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY) AND date <= CURRENT_DATE())
        OR
        -- 去年同期
        (date >= DATE_SUB(CURRENT_DATE(), INTERVAL 371 DAY) AND date <= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY))
    )
    AND is_active = 1
GROUP BY 
    date
ORDER BY 
    date;
```

### 变体 3: 只看完整的天（不含今天）

**需求变化**: 只看过去 7 个完整的自然日

**SQL 调整**:
```sql
WHERE 
    date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    AND date < CURRENT_DATE()  -- 不含今天
```

---

## 相关案例

- WAU 趋势: `knowledge/sql_examples/user_analysis/wau_trend.md`
- MAU 趋势: `knowledge/sql_examples/user_analysis/mau_trend.md`

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建案例 |
