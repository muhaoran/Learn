# 表名: dwd_user_register

> 用户注册明细表 - 这是一个示例表，请根据实际情况修改

---

## 基本信息

| 属性 | 值 |
|------|-----|
| 表名 | `dwd_user_register` |
| 中文名 | 用户注册明细表 |
| 数据层级 | DWD (数据仓库明细层) |
| 更新频率 | 实时 |
| 数据范围 | 2015-01-01 至今 |
| 分区字段 | `register_date` |
| 数据量级 | 日增约 5 万行 |
| 负责人 | [待补充] |

---

## 表说明

### 业务含义
记录每个用户的注册信息，包括注册时间、注册渠道、注册设备等。

### 数据来源
用户注册系统

### 更新逻辑
- 实时写入
- 一个用户只有一条记录（首次注册）

---

## 字段列表

| 字段名 | 类型 | 说明 | 示例值 | 是否必填 | 备注 |
|--------|------|------|--------|----------|------|
| user_id | bigint | 用户ID | 123456 | 是 | 主键 |
| register_time | timestamp | 注册时间 | 2024-01-01 12:30:45 | 是 | |
| register_date | date | 注册日期 | 2024-01-01 | 是 | 分区字段 |
| register_channel | varchar(50) | 注册渠道 | app_store | 是 | 见渠道说明 |
| register_platform | varchar(20) | 注册平台 | iOS | 是 | iOS/Android/Web |
| device_id | varchar(100) | 设备ID | abc123 | 否 | |
| ip | varchar(50) | 注册IP | 192.168.1.1 | 否 | |
| province | varchar(50) | 省份 | 北京 | 否 | |
| city | varchar(50) | 城市 | 北京市 | 否 | |
| invite_user_id | bigint | 邀请人ID | 789012 | 否 | 如果是邀请注册 |

**注**: 以上字段为示例，请根据实际表结构修改。

---

## 注册渠道说明

| register_channel | 中文名 | 说明 |
|------------------|--------|------|
| app_store | App Store | iOS 应用商店 |
| android_market | 安卓应用市场 | 各大安卓市场 |
| ad_baidu | 百度广告 | 百度广告投放 |
| ad_tencent | 腾讯广告 | 腾讯广告投放 |
| organic | 自然流量 | 自然搜索、口碑传播 |
| invite | 邀请注册 | 用户邀请 |

**注**: 请根据实际的渠道列表补充。

---

## 主键和索引

### 主键
- `user_id`

### 索引
- 索引1: `register_date` (分区字段)
- 索引2: `register_channel` (按渠道分析)
- 索引3: `register_time` (时间范围查询)

---

## 关联关系

### 可关联的表

| 关联表 | 关联字段 | 关联类型 | 说明 |
|--------|----------|----------|------|
| dim_user | user_id | 1:1 | 获取用户基础信息 |
| dws_user_daily | user_id | 1:N | 关联用户日度数据 |
| dwd_user_behavior | user_id | 1:N | 关联用户行为 |

---

## 使用场景

### 场景 1: 查询新增用户数

**需求**: 查询某天的新增用户数

**SQL**:
```sql
SELECT 
    register_date,
    COUNT(DISTINCT user_id) as new_users
FROM 
    dwd_user_register
WHERE 
    register_date = '2024-01-01'
GROUP BY 
    register_date;
```

### 场景 2: 按渠道分析新增

**需求**: 查询各渠道的新增用户数

**SQL**:
```sql
SELECT 
    register_date,
    register_channel,
    COUNT(DISTINCT user_id) as new_users
FROM 
    dwd_user_register
WHERE 
    register_date >= '2024-01-01'
    AND register_date < '2024-01-08'
GROUP BY 
    register_date,
    register_channel;
```

### 场景 3: 计算留存率（与行为表关联）

**需求**: 计算次日留存率

**SQL**:
```sql
-- 见 knowledge/sql_examples/user_analysis/retention.md
```

---

## 数据质量

### 数据完整性
- ✅ 注册数据完整

### 数据准确性
- ✅ 与业务系统对账，准确率 100%

---

## 注意事项

### 性能注意事项
- ⚠️ 查询时建议加 `register_date` 分区条件
- ✅ 数据量相对较小，查询性能较好

### 业务注意事项
- ⚠️ 一个用户只有一条注册记录
- ⚠️ 注销后重新注册的用户会有新的 user_id（如果适用）

---

## 变更历史

| 日期 | 变更类型 | 变更内容 | 影响 |
|------|----------|----------|------|
| 2015-01-01 | 新增 | 创建表 | - |

---

## 相关文档

- 业务定义: `knowledge/business/metrics/user_metrics.md` - 新增用户定义
- SQL 案例: `knowledge/sql_examples/user_analysis/`

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建示例文档 |
