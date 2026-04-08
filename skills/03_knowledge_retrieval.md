# Skill: 知识检索

---

## 目标

从知识库中检索与当前需求相关的信息，为 SQL 生成提供依据。

---

## 触发条件

需求澄清完成后，在生成 SQL 之前触发。

---

## 输入

- 澄清后的需求（结构化信息）
- 用户的原始需求

---

## 处理步骤

### 步骤 1: 检索业务知识

**目标**: 获取指标定义、计算规则等业务知识。

**检索范围**:
```
knowledge/business/
├── glossary.md              # 业务术语
├── metrics/                 # 指标定义
│   ├── user_metrics.md
│   ├── content_metrics.md
│   └── trade_metrics.md
├── dimensions/              # 维度定义
│   ├── time_dimensions.md
│   └── user_dimensions.md
└── calculation_rules/       # 计算规则
    ├── retention.md
    └── dau_mau.md
```

**检索方法**:
1. 根据指标名称，查找对应的指标定义文档
2. 读取指标的计算规则、数据口径
3. 读取相关的维度定义

**示例**:
- 需求包含 "DAU" → 读取 `knowledge/business/metrics/user_metrics.md#DAU`
- 需求包含 "留存率" → 读取 `knowledge/business/calculation_rules/retention.md`
- 需求包含 "按日期" → 读取 `knowledge/business/dimensions/time_dimensions.md`

**输出**:
```json
{
  "business_knowledge": {
    "DAU": {
      "definition": "某自然日内有任意行为的去重用户数",
      "calculation": "COUNT(DISTINCT user_id)",
      "source": "knowledge/business/metrics/user_metrics.md"
    }
  }
}
```

### 步骤 2: 检索数据资产信息

**目标**: 获取相关的数据表、字段信息。

**检索范围**:
```
knowledge/data_assets/
├── tables/                  # 表结构文档
│   ├── dws/                # 汇总表
│   ├── dwd/                # 明细表
│   └── ods/                # 原始表
├── relationships.md         # 表关联关系
└── best_practices.md        # SQL 最佳实践
```

**检索方法**:
1. 根据指标，确定需要哪些表
2. 读取表的结构文档
3. 读取表关联关系
4. 读取 SQL 最佳实践

**决策树: 如何选择表**

```
需要查询 DAU？
├─ 是否需要自定义活跃行为？
│  ├─ 是 → 使用 dwd_user_behavior (明细表)
│  └─ 否 → 使用 dws_user_daily (汇总表) ✅ 推荐
│
需要查询新增用户？
├─ 是否需要注册详情？
│  ├─ 是 → 使用 dwd_user_register
│  └─ 否 → 使用 dws_user_daily (如果有新增字段) ✅ 推荐
│
需要查询留存率？
├─ 需要关联哪些表？
│  └─ dwd_user_register (基准用户) + dwd_user_behavior (活跃数据)
```

**输出**:
```json
{
  "data_assets": {
    "tables": [
      {
        "name": "dws_user_daily",
        "usage": "获取 DAU",
        "reason": "汇总表，性能好",
        "doc": "knowledge/data_assets/tables/dws/dws_user_daily.md"
      }
    ],
    "relationships": [],
    "best_practices": [
      "必须使用分区字段",
      "优先使用汇总表"
    ]
  }
}
```

### 步骤 3: 检索相似 SQL 案例

**目标**: 找到相似需求的 SQL 案例作为参考。

**检索范围**:
```
knowledge/sql_examples/
├── user_analysis/           # 用户分析
├── content_analysis/        # 内容分析
├── trade_analysis/          # 交易分析
└── complex_queries/         # 复杂查询
```

**检索方法**:
1. 根据指标类型，确定案例分类
2. 查找相似的案例
3. 读取案例的 SQL 和技术方案

**相似度判断**:
- 指标相同或相似（如 DAU 和 WAU）
- 维度相同或相似
- 计算逻辑相似

**示例**:
- 需求: "查询最近 7 天的 DAU" 
- 相似案例: `knowledge/sql_examples/user_analysis/dau_trend.md`

**输出**:
```json
{
  "similar_cases": [
    {
      "name": "DAU 趋势分析",
      "similarity": 0.95,
      "doc": "knowledge/sql_examples/user_analysis/dau_trend.md",
      "sql_structure": "SELECT date, COUNT(DISTINCT user_id) FROM ..."
    }
  ]
}
```

### 步骤 4: 整合检索结果

**目标**: 将检索到的信息整合，为 SQL 生成做准备。

**输出**:
```json
{
  "retrieval_result": {
    "business_knowledge": {...},
    "data_assets": {...},
    "similar_cases": [...],
    "ready_for_generation": true
  }
}
```

---

## 输出

检索到的知识信息，传递给 SQL 生成环节。

---

## 示例

### 示例 1: 简单需求

**输入**: 查询昨天的 DAU

**检索过程**:
1. 读取 `knowledge/business/metrics/user_metrics.md#DAU`
   - 获取 DAU 定义和计算规则
2. 读取 `knowledge/data_assets/tables/dws/dws_user_daily.md`
   - 确认使用 dws_user_daily 表
3. 读取 `knowledge/sql_examples/user_analysis/dau_trend.md`
   - 获取参考 SQL

**输出**:
```
业务知识:
- DAU = COUNT(DISTINCT user_id) WHERE is_active = 1

数据表:
- 使用 dws_user_daily 表
- 字段: date, user_id, is_active

参考案例:
- dau_trend.md 中的 SQL 结构
```

### 示例 2: 复杂需求

**输入**: 计算 1 月份新用户的次日留存率，按渠道分

**检索过程**:
1. 读取 `knowledge/business/calculation_rules/retention.md`
   - 获取留存率计算规则
2. 读取 `knowledge/data_assets/tables/dwd/dwd_user_register.md`
   - 确认使用注册表获取新用户
3. 读取 `knowledge/data_assets/tables/dwd/dwd_user_behavior.md`
   - 确认使用行为表获取活跃数据
4. 读取 `knowledge/data_assets/relationships.md`
   - 确认两表的关联方式
5. 读取 `knowledge/sql_examples/user_analysis/retention.md`
   - 获取参考 SQL

**输出**:
```
业务知识:
- 次日留存率 = D1活跃用户数 / D0新增用户数
- D1 = D0 + 1天
- 必须使用 LEFT JOIN

数据表:
- dwd_user_register: 获取新用户
- dwd_user_behavior: 获取活跃数据
- 关联字段: user_id
- 关联条件: date = register_date + 1

参考案例:
- retention.md 中的完整 SQL
```

---

## 注意事项

### 1. 检索顺序

按照以下顺序检索，效率最高：
1. 业务知识（理解需求）
2. 数据资产（知道用什么表）
3. SQL 案例（知道怎么写）

### 2. 知识缺失处理

如果知识库中没有相关信息：
1. 记录缺失项到 `feedback/knowledge_gaps/`
2. 告知用户缺少哪些信息
3. 请求用户补充

**示例**:
```
抱歉，我在知识库中没有找到"用户等级"的定义。

请问：
1. 用户等级有哪些？（如: 普通、VIP、SVIP）
2. 等级信息在哪张表的哪个字段？

补充后我可以为您生成 SQL。
```

### 3. 版本管理

如果知识库有多个版本，使用最新版本。

### 4. 缓存机制

对于高频查询的知识（如 DAU 定义），可以缓存，提高效率。

---

## 检索质量评估

### 自检清单

- [ ] 是否找到了所有相关的指标定义？
- [ ] 是否找到了所有需要的数据表？
- [ ] 是否了解了表之间的关联关系？
- [ ] 是否找到了相似的 SQL 案例？
- [ ] 是否有知识缺失？

---

## 错误处理

### 情况 1: 找不到指标定义

**处理**:
1. 检查是否是术语问题（查 glossary.md）
2. 检查是否是新指标（查 feedback/new_requirements.md）
3. 如果确实没有，请求用户提供定义

### 情况 2: 找不到数据表

**处理**:
1. 检查是否有替代表
2. 询问用户数据在哪里
3. 记录到知识缺口

### 情况 3: 没有相似案例

**处理**:
1. 查找部分相似的案例
2. 基于基础知识生成 SQL
3. 生成后建议将其加入案例库

---

## 成功标准

- ✅ 找到所有相关的业务定义
- ✅ 找到所有需要的数据表
- ✅ 了解表的关联关系
- ✅ 找到可参考的 SQL 案例（如果有）
- ✅ 识别知识缺口（如果有）

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建文档 |
