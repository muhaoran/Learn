# Skill: 原始知识处理

---

## 目标

将用户提供的原始知识资料（Excel、Word、SQL 等）转换为结构化的知识库内容。

---

## 触发条件

用户将原始资料放到 `raw_knowledge/` 文件夹，并请求处理。

**触发指令示例**:
- "请处理 raw_knowledge/mixed/数据需求.docx"
- "我放了新的原始资料，请帮我处理"
- "处理 raw_knowledge/mixed/ 下的所有文件"

---

## 输入

- 原始知识资料文件（Excel、Word、SQL、Markdown、txt 等任意文本格式）
- 文件位置：`raw_knowledge/mixed/`（唯一的输入目录，不区分类型）

---

## 处理步骤

### 步骤 1: 智能识别文件和内容

**任务**: 读取和分析原始资料，智能识别内容类型

**核心原则**：**完全不依赖用户标注，AI 自主判断** ✅

**必须做**:
1. **读取文件内容**
   - 支持任何文本格式（docx, xlsx, txt, md, pdf, sql 等）
   - 提取所有文本内容

2. **智能分析内容**（不需要用户告诉我们是什么）
   - 逐句、逐段分析
   - 使用 AI 的语义理解能力判断每部分内容
   - 识别关键特征：
     - 术语特征：定义性描述（"XX 是..."、"XX 指..."）
     - 表结构特征：字段列表、类型说明、表名
     - SQL 特征：SELECT、FROM、WHERE 等关键字
     - 指标特征：计算公式、统计逻辑
     - 业务规则特征：条件判断、规则说明

3. **分类和标记**
   - 为每句话、每段落标注可能的类型
   - 可能的类型包括：
     - 业务术语定义
     - 指标说明
     - 数据表结构
     - 字段定义
     - SQL 查询
     - 业务规则
     - 计算逻辑
     - 使用场景
     - 背景说明
     - 其他/不确定

4. **评估质量和置信度**
   - 对每个识别结果给出置信度（高/中/低）
   - 标注不确定的部分
   - 记录可能的歧义

**特别注意**:
- ✅ **完全不依赖用户标注** - 用户不需要告诉我们哪些是术语、哪些是表
- ✅ **内容可以混杂** - 一句话里可能包含多个信息
- ✅ **无结构也能处理** - 即使是纯文本、会议记录、聊天记录都可以
- ✅ **智能补全** - SQL 片段可以补全，表名可以推测
- ✅ **标注不确定** - 对于不确定的识别结果，明确标注并请求用户确认

**识别示例**:

**输入文本**: "DAU 是日活，user_behavior 表有 user_id 字段，查询用 SELECT COUNT(DISTINCT user_id)"

**AI 分析**:
```
1. "DAU 是日活" 
   → 识别为：术语定义（置信度：高）
   → 提取：术语名=DAU，定义=日活跃用户数

2. "user_behavior 表有 user_id 字段"
   → 识别为：表结构信息（置信度：高）
   → 提取：表名=user_behavior，字段=user_id

3. "查询用 SELECT COUNT(DISTINCT user_id)"
   → 识别为：SQL 片段（置信度：中，不完整）
   → 提取：需要补全为完整 SQL
```

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

### 步骤 3: 确定写入目标

**任务**: 根据识别出的内容类型，确定应该写入新四层架构的哪个位置

**映射关系**:

| 识别出的内容类型 | 写入目标 | 参考模板 |
|----------------|---------|---------|
| 表名、字段、类型、分区、枚举值 | `knowledge/schema/tables/{表名}.yaml` | `knowledge/schema/TEMPLATE.yaml` |
| 业务对象定义（用户/帖子/订单） | `knowledge/semantics/entities/{实体id}.yaml` | `knowledge/semantics/entities/TEMPLATE.yaml` |
| 业务动作定义（注册/活跃/发帖） | `knowledge/semantics/events/{事件id}.yaml` | `knowledge/semantics/events/TEMPLATE.yaml` |
| 简单属性维度（渠道/平台等字段） | `knowledge/semantics/dimensions/{维度id}.yaml` | `knowledge/semantics/dimensions/TEMPLATE.yaml` |
| 命名标签/分群定义（活跃用户/新用户等） | `knowledge/semantics/dimensions/*.yaml` 中的 `named_values` | 同上 |
| 可复用计算逻辑（留存、去重计数等） | `knowledge/patterns/{模式id}.yaml` | `knowledge/patterns/TEMPLATE.yaml` |
| 有名字的具体指标口径（DAU、次日留存率等） | `knowledge/metrics/{指标id}.yaml` | `knowledge/metrics/TEMPLATE.yaml` |

**关键判断原则**:
- 同一份原始资料通常包含多种类型内容，应分别写入多个文件
- 有独立业务名称且口径需固化的指标 → 写 `metrics/`，否则由 AI 即时推导
- 能用字段直接表达的维度 → `sql_expr` 字段；需要 SQL 计算的 → `named_values`

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

4. **转换 SQL 语法**（如果涉及 SQL 片段）
   - **必须将 SQL 转换为 Trino 语法**
   - 不能保留 MySQL/Hive 等其他语法
   - 参考 `knowledge/schema/trino_syntax.md`
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
   - 指标定义 → `knowledge/metrics/`
   - 实体/事件/维度定义 → `knowledge/semantics/`
   - 表结构 → `knowledge/schema/tables/`
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
1. `knowledge/semantics/entities/user.yaml` - 更新实体定义（如有新信息）
2. `knowledge/semantics/events/*.yaml` - 新增/更新事件定义
3. `knowledge/semantics/dimensions/*.yaml` - 新增/更新维度和命名标签
4. `knowledge/metrics/*.yaml` - 新增有独立名称的指标（如有）

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
✅ 自动识别到 3 类知识：
1. **业务语义定义**: 在第 1-2 章
   - DAU、MAU 是有名字的指标；活跃用户、新用户是命名标签；注册渠道是维度
2. **数据表结构**: 在第 3 章
   - 用户行为表、用户注册表、用户日度汇总表
3. **计算逻辑**: 在第 4 章
   - 留存率的计算公式（同期群模式）

### 写入位置（按新四层架构）

**业务语义层**:
1. `knowledge/semantics/events/registration.yaml` - 注册事件（更新或确认）
2. `knowledge/semantics/events/active_behavior.yaml` - 活跃行为事件（更新或确认）
3. `knowledge/semantics/dimensions/user_register_channel.yaml` - 注册渠道维度
4. `knowledge/semantics/dimensions/user_computed_tags.yaml` - 更新 active_user、new_user 命名标签

**数据字典层**:
5. `knowledge/schema/tables/dwd_user_behavior.yaml` - 用户行为表（更新或创建）
6. `knowledge/schema/tables/dwd_user_register.yaml` - 用户注册表（更新或创建）
7. `knowledge/schema/tables/dws_user_daily.yaml` - 用户日度汇总表（更新或创建）

**指标目录层**:
8. `knowledge/metrics/dau.yaml` - DAU 指标（如不存在则创建）
9. `knowledge/metrics/d1_retention_rate.yaml` - 次日留存率指标（如不存在则创建）

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

第 1 章: 业务背景（术语定义）
  → 识别实体/事件/维度/指标 → knowledge/semantics/ 和 knowledge/metrics/

第 2 章: 数据表说明
  → 提取表结构 → knowledge/schema/tables/

第 3 章: 查询需求（SQL 片段）
  → 确认 Pattern 和语义定义，不新建 SQL 文件
  → 如有新表结构信息 → 更新 knowledge/schema/tables/

结果: 从 1 个原始文件更新多个知识库 YAML 文件
```

---

## 示例

### 示例 1: 处理术语表 Excel

**输入**: `raw_knowledge/business/业务术语表.xlsx`

**内容**:
| 术语 | 英文 | 定义 | 业务场景 |
|------|------|------|----------|
| DAU | Daily Active Users | 日活跃用户数 | 用户增长分析 |
| 次留 | D1 Retention | 次日留存率 | 用户留存分析 |

**处理过程**:

```markdown
1. ✅ 识别类型: 两个有名字的指标（DAU、次留）+ 关联的事件/计算逻辑
2. ✅ 质量评估: 良好（结构清晰，有定义）
3. ✅ 判断写入位置:
   - DAU → knowledge/metrics/dau.yaml（指标层）
   - 次留 → knowledge/metrics/d1_retention_rate.yaml（指标层）
   - 活跃行为事件 → knowledge/semantics/events/active_behavior.yaml（语义层）
4. ✅ 写入文件（新建或更新）
5. ✅ 归档: raw_knowledge/processed/2024-01/业务术语表.xlsx
```

**输出**: 在 `knowledge/metrics/` 新增或更新 2 个指标文件

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
1. ✅ 识别类型: 涉及 DAU 指标 + active_behavior 事件 + dwd_user_behavior 表
2. ✅ 质量评估: 良好（语义清晰，语法需转换）
3. ✅ 判断写入位置:
   - 表名需确认: user_behavior → dwd_user_behavior?（标注待确认）
   - active_behavior 事件已有定义，无需新建
   - DAU 指标已有定义，无需新建
   - SQL 中的计算逻辑（COUNT DISTINCT）对应 count_distinct Pattern，已有
4. ✅ 如果表名确认，更新 knowledge/schema/tables/dwd_user_behavior.yaml（如有新字段信息）
5. ✅ 注意：SQL 本身不作为独立文件保存（新架构下由 Pattern 组合生成），但 Trino 语法转换提示:
   - DATE_SUB(CURRENT_DATE(), 1) → date_add('day', -1, current_date)
6. ✅ 归档: raw_knowledge/processed/2024-01/计算DAU.sql
```

**输出**: 确认表结构信息，更新 schema/（如有新信息）

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
1. ✅ 识别类型: 数据字典（表结构信息）→ 写入 Schema 层
2. ✅ 质量评估: 优秀（字段完整，有分区说明）
3. ✅ 判断写入位置: knowledge/schema/tables/dwd_user_behavior.yaml
4. ✅ 按 TEMPLATE.yaml 格式组织:
   - 填写 columns 列表（字段名、类型、说明、is_partition）
   - 补充 notes（如：必须加 date 分区条件）
   - 填写 related_tables（如果原始资料有关联信息）
5. ✅ 生成文件: knowledge/schema/tables/dwd_user_behavior.yaml
6. ✅ 归档: raw_knowledge/processed/2024-01/用户行为表.xlsx
```

**输出**: 新建或更新 `knowledge/schema/tables/dwd_user_behavior.yaml`

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
- ✅ 参考 `knowledge/schema/trino_syntax.md`
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
