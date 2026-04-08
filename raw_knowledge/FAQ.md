# 原始知识处理 - 常见问题

> 关于使用原始知识处理功能的常见问题解答

---

## 关于文件格式

### Q1: 只能用 Word (docx) 格式吗？

**A**: 不是！支持几乎所有文本格式：

**最推荐** ⭐⭐⭐⭐⭐:
- `.docx`, `.doc` (Word)
- `.xlsx`, `.xls` (Excel)
- `.txt` (纯文本)
- `.md` (Markdown)
- `.sql` (SQL 文件)

**也支持** ⭐⭐⭐⭐:
- `.pdf` (PDF 文档)
- `.csv` (CSV 表格)
- `.json` (JSON 数据)

**需要辅助** ⭐⭐:
- `.png`, `.jpg` (图片，需要你说明内容)

**总结**：只要是文本内容，什么格式都可以！

### Q2: 我的文件是纯文本 (.txt)，行吗？

**A**: 完全可以！AI 同样能处理。

**示例**:
```
你的 notes.txt:
DAU 是日活用户数
user_behavior 表包含用户行为
需要统计去重的用户数

AI 处理后:
- 提取术语: DAU
- 提取表: user_behavior
- 生成 SQL: 统计去重用户数的查询
```

### Q3: 我有 Excel 表格，可以吗？

**A**: 可以！Excel 是最好处理的格式之一。

**示例**:
```
你的 Excel (术语表.xlsx):
| 术语 | 定义 |
| DAU | 日活跃用户数 |
| MAU | 月活跃用户数 |

AI 会自动识别表头和内容，提取所有术语。
```

---

## 关于内容标注

### Q4: 我需要在文档里标注什么是业务术语、什么是数据表吗？

**A**: **完全不需要！** ✅

AI 会**自动识别**内容类型，你只需要：
1. 把文件放到 `raw_knowledge/mixed/`
2. 告诉 AI "请处理"
3. 完成！

**AI 自己会判断**：
- 哪些是术语定义（如 "DAU 是日活"）
- 哪些是表结构（如 "user_behavior 表有 user_id 字段"）
- 哪些是 SQL（如 "SELECT COUNT..."）

### Q5: 我的文档完全没有结构，都混在一起，行吗？

**A**: **完全可以！** ✅

**示例 - 混乱的会议记录**:
```
今天讨论数据需求，DAU 要统计去重用户，user_behavior 表有 user_id 
和 behavior_type 字段，SQL 大概是 SELECT COUNT(DISTINCT user_id)，
还有 MAU 是月活，次留是第二天回来的用户。
```

**AI 会做什么**:
1. ✅ 识别出 3 个术语：DAU、MAU、次留
2. ✅ 识别出 1 个表：user_behavior 及其字段
3. ✅ 识别出 SQL 需求，并补全为完整查询
4. ✅ 生成多个知识库文件
5. ⚠️ 标注不确定的部分让你确认

### Q6: 我都不知道哪些算术语、哪些算表结构，怎么办？

**A**: **没关系，你不需要知道！** ✅

这正是 AI 的工作！

**AI 的判断能力**:
- "DAU 是日活" → AI 识别为术语定义
- "user_behavior 表" → AI 识别为数据表
- "user_id 字段" → AI 识别为字段定义
- "SELECT ..." → AI 识别为 SQL

**你只需要**:
- 把文档内容写清楚（即使混乱也行）
- AI 负责识别和分类

---

## 关于文档质量

### Q7: 我的文档质量很低，内容混杂，AI 能处理吗？

**A**: **能处理！** ✅

AI 会尽力提取有用信息，并标注不确定的部分。

**不同质量的处理结果**:

| 文档质量 | AI 能做什么 | 你需要做什么 |
|---------|-----------|------------|
| ⭐⭐⭐⭐⭐ 完美 | 完全自动处理 | 无 |
| ⭐⭐⭐⭐ 良好 | 自动处理，标注少量缺失 | 补充缺失 |
| ⭐⭐⭐ 一般 | 提取大部分，标注不确定项 | 确认不确定项 |
| ⭐⭐ 较差 | 提取部分，提出多个问题 | 回答问题 |
| ⭐ 很差 | 建议整理 | 简单整理 |

### Q8: 如果 AI 理解错了怎么办？

**A**: AI 会标注不确定的部分，你可以：

1. **查看 AI 的反馈**
   ```markdown
   ### 需要确认 ⚠️
   1. user_behavior 表的完整表名是 dwd_user_behavior 吗？
   2. "昨天" 转换为 date_add('day', -1, current_date)，对吗？
   ```

2. **确认或纠正**
   ```
   是的，表名是 dwd_user_behavior
   或者：不对，应该是 ods_user_behavior
   ```

3. **AI 重新处理**
   根据你的反馈修正内容

### Q9: 我的文档是口语化的，AI 能理解吗？

**A**: **可以！** ✅

**示例**:
```
口语化: "查一下昨天有多少人登录过"

AI 理解为:
- 需求: 查询昨天的登录用户数
- SQL: SELECT COUNT(DISTINCT user_id) 
       FROM dwd_user_behavior 
       WHERE date = date_add('day', -1, current_date)
         AND behavior_type = 'login'
```

---

## 关于使用方式

### Q10: 我有多个文件，都要一个个处理吗？

**A**: 可以批量处理：

**方式 1**: 逐个处理
```
请处理 raw_knowledge/mixed/文件1.docx
请处理 raw_knowledge/mixed/文件2.xlsx
```

**方式 2**: 批量处理
```
请处理 raw_knowledge/mixed/ 下的所有文件
```

**方式 3**: 优先级处理
```
请按优先级处理 raw_knowledge/mixed/ 的文件：
1. 先处理术语相关的
2. 再处理表结构相关的
3. 最后处理 SQL 相关的
```

### Q11: 我不确定文件应该放到哪个文件夹？

**A**: **直接放 `mixed/` 就对了！** ⭐推荐

```
raw_knowledge/
└── mixed/          👈 不确定？放这里！
```

理由：
- ✅ 不需要判断文件类型
- ✅ AI 自动识别和分类
- ✅ 即使放错了也没关系，AI 会处理

### Q12: AI 生成的文件在哪里？

**A**: AI 会自动放到正确的位置：

```
knowledge/
├── business/
│   ├── glossary.md              👈 术语在这里
│   ├── metrics/                 👈 指标在这里
│   └── ...
├── data_assets/
│   └── tables/                  👈 表结构在这里
└── sql_examples/                👈 SQL 案例在这里
```

AI 会告诉你生成了哪些文件。

---

## 关于 SQL 处理

### Q13: 我的 SQL 是 MySQL 语法，AI 能处理吗？

**A**: **可以！AI 会自动转换为 Trino 语法** ✅

**示例**:
```sql
你的 MySQL SQL:
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) as date
FROM user_behavior

AI 自动转换为 Trino:
SELECT date_add('day', -1, current_date) as date
FROM dwd_user_behavior
```

### Q14: 我的 SQL 不完整，只有片段，行吗？

**A**: **可以！AI 会补全** ✅

**示例**:
```sql
你的 SQL 片段:
SELECT COUNT(DISTINCT user_id) FROM user_behavior

AI 补全为:
SELECT 
    date,
    COUNT(DISTINCT user_id) as dau
FROM 
    dwd_user_behavior
WHERE 
    date = date_add('day', -1, current_date)
GROUP BY 
    date;
```

---

## 关于处理结果

### Q15: AI 处理后我需要检查什么？

**A**: 只需要简单检查：

**必须检查** ✅:
- [ ] AI 识别的内容类型对不对？
- [ ] AI 标注的"需要确认"的部分，你能回答吗？

**可选检查**:
- [ ] 有没有遗漏的重要信息？
- [ ] 理解是否准确？

**不用担心**:
- ✅ 格式 - AI 已处理
- ✅ 分类 - AI 已识别
- ✅ 语法 - AI 已转换

### Q16: 如果 AI 遗漏了一些内容怎么办？

**A**: 可以：

1. **告诉 AI**
   ```
   你遗漏了 XXX，这也是一个术语
   ```

2. **AI 补充**
   AI 会重新处理并补充

3. **或者你直接编辑**
   直接修改生成的知识库文件

---

## 关于特殊场景

### Q17: 我的文件是图片（截图、ER图），怎么办？

**A**: 需要你辅助说明：

```
我有一张 ER 图，包含以下表：
- user_behavior: 用户行为表
- user_register: 用户注册表
它们通过 user_id 关联

AI 会根据你的描述生成对应的文档。
```

### Q18: 我有 JSON 格式的元数据，可以处理吗？

**A**: 可以！

```json
你的 metadata.json:
{
  "table": "user_behavior",
  "fields": [
    {"name": "user_id", "type": "bigint"},
    {"name": "behavior_type", "type": "varchar"}
  ]
}

AI 会解析 JSON 并生成表文档。
```

### Q19: 我有一堆聊天记录/邮件，能处理吗？

**A**: 可以尝试！

```
把聊天记录保存为文本文件，放到 mixed/
AI 会从中提取有用的信息（术语、表、需求等）
```

---

## 总结

### 核心原则 ✅

1. **任何格式都可以** - docx、txt、pdf、Excel 等
2. **不需要标注** - AI 自动识别内容类型
3. **质量不高也行** - AI 尽力提取有用信息
4. **内容混杂也行** - AI 智能分类处理
5. **不确定就放 mixed/** - 最简单的方式

### 你只需要做 3 件事 ✅

1. 放文件到 `raw_knowledge/mixed/`
2. 告诉 AI "请处理"
3. 确认 AI 标注的不确定项

### AI 会做的事 ✅

1. 读取任何格式的文件
2. 智能识别内容类型
3. 提取和补全信息
4. 转换为标准格式
5. 生成知识库文件
6. 标注不确定项
7. 归档原始文件

---

**还有其他问题？直接问 AI！** 🤖
