# 表名: dwd_user_behavior

> 用户行为明细表 - 这是一个示例表，请根据实际情况修改

---

## 基本信息

| 属性 | 值 |
|------|-----|
| 表名 | `dwd_user_behavior` |
| 中文名 | 用户行为明细表 |
| 数据层级 | DWD (数据仓库明细层) |
| 更新频率 | 实时/准实时 |
| 数据范围 | 2020-01-01 至今 |
| 分区字段 | `date` (行为日期) |
| 数据量级 | 日增约 5000 万行 |
| 负责人 | [待补充] |

---

## 表说明

### 业务含义
记录用户的所有行为明细，包括浏览、发帖、评论、点赞等。

### 数据来源
- 埋点日志
- 业务系统日志
- 实时数据流

### 更新逻辑
- 实时写入
- 延迟约 5-10 分钟

---

## 字段列表

| 字段名 | 类型 | 说明 | 示例值 | 是否必填 | 备注 |
|--------|------|------|--------|----------|------|
| behavior_id | bigint | 行为ID | 123456789 | 是 | 主键 |
| user_id | bigint | 用户ID | 123456 | 是 | |
| behavior_type | varchar(50) | 行为类型 | view_post | 是 | 见行为类型说明 |
| behavior_time | timestamp | 行为时间 | 2024-01-01 12:30:45 | 是 | |
| date | date | 行为日期 | 2024-01-01 | 是 | 分区字段 |
| platform | varchar(20) | 平台 | iOS | 是 | iOS/Android/Web/H5 |
| object_id | bigint | 对象ID | 789012 | 否 | 行为对象的ID（如帖子ID） |
| object_type | varchar(50) | 对象类型 | post | 否 | post/comment/user等 |
| channel | varchar(50) | 渠道 | feed | 否 | 用户从哪个入口进来 |
| session_id | varchar(100) | 会话ID | abc123 | 否 | 用于会话分析 |

**注**: 以上字段为示例，请根据实际表结构修改。

---

## 行为类型说明

| behavior_type | 中文名 | 说明 |
|---------------|--------|------|
| login | 登录 | 用户登录 |
| view_post | 浏览帖子 | 用户查看帖子详情 |
| view_feed | 浏览信息流 | 用户浏览信息流 |
| create_post | 发帖 | 用户发布帖子 |
| create_comment | 评论 | 用户发布评论 |
| like | 点赞 | 用户点赞 |
| favorite | 收藏 | 用户收藏 |
| share | 分享 | 用户分享 |
| follow | 关注 | 用户关注其他用户 |
| trade | 交易 | 用户进行交易 |

**注**: 请根据实际的行为类型补充。

---

## 主键和索引

### 主键
- `behavior_id`

### 索引
- 索引1: `date` (分区字段，必须)
- 索引2: `user_id` (高频查询)
- 索引3: `behavior_type` (按类型筛选)
- 索引4: `behavior_time` (时间范围查询)

---

## 关联关系

### 可关联的表

| 关联表 | 关联字段 | 关联类型 | 说明 |
|--------|----------|----------|------|
| dim_user | user_id | N:1 | 获取用户属性 |
| dwd_post | object_id | N:1 | 当 object_type='post' 时关联帖子 |
| dwd_comment | object_id | N:1 | 当 object_type='comment' 时关联评论 |

---

## 使用场景

### 场景 1: 计算 DAU（从明细表）

**需求**: 计算某天的 DAU

**SQL**:
```sql
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dwd_user_behavior
WHERE 
    date = '2024-01-01'
GROUP BY 
    date;
```

**注意**: 如果只需要 DAU，推荐使用 `dws_user_daily` 汇总表，性能更好。

### 场景 2: 分析特定行为

**需求**: 查询某天的发帖用户数

**SQL**:
```sql
SELECT 
    date,
    COUNT(DISTINCT user_id) as post_users
FROM 
    dwd_user_behavior
WHERE 
    date = '2024-01-01'
    AND behavior_type = 'create_post'
GROUP BY 
    date;
```

### 场景 3: 用户行为序列分析

**需求**: 分析用户的行为路径

**SQL**:
```sql
SELECT 
    user_id,
    behavior_time,
    behavior_type,
    object_id
FROM 
    dwd_user_behavior
WHERE 
    date = '2024-01-01'
    AND user_id = 123456
ORDER BY 
    behavior_time;
```

---

## 数据质量

### 数据完整性
- ✅ 数据完整，实时写入
- ⚠️ 可能有 5-10 分钟延迟

### 数据准确性
- ✅ 埋点数据准确率 > 99%

### 已知问题
- 部分老版本客户端的埋点可能缺失
- [补充其他已知问题]

---

## 注意事项

### 性能注意事项
- ⚠️ **必须加 date 分区条件**，否则会扫描全表，查询超时
- ⚠️ 数据量大，尽量使用汇总表（`dws_user_daily`）
- ⚠️ 如需查询多天数据，建议限制在 30 天以内

### 业务注意事项
- ⚠️ 实时数据有延迟，统计当天数据可能不完整
- ⚠️ 需要根据 `behavior_type` 筛选特定行为
- ⚠️ 同一用户可能有多条记录（不同行为）

### 使用限制
- 保留最近 90 天明细数据
- 更早的数据已归档或聚合到汇总表

---

## 最佳实践

### ✅ 推荐写法

```sql
-- 1. 必须加分区条件
WHERE date >= '2024-01-01' AND date < '2024-01-08'

-- 2. 使用 DISTINCT 去重
COUNT(DISTINCT user_id)

-- 3. 限制查询范围
LIMIT 10000
```

### ❌ 不推荐写法

```sql
-- 1. 没有分区条件（会全表扫描）
WHERE behavior_time >= '2024-01-01'

-- 2. 没有去重（会重复计数）
COUNT(user_id)

-- 3. 查询时间范围过大
WHERE date >= '2020-01-01'
```

---

## 变更历史

| 日期 | 变更类型 | 变更内容 | 影响 |
|------|----------|----------|------|
| 2020-01-01 | 新增 | 创建表 | - |
| 2023-06-01 | 字段新增 | 新增 session_id 字段 | 无影响 |

---

## 相关文档

- 业务定义: `knowledge/business/glossary.md` - 活跃用户定义
- 汇总表: `knowledge/data_assets/tables/dws/dws_user_daily.md`
- SQL 案例: `knowledge/sql_examples/user_analysis/`

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建示例文档 |
