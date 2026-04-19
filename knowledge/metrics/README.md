# 指标目录（Metric）

## 职责

定义**有名字的指标**，本质是"语义原子 + 计算模式"的具名组合。

指标目录是最薄的一层——它不重复定义计算逻辑（Pattern 已定义），也不重复定义业务含义（Semantics 已定义），只是把它们组合起来并给这个组合一个正式的名字。

---

## 什么指标需要在这里登记？

并非所有可查询的数据都需要在这里登记。**登记的判断标准**：

1. **有独立命名**：业务上有固定叫法（"DAU"、"次日留存率"），而不是即时描述的组合
2. **口径有争议历史**：曾经因为定义不清导致不同人算出不同结果
3. **高频使用**：被多个需求反复查询，值得固化口径

即时推导（如"iOS用户中昨天的发帖数"）不需要登记，直接由 AI 组合 Pattern + Semantics 生成。

---

## 目录结构

```
metrics/
├── README.md
├── TEMPLATE.yaml
└── user/
    ├── dau.yaml
    ├── mau.yaml
    ├── new_user_count.yaml
    ├── d1_retention_rate.yaml
    └── d7_retention_rate.yaml
```

---

## 维护规范

- 指标的 `pattern` 字段必须对应 `patterns/` 目录中存在的 pattern_id
- 指标的参数值必须对应 `semantics/` 目录中存在的 entity_id、event_id 或 dimension value_id
- 别名（aliases）是 AI 识别用户意图的关键，请尽可能列举所有叫法
