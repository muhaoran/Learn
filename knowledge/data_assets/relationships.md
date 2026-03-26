# 数据表关联关系

> 本文档说明各数据表之间的关联关系，帮助 AI 正确编写 JOIN 语句。

---

## 核心关联关系图

```
                    dim_user (用户维表)
                         |
                    [user_id]
                         |
        +----------------+----------------+
        |                |                |
   dwd_user_register  dwd_user_behavior  dws_user_daily
   (注册表)           (行为明细表)       (用户日度汇总表)
        |                |                |
   [user_id]        [user_id]        [user_id]
                         |
                    [object_id]
                         |
              +----------+----------+
              |                     |
         dwd_post              dwd_comment
         (帖子表)              (评论表)
```

---

## 详细关联关系

### 1. dim_user ↔ dwd_user_register

**关联字段**: `user_id`

**关联类型**: 1:1

**说明**: 获取用户的注册信息

**SQL 示例**:
```sql
SELECT 
    u.user_id,
    u.user_name,
    r.register_time,
    r.register_channel
FROM 
    dim_user u
LEFT JOIN 
    dwd_user_register r
ON 
    u.user_id = r.user_id;
```

---

### 2. dim_user ↔ dwd_user_behavior

**关联字段**: `user_id`

**关联类型**: 1:N (一个用户有多条行为记录)

**说明**: 获取用户的行为明细

**SQL 示例**:
```sql
SELECT 
    u.user_id,
    u.user_name,
    b.behavior_type,
    b.behavior_time
FROM 
    dim_user u
LEFT JOIN 
    dwd_user_behavior b
ON 
    u.user_id = b.user_id
WHERE 
    b.date = '2024-01-01';
```

**注意**: 
- 必须加 `date` 分区条件
- 一个用户会有多条行为记录

---

### 3. dim_user ↔ dws_user_daily

**关联字段**: `user_id`

**关联类型**: 1:N (一个用户有多天的汇总记录)

**说明**: 获取用户的日度汇总数据

**SQL 示例**:
```sql
SELECT 
    u.user_id,
    u.user_name,
    d.date,
    d.behavior_count,
    d.post_count
FROM 
    dim_user u
LEFT JOIN 
    dws_user_daily d
ON 
    u.user_id = d.user_id
WHERE 
    d.date >= '2024-01-01'
    AND d.date < '2024-01-08';
```

---

### 4. dwd_user_register ↔ dwd_user_behavior

**关联字段**: `user_id`

**关联类型**: 1:N

**说明**: 分析新用户的行为（如留存分析）

**SQL 示例**:
```sql
-- 计算次日留存
SELECT 
    r.register_date,
    COUNT(DISTINCT r.user_id) as new_users,
    COUNT(DISTINCT b.user_id) as retention_users
FROM 
    dwd_user_register r
LEFT JOIN 
    dwd_user_behavior b
ON 
    r.user_id = b.user_id
    AND b.date = DATE_ADD(r.register_date, INTERVAL 1 DAY)
WHERE 
    r.register_date = '2024-01-01'
GROUP BY 
    r.register_date;
```

---

### 5. dwd_user_behavior ↔ dwd_post

**关联字段**: `object_id` (当 `object_type = 'post'`)

**关联类型**: N:1

**说明**: 获取用户行为对应的帖子详情

**SQL 示例**:
```sql
SELECT 
    b.user_id,
    b.behavior_type,
    p.post_id,
    p.post_title,
    p.post_content
FROM 
    dwd_user_behavior b
LEFT JOIN 
    dwd_post p
ON 
    b.object_id = p.post_id
    AND b.object_type = 'post'
WHERE 
    b.date = '2024-01-01'
    AND b.behavior_type IN ('view_post', 'like', 'favorite');
```

**注意**: 
- 必须同时匹配 `object_id` 和 `object_type`
- 不是所有行为都有 `object_id`（如登录行为）

---

### 6. dwd_user_behavior ↔ dwd_comment

**关联字段**: `object_id` (当 `object_type = 'comment'`)

**关联类型**: N:1

**说明**: 获取用户行为对应的评论详情

**SQL 示例**:
```sql
SELECT 
    b.user_id,
    b.behavior_type,
    c.comment_id,
    c.comment_content
FROM 
    dwd_user_behavior b
LEFT JOIN 
    dwd_comment c
ON 
    b.object_id = c.comment_id
    AND b.object_type = 'comment'
WHERE 
    b.date = '2024-01-01';
```

---

## 多表关联示例

### 示例 1: 用户 + 注册 + 行为

**需求**: 查询某渠道新用户的活跃情况

**SQL**:
```sql
SELECT 
    r.register_date,
    r.register_channel,
    COUNT(DISTINCT r.user_id) as new_users,
    COUNT(DISTINCT b.user_id) as active_users,
    COUNT(DISTINCT b.user_id) * 100.0 / COUNT(DISTINCT r.user_id) as active_rate
FROM 
    dwd_user_register r
LEFT JOIN 
    dwd_user_behavior b
ON 
    r.user_id = b.user_id
    AND b.date = r.register_date
WHERE 
    r.register_date = '2024-01-01'
    AND r.register_channel = 'app_store'
GROUP BY 
    r.register_date,
    r.register_channel;
```

### 示例 2: 用户 + 行为 + 内容

**需求**: 分析用户浏览的帖子类型

**SQL**:
```sql
SELECT 
    b.user_id,
    p.post_category,
    COUNT(*) as view_count
FROM 
    dwd_user_behavior b
INNER JOIN 
    dwd_post p
ON 
    b.object_id = p.post_id
    AND b.object_type = 'post'
WHERE 
    b.date = '2024-01-01'
    AND b.behavior_type = 'view_post'
GROUP BY 
    b.user_id,
    p.post_category;
```

---

## 关联注意事项

### 1. 分区字段对齐

**问题**: 关联表的分区字段可能不同

**示例**:
- `dwd_user_behavior` 的分区字段是 `date`
- `dwd_post` 的分区字段可能是 `create_date`

**解决**:
```sql
-- 两个表都加上各自的分区条件
WHERE b.date = '2024-01-01'
  AND p.create_date >= '2024-01-01'
  AND p.create_date < '2024-01-08'
```

### 2. JOIN 类型选择

**LEFT JOIN vs INNER JOIN**:

- **LEFT JOIN**: 保留左表所有记录，即使右表没有匹配
  - 适用场景: 计算留存率、转化率（需要保留未转化的用户）
  
- **INNER JOIN**: 只保留两表都有的记录
  - 适用场景: 需要同时满足两个条件的数据

### 3. 性能优化

**小表驱动大表**:
```sql
-- ✅ 推荐：小表（注册表）在前
FROM dwd_user_register r
LEFT JOIN dwd_user_behavior b ON r.user_id = b.user_id

-- ❌ 不推荐：大表（行为表）在前
FROM dwd_user_behavior b
LEFT JOIN dwd_user_register r ON b.user_id = r.user_id
```

**提前过滤**:
```sql
-- ✅ 推荐：先过滤再关联
FROM (
    SELECT * FROM dwd_user_register 
    WHERE register_date = '2024-01-01'
) r
LEFT JOIN dwd_user_behavior b ON ...

-- ❌ 不推荐：关联后再过滤
FROM dwd_user_register r
LEFT JOIN dwd_user_behavior b ON r.user_id = b.user_id
WHERE r.register_date = '2024-01-01'
```

---

## 常见关联场景

### 场景 1: 新增用户分析
- 主表: `dwd_user_register`
- 关联: `dwd_user_behavior` (分析行为)
- 关联: `dws_user_daily` (分析汇总指标)

### 场景 2: 用户行为分析
- 主表: `dwd_user_behavior`
- 关联: `dim_user` (获取用户属性)
- 关联: `dwd_post` (获取内容详情)

### 场景 3: 留存分析
- 主表: `dwd_user_register` (基准用户)
- 关联: `dwd_user_behavior` (活跃数据)

### 场景 4: 内容分析
- 主表: `dwd_post`
- 关联: `dim_user` (获取作者信息)
- 关联: `dwd_user_behavior` (获取互动数据)

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建文档 |

---

## 使用说明

**For AI**:
- 生成多表关联 SQL 时必须参考本文档
- 注意关联字段的选择
- 注意 JOIN 类型的选择（LEFT/INNER）
- 注意分区字段的过滤

**For Human**:
- 请补充实际的表关联关系
- 请更新关联关系图
- 如有新表，请及时补充关联关系
