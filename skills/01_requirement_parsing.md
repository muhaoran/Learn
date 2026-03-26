# Skill: 需求解析

---

## 目标

从用户的自然语言需求中提取结构化信息，为后续处理做准备。

---

## 触发条件

用户提交数据统计需求时，自动触发。

---

## 输入

用户的原始需求描述（自然语言）。

**示例**:
- "查询最近 7 天的 DAU"
- "帮我看下 1 月份新用户的次留，按渠道分"
- "分析一下 VIP 用户的发帖情况"

---

## 处理步骤

### 步骤 1: 读取业务知识库

在解析需求前，必须先读取相关知识库：

```
必读文档:
- knowledge/business/glossary.md (业务术语表)
- knowledge/business/metrics/ (指标定义)
- knowledge/business/dimensions/ (维度定义)
```

### 步骤 2: 识别指标

**任务**: 识别用户想要查询的指标。

**方法**:
1. 查找指标关键词（DAU, MAU, 留存率, 发帖数等）
2. 查找业务术语（活跃, 新增, 留存等）
3. 翻译黑话为标准术语（参考 glossary.md）

**示例**:
- "DAU" → 日活跃用户数
- "次留" → 次日留存率
- "发帖情况" → 发帖数、发帖用户数、人均发帖数（需要澄清）

**输出**:
```json
{
  "metrics": ["DAU"],
  "metrics_aliases": {"DAU": "日活跃用户数"},
  "metrics_definitions": "knowledge/business/metrics/user_metrics.md#DAU"
}
```

### 步骤 3: 识别维度

**任务**: 识别分析维度。

**方法**:
1. 查找维度关键词（按渠道、按平台、按日期等）
2. 识别时间粒度（日、周、月）
3. 识别用户分层（新用户、VIP 用户等）

**示例**:
- "按渠道分" → 维度: 渠道
- "最近 7 天" → 维度: 日期（日粒度）
- "VIP 用户" → 筛选条件: user_type = 'VIP'

**输出**:
```json
{
  "dimensions": ["date", "channel"],
  "time_granularity": "daily"
}
```

### 步骤 4: 识别时间范围

**任务**: 识别时间范围。

**方法**:
1. 识别相对时间（最近N天、昨天、本月等）
2. 识别绝对时间（2024-01-01、1月份等）
3. 参考 `knowledge/business/dimensions/time_dimensions.md`

**示例**:
- "最近 7 天" → `{"type": "relative", "value": "last_7_days", "include_today": true}`
- "1 月份" → `{"type": "absolute", "value": "2024-01", "start": "2024-01-01", "end": "2024-02-01"}`
- "昨天" → `{"type": "relative", "value": "yesterday"}`

**输出**:
```json
{
  "time_range": {
    "type": "relative",
    "value": "last_7_days",
    "include_today": true,
    "sql_condition": "date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY) AND date <= CURRENT_DATE()"
  }
}
```

### 步骤 5: 识别筛选条件

**任务**: 识别其他筛选条件。

**示例**:
- "VIP 用户" → `user_type = 'VIP'`
- "iOS 平台" → `platform = 'iOS'`
- "广告渠道" → `register_channel LIKE 'ad_%'`

**输出**:
```json
{
  "filters": [
    {"field": "user_type", "operator": "=", "value": "VIP"}
  ]
}
```

### 步骤 6: 识别聚合方式

**任务**: 识别如何聚合数据。

**示例**:
- "每天的" → 按日期分组
- "总共" → 不分组，只要总数
- "Top 10" → 排序后取前 10

**输出**:
```json
{
  "aggregation": {
    "group_by": ["date", "channel"],
    "order_by": ["date ASC", "channel ASC"],
    "limit": null
  }
}
```

### 步骤 7: 标记不确定项

**任务**: 标记需要澄清的模糊点。

**检查清单**:
- [ ] 指标定义是否明确？
- [ ] 时间范围是否明确？
- [ ] 维度是否明确？
- [ ] 是否有多种理解方式？

**示例**:
- "用户情况" → 不明确，是 DAU？新增？留存？
- "最近" → 不明确，是包含今天还是不包含？
- "活跃" → 需要确认活跃的定义

**输出**:
```json
{
  "uncertainties": [
    {
      "item": "指标",
      "issue": "用户情况 不明确",
      "options": ["DAU", "新增用户数", "活跃率"],
      "need_clarification": true
    }
  ]
}
```

---

## 输出

结构化的需求信息：

```json
{
  "metrics": ["DAU"],
  "dimensions": ["date", "channel"],
  "time_range": {
    "type": "relative",
    "value": "last_7_days",
    "sql_condition": "..."
  },
  "filters": [],
  "aggregation": {
    "group_by": ["date", "channel"],
    "order_by": ["date ASC"]
  },
  "uncertainties": []
}
```

---

## 示例

### 示例 1: 简单需求

**输入**: "查询昨天的 DAU"

**处理**:
1. 读取 `knowledge/business/glossary.md` - 确认 DAU 定义
2. 识别指标: DAU
3. 识别时间: 昨天
4. 识别维度: 无（只要总数）
5. 无不确定项

**输出**:
```json
{
  "metrics": ["DAU"],
  "dimensions": [],
  "time_range": {"type": "relative", "value": "yesterday"},
  "filters": [],
  "aggregation": {"group_by": []},
  "uncertainties": []
}
```

### 示例 2: 复杂需求

**输入**: "帮我看下最近一个月新用户的次留情况，按渠道分"

**处理**:
1. 读取知识库
2. 识别指标: 次日留存率
3. 识别维度: 日期（注册日期）、渠道
4. 识别时间: 最近一个月
5. 识别筛选: 新用户
6. 标记不确定项:
   - "最近一个月" - 30天还是自然月？
   - "渠道" - 注册渠道还是活跃渠道？

**输出**:
```json
{
  "metrics": ["次日留存率"],
  "dimensions": ["register_date", "channel"],
  "time_range": {"type": "relative", "value": "last_month"},
  "filters": [{"field": "is_new_user", "value": true}],
  "aggregation": {"group_by": ["register_date", "channel"]},
  "uncertainties": [
    {
      "item": "时间范围",
      "issue": "最近一个月 不明确",
      "options": ["最近30天", "本自然月"],
      "need_clarification": true
    },
    {
      "item": "维度",
      "issue": "渠道 不明确",
      "options": ["注册渠道", "活跃渠道"],
      "need_clarification": true
    }
  ]
}
```

### 示例 3: 模糊需求

**输入**: "看下用户情况"

**处理**:
1. 识别指标: 不明确
2. 标记为高度模糊需求

**输出**:
```json
{
  "metrics": [],
  "uncertainties": [
    {
      "item": "指标",
      "issue": "用户情况 过于模糊",
      "options": ["DAU", "新增用户数", "活跃率", "留存率", "用户画像"],
      "need_clarification": true,
      "priority": "high"
    },
    {
      "item": "时间范围",
      "issue": "未指定时间范围",
      "need_clarification": true,
      "priority": "high"
    }
  ]
}
```

---

## 注意事项

### 1. 必须先读取知识库

不能凭空猜测业务术语的含义，必须从知识库中查询。

### 2. 识别黑话

用户可能使用公司内部黑话，需要翻译为标准术语。

**示例**:
- "次留" → 次日留存率
- "月活" → MAU
- "拉新" → 新增用户

### 3. 多义词处理

有些词可能有多种理解，需要标记为不确定项。

**示例**:
- "活跃" - 可能指 DAU，也可能指活跃率
- "用户" - 可能指全量用户，也可能指活跃用户
- "渠道" - 可能指注册渠道，也可能指活跃渠道

### 4. 隐含信息

有些信息是隐含的，需要根据上下文推断。

**示例**:
- "查询 DAU" → 隐含维度是日期
- "新用户的留存" → 隐含需要关联注册表和行为表

---

## 错误处理

### 情况 1: 完全无法理解

如果需求过于模糊，无法提取任何有效信息：
1. 礼貌地告知用户
2. 给出需求描述的建议
3. 提供示例需求

### 情况 2: 部分理解

如果能理解部分需求：
1. 先输出已理解的部分
2. 列出不确定的部分
3. 进入需求澄清环节

---

## 成功标准

- ✅ 正确识别所有指标
- ✅ 正确识别所有维度
- ✅ 正确识别时间范围
- ✅ 正确识别筛选条件
- ✅ 标记所有不确定项
- ✅ 将黑话翻译为标准术语

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建文档 |
