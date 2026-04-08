# Skill: 原始知识处理

---

## 目标

将用户提供的原始知识资料（Excel、Word、SQL 等）转换为结构化的知识库内容。

---

## 触发条件

用户将原始资料放到 `raw_knowledge/` 文件夹，并请求处理。

**触发指令示例**:
- "请处理 raw_knowledge/mixed/数据需求.docx" ⭐最常见
- "请处理 raw_knowledge/business/术语表.xlsx"
- "我放了新的原始资料，请帮我处理"
- "处理 raw_knowledge/ 下的所有文件"

---

## 输入

- 原始知识资料文件（Excel、Word、SQL、Markdown 等）
- 文件位置：`raw_knowledge/{mixed|business|data_assets|sql_examples}/`
  - **推荐**: 优先放到 `mixed/`，AI 自动识别和分类
  - **可选**: 如果明确是单一类型，可以放到对应文件夹

---

## 处理步骤

### 步骤 1: 识别文件类型和内容

**任务**: 确定原始资料的类型和内容，识别是否包含多种类型

**必须做**:
1. 读取文件内容
2. 识别文件格式（Excel、Word、SQL 等）
3. **识别内容类型（可能包含多种类型）**：
   - 业务知识（术语、指标、维度、规则）
   - 数据资产（表结构、字段说明、关联关系）
   - SQL 案例（查询语句、需求、分析逻辑）
4. **标记每部分内容的类型**
5. 评估资料质量（完整性、准确性、结构化程度）

**特别注意**:
- ✅ 文件可能包含**多种类型**的内容（混合文档）
- ✅ 需要**逐段分析**，识别每部分的类型
- ✅ 不同类型的内容需要**分别处理**
- ✅ 即使在 `business/` 文件夹，也可能包含数据表信息

**质量评估标准**:

| 质量等级 | 特征 | 处理方式 |
|---------|------|---------|
| ⭐⭐⭐⭐⭐ 优秀 | 完整、准确、结构化 | 直接转换 |
| ⭐⭐⭐⭐ 良好 | 大部分完整，少量缺失 | 转换 + 标注缺失项 |
| ⭐⭐⭐ 一般 | 信息不完整，需要补充 | 部分转换 + 提出问题 |
| ⭐⭐ 较差 | 结构混乱，信息缺失严重 | 整理建议 + 等待补充 |
| ⭐ 很差 | 无法理解或错误严重 | 拒绝处理 + 说明原因 |

### 步骤 2: 智能提取和补全

**任务**: 从混杂、不完整的内容中提取并补全信息

**核心能力**：**从混乱中提取秩序** ✅

**处理策略**:

1. **提取已有信息**
   - 从识别出的内容中提取关键信息
   - 即使信息不完整也先提取

2. **智能补全**
   - SQL 片段 → 补全为完整 SQL
   - 简化的表名 → 推测完整表名（如 user_behavior → dwd_user_behavior）
   - 缺少的定义 → 根据上下文补充
   - 不完整的字段 → 标注需要补充

3. **推理关联关系**
   - 术语和表的关系（如 DAU 来自哪张表）
   - 表之间的关系（根据字段名推测）
   - SQL 使用的表和字段

4. **标注置信度**
   - 高置信度：直接从文档中提取，信息完整
   - 中置信度：需要推理或补全的部分
   - 低置信度：不太确定，需要用户确认

**处理不同质量的内容**:

| 内容质量 | 提取策略 | 示例 |
|---------|---------|------|
| **结构清晰** | 直接提取 | "用户ID (user_id, bigint, 主键)" → 完整提取 |
| **部分信息** | 提取 + 补全 | "user_id 用户ID" → 推测类型为 bigint |
| **混杂描述** | 智能解析 | "表里有用户ID字段" → 提取出字段信息 |
| **片段信息** | 补全 | "SELECT user_id FROM..." → 补全完整 SQL |
| **口语化** | 标准化 | "查昨天的活跃用户" → 转换为标准需求 |

**根据识别结果提取**:

#### 业务知识（术语、指标、维度、规则）

提取内容：
- 术语名称和定义
- 英文缩写
- 业务场景
- 计算规则
- 相关术语
- 数据来源

#### 数据资产（表结构、字段说明）

提取内容：
- 表名和说明
- 字段名、类型、说明
- 主键和索引
- 分区字段
- 表关联关系
- 使用场景

#### SQL 案例（查询语句、需求文档）

提取内容：
- 业务需求
- SQL 语句
- 查询逻辑
- 使用的表和字段
- 结果说明
- 注意事项

### 步骤 3: 选择目标模板

**任务**: 根据资料类型选择对应的知识库模板

**映射关系**:

| 原始资料类型 | 目标模板 | 目标路径 |
|-------------|---------|---------|
| 术语表 | glossary.md | `knowledge/business/glossary.md` |
| 指标定义 | metrics 模板 | `knowledge/business/metrics/{类型}_metrics.md` |
| 维度定义 | dimensions 模板 | `knowledge/business/dimensions/{类型}_dimensions.md` |
| 计算规则 | calculation_rules 模板 | `knowledge/business/calculation_rules/{规则名}.md` |
| 数据字典/表结构 | TABLE_TEMPLATE.md | `knowledge/data_assets/tables/{层级}/{表名}.md` |
| 表关系 | relationships.md | `knowledge/data_assets/relationships.md` |
| SQL 查询 | EXAMPLE_TEMPLATE.md | `knowledge/sql_examples/{分类}/{案例名}.md` |

### 步骤 4: 转换和组织内容

**任务**: 按照模板格式组织提取的信息

**必须做**:

1. **使用标准模板**
   - 严格按照模板结构组织内容
   - 不要遗漏必填章节
   - 保持格式一致性

2. **补充必要信息**
   - 添加分类和标签
   - 补充示例（如果原始资料没有）
   - 添加相关链接
   - 标注来源和更新时间

3. **标准化术语**
   - 使用标准的业务术语
   - 统一字段命名规范
   - 统一数据类型表示

4. **转换 SQL 语法**（如果是 SQL 案例）
   - **必须将 SQL 转换为 Trino 语法**
   - 不能保留 MySQL/Hive 等其他语法
   - 参考 `knowledge/data_assets/trino_syntax_guide.md`
   - 添加必要的注释

### 步骤 5: 质量检查

**任务**: 检查转换后的内容质量

**检查清单**:

- [ ] 内容是否完整（没有遗漏重要信息）
- [ ] 格式是否符合模板要求
- [ ] 术语和定义是否准确
- [ ] 示例是否清晰易懂
- [ ] SQL 是否使用 Trino 语法（如适用）
- [ ] 是否有明显的理解错误
- [ ] 是否需要补充额外说明
- [ ] 引用和链接是否正确

**如果发现问题**:
- 标注不确定的地方
- 提出需要澄清的问题
- 说明缺失的信息

### 步骤 6: 生成知识库文件

**任务**: 将转换后的内容写入知识库

**处理混合内容**:

如果原始文件包含多种类型的内容：
1. ✅ **分别生成多个文件**
   - 业务术语 → `knowledge/business/glossary.md`
   - 数据表 → `knowledge/data_assets/tables/...`
   - SQL 案例 → `knowledge/sql_examples/...`
2. ✅ **记录来源**: 在每个生成的文件中标注来源于同一份原始资料
3. ✅ **保持关联**: 在文件中添加相互引用

**必须做**:

1. **确定文件路径**
   - 根据内容类型确定正确的路径
   - 使用规范的文件命名
   - 混合内容生成多个文件

2. **写入文件**
   - 如果目标文件不存在，创建新文件
   - 如果目标文件已存在，合并内容（不要覆盖）
   - 保持原有内容的完整性
   - 添加来源信息

3. **更新相关文件**
   - 如果是新增表，更新 `relationships.md`
   - 如果是新增术语，确保在 `glossary.md` 中
   - 更新索引和目录（如果需要）
   - 添加文件间的交叉引用

### 步骤 7: 归档原始文件

**任务**: 将处理完的原始文件移动到存档目录

**必须做**:

1. **创建归档目录**
   - 按照日期创建子目录：`raw_knowledge/processed/YYYY-MM/`
   - 例如：`raw_knowledge/processed/2024-01/`

2. **移动原始文件**
   - 将原始文件从 `raw_knowledge/{类型}/` 移动到 `processed/YYYY-MM/`
   - 保留原始文件名
   - 如果有同名文件，添加时间戳

3. **记录处理日志**
   - 在归档目录创建 `processing_log.md`
   - 记录处理时间、原始文件、生成文件、质量评估

---

## 输出

### 成功输出

**示例 1: 单一类型内容**

```markdown
## 处理完成 ✅

### 原始文件
- 文件名: `术语表_v1.xlsx`
- 位置: `raw_knowledge/business/`
- 内容类型: 业务术语
- 质量评估: ⭐⭐⭐⭐⭐ 优秀

### 提取信息
- 术语数量: 15 个
- 指标数量: 8 个
- 维度数量: 3 个

### 生成文件
1. `knowledge/business/glossary.md` - 新增 15 个术语
2. `knowledge/business/metrics/user_metrics.md` - 新增 8 个指标
3. `knowledge/business/dimensions/user_dimensions.md` - 新增 3 个维度

### 处理说明
- ✅ 所有术语定义清晰
- ✅ 指标计算规则完整
- ✅ 已添加示例和说明
- ⚠️ 有 2 个术语缺少英文缩写，已标注

### 归档
- 原始文件已移动到: `raw_knowledge/processed/2024-01/术语表_v1.xlsx`
- 处理日志: `raw_knowledge/processed/2024-01/processing_log.md`

### 建议
- 请补充缺少英文缩写的术语
- 建议添加更多使用场景的示例
```

**示例 2: 混合类型内容** ⭐

```markdown
## 处理完成 ✅

### 原始文件
- 文件名: `数据需求文档.docx`
- 位置: `raw_knowledge/mixed/`
- 内容类型: 混合（业务术语 + 数据表 + SQL 查询）
- 质量评估: ⭐⭐⭐⭐ 良好

### 识别结果
✅ 自动识别到 3 种类型的内容：
1. **业务术语**: 在第 1-2 章
   - DAU, MAU, 次留 等 8 个术语
2. **数据表结构**: 在第 3 章
   - 用户行为表、用户注册表 等 3 张表
3. **SQL 查询**: 在第 4 章
   - DAU 统计、留存分析 等 2 个查询

### 提取信息
- 业务术语: 8 个
- 数据表: 3 张，共 25 个字段
- SQL 查询: 2 个

### 生成文件
**业务知识** (8 个术语):
1. `knowledge/business/glossary.md` - 新增 8 个术语

**数据资产** (3 张表):
2. `knowledge/data_assets/tables/dwd/dwd_user_behavior.md` - 用户行为表
3. `knowledge/data_assets/tables/dwd/dwd_user_register.md` - 用户注册表
4. `knowledge/data_assets/tables/dws/dws_user_daily.md` - 用户日度汇总表
5. `knowledge/data_assets/relationships.md` - 更新表关联关系

**SQL 案例** (2 个查询):
6. `knowledge/sql_examples/user_analysis/dau_stat.md` - DAU 统计（已转为 Trino 语法）
7. `knowledge/sql_examples/user_analysis/retention.md` - 留存分析（已转为 Trino 语法）

### 处理说明
- ✅ 成功识别并分类处理所有内容
- ✅ 自动将不同类型内容生成到对应位置
- ✅ SQL 已自动转换为 Trino 语法
- ✅ 添加了文件间的交叉引用
- ⚠️ 有 1 张表缺少分区字段说明，已标注

### 来源追溯
所有生成的文件都标注了来源：
```
**来源**: raw_knowledge/mixed/数据需求文档.docx
**处理时间**: 2024-01-01 10:30:00
```

### 归档
- 原始文件已移动到: `raw_knowledge/processed/2024-01/数据需求文档.docx`
- 处理日志: `raw_knowledge/processed/2024-01/processing_log.md`

### 建议
- 请补充用户日度汇总表的分区字段说明
- 所有内容已自动分类，无需手动整理
```

### 部分成功输出

```markdown
## 处理完成（部分） ⚠️

### 原始文件
- 文件名: `数据字典_不完整.xlsx`
- 位置: `raw_knowledge/data_assets/`
- 质量评估: ⭐⭐⭐ 一般

### 提取信息
- 表数量: 3 个
- 字段数量: 25 个

### 生成文件
1. `knowledge/data_assets/tables/dwd/dwd_user_behavior.md` - 完整
2. `knowledge/data_assets/tables/dwd/dwd_user_register.md` - 缺少分区说明
3. `knowledge/data_assets/tables/dws/dws_user_daily.md` - 缺少字段说明

### 缺失信息
以下信息需要补充：

1. **dwd_user_register 表**
   - 缺少分区字段说明
   - 缺少主键定义

2. **dws_user_daily 表**
   - 有 5 个字段缺少说明
   - 缺少使用场景

### 建议
请补充缺失信息后，我可以重新处理这些表。

或者，我可以先生成不完整的文档，并在文档中标注缺失项。

请问您希望如何处理？
```

### 失败输出

```markdown
## 处理失败 ❌

### 原始文件
- 文件名: `混乱的文档.xlsx`
- 位置: `raw_knowledge/business/`
- 质量评估: ⭐ 很差

### 问题
1. **结构混乱**: 无法识别表头和数据行
2. **信息缺失**: 大部分字段没有说明
3. **格式错误**: 包含大量空行和无效数据

### 建议
请按照以下格式整理后重新提供：

**术语表格式**:
| 术语 | 英文 | 定义 | 业务场景 |
|------|------|------|----------|
| ... | ... | ... | ... |

**指标表格式**:
| 指标名称 | 英文 | 定义 | 计算规则 | 数据来源 |
|---------|------|------|----------|----------|
| ... | ... | ... | ... | ... |

或者，您可以参考 `raw_knowledge/README.md` 中的示例。
```

---

## 特殊场景处理

### 场景 1: Excel 文件有多个 Sheet

**处理方式**:
1. 列出所有 Sheet 名称
2. 询问用户要处理哪些 Sheet
3. 或者自动处理所有 Sheet（如果结构清晰）

### 场景 2: SQL 文件包含多个查询

**处理方式**:
1. 识别所有独立的查询
2. 为每个查询生成独立的案例文档
3. 或者合并为一个文档的多个变体

### 场景 3: Word 文档结构复杂

**处理方式**:
1. 识别章节结构
2. 按照章节分类提取信息
3. 如果无法自动识别，请求用户说明结构

### 场景 4: 图片格式的表关系图

**处理方式**:
1. 说明无法直接读取图片内容
2. 请求用户描述表关系
3. 或者提供文字版的表关系说明

### 场景 5: SQL 使用非 Trino 语法

**处理方式**:
1. 识别 SQL 方言（MySQL、Hive、PostgreSQL 等）
2. 自动转换为 Trino 语法
3. 标注转换的部分
4. 如果不确定，询问用户确认

### 场景 6: 混合内容的文件 ⭐最常见

**处理方式**:
1. **逐段分析内容**
   - 识别每个章节/段落的类型
   - 标记每部分内容的边界
   
2. **分类提取信息**
   - 业务术语 → 提取到术语列表
   - 数据表 → 提取到表结构列表
   - SQL 查询 → 提取到 SQL 列表
   
3. **分别转换**
   - 每种类型按对应模板转换
   - 保持内容之间的关联
   
4. **生成多个文件**
   - 不同类型生成到不同位置
   - 在每个文件中标注来源
   - 添加交叉引用

**示例**:
```
原始文件: 数据需求.docx

第 1 章: 业务背景
  → 提取术语 → knowledge/business/glossary.md

第 2 章: 数据表说明
  → 提取表结构 → knowledge/data_assets/tables/...

第 3 章: 查询需求
  → 提取 SQL → knowledge/sql_examples/...

结果: 从 1 个原始文件生成 5+ 个知识库文件
```

---

## 示例

### 示例 1: 处理术语表 Excel

**输入**: `raw_knowledge/business/雪球术语表.xlsx`

**内容**:
| 术语 | 英文 | 定义 | 业务场景 |
|------|------|------|----------|
| DAU | Daily Active Users | 日活跃用户数 | 用户增长分析 |
| 次留 | D1 Retention | 次日留存率 | 用户留存分析 |

**处理过程**:

```markdown
1. ✅ 识别文件类型: Excel 术语表
2. ✅ 质量评估: ⭐⭐⭐⭐⭐ 优秀（结构清晰，信息完整）
3. ✅ 提取信息: 2 个术语
4. ✅ 选择模板: glossary.md
5. ✅ 转换内容:
   - DAU: 补充计算规则、数据来源
   - 次留: 补充计算公式、相关指标
6. ✅ 生成文件: knowledge/business/glossary.md（追加内容）
7. ✅ 归档: raw_knowledge/processed/2024-01/雪球术语表.xlsx
```

**输出**: 在 `knowledge/business/glossary.md` 中新增 2 个术语定义

### 示例 2: 处理 SQL 文件

**输入**: `raw_knowledge/sql_examples/计算DAU.sql`

**内容**:
```sql
-- 查询昨天的DAU
SELECT DATE_SUB(CURRENT_DATE(), 1) as date,
       COUNT(DISTINCT user_id) as dau
FROM user_behavior
WHERE date = DATE_SUB(CURRENT_DATE(), 1);
```

**处理过程**:

```markdown
1. ✅ 识别文件类型: SQL 查询（MySQL 语法）
2. ✅ 质量评估: ⭐⭐⭐⭐ 良好（有注释，但语法需转换）
3. ✅ 提取信息:
   - 业务需求: 查询昨天的 DAU
   - 使用的表: user_behavior
   - 计算逻辑: COUNT(DISTINCT user_id)
4. ✅ 选择模板: EXAMPLE_TEMPLATE.md
5. ✅ 转换内容:
   - 补充需求分析
   - **转换为 Trino 语法**:
     - DATE_SUB(CURRENT_DATE(), 1) → date_add('day', -1, current_date)
     - 表名可能需要确认（user_behavior → dwd_user_behavior?）
   - 补充技术方案说明
   - 添加结果字段说明
6. ✅ 生成文件: knowledge/sql_examples/user_analysis/dau_yesterday.md
7. ✅ 归档: raw_knowledge/processed/2024-01/计算DAU.sql
```

**输出**: 生成完整的 SQL 案例文档（使用 Trino 语法）

### 示例 3: 处理数据字典 Excel

**输入**: `raw_knowledge/data_assets/用户行为表.xlsx`

**内容**:
| 字段名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| user_id | bigint | 用户ID | 123456 |
| behavior_type | varchar(50) | 行为类型 | login |
| behavior_time | timestamp | 行为时间 | 2024-01-01 10:30:00 |
| date | date | 分区字段-日期 | 2024-01-01 |

**处理过程**:

```markdown
1. ✅ 识别文件类型: 数据字典
2. ✅ 质量评估: ⭐⭐⭐⭐⭐ 优秀（字段完整，有分区说明）
3. ✅ 提取信息:
   - 表名: 用户行为表（推测为 dwd_user_behavior）
   - 字段: 4 个
   - 分区字段: date
4. ✅ 选择模板: TABLE_TEMPLATE.md
5. ✅ 转换内容:
   - 补充表的中英文名称
   - 补充表的用途和使用场景
   - 补充字段的约束（主键、非空等）
   - 补充数据更新频率
6. ✅ 生成文件: knowledge/data_assets/tables/dwd/dwd_user_behavior.md
7. ✅ 更新关联: knowledge/data_assets/relationships.md
8. ✅ 归档: raw_knowledge/processed/2024-01/用户行为表.xlsx
```

**输出**: 生成完整的表文档

---

## 注意事项

### 1. 保持原始信息的准确性

- ✅ 不要修改原始定义的含义
- ✅ 如果不确定，保留原文并标注疑问
- ❌ 不要臆造不存在的信息

### 2. 使用标准模板

- ✅ 严格按照模板结构组织内容
- ✅ 不要遗漏必填章节
- ✅ 保持格式一致性

### 3. 转换 SQL 为 Trino 语法

- ✅ **必须转换为 Trino 语法**
- ✅ 参考 `trino_syntax_guide.md`
- ✅ 标注转换的部分
- ❌ 不能保留非 Trino 语法

### 4. 标注不确定的地方

- ✅ 使用 `[待确认]` 标记
- ✅ 说明为什么不确定
- ✅ 提供可能的选项

### 5. 保留原始文件

- ✅ 移动到 processed/ 而不是删除
- ✅ 按日期归档
- ✅ 记录处理日志

---

## 成功标准

- ✅ 成功提取原始资料中的所有关键信息
- ✅ 生成的文件符合模板格式要求
- ✅ SQL 使用 Trino 语法（如适用）
- ✅ 内容准确、完整、易懂
- ✅ 原始文件已归档
- ✅ 处理日志已记录

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建原始知识处理技能文档 |
