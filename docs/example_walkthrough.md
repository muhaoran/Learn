# ChatBI 完整示例演示

> 本文档通过一个完整的示例，演示 ChatBI 系统的工作流程。

---

## 场景设定

**角色**: 
- 用户: 雪球运营部门的产品经理
- AI: ChatBI 系统

**背景**: 
- 产品经理想分析最近的用户增长情况
- 需要数据支持决策

---

## 示例 1: 简单需求

### 用户输入

```
查询最近 7 天的 DAU 趋势
```

### AI 处理过程

#### 步骤 1: 需求解析

```
[AI 内部处理]
1. 读取 knowledge/business/glossary.md
2. 识别指标: DAU (日活跃用户数)
3. 识别时间: 最近 7 天
4. 识别维度: 日期（按日展示）
5. 不确定项: "最近 7 天" 是否包含今天？
```

#### 步骤 2: 需求澄清

```
[AI 内部判断]
- "最近 7 天" 通常默认包含今天
- 这是低优先级不确定项
- 可以使用默认理解，在输出时说明
```

#### 步骤 3: 知识检索

```
[AI 内部处理]
1. 读取 knowledge/business/metrics/user_metrics.md#DAU
   - 获取 DAU 定义: COUNT(DISTINCT user_id) WHERE is_active = 1
2. 读取 knowledge/data_assets/tables/dws/dws_user_daily.md
   - 确认使用 dws_user_daily 表
3. 读取 knowledge/sql_examples/user_analysis/dau_trend.md
   - 获取参考 SQL
```

#### 步骤 4: SQL 生成

```
[AI 内部处理]
1. 选择表: dws_user_daily (汇总表，性能好)
2. 构建 WHERE: date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
3. 构建 SELECT: date, COUNT(DISTINCT user_id) as dau
4. 构建 GROUP BY: date
5. 构建 ORDER BY: date
6. 添加注释
```

#### 步骤 5: SQL 验证

```
[AI 内部处理]
✅ 语法正确
✅ 表和字段存在
✅ 逻辑符合 DAU 定义
✅ 有分区条件
✅ 性能良好
```

#### 步骤 6: 输出结果

### AI 输出

```markdown
## 需求理解

您的需求是：查询最近 7 天（含今天）每天的 DAU（日活跃用户数）趋势。

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

---

## 技术方案

### 使用的数据表
- **主表**: `dws_user_daily` - 用户日度汇总表，已预计算活跃用户，性能好

### 计算逻辑
1. 从用户日度汇总表查询最近 7 天的数据
2. 筛选活跃用户（is_active = 1）
3. 按日期分组，统计去重用户数
4. 按日期升序排列

### 关键技术点
- 使用汇总表而非明细表，查询速度快
- 时间范围: [今天-6, 今天]，共 7 天
- 按 user_id 去重，符合 DAU 定义

---

## 执行说明

- **数据表**: `dws_user_daily`
- **数据范围**: 最近 7 天
- **预计耗时**: < 1 秒

---

## 结果字段说明

| 字段名 | 含义 | 示例值 |
|--------|------|--------|
| date | 日期 | 2024-01-15 |
| dau | 日活跃用户数 | 1500000 |

---

## 注意事项

- ⚠️ 今天的数据可能不完整（如果是 T+1 更新）
- ✅ 使用汇总表，查询速度很快
- ✅ 结果按日期升序排列，方便查看趋势
```

---

## 示例 2: 需要澄清的需求

### 用户输入

```
帮我看下新用户的留存情况
```

### AI 处理过程

#### 步骤 1: 需求解析

```
[AI 内部处理]
1. 识别指标: 留存率（但具体是哪种留存？）
2. 识别对象: 新用户
3. 不确定项:
   - 时间范围不明确
   - 留存类型不明确（次日？7日？30日？）
   - 是否需要分维度
```

#### 步骤 2: 需求澄清

### AI 输出

```markdown
## 需求理解

您想查询新用户的留存情况。

---

## 需要确认

为了生成准确的 SQL，请确认以下几点：

### 1. 时间范围
想看哪个时间段注册的新用户？

A. 最近 30 天
B. 本月（2024年1月）
C. 上月（2023年12月）
D. 其他（请指定具体日期）

### 2. 留存类型
想看哪种留存？

A. 次日留存（D1）- 注册后第 1 天是否活跃
B. 7 日留存（D7）- 注册后第 7 天是否活跃
C. 30 日留存（D30）- 注册后第 30 天是否活跃
D. 留存曲线 - 同时看 D1, D3, D7, D15, D30

推荐: A（次日留存），最常用的留存指标

### 3. 分析维度
是否需要按维度分组？

A. 不需要，只看整体留存率
B. 按注册渠道分组（评估渠道质量）
C. 按日期分组（看每天的留存情况）
D. 其他维度

推荐: C（按日期分组），可以看到留存率的变化趋势

---

请告诉我您的选择（如: A, A, C），我将为您生成准确的 SQL。
```

### 用户回复

```
A, A, C
```

### AI 继续处理

#### 步骤 3-6: 知识检索、SQL 生成、验证、输出

### AI 输出

```markdown
## 需求理解

您的需求是：查询最近 30 天每天注册的新用户的次日留存率。

---

## SQL 语句

```sql
-- 计算最近 30 天新用户的次日留存率，按注册日期分组

WITH new_users AS (
    -- 获取最近 30 天的新注册用户
    SELECT 
        user_id,
        DATE(register_time) as register_date
    FROM 
        dwd_user_register
    WHERE 
        register_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY)
        AND register_date <= CURRENT_DATE()
),
retention_users AS (
    -- 获取次日活跃的用户
    SELECT 
        nu.user_id,
        nu.register_date
    FROM 
        new_users nu
    INNER JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        -- 关键: D1 = D0 + 1 天
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

---

## 技术方案

### 使用的数据表
- **主表**: `dwd_user_register` - 用户注册表，获取新用户信息
- **关联表**: `dwd_user_behavior` - 用户行为表，获取活跃数据

### 计算逻辑
1. 从注册表获取最近 30 天的新用户（D0）
2. 从行为表获取这些用户在次日（D1）的活跃情况
3. 使用 LEFT JOIN 关联（保留所有新用户，包括未留存的）
4. 按注册日期分组
5. 计算留存率 = D1 活跃用户数 / D0 新增用户数

### 关键技术点
- 使用 CTE 提高可读性
- 使用 LEFT JOIN 避免遗漏未留存用户
- D1 日期 = 注册日期 + 1 天
- 严格按照留存率定义计算

---

## 执行说明

- **数据表**: `dwd_user_register`, `dwd_user_behavior`
- **数据范围**: 
  - 注册表: 最近 30 天
  - 行为表: 最近 31 天（包含 D1 数据）
- **预计数据量**: 约 150 万新用户，15 亿行为记录
- **预计耗时**: 10-30 秒

---

## 结果字段说明

| 字段名 | 含义 | 示例值 | 单位 |
|--------|------|--------|------|
| register_date | 注册日期 | 2024-01-15 | - |
| new_users_count | 新增用户数 | 50000 | 人 |
| retention_users_count | 留存用户数 | 20000 | 人 |
| retention_rate | 次日留存率 | 40.00 | % |

---

## 注意事项

- ⚠️ 最后一天（今天）的次日留存需要明天的数据，目前可能不完整
- ⚠️ 行为表数据量大，查询可能需要 10-30 秒
- ✅ 已使用分区条件，性能可接受
- ✅ 计算逻辑符合业务定义
```

---

## 示例 3: 多轮对话

### 第一轮

**用户**: "查询最近 7 天的 DAU"

**AI**: [生成 SQL，如示例 1]

### 第二轮 - 需求追加

**用户**: "在刚才的基础上，再加上按平台分组"

**AI**:

```markdown
## 需求理解

在之前的 DAU 查询基础上，增加平台维度。

---

## SQL 语句

```sql
-- 查询最近 7 天的 DAU 趋势，按平台分组
SELECT 
    date,
    platform,  -- 新增维度
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
    AND date <= CURRENT_DATE()
    AND is_active = 1
GROUP BY 
    date,
    platform  -- 新增分组
ORDER BY 
    date,
    platform;
```

---

## 变更说明

相比之前的 SQL，主要变更：
1. SELECT 中增加了 `platform` 字段
2. GROUP BY 中增加了 `platform`
3. ORDER BY 中增加了 `platform`

现在可以看到每天各平台的 DAU 分布。
```

### 第三轮 - 需求调整

**用户**: "不对，我只想看 iOS 平台的"

**AI**:

```markdown
## 需求理解

只查询 iOS 平台最近 7 天的 DAU。

---

## SQL 语句

```sql
-- 查询最近 7 天 iOS 平台的 DAU 趋势
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
    AND date <= CURRENT_DATE()
    AND is_active = 1
    AND platform = 'iOS'  -- 新增筛选条件
GROUP BY 
    date
ORDER BY 
    date;
```

---

## 变更说明

相比之前的 SQL，主要变更：
1. WHERE 条件中增加了 `platform = 'iOS'`
2. SELECT 和 GROUP BY 中移除了 `platform`（因为只看一个平台）

现在只显示 iOS 平台的 DAU。
```

---

## 示例 4: 知识库缺失

### 用户输入

```
查询用户的 ARPU 值
```

### AI 处理过程

#### 步骤 1: 需求解析

```
[AI 内部处理]
1. 识别指标: ARPU
2. 在 knowledge/business/metrics/ 中搜索 ARPU
3. 未找到定义
4. 标记为知识缺口
```

### AI 输出

```markdown
## 需求理解

您想查询 ARPU 值。

---

## 需要补充信息

抱歉，我在知识库中没有找到 ARPU 的定义。

为了生成准确的 SQL，请告诉我：

1. **ARPU 的完整定义**
   - ARPU 是指什么？（Average Revenue Per User？）
   - 如何计算？（总收入 / 用户数？）

2. **数据口径**
   - 收入数据在哪张表？
   - 用户数是指活跃用户还是全量用户？
   - 统计周期是？（日/周/月）

3. **时间范围**
   - 您想查询哪个时间段的 ARPU？

补充这些信息后，我可以为您生成 SQL。

同时，我已将 ARPU 记录到知识缺口中，建议补充到知识库，方便后续使用。
```

---

## 示例 5: 复杂需求

### 用户输入

```
分析一下 Q1 通过广告渠道来的用户，他们的发帖行为和留存表现，和其他渠道对比一下
```

### AI 处理过程

#### 步骤 1: 需求解析

```
[AI 内部处理]
1. 识别时间: Q1 (2024年1-3月)
2. 识别对象: 广告渠道用户
3. 识别指标: 
   - 发帖行为（发帖数？发帖用户数？人均发帖数？）
   - 留存表现（次日留存？7日留存？）
4. 识别对比: 与其他渠道对比
5. 不确定项较多
```

#### 步骤 2: 需求澄清

### AI 输出

```markdown
## 需求理解

您想分析 2024 年 Q1（1-3月）通过广告渠道注册的用户，对比其他渠道。

---

## 需要确认

这是一个较复杂的分析需求，请确认以下细节：

### 1. 发帖行为 - 具体想看哪些指标？
A. 发帖数（总共发了多少帖子）
B. 发帖用户数（有多少用户发过帖）
C. 人均发帖数（平均每个用户发多少帖）
D. 以上都要

推荐: D（全面了解发帖情况）

### 2. 留存表现 - 想看哪种留存？
A. 次日留存（D1）
B. 7 日留存（D7）
C. 30 日留存（D30）
D. 留存曲线（D1, D3, D7, D30）

推荐: A 和 B（次日留存看短期，7日留存看中期）

### 3. 对比方式
A. 广告渠道 vs 所有其他渠道（合并）
B. 广告渠道 vs 各个其他渠道（分别展示）
C. 所有渠道都展示（包括广告渠道）

推荐: C（全面对比）

### 4. 聚合粒度
A. 整个 Q1 的汇总数据
B. 按月展示（1月、2月、3月）
C. 按日展示（每天的数据）

推荐: A（Q1 整体）或 B（按月），数据更稳定

---

请告诉我您的选择，我将为您生成 SQL。
```

### 用户回复

```
D, A和B, C, A
```

### AI 继续处理

```markdown
## 需求理解

您的需求是：分析 2024 年 Q1 各注册渠道用户的表现，包括：
- 发帖行为: 发帖数、发帖用户数、人均发帖数
- 留存表现: 次日留存率、7日留存率

---

## SQL 语句

```sql
-- 分析 2024 年 Q1 各渠道用户的发帖行为和留存表现

WITH q1_new_users AS (
    -- Q1 新注册用户
    SELECT 
        user_id,
        DATE(register_time) as register_date,
        register_channel
    FROM 
        dwd_user_register
    WHERE 
        register_date >= '2024-01-01'
        AND register_date < '2024-04-01'
),
post_behavior AS (
    -- 发帖行为统计
    SELECT 
        nu.register_channel,
        COUNT(DISTINCT CASE WHEN b.behavior_type = 'create_post' THEN b.user_id END) as post_users,
        COUNT(CASE WHEN b.behavior_type = 'create_post' THEN 1 END) as post_count
    FROM 
        q1_new_users nu
    LEFT JOIN 
        dwd_user_behavior b
    ON 
        nu.user_id = b.user_id
        AND b.date >= nu.register_date
        AND b.date < '2024-04-01'
    GROUP BY 
        nu.register_channel
),
d1_retention AS (
    -- 次日留存
    SELECT 
        nu.register_channel,
        COUNT(DISTINCT nu.user_id) as total_users,
        COUNT(DISTINCT b.user_id) as d1_retention_users
    FROM 
        q1_new_users nu
    LEFT JOIN 
        dwd_user_behavior b
    ON 
        nu.user_id = b.user_id
        AND b.date = DATE_ADD(nu.register_date, INTERVAL 1 DAY)
    GROUP BY 
        nu.register_channel
),
d7_retention AS (
    -- 7日留存
    SELECT 
        nu.register_channel,
        COUNT(DISTINCT b.user_id) as d7_retention_users
    FROM 
        q1_new_users nu
    LEFT JOIN 
        dwd_user_behavior b
    ON 
        nu.user_id = b.user_id
        AND b.date = DATE_ADD(nu.register_date, INTERVAL 7 DAY)
    GROUP BY 
        nu.register_channel
)
SELECT 
    d1.register_channel,
    d1.total_users as new_users_count,
    
    -- 发帖行为
    pb.post_count,
    pb.post_users as post_users_count,
    ROUND(pb.post_count * 1.0 / pb.post_users, 2) as avg_posts_per_user,
    
    -- 留存表现
    d1.d1_retention_users,
    ROUND(d1.d1_retention_users * 100.0 / d1.total_users, 2) as d1_retention_rate,
    d7.d7_retention_users,
    ROUND(d7.d7_retention_users * 100.0 / d1.total_users, 2) as d7_retention_rate
FROM 
    d1_retention d1
LEFT JOIN 
    post_behavior pb ON d1.register_channel = pb.register_channel
LEFT JOIN 
    d7_retention d7 ON d1.register_channel = d7.register_channel
ORDER BY 
    d1.total_users DESC;  -- 按新增用户数降序，方便对比
```

---

## 技术方案

### 使用的数据表
- `dwd_user_register`: 获取 Q1 新用户
- `dwd_user_behavior`: 获取用户的发帖行为和活跃数据

### 计算逻辑
1. 定义 Q1 新用户（CTE: q1_new_users）
2. 统计发帖行为（CTE: post_behavior）
3. 计算次日留存（CTE: d1_retention）
4. 计算 7日留存（CTE: d7_retention）
5. 关联所有 CTE，输出综合结果

### 关键技术点
- 使用多个 CTE 分别计算各项指标，逻辑清晰
- 所有关联都使用 LEFT JOIN，避免数据缺失
- 人均发帖数 = 总发帖数 / 发帖用户数（不是全部用户）
- 留存率计算使用 LEFT JOIN，保留未留存用户

---

## 执行说明

- **数据范围**: 2024 年 Q1（1-3月）
- **预计数据量**: 约 450 万新用户，45 亿行为记录
- **预计耗时**: 30-60 秒（数据量较大）

---

## 结果字段说明

| 字段名 | 含义 | 示例值 | 单位 |
|--------|------|--------|------|
| register_channel | 注册渠道 | app_store | - |
| new_users_count | Q1 新增用户数 | 150000 | 人 |
| post_count | 发帖总数 | 50000 | 条 |
| post_users_count | 发帖用户数 | 30000 | 人 |
| avg_posts_per_user | 人均发帖数 | 1.67 | 条/人 |
| d1_retention_users | 次日留存用户数 | 60000 | 人 |
| d1_retention_rate | 次日留存率 | 40.00 | % |
| d7_retention_users | 7日留存用户数 | 45000 | 人 |
| d7_retention_rate | 7日留存率 | 30.00 | % |

---

## 结果解读

- 每行代表一个渠道的综合表现
- 可以对比各渠道的用户质量（留存率）和活跃度（发帖行为）
- 结果按新增用户数降序排列，方便找到主要渠道
- 广告渠道的数据会在结果中，可以与其他渠道对比

---

## 注意事项

- ⚠️ 数据量较大，查询可能需要 30-60 秒
- ⚠️ 最近几天的 7日留存可能不完整（需要等 D7 数据）
- ✅ 已使用分区条件
- ✅ 使用 CTE 结构，逻辑清晰
```

---

## 总结

通过以上示例可以看到：

1. **简单需求**: AI 可以快速理解并生成 SQL
2. **模糊需求**: AI 会主动澄清，确保理解准确
3. **多轮对话**: AI 可以在之前的基础上调整
4. **知识缺失**: AI 会明确告知，并请求补充
5. **复杂需求**: AI 可以处理多表关联、多指标计算

**关键成功因素**:
- 完整的知识库
- 清晰的工作流程
- 主动的需求澄清
- 严格的验证机制

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建示例文档 |
