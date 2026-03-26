# 表名: dws_user_daily

> 用户日度汇总表 - 这是一个示例表，请根据实际情况修改

---

## 基本信息

| 属性 | 值 |
|------|-----|
| 表名 | `dws_user_daily` |
| 中文名 | 用户日度汇总表 |
| 数据层级 | DWS (数据仓库汇总层) |
| 更新频率 | 天 (T+1) |
| 数据范围 | 2020-01-01 至今 |
| 分区字段 | `date` |
| 数据量级 | 日增约 100 万行 |
| 负责人 | [待补充] |

---

## 表说明

### 业务含义
汇总每天每个用户的行为数据，包括活跃情况、行为次数、内容生产等核心指标。

### 数据来源
基于 `dwd_user_behavior` 明细表，按日期和用户聚合计算。

### 更新逻辑
- T+1 更新（每天凌晨更新前一天的数据）
- 全量更新，不支持增量

---

## 字段列表

| 字段名 | 类型 | 说明 | 示例值 | 是否必填 | 备注 |
|--------|------|------|--------|----------|------|
| date | date | 日期 | 2024-01-01 | 是 | 分区字段 |
| user_id | bigint | 用户ID | 123456 | 是 | |
| is_active | int | 是否活跃 | 1 | 是 | 1=活跃, 0=不活跃 |
| is_new_user | int | 是否新用户 | 1 | 是 | 1=新用户, 0=老用户 |
| register_date | date | 注册日期 | 2024-01-01 | 否 | 新用户才有值 |
| register_channel | varchar(50) | 注册渠道 | app_store | 否 | 新用户才有值 |
| platform | varchar(20) | 活跃平台 | iOS | 否 | 当日主要使用的平台 |
| behavior_count | int | 行为次数 | 25 | 是 | 当日总行为次数 |
| post_count | int | 发帖数 | 3 | 是 | 当日发帖数 |
| comment_count | int | 评论数 | 10 | 是 | 当日评论数 |
| like_count | int | 点赞数 | 12 | 是 | 当日点赞数 |
| duration_seconds | int | 使用时长(秒) | 3600 | 是 | 当日使用时长 |

**注**: 以上字段为示例，请根据实际表结构修改。

---

## 主键和索引

### 主键
- `date` + `user_id`

### 索引
- 索引1: `date` (分区字段)
- 索引2: `user_id`
- 索引3: `register_date` (用于新增用户分析)

---

## 关联关系

### 可关联的表

| 关联表 | 关联字段 | 关联类型 | 说明 |
|--------|----------|----------|------|
| dim_user | user_id | N:1 | 获取用户基础信息 |
| dwd_user_register | user_id | N:1 | 获取注册详情 |

---

## 使用场景

### 场景 1: 查询 DAU

**需求**: 查询某天的 DAU

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

### 场景 2: 查询新增用户数

**需求**: 查询某天的新增用户数

**SQL**:
```sql
SELECT 
    date,
    COUNT(DISTINCT user_id) as new_users
FROM 
    dws_user_daily
WHERE 
    date = '2024-01-01'
    AND is_new_user = 1
GROUP BY 
    date;
```

### 场景 3: 按渠道分析

**需求**: 查询各渠道的新增用户数

**SQL**:
```sql
SELECT 
    date,
    register_channel,
    COUNT(DISTINCT user_id) as new_users
FROM 
    dws_user_daily
WHERE 
    date = '2024-01-01'
    AND is_new_user = 1
GROUP BY 
    date,
    register_channel;
```

---

## 数据质量

### 数据完整性
- ✅ 数据完整，每天都有更新
- ⚠️ T+1 更新，当天数据需要等到第二天

### 数据准确性
- ✅ 与明细表对账，准确率 99.9%+

### 已知问题
- [列出已知问题，如果有]

---

## 注意事项

### 性能注意事项
- ⚠️ 查询时必须带上 `date` 分区条件，否则会全表扫描
- ✅ 该表已经是汇总表，性能较好，优先使用

### 业务注意事项
- ⚠️ T+1 更新，查询当天数据不准确（数据为空或不完整）
- ⚠️ `is_active = 1` 才是活跃用户
- ⚠️ `is_new_user = 1` 才是新增用户

### 使用限制
- 保留最近 2 年数据
- 更早的数据已归档

---

## 变更历史

| 日期 | 变更类型 | 变更内容 | 影响 |
|------|----------|----------|------|
| 2023-01-01 | 新增 | 创建表 | - |
| 2023-06-01 | 字段新增 | 新增 duration_seconds 字段 | 无影响 |

---

## 相关文档

- 业务定义: `knowledge/business/metrics/user_metrics.md`
- SQL 案例: `knowledge/sql_examples/user_analysis/`

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建示例文档 |

---

## 使用说明

**For AI**:
- 查询 DAU、新增用户等指标时，优先使用本表
- 必须加 `date` 分区条件
- 注意 `is_active` 和 `is_new_user` 的过滤条件

**For Human**:
- 请根据实际表结构修改字段列表
- 请补充实际的数据量级和负责人信息
