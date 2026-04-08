# 时间维度定义

> 本文档定义时间相关的维度和处理规则。

---

## 时间粒度

### 日（Day）
- **定义**: 自然日，00:00:00 - 23:59:59
- **字段格式**: `YYYY-MM-DD` (如 2024-01-01)
- **SQL 示例**: `DATE(timestamp_column)`

### 周（Week）
- **定义**: 自然周，周一到周日
- **起始**: 周一 00:00:00
- **结束**: 周日 23:59:59
- **字段格式**: `YYYY-Www` (如 2024-W01) 或 周一日期
- **SQL 示例**: `DATE_TRUNC('week', timestamp_column)`

### 月（Month）
- **定义**: 自然月，1日到月末
- **字段格式**: `YYYY-MM` (如 2024-01)
- **SQL 示例**: `DATE_TRUNC('month', timestamp_column)`

### 季度（Quarter）
- **定义**: 自然季度
  - Q1: 1-3月
  - Q2: 4-6月
  - Q3: 7-9月
  - Q4: 10-12月
- **字段格式**: `YYYY-Qq` (如 2024-Q1)

### 年（Year）
- **定义**: 自然年，1月1日到12月31日
- **字段格式**: `YYYY` (如 2024)

---

## 时间范围表达

### 相对时间

| 表达方式 | 含义 | SQL 实现 |
|----------|------|----------|
| 今天 | 当前自然日 | `CURRENT_DATE()` |
| 昨天 | 当前日期 - 1 | `DATE_SUB(CURRENT_DATE(), 1)` |
| 最近7天 | 过去7天（含今天） | `>= DATE_SUB(CURRENT_DATE(), 6)` |
| 最近30天 | 过去30天（含今天） | `>= DATE_SUB(CURRENT_DATE(), 29)` |
| 本周 | 本周周一到今天 | `>= DATE_TRUNC('week', CURRENT_DATE())` |
| 上周 | 上周周一到周日 | [待补充具体SQL] |
| 本月 | 本月1日到今天 | `>= DATE_TRUNC('month', CURRENT_DATE())` |
| 上月 | 上月1日到月末 | [待补充具体SQL] |

### 绝对时间

| 表达方式 | 示例 | SQL 实现 |
|----------|------|----------|
| 具体日期 | 2024-01-01 | `= '2024-01-01'` |
| 日期范围 | 2024-01-01 到 2024-01-07 | `>= '2024-01-01' AND < '2024-01-08'` |
| 具体月份 | 2024年1月 | `>= '2024-01-01' AND < '2024-02-01'` |

---

## 时间边界处理

### 包含性

**"最近 7 天"的两种理解**:

1. **包含今天** (推荐默认):
   ```sql
   WHERE date >= DATE_SUB(CURRENT_DATE(), 6)
     AND date <= CURRENT_DATE()
   ```

2. **不包含今天**:
   ```sql
   WHERE date >= DATE_SUB(CURRENT_DATE(), 7)
     AND date < CURRENT_DATE()
   ```

**澄清策略**: 如果用户说"最近N天"，默认包含今天，除非明确说明。

### 时间范围的闭合性

**推荐写法**:
```sql
-- 左闭右开区间
WHERE date >= '2024-01-01' 
  AND date < '2024-02-01'  -- 注意是 <，不是 <=
```

**原因**: 避免时间戳的边界问题

---

## 时区处理

### 标准时区
雪球使用的标准时区: [待补充，如 UTC+8]

### 时区转换
```sql
-- 如果数据库存储的是 UTC 时间，需要转换
CONVERT_TZ(utc_timestamp, 'UTC', 'Asia/Shanghai')
```

### 注意事项
- 确认数据库中时间字段的时区
- 跨时区分析时需要统一时区
- 注意夏令时的影响（如果有）

---

## 时间维度组合

### 按日统计
```sql
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as cnt
FROM table
GROUP BY DATE(timestamp)
```

### 按周统计
```sql
SELECT 
    DATE_TRUNC('week', timestamp) as week,
    COUNT(*) as cnt
FROM table
GROUP BY DATE_TRUNC('week', timestamp)
```

### 按月统计
```sql
SELECT 
    DATE_TRUNC('month', timestamp) as month,
    COUNT(*) as cnt
FROM table
GROUP BY DATE_TRUNC('month', timestamp)
```

---

## 特殊时间概念

### 工作日 vs 节假日

**定义**: [待补充雪球的工作日定义]

**使用场景**: 
- 分析工作日和节假日的用户行为差异
- 需要一个节假日维表

### 时段

**定义**: 一天中的时间段

**常见划分**:
- 凌晨: 00:00-06:00
- 上午: 06:00-12:00
- 下午: 12:00-18:00
- 晚上: 18:00-24:00

**SQL 示例**:
```sql
CASE 
    WHEN HOUR(timestamp) < 6 THEN '凌晨'
    WHEN HOUR(timestamp) < 12 THEN '上午'
    WHEN HOUR(timestamp) < 18 THEN '下午'
    ELSE '晚上'
END as time_period
```

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建模板 |

---

## 使用说明

**For AI**:
- 处理时间相关需求时必须参考本文档
- 注意时间边界的处理（包含/不包含）
- 注意时区转换
- 优先使用相对时间的标准实现

**For Human**:
- 请补充雪球的时区设置
- 请补充特殊时间概念的定义
- 请确认相对时间的默认理解方式
