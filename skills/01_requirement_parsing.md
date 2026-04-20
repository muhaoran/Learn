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
- "查询最近 7 天每日下单客户数"
- "帮我看下 1 月份新开户客户的次月复购，按开户渠道分"
- "分析一下黑金卡客户的 SOP 触达情况"

---

## 处理步骤

### 步骤 1: 读取业务知识库

在解析需求前，必须先读取相关知识库：

```
必读文档（优先顺序）:
- knowledge/metrics/              (指标目录：识别用户说的是哪个有名字的指标)
- knowledge/semantics/entities/   (实体定义：识别统计对象)
- knowledge/semantics/events/     (业务过程：识别用户描述的业务动作)
- knowledge/semantics/dimensions/ (维度定义：识别分组和筛选条件)
```

### 步骤 2: 识别指标

**任务**: 识别用户想要查询的指标。

**方法**:
1. 查找指标关键词（日下单客户数、复购率、触达条数等）
2. 查找业务术语（开户、首购、复购、触达等）
3. 翻译黑话为标准术语（参考 `knowledge/metrics/`、`knowledge/semantics/` 中的 `aliases`）

**示例**:
- "日下单" → 日下单客户数
- "次月复购" → 开户后次月再次下单的客户占比
- "触达情况" → 触达条数、触达客户数、人均触达数（需要澄清）

**输出**:
```json
{
  "metrics": ["daily_buying_customer"],
  "metrics_aliases": {"日下单": "日下单客户数"},
  "metrics_definition_file": "knowledge/metrics/daily_buying_customer.yaml"
}
```

### 步骤 3: 识别维度

**任务**: 识别分析维度。

**方法**:
1. 查找维度关键词（按开户渠道、按产品大类、按日期等）
2. 识别时间粒度（日、周、月）
3. 识别客户分层（新开户客户、黑金卡客户等）

**示例**:
- "按开户渠道分" → 维度: open_channel
- "最近 7 天" → 维度: 日期（日粒度）
- "黑金卡客户" → 筛选条件: 客户标签包含黑金卡（依赖 `knowledge/semantics/dimensions/` 中相应命名取值）

**输出**:
```json
{
  "dimensions": ["dt", "open_channel"],
  "time_granularity": "daily"
}
```

### 步骤 4: 识别时间范围

**任务**: 识别时间范围。

**方法**:
1. 识别相对时间（最近N天、昨天、本月等）
2. 识别绝对时间（2024-01-01、1月份等）
3. 时间函数必须使用 Trino 语法（`date_add`、`current_date`）

**示例**:
- "最近 7 天" → `{"type": "relative", "value": "last_7_days", "include_today": true}`
- "1 月份" → `{"type": "absolute", "value": "<YYYY-MM>", "start": "<YYYY-MM-01>", "end": "<下月-01>"}`
- "昨天" → `{"type": "relative", "value": "yesterday"}`

**输出**:
```json
{
  "time_range": {
    "type": "relative",
    "value": "last_7_days",
    "include_today": true,
    "sql_condition": "dt >= date_format(date_add('day', -6, current_date), '%Y-%m-%d') AND dt <= date_format(current_date, '%Y-%m-%d')"
  }
}
```

### 步骤 5: 识别筛选条件

**任务**: 识别其他筛选条件。

**示例**:
- "黑金卡客户" → 关联 `dwd_pat_juzi_mhlabel_record` 中的黑金卡标签
- "外部渠道" → `flavor_type = 'external'`
- "公募小雪触达" → `business_type = '公募小雪'`

**输出**:
```json
{
  "filters": [
    {"field": "flavor_type", "operator": "=", "value": "external"}
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
    "group_by": ["dt", "open_channel"],
    "order_by": ["dt ASC", "open_channel ASC"],
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
- "客户情况" → 不明确，是日下单客户数？新开户客户数？复购率？
- "最近" → 不明确，是包含今天还是不包含？
- "活跃" → 需要确认活跃的定义（当日下单？当月下单？登录？）

**输出**:
```json
{
  "uncertainties": [
    {
      "item": "指标",
      "issue": "客户情况 不明确",
      "options": ["日下单客户数", "新开户客户数", "复购率"],
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
  "metrics": ["daily_buying_customer"],
  "dimensions": ["dt", "open_channel"],
  "time_range": {
    "type": "relative",
    "value": "last_7_days",
    "sql_condition": "..."
  },
  "filters": [],
  "aggregation": {
    "group_by": ["dt", "open_channel"],
    "order_by": ["dt ASC"]
  },
  "uncertainties": []
}
```

---

## 示例

### 示例 1: 简单需求

**输入**: "查询昨天的下单客户数"

**处理**:
1. 读取 `knowledge/metrics/daily_buying_customer.yaml` 确认指标定义
2. 识别指标: 日下单客户数
3. 识别时间: 昨天
4. 识别维度: 无（只要总数）
5. 无不确定项

**输出**:
```json
{
  "metrics": ["daily_buying_customer"],
  "dimensions": [],
  "time_range": {"type": "relative", "value": "yesterday"},
  "filters": [],
  "aggregation": {"group_by": []},
  "uncertainties": []
}
```

### 示例 2: 复杂需求

**输入**: "帮我看下最近一个月新开户客户的次月复购情况，按开户渠道分"

**处理**:
1. 读取 `knowledge/metrics/`、`knowledge/semantics/`
2. 识别指标: 次月复购率
3. 识别维度: 开户日期、开户渠道（flavor）
4. 识别时间: 最近一个月（开户时间）
5. 识别筛选: 新开户客户
6. 标记不确定项:
   - "最近一个月" - 30 天还是自然月？
   - "复购口径" - 是否包含定投执行？

**输出**:
```json
{
  "metrics": ["next_month_repurchase_rate"],
  "dimensions": ["open_date", "open_channel"],
  "time_range": {"type": "relative", "value": "last_month"},
  "filters": [{"field": "is_new_customer", "value": true}],
  "aggregation": {"group_by": ["open_date", "open_channel"]},
  "uncertainties": [
    {
      "item": "时间范围",
      "issue": "最近一个月 不明确",
      "options": ["最近30天", "本自然月"],
      "need_clarification": true
    },
    {
      "item": "复购口径",
      "issue": "是否包含定投执行",
      "options": ["仅主动买入", "含定投执行"],
      "need_clarification": true
    }
  ]
}
```

### 示例 3: 模糊需求

**输入**: "看下客户情况"

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
      "issue": "客户情况 过于模糊",
      "options": ["日下单客户数", "新开户客户数", "复购率", "客户画像"],
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

不能凭空猜测业务术语的含义，必须从知识库中查询。优先查 `knowledge/metrics/` 中的 `aliases` 字段识别指标，再查 `knowledge/semantics/` 中各类型的 `aliases` 字段识别实体/事件/维度。

### 2. 识别黑话

用户可能使用公司内部黑话，需要翻译为标准术语。标准词一律以 `knowledge/metrics/` 与 `knowledge/semantics/` 中登记的 `name` 为准，别名由对应文件的 `aliases` 字段承载。

**做法**:
- 遇到非标准表述时，先在 `aliases` 中匹配；匹配不到的黑话必须走澄清流程，不能臆测。

### 3. 多义词处理

有些词可能有多种理解，需要标记为不确定项。

**做法**:
- 同一个业务词在多个 `aliases` 中出现时，把全部候选列给用户选择；不要默认取其一。
- 典型多义场景：同一个中文词对应多个指标（如"客户数"可能对应"下单客户数 / 开户客户数 / 触达客户数"）、或同一个维度词在不同实体上意义不同。

### 4. 隐含信息

有些信息是隐含的，需要根据上下文推断，但推断结果必须能在知识库中找到对应定义。

**做法**:
- 缺省维度：用户未指定 `group_by` 时，默认不分组（只产出总数）；若业务上显然需要分组（如"按渠道"是该指标的主要观察角度），必须在下一步主动澄清，不自行假设；
- 缺省时间范围按用户给的时间粒度推断（如只说"每天"但没说几天 → 澄清窗口长度）；
- 涉及多表的指标，按 pattern 定义中声明的事件来源展开，不自行选择表。

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
| 2026-04-20 | AI | 清理虚构通用示例（DAU/MAU/留存）；澄清缺省维度策略，删除对不存在字段 `default_group_by` 的引用 |
