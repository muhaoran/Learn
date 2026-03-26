# ChatBI 演示文档

> 实际演示如何使用 ChatBI 系统

---

## 🎬 演示场景

假设你是雪球的产品经理，需要分析用户数据来支持决策。

---

## 演示 1: 最简单的使用

### 场景
你想看昨天的用户活跃情况。

### 你的操作

**在 Cursor Chat 中输入**:
```
查询昨天的 DAU
```

### AI 的响应

```markdown
## 需求理解

您的需求是：查询昨天的日活跃用户数（DAU）。

---

## SQL 语句

```sql
-- 查询昨天的 DAU
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    AND is_active = 1
GROUP BY 
    date;
```

---

## 技术方案

### 使用的数据表
- **主表**: `dws_user_daily` - 用户日度汇总表，已预计算活跃用户，性能好

### 计算逻辑
1. 从用户日度汇总表查询昨天的数据
2. 筛选活跃用户（is_active = 1）
3. 按 user_id 去重统计

### 关键技术点
- 使用汇总表，查询速度快（< 1 秒）
- 按 user_id 去重，符合 DAU 定义

---

## 执行说明

- **数据表**: `dws_user_daily`
- **数据范围**: 昨天 1 天
- **预计耗时**: < 1 秒

---

## 结果字段说明

| 字段名 | 含义 | 示例值 |
|--------|------|--------|
| date | 日期 | 2024-01-15 |
| dau | 日活跃用户数 | 1,500,000 |

---

## 注意事项

- ✅ 使用汇总表，查询速度很快
- ⚠️ 数据为 T+1 更新，确保已更新完成
```

### 结果
✅ **10 秒内得到准确的 SQL**
✅ **有详细的说明**
✅ **可以直接执行**

---

## 演示 2: 需要澄清的场景

### 场景
你想分析新用户的留存情况，但需求不够具体。

### 你的操作

**在 Cursor Chat 中输入**:
```
帮我看下新用户的留存情况
```

### AI 的响应（第一轮：澄清）

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

### 你的回复

```
A, A, C
```

### AI 的响应（第二轮：生成 SQL）

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

[... 完整的技术方案说明 ...]
```

### 结果
✅ **通过澄清，理解准确**
✅ **生成复杂的 SQL**
✅ **有详细的技术说明**

---

## 演示 3: 多轮对话

### 场景
你先查询了 DAU，然后想追加维度。

### 第一轮

**你**: 查询最近 7 天的 DAU

**AI**: [生成基础的 DAU 查询 SQL]

### 第二轮：追加需求

**你**: 在刚才的基础上，再加上按平台分组

**AI**: 
```markdown
## 需求理解

在之前的 DAU 查询基础上，增加平台维度。

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

## 变更说明

相比之前的 SQL，主要变更：
1. SELECT 中增加了 `platform` 字段
2. GROUP BY 中增加了 `platform`
3. ORDER BY 中增加了 `platform`
```

### 第三轮：调整需求

**你**: 不对，我只想看 iOS 平台的

**AI**: 
```markdown
## 需求理解

只查询 iOS 平台最近 7 天的 DAU。

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

## 变更说明

相比之前的 SQL，主要变更：
1. WHERE 条件中增加了 `platform = 'iOS'`
2. SELECT 和 GROUP BY 中移除了 `platform`
```

### 结果
✅ **支持多轮对话**
✅ **可以追加和调整需求**
✅ **清晰说明变更点**

---

## 演示 4: 知识库缺失的场景

### 场景
你想查询一个知识库中没有的指标。

### 你的操作

**在 Cursor Chat 中输入**:
```
查询用户的 RFM 得分分布
```

### AI 的响应

```markdown
## 需求理解

您想查询用户的 RFM 得分分布。

---

## 需要补充信息

抱歉，我在知识库中没有找到 RFM 的定义。

为了生成准确的 SQL，请告诉我：

### 1. RFM 的定义
- RFM 是指什么？（Recency, Frequency, Monetary？）
- 如何计算每个维度的得分？

### 2. 数据来源
- R（最近一次行为）: 数据在哪张表？
- F（行为频率）: 数据在哪张表？
- M（金额）: 数据在哪张表？

### 3. 得分规则
- 如何将 R、F、M 转换为得分？
- 得分范围是多少？（如 1-5）

### 4. 时间范围
- 统计多长时间内的数据？（如最近 90 天）

---

补充这些信息后，我可以为您生成 SQL。

同时，我已将 RFM 记录到知识缺口中，建议补充到知识库：
- 位置: `knowledge/business/metrics/user_metrics.md`
- 或创建: `knowledge/business/calculation_rules/rfm.md`

这样下次就可以直接处理 RFM 相关的需求了。
```

### 你的回复

```
RFM 是用户价值模型：
- R: 最近一次交易距今天数，越小越好
- F: 最近 90 天交易次数，越多越好
- M: 最近 90 天交易金额，越大越好

每个维度按五分位数分为 1-5 分，然后组合成 RFM 得分。

数据在 dwd_trade_order 表中。
```

### AI 的响应

```markdown
## 需求理解

明白了。您想查询用户的 RFM 得分分布，其中：
- R: 最近一次交易距今天数（1-5分）
- F: 最近 90 天交易次数（1-5分）
- M: 最近 90 天交易金额（1-5分）

---

## SQL 语句

```sql
-- 计算用户 RFM 得分分布

WITH user_rfm_raw AS (
    -- 计算每个用户的 R、F、M 原始值
    SELECT 
        user_id,
        DATEDIFF(CURRENT_DATE(), MAX(order_date)) as recency,
        COUNT(DISTINCT order_id) as frequency,
        SUM(order_amount) as monetary
    FROM 
        dwd_trade_order
    WHERE 
        order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
        AND order_status = 'success'
    GROUP BY 
        user_id
),
user_rfm_score AS (
    -- 将 R、F、M 转换为 1-5 分
    SELECT 
        user_id,
        -- R: 天数越小越好，所以用 DESC
        NTILE(5) OVER (ORDER BY recency DESC) as r_score,
        -- F: 次数越多越好
        NTILE(5) OVER (ORDER BY frequency ASC) as f_score,
        -- M: 金额越大越好
        NTILE(5) OVER (ORDER BY monetary ASC) as m_score
    FROM 
        user_rfm_raw
)
SELECT 
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) as rfm_score,
    COUNT(DISTINCT user_id) as user_count,
    ROUND(COUNT(DISTINCT user_id) * 100.0 / SUM(COUNT(DISTINCT user_id)) OVER (), 2) as user_ratio
FROM 
    user_rfm_score
GROUP BY 
    r_score,
    f_score,
    m_score
ORDER BY 
    user_count DESC;
```

---

## 技术方案

### 使用的数据表
- **主表**: `dwd_trade_order` - 交易订单表

### 计算逻辑
1. 计算每个用户的 R、F、M 原始值
2. 使用 NTILE(5) 将原始值转换为 1-5 分
3. 组合成 RFM 得分（如 "555" 表示最优质用户）
4. 统计每个 RFM 组合的用户数和占比

### 关键技术点
- 使用 CTE 提高可读性
- 使用 NTILE 窗口函数进行五分位数分组
- R 值用 DESC（天数越小越好）
- F 和 M 用 ASC（越多/越大越好）

---

## 建议

我已经为您生成了 SQL，同时建议：

1. **补充到知识库**: 
   - 创建 `knowledge/business/calculation_rules/rfm.md`
   - 详细记录 RFM 的定义和计算规则

2. **补充到案例库**:
   - 创建 `knowledge/sql_examples/user_analysis/rfm_analysis.md`
   - 记录这个完整的案例

这样下次遇到 RFM 相关需求，就可以直接处理了。
```

### 结果
✅ **即使知识库没有，AI 也能处理**
✅ **基于你提供的信息生成 SQL**
✅ **建议补充到知识库**

---

## 演示 5: 复杂的多维分析

### 场景
你想全面分析各渠道用户的质量。

### 你的操作

**在 Cursor Chat 中输入**:
```
分析一下 Q1 各渠道新用户的质量，包括留存率和活跃度
```

### AI 的响应（第一轮：澄清）

```markdown
## 需求理解

您想分析 2024 年 Q1 各渠道新用户的质量。

---

## 需要确认

这是一个综合分析需求，请确认以下细节：

### 1. 留存率 - 具体看哪些？
A. 只看次日留存
B. 只看 7 日留存
C. 次日留存 + 7 日留存
D. 留存曲线（D1, D3, D7, D30）

推荐: C（次日和 7 日留存，短期+中期）

### 2. 活跃度 - 具体看哪些指标？
A. 人均活跃天数
B. 人均行为次数
C. 人均发帖数
D. 以上都要

推荐: A 和 B（反映用户活跃程度）

### 3. 对比方式
A. 各渠道分别展示
B. 只对比广告渠道 vs 其他渠道
C. 按渠道类型分组（付费渠道 vs 自然渠道）

推荐: A（各渠道分别展示，全面对比）

---

请告诉我您的选择。
```

### 你的回复

```
C, D, A
```

### AI 的响应（第二轮：生成 SQL）

```markdown
## 需求理解

您的需求是：分析 2024 年 Q1 各注册渠道新用户的质量，包括：
- 留存率: 次日留存率、7日留存率
- 活跃度: 人均活跃天数、人均行为次数、人均发帖数

---

## SQL 语句

```sql
-- 分析 2024 年 Q1 各渠道新用户的质量

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
user_activity AS (
    -- 用户活跃情况
    SELECT 
        nu.register_channel,
        nu.user_id,
        COUNT(DISTINCT ub.date) as active_days,
        COUNT(*) as behavior_count,
        COUNT(CASE WHEN ub.behavior_type = 'create_post' THEN 1 END) as post_count
    FROM 
        q1_new_users nu
    LEFT JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        AND ub.date >= nu.register_date
        AND ub.date < '2024-04-01'
    GROUP BY 
        nu.register_channel,
        nu.user_id
),
d1_retention AS (
    -- 次日留存
    SELECT 
        nu.register_channel,
        COUNT(DISTINCT nu.user_id) as total_users,
        COUNT(DISTINCT ub.user_id) as d1_retention_users
    FROM 
        q1_new_users nu
    LEFT JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        AND ub.date = DATE_ADD(nu.register_date, INTERVAL 1 DAY)
    GROUP BY 
        nu.register_channel
),
d7_retention AS (
    -- 7日留存
    SELECT 
        nu.register_channel,
        COUNT(DISTINCT ub.user_id) as d7_retention_users
    FROM 
        q1_new_users nu
    LEFT JOIN 
        dwd_user_behavior ub
    ON 
        nu.user_id = ub.user_id
        AND ub.date = DATE_ADD(nu.register_date, INTERVAL 7 DAY)
    GROUP BY 
        nu.register_channel
)
SELECT 
    d1.register_channel,
    d1.total_users as new_users_count,
    
    -- 留存指标
    d1.d1_retention_users,
    ROUND(d1.d1_retention_users * 100.0 / d1.total_users, 2) as d1_retention_rate,
    d7.d7_retention_users,
    ROUND(d7.d7_retention_users * 100.0 / d1.total_users, 2) as d7_retention_rate,
    
    -- 活跃度指标
    ROUND(AVG(ua.active_days), 2) as avg_active_days,
    ROUND(AVG(ua.behavior_count), 2) as avg_behavior_count,
    ROUND(AVG(ua.post_count), 2) as avg_post_count
FROM 
    d1_retention d1
LEFT JOIN 
    d7_retention d7 ON d1.register_channel = d7.register_channel
LEFT JOIN 
    user_activity ua ON d1.register_channel = ua.register_channel
GROUP BY 
    d1.register_channel,
    d1.total_users,
    d1.d1_retention_users,
    d7.d7_retention_users
ORDER BY 
    d1.total_users DESC;
```

[... 详细的技术方案说明 ...]
```

### 结果
✅ **处理复杂的多维分析**
✅ **多表关联，多指标计算**
✅ **逻辑清晰，使用 CTE**

---

## 演示 6: 实际工作场景

### 场景：周报数据准备

你需要准备每周的数据周报。

### 你的操作序列

**需求 1**: 
```
查询上周的 DAU、MAU、新增用户数
```

**AI**: [生成 SQL，10秒]

---

**需求 2**:
```
查询上周新增用户的次日留存率和7日留存率，按渠道分
```

**AI**: [澄清"上周"的定义，然后生成 SQL，30秒]

---

**需求 3**:
```
查询上周各平台的发帖数、发帖用户数、人均发帖数
```

**AI**: [生成 SQL，15秒]

---

**需求 4**:
```
对比上周和上上周的核心指标变化
```

**AI**: [澄清"核心指标"包括哪些，然后生成 SQL，1分钟]

### 结果
✅ **连续处理多个需求**
✅ **每个需求 10-60 秒**
✅ **传统方式需要 2-3 小时**
✅ **效率提升 20+ 倍**

---

## 🎯 演示总结

### ChatBI 的能力

1. ✅ **快速响应**: 10-30 秒
2. ✅ **主动澄清**: 识别模糊需求
3. ✅ **准确生成**: 基于知识库
4. ✅ **详细说明**: 技术方案、字段含义
5. ✅ **多轮对话**: 支持追加和调整
6. ✅ **知识学习**: 补充缺失的知识

### 适用场景

- ✅ 日常监控（DAU、MAU、新增）
- ✅ 趋势分析（时间序列）
- ✅ 留存分析（次日、7日、30日）
- ✅ 渠道分析（渠道质量、效果）
- ✅ 多维分析（多个维度交叉）
- ✅ 复杂计算（基于知识库）

### 不适用场景

- ❌ 需要创新思路的探索性分析
- ❌ 需要深度业务判断的分析
- ❌ 跨多个业务系统的复杂分析
- ❌ 知识库中完全没有的全新需求

**解决方案**: 这些场景由人工处理，处理后补充到知识库

---

## 🚀 如何开始演示

### 准备工作

1. **填充知识库**（最小数据集）
   - 5 个核心术语（如：活跃用户、新增用户、留存用户、DAU、留存率）
   - 3 张核心表（如：dws_user_daily、dwd_user_register、dwd_user_behavior）
   - 2 个 SQL 案例（如：DAU 查询、留存率计算）

2. **配置 AI**
   - 确保 `.cursorrules` 文件生效
   - 确保 AI 可以读取 `knowledge/` 目录

3. **准备测试需求**
   - 准备 3-5 个真实的数据需求
   - 涵盖简单、中等、复杂的场景

### 演示步骤

**Step 1**: 简单需求（展示速度）
```
查询昨天的 DAU
```
预期: 10 秒内得到结果

**Step 2**: 需要澄清的需求（展示澄清能力）
```
看下新用户的留存
```
预期: AI 主动提问，澄清后生成 SQL

**Step 3**: 复杂需求（展示处理能力）
```
分析各渠道新用户的质量
```
预期: 生成复杂的多表关联 SQL

**Step 4**: 多轮对话（展示交互能力）
```
1. 查询最近 7 天的 DAU
2. 加上按平台分组
3. 只看 iOS 平台
```
预期: 每轮都能正确理解和调整

**Step 5**: 知识缺失（展示学习能力）
```
查询一个知识库中没有的指标
```
预期: AI 询问定义，基于你的回答生成 SQL

### 演示效果

- ⚡ 速度: 10-30 秒（vs 传统的 30-60 分钟）
- 🎯 准确: 符合业务定义
- 💬 智能: 主动澄清
- 📚 学习: 补充知识

---

## 💡 演示技巧

### 技巧 1: 对比展示

**传统方式**:
1. 展示传统流程（接需求→沟通→查表→写SQL→验证）
2. 说明耗时（30-60 分钟）

**ChatBI 方式**:
1. 直接输入需求
2. 10-30 秒得到结果
3. 对比效率提升

### 技巧 2: 循序渐进

1. 先演示简单需求（建立信心）
2. 再演示复杂需求（展示能力）
3. 最后演示特殊场景（展示智能）

### 技巧 3: 强调价值

- 不仅是快，更是准（基于知识库）
- 不仅是工具，更是知识沉淀
- 不仅是效率，更是能力提升

### 技巧 4: 处理质疑

**质疑 1**: "准确率只有 85%，还是有 15% 错误"

**回应**: 
- 人工也会犯错，准确率也不是 100%
- 85% 是一次通过率，剩余 15% 可以调整
- 随着知识库完善，准确率会持续提升
- 即使 85%，效率提升也是巨大的（20倍）

**质疑 2**: "初期投入 5 人周，值得吗？"

**回应**:
- 5 人周的投入，每年节省 26 人周
- ROI 1.3 倍（第一年），后续年份 2.6 倍
- 更重要的是知识沉淀和能力提升
- 可以先用 2-3 人周快速验证

**质疑 3**: "业务变化快，知识库会不会过时？"

**回应**:
- 建立了定期更新机制
- 维护成本低（每周 4-8 小时）
- 知识库本身就是业务的文档化
- 即使不用 AI，这些文档也有价值

---

## 📊 演示数据

### 准备演示数据

如果需要实际执行 SQL 演示，准备：

1. **测试数据库**
   - 包含示例数据的测试库
   - 或使用生产数据库的只读副本

2. **示例数据**
   - 用户表: 1000 个示例用户
   - 行为表: 10000 条示例行为
   - 注册表: 1000 条注册记录

3. **预期结果**
   - 提前准备好预期的查询结果
   - 用于验证 SQL 的正确性

---

## 🎬 演示脚本

### 5 分钟快速演示

**目标受众**: 决策者、管理者

**演示内容**:
1. **介绍**（1分钟）
   - ChatBI 是什么
   - 核心价值

2. **演示**（3分钟）
   - 演示 1: 简单查询（30秒）
   - 演示 2: 复杂查询（2分钟）
   - 对比传统方式

3. **总结**（1分钟）
   - 效率提升 20 倍
   - 投入产出分析
   - 下一步行动

### 30 分钟深度演示

**目标受众**: 项目负责人、技术团队

**演示内容**:
1. **背景介绍**（5分钟）
   - 现状和痛点
   - ChatBI 的解决方案

2. **系统架构**（10分钟）
   - 三层知识库
   - 六步工作流
   - 六大技能

3. **实际演示**（10分钟）
   - 5 个不同场景的演示
   - 展示各种能力

4. **实施计划**（5分钟）
   - 实施阶段
   - 资源需求
   - 时间线

---

## 📝 演示检查清单

### 演示前

- [ ] 知识库已填充（至少最小数据集）
- [ ] AI 配置已生效
- [ ] 测试需求已准备
- [ ] 演示环境已就绪
- [ ] 演示脚本已熟悉

### 演示中

- [ ] 清晰介绍背景和价值
- [ ] 循序渐进展示能力
- [ ] 强调关键亮点
- [ ] 处理质疑和问题
- [ ] 记录反馈

### 演示后

- [ ] 收集反馈
- [ ] 回答问题
- [ ] 提供文档
- [ ] 跟进行动

---

## 🎯 演示目标

### 让决策者看到

- 💰 投入产出（ROI 11.8 倍）
- ⚡ 效率提升（20 倍）
- 🎯 准确性（85%+）
- 📚 知识沉淀（长期价值）

### 让项目负责人看到

- 🏗️ 完整的架构
- 📋 清晰的实施计划
- ✅ 可控的风险
- 📈 明确的里程碑

### 让使用者看到

- 🚀 简单易用（自然语言）
- ⚡ 快速响应（10-30秒）
- 💬 智能澄清（主动提问）
- 📝 详细说明（易于理解）

### 让技术团队看到

- 🏗️ 优雅的架构
- 📚 完整的文档
- 🎯 标准化的流程
- 🔄 可进化的系统

---

## 🎉 演示成功标准

- ✅ 观众理解了 ChatBI 的价值
- ✅ 观众看到了实际效果
- ✅ 观众认可投入产出比
- ✅ 观众愿意支持项目
- ✅ 获得了启动项目的批准

---

**准备好了吗？让我们开始演示！** 🎬

---

_演示文档更新于: 2024-01-01_
EOF
cat /workspace/DEMO.md | head -50