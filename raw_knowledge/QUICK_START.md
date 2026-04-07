# 原始知识处理 - 快速开始

> 5 分钟学会如何使用原始知识处理功能

---

## 🎯 这是什么？

**原始知识处理**功能让你可以直接提供原始资料（Excel、Word、SQL 等），AI 会自动将其转换为结构化的知识库内容。

**不需要**：
- ❌ 学习复杂的 Markdown 格式
- ❌ 手动整理和格式化
- ❌ 理解知识库的结构

**只需要**：
- ✅ 提供你的原始资料
- ✅ 告诉 AI "请处理"
- ✅ 等待自动转换完成

---

## 🚀 3 步快速开始

### 步骤 1: 准备原始资料

将你的原始资料放到对应的文件夹：

```
raw_knowledge/
├── business/          👈 业务相关（术语、指标、规则）
├── data_assets/       👈 数据相关（表结构、字段说明）
└── sql_examples/      👈 SQL 相关（查询语句、需求文档）
```

**示例**：
- 有一份术语表 Excel → 放到 `raw_knowledge/business/`
- 有一份数据字典 → 放到 `raw_knowledge/data_assets/`
- 有一些常用 SQL → 放到 `raw_knowledge/sql_examples/`

### 步骤 2: 告诉 AI 处理

在 Cursor 中输入：

```
请处理 raw_knowledge/business/术语表.xlsx
```

或者：

```
我在 raw_knowledge/ 中放了新资料，请帮我处理
```

### 步骤 3: 检查结果

AI 会：
1. ✅ 读取你的原始资料
2. ✅ 自动提取关键信息
3. ✅ 转换为标准的知识库格式
4. ✅ 生成对应的 `.md` 文件到 `knowledge/` 目录
5. ✅ 将原始文件归档到 `processed/`

然后你可以：
- 查看生成的知识库文件
- 检查是否有需要补充的信息
- 立即开始使用 ChatBI

---

## 📋 支持的文件类型

### 业务知识

| 你有什么 | 放到哪里 | AI 会生成什么 |
|---------|---------|--------------|
| 📊 术语表 Excel | `business/` | `knowledge/business/glossary.md` |
| 📄 指标定义 Word | `business/` | `knowledge/business/metrics/*.md` |
| 📝 业务规则 Markdown | `business/` | `knowledge/business/calculation_rules/*.md` |

### 数据资产

| 你有什么 | 放到哪里 | AI 会生成什么 |
|---------|---------|--------------|
| 📊 数据字典 Excel | `data_assets/` | `knowledge/data_assets/tables/*/*.md` |
| 💾 建表语句 SQL | `data_assets/` | 提取字段信息到表文档 |
| 🖼️ 表关系图 PNG | `data_assets/` | 文字描述 + 更新 relationships.md |

### SQL 案例

| 你有什么 | 放到哪里 | AI 会生成什么 |
|---------|---------|--------------|
| 💻 SQL 查询 .sql | `sql_examples/` | `knowledge/sql_examples/*/*.md` |
| 📄 需求文档 Word | `sql_examples/` | 提取需求到 SQL 案例 |
| 📊 分析报告 Excel | `sql_examples/` | 提取分析逻辑到案例 |

---

## 💡 实际示例

### 示例 1: 我有一份术语表 Excel

**你的文件**：`雪球业务术语.xlsx`

| 术语 | 英文 | 定义 |
|------|------|------|
| DAU | Daily Active Users | 日活跃用户数 |
| MAU | Monthly Active Users | 月活跃用户数 |

**操作步骤**：

1. 将文件放到 `raw_knowledge/business/雪球业务术语.xlsx`

2. 在 Cursor 中输入：
   ```
   请处理 raw_knowledge/business/雪球业务术语.xlsx
   ```

3. AI 会自动：
   - 读取 Excel 中的所有术语
   - 提取术语、英文、定义
   - 补充示例和说明
   - 生成或更新 `knowledge/business/glossary.md`
   - 将原始文件移动到 `processed/2024-01/`

4. 完成！你的术语已经加入知识库

### 示例 2: 我有一份数据字典 Excel

**你的文件**：`用户行为表.xlsx`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| user_id | bigint | 用户ID |
| behavior_type | varchar | 行为类型 |
| behavior_time | timestamp | 行为时间 |

**操作步骤**：

1. 将文件放到 `raw_knowledge/data_assets/用户行为表.xlsx`

2. 在 Cursor 中输入：
   ```
   请处理 raw_knowledge/data_assets/用户行为表.xlsx
   ```

3. AI 会自动：
   - 识别表名和字段
   - 按照表模板组织内容
   - 生成 `knowledge/data_assets/tables/dwd/dwd_user_behavior.md`
   - 更新 `relationships.md`
   - 归档原始文件

4. 完成！表文档已生成

### 示例 3: 我有一些常用的 SQL 查询

**你的文件**：`常用查询.sql`

```sql
-- 查询昨天的DAU
SELECT DATE_SUB(CURRENT_DATE(), 1) as date,
       COUNT(DISTINCT user_id) as dau
FROM user_behavior
WHERE date = DATE_SUB(CURRENT_DATE(), 1);
```

**操作步骤**：

1. 将文件放到 `raw_knowledge/sql_examples/常用查询.sql`

2. 在 Cursor 中输入：
   ```
   请处理 raw_knowledge/sql_examples/常用查询.sql
   ```

3. AI 会自动：
   - 分析 SQL 的业务需求
   - **将 SQL 转换为 Trino 语法**
   - 补充技术方案说明
   - 生成 `knowledge/sql_examples/user_analysis/dau_yesterday.md`
   - 归档原始文件

4. 完成！SQL 案例已生成（使用 Trino 语法）

---

## ⚡ 常见问题

### Q1: 我的文件格式不标准怎么办？

**A**: AI 会尽力处理，但可能需要你补充信息。AI 会告诉你缺少什么，你补充后重新处理即可。

### Q2: 我有很多文件，可以批量处理吗？

**A**: 可以！有两种方式：

**方式 1**: 逐个处理
```
请处理 raw_knowledge/business/术语表.xlsx
请处理 raw_knowledge/business/指标定义.docx
```

**方式 2**: 批量处理
```
请处理 raw_knowledge/business/ 文件夹下的所有文件
```

### Q3: AI 生成的内容不准确怎么办？

**A**: 
1. 检查生成的文件，找到不准确的地方
2. 告诉 AI 哪里不对，AI 会修正
3. 或者你直接编辑生成的文件

### Q4: 原始文件会被删除吗？

**A**: 不会！原始文件会被移动到 `raw_knowledge/processed/` 存档，不会删除。

### Q5: 我的 SQL 是 MySQL 语法，AI 能处理吗？

**A**: 可以！AI 会自动识别并转换为 Trino 语法。例如：
- `DATE_SUB(CURRENT_DATE(), 1)` → `date_add('day', -1, current_date)`
- `CURDATE()` → `current_date`

### Q6: 我不知道应该放到哪个文件夹？

**A**: 简单判断：
- 如果是**术语、指标、规则** → `business/`
- 如果是**表结构、字段说明** → `data_assets/`
- 如果是**SQL 查询、需求文档** → `sql_examples/`

不确定的话，随便放一个，AI 会识别并放到正确的位置。

---

## 🎯 最佳实践

### 1. 文件命名清晰

✅ 好的命名：
- `术语表_雪球业务_v1.xlsx`
- `数据字典_用户表_20240101.xlsx`
- `SQL案例_DAU统计.sql`

❌ 不好的命名：
- `文件1.xlsx`
- `新建文档.docx`
- `未命名.sql`

### 2. 保持文件结构清晰

如果是 Excel：
- ✅ 有清晰的表头
- ✅ 数据从第一行或第二行开始
- ❌ 不要有大量空行和合并单元格

如果是 Word：
- ✅ 使用标题和章节
- ✅ 内容结构化
- ❌ 不要全是纯文本没有结构

如果是 SQL：
- ✅ 添加注释说明
- ✅ 格式化代码
- ❌ 不要把多个不相关的查询混在一起

### 3. 提供完整信息

尽量提供：
- ✅ 定义和说明
- ✅ 示例和场景
- ✅ 数据类型和约束
- ✅ 计算规则和公式

### 4. 逐步添加

不要一次性放太多文件，建议：
1. 先处理 5-10 个核心术语
2. 再处理 3-5 张重要的表
3. 最后处理 SQL 案例

这样可以：
- 快速看到效果
- 及时发现问题
- 逐步完善知识库

---

## 📊 处理流程示意图

```
你的原始资料
    ↓
放到 raw_knowledge/
    ↓
告诉 AI "请处理"
    ↓
AI 自动读取和分析
    ↓
AI 提取关键信息
    ↓
AI 转换为标准格式
    ↓
生成知识库文件 (knowledge/)
    ↓
原始文件归档 (processed/)
    ↓
完成！可以使用 ChatBI
```

---

## 🎉 开始使用

现在就试试吧！

1. 找一份你手头的原始资料（术语表、数据字典、SQL 等）
2. 放到 `raw_knowledge/` 对应文件夹
3. 告诉 AI "请处理 raw_knowledge/xxx"
4. 等待 AI 自动转换
5. 检查生成的知识库文件
6. 开始使用 ChatBI！

---

## 📚 更多信息

- 详细使用指南：[raw_knowledge/README.md](README.md)
- AI 处理技能：[skills/07_raw_knowledge_processing.md](../skills/07_raw_knowledge_processing.md)
- 知识库贡献指南：[docs/knowledge_contribution_guide.md](../docs/knowledge_contribution_guide.md)

---

**让知识录入变得简单！** 🚀
