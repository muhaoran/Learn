# 原始知识资料库（raw_knowledge）

## 用途

存放**未经整理的原始知识资料**，由 AI 解析后写入 `knowledge/` 目录。

原始资料可以是任意形式：会议记录、数据字典、需求文档、SQL 片段、聊天截图说明……不需要提前分类或整理。

---

## 目录结构

```
raw_knowledge/
├── README.md       # 本文档
├── mixed/          # 放原始资料的地方
└── processed/      # AI 处理完后，原始文件归档到这里
```

只有两个目录，`mixed/` 放进来，`processed/` 存档。

---

## 使用流程

**第一步**：把原始资料放到 `mixed/`

**第二步**：告诉 AI

```
请处理 raw_knowledge/mixed/xxx
```

**第三步**：AI 会从原始资料中识别信息，按新架构写入 `knowledge/` 对应位置，完成后将原始文件移入 `processed/`

---

## AI 处理的目标结构

AI 解析原始资料后，会判断每条信息属于哪一层，写入对应文件：

| 识别到的内容 | 写入位置 |
|-------------|----------|
| 表名、字段、类型、分区、枚举值 | `knowledge/schema/tables/` |
| 业务对象（用户/帖子/订单）的定义 | `knowledge/semantics/entities/` |
| 业务动作（注册/活跃/发帖）的定义 | `knowledge/semantics/events/` |
| 实体属性维度或计算属性分群的定义 | `knowledge/semantics/dimensions/` |
| 可复用的计算逻辑 | `knowledge/patterns/` |
| 有独立名称的指标口径 | `knowledge/metrics/` |

---

## 原始资料的典型形态

- 一段混乱的会议记录（"DAU 就是日活，user_behavior 表有 user_id 和 behavior_type…"）
- 一份 Excel 数据字典（表名、字段、类型混在一起）
- 一些 SQL 片段（MySQL 或 Hive 语法也没关系，AI 会转换成 Trino）
- 一份 Word 需求文档（业务定义和表结构混写）
- 任何你觉得"里面有有用信息"的文件

---

## 处理后 AI 会说明

- 从哪些内容里识别出了什么
- 分别写入了哪些文件
- 哪些地方不确定，需要你确认

不确定的地方 AI 会主动提问，不会自己猜然后悄悄写进去。
