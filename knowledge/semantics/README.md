# 业务语义（Semantics）

## 职责

将**业务语言翻译为数据条件**，是 AI 理解需求的核心。

数据字典（Schema）告诉 AI "有什么"，业务语义（Semantics）告诉 AI "什么意思"。

---

## 三个子层

### 实体（Entity）`entities/`

业务中的核心对象，是大多数指标的统计主体。

- 定义"统计谁"：明确主键字段，让 AI 知道 `COUNT DISTINCT` 用哪个字段
- 通常对应现实中的一类业务对象：用户、帖子、订单、评论…

### 业务过程（Event）`events/`

某类业务动作**发生了**的事实，不包含筛选和评价。

- 定义"什么叫做 X 发生了"：映射到具体的表和条件
- 只描述事件类型的识别条件（如 `behavior_type = 'create_post'`），**不包含属性过滤**

### 维度（Dimension）`dimensions/`

实体的属性，值必须是有限离散的分类值，用于 GROUP BY 或 WHERE 过滤。

两种业务场景：
- **实体属性**：实体本身具备这个属性，值可从表中直接读取或计算（渠道、平台、新老用户类型）→ 填 `source_table` + `sql_expr`，用 `known_values` 记录枚举含义
- **计算属性**：属性值无法从字段直接读取，需通过行为或关联数据计算（活跃状态、首购状态）→ 用 `named_values` 的自包含子查询定义每个取值的归属条件

---

## 目录结构

```
semantics/
├── README.md
├── templates/                              # ← 新增定义时从这里复制
│   ├── entity.yaml
│   ├── event.yaml
│   └── dimension.yaml
├── entities/
│   ├── user.yaml
│   └── fund_product.yaml
├── events/
│   ├── active_behavior.yaml
│   ├── comment_publish.yaml
│   └── fund_first_purchase.yaml
└── dimensions/
    ├── user_register_channel.yaml          # 注册渠道
    ├── user_platform.yaml                  # 活跃平台
    ├── user_behavior_type.yaml             # 行为类型
    ├── user_computed_tags.yaml             # 用户计算标签（活跃、新老、留存、首购）
    ├── fund_account_type.yaml              # 子账户类型
    ├── fund_product_type.yaml              # 产品类型
    └── fund_register_channel_type.yaml     # 注册渠道类型
```

---

## 边界说明

| 放在 Semantics | 不放在 Semantics |
|----------------|-----------------|
| "活跃" 的业务定义（有任意行为） | 具体的 SQL 查询逻辑（放在 Pattern） |
| "新用户" 指的是什么（注册当天） | DAU 如何计算（放在 Metric） |
| 注册渠道有哪些枚举值 | 字段的物理类型（放在 Schema） |
| "N日首购" 是什么概念 | 指标与指标之间的组合（放在 Metric） |
