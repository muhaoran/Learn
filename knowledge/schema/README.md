# 数据字典（Schema）

## 职责

描述数据仓库中**物理存在的内容**：有哪些表、每张表有哪些字段、字段类型是什么、分区是什么、表之间如何关联。

数据字典**不包含**业务含义的解释（那是 `semantics/` 的职责），只描述客观的物理事实。

---

## 目录结构

```
schema/
├── README.md              # 本文档
├── TEMPLATE.yaml          # 表定义模板
├── trino_syntax.md        # Trino 语法参考
└── tables/
    ├── dwd_user_register.yaml   # 用户注册明细表
    ├── dwd_user_behavior.yaml   # 用户行为明细表
    └── dws_user_daily.yaml      # 用户日度汇总表
```

表的关联关系（JOIN 字段、JOIN 类型）直接在各表 YAML 的 `related_tables` 字段中维护。

---

## 维护规范

- 新增表时，复制 `TEMPLATE.yaml` 填写
- 字段变更必须及时更新（否则 AI 生成的 SQL 会用错字段）
- 枚举值字段需要在 `enum_values` 中列举，这是 AI 做条件过滤的依据
- 新增表时，在该表的 `related_tables` 字段中补充与其他表的关联关系

---

## JOIN 编写原则

生成多表 SQL 时遵守以下规则：

- **小表驱动大表**：FROM 后放数据量小的表（注册表、维表），大表（行为明细表）放在 JOIN 后
- **提前过滤**：用 CTE 或子查询先过滤数据，再做 JOIN，减少参与 JOIN 的数据量
- **分区条件对齐**：多表关联时，每张表都必须带上各自的分区条件
- **明确 JOIN 类型**：计算留存率/转化率时用 LEFT JOIN 保留分母；需同时满足条件时用 INNER JOIN

---

## 数据层级说明

| 层级 | 英文 | 说明 | 查询建议 |
|------|------|------|----------|
| ODS | Operational Data Store | 原始日志，一般不直接查询 | ❌ 避免 |
| DWD | Data Warehouse Detail | 经过清洗的明细数据 | ⚠️ 数据量大，注意分区 |
| DWS | Data Warehouse Summary | 按维度汇总，推荐使用 | ✅ 优先 |
| ADS | Application Data Store | 面向特定业务场景的应用层 | ✅ 优先 |
| DIM | Dimension | 维度表（用户属性等） | ✅ 关联使用 |
