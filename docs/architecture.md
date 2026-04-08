# 雪球 ChatBI 系统架构设计

## 一、系统目标

**核心目标**: 使用者提交数据统计需求 → AI 自动生成完全准确、符合需求的 SQL

## 二、核心挑战分析

基于人类数据分析师的工作流程，AI 需要具备以下能力：

1. **需求理解能力**: 理解业务方的自然语言需求（包含公司黑话、业务术语）
2. **需求澄清能力**: 识别模糊需求，主动提问澄清歧义
3. **业务知识**: 掌握公司业务概念、指标口径、计算规则
4. **数据资产知识**: 了解数据库表结构、字段含义、表关联关系
5. **SQL 生成能力**: 根据需求和知识库生成准确的 SQL
6. **验证能力**: 对生成的 SQL 进行合理性检查

## 三、系统架构设计

### 3.1 知识体系（Knowledge Base）

这是整个系统的核心基础设施，分为以下几个模块：

#### 📚 业务知识库 (`knowledge/business/`)

**作用**: 让 AI 理解雪球的业务

```
knowledge/business/
├── glossary.md              # 业务术语表（含黑话翻译）
├── metrics/                 # 指标定义
│   ├── user_metrics.md      # 用户相关指标
│   ├── content_metrics.md   # 内容相关指标
│   ├── trade_metrics.md     # 交易相关指标
│   └── financial_metrics.md # 财务相关指标
├── dimensions/              # 维度定义
│   ├── time_dimensions.md   # 时间维度（日、周、月等）
│   └── user_dimensions.md   # 用户维度（新老用户、用户分层等）
└── calculation_rules/       # 计算规则
    ├── dau_mau.md          # DAU/MAU 计算规则
    ├── retention.md        # 留存率计算规则
    └── conversion.md       # 转化率计算规则
```

**内容示例**:
- 业务术语: "活跃用户" = 当日有任意行为的用户
- 指标口径: DAU 的具体定义、去重规则、统计时间范围
- 计算公式: 次日留存率 = D1留存用户数 / D0新增用户数

#### 🗄️ 数据资产知识库 (`knowledge/data_assets/`)

**作用**: 让 AI 了解数据库表结构和使用方法

```
knowledge/data_assets/
├── tables/                  # 表结构文档
│   ├── user_tables.md       # 用户相关表
│   ├── content_tables.md    # 内容相关表
│   ├── trade_tables.md      # 交易相关表
│   └── dws_tables.md        # 数据仓库汇总表
├── relationships.md         # 表关联关系图
├── data_quality.md          # 数据质量说明
└── best_practices.md        # SQL 编写最佳实践
```

**内容示例**:
- 表结构: 字段名、类型、含义、示例值
- 关联关系: 主外键关系、常用 JOIN 方式
- 使用建议: 哪些表适合什么场景、性能注意事项

#### 📖 SQL 案例库 (`knowledge/sql_examples/`)

**作用**: 提供参考案例，让 AI 学习如何编写 SQL

```
knowledge/sql_examples/
├── user_analysis/           # 用户分析类 SQL
│   ├── dau_trend.md        # DAU 趋势分析
│   ├── retention.md        # 留存分析
│   └── user_profile.md     # 用户画像
├── content_analysis/        # 内容分析类 SQL
├── trade_analysis/          # 交易分析类 SQL
└── complex_queries/         # 复杂查询案例
    ├── cohort_analysis.md  # 同期群分析
    └── funnel_analysis.md  # 漏斗分析
```

**案例格式**:
```markdown
## 需求描述
查询最近 7 天的 DAU 趋势

## 需求澄清
- 时间范围: 最近 7 天（含今天）
- 活跃定义: 有任意行为记录
- 去重维度: user_id

## SQL 语句
[SQL 代码]

## 说明
- 使用了 dws_user_daily 汇总表，性能更好
- 注意时区处理
```

#### 🔧 技能规则库 (`skills/`)

**作用**: 定义 AI 的工作流程和行为规范

```
skills/
├── requirement_clarification.md  # 需求澄清技能
├── sql_generation.md            # SQL 生成技能
├── sql_validation.md            # SQL 验证技能
└── error_handling.md            # 错误处理技能
```

### 3.2 工作流引擎（Workflow Engine）

定义 AI 处理需求的标准流程：

```
用户需求输入
    ↓
[1] 需求解析 (Requirement Parsing)
    - 提取关键信息：指标、维度、筛选条件、时间范围
    - 识别业务术语
    ↓
[2] 需求澄清 (Requirement Clarification)
    - 检查模糊点
    - 生成澄清问题列表
    - 与用户交互确认
    ↓
[3] 知识检索 (Knowledge Retrieval)
    - 查询业务知识库：指标定义、计算规则
    - 查询数据资产库：相关表、字段
    - 查询案例库：相似需求的 SQL
    ↓
[4] SQL 生成 (SQL Generation)
    - 选择数据表
    - 构建查询逻辑
    - 生成 SQL 语句
    ↓
[5] SQL 验证 (SQL Validation)
    - 语法检查
    - 逻辑检查（是否符合需求）
    - 性能检查（是否有优化空间）
    ↓
[6] 结果输出 (Output)
    - SQL 语句
    - 执行说明
    - 注意事项
```

### 3.3 Agent 能力模块

#### Agent 1: 需求澄清 Agent
- **职责**: 识别需求中的模糊点，生成澄清问题
- **输入**: 用户原始需求
- **输出**: 澄清问题列表 + 已确认的需求要素

#### Agent 2: 知识检索 Agent
- **职责**: 从知识库中检索相关信息
- **输入**: 澄清后的需求
- **输出**: 相关的业务定义、表结构、SQL 案例

#### Agent 3: SQL 生成 Agent
- **职责**: 生成 SQL 语句
- **输入**: 需求 + 检索到的知识
- **输出**: SQL 语句 + 生成说明

#### Agent 4: SQL 验证 Agent
- **职责**: 验证 SQL 的正确性
- **输入**: SQL 语句 + 原始需求
- **输出**: 验证结果 + 修改建议

### 3.4 自我进化机制

#### 反馈循环
```
knowledge/feedback/
├── sql_corrections.md       # SQL 纠错记录
├── new_requirements.md      # 新需求类型
└── knowledge_gaps.md        # 知识缺口
```

每次交互后记录：
- 生成的 SQL 是否准确
- 用户的修改意见
- 新出现的业务概念
- 知识库的缺失项

#### 知识库更新流程
1. 收集反馈
2. 人工审核
3. 更新知识库文档
4. 版本控制

## 四、实施路线图

### 阶段 1: 基础设施搭建（Foundation）

**目标**: 建立知识库框架和基础文档

**任务清单**:
1. 创建目录结构
2. 编写知识库模板
3. 梳理核心业务术语（Top 50）
4. 梳理核心数据表（Top 20）
5. 收集典型 SQL 案例（Top 30）

**交付物**:
- 完整的目录结构
- 知识库文档模板
- 初始版本的业务术语表
- 初始版本的数据表文档
- 初始版本的 SQL 案例库

### 阶段 2: 核心能力开发（Core Capabilities）

**目标**: 实现基本的需求理解和 SQL 生成能力

**任务清单**:
1. 开发需求解析模块
2. 开发知识检索模块
3. 开发 SQL 生成模块
4. 开发基础验证模块
5. 编写核心 Skills 文档

**交付物**:
- 需求解析 Skill
- SQL 生成 Skill
- 可运行的端到端流程

### 阶段 3: 知识库丰富（Knowledge Enrichment）

**目标**: 补充完整的业务知识和数据资产信息

**任务清单**:
1. 补充全量业务术语
2. 补充全量数据表文档
3. 补充各业务线的指标定义
4. 补充计算规则文档
5. 补充更多 SQL 案例

**交付物**:
- 完整的业务知识库
- 完整的数据资产文档
- 丰富的 SQL 案例库（100+ 案例）

### 阶段 4: 智能化增强（Intelligence Enhancement）

**目标**: 提升 AI 的理解和生成能力

**任务清单**:
1. 开发智能需求澄清能力
2. 开发 SQL 优化建议能力
3. 开发多轮对话能力
4. 开发相似案例推荐能力
5. 建立反馈收集机制

**交付物**:
- 智能澄清 Agent
- SQL 优化 Agent
- 反馈收集系统

### 阶段 5: 自我进化（Self-Evolution）

**目标**: 建立持续学习和优化机制

**任务清单**:
1. 建立反馈数据收集流程
2. 开发知识库自动更新机制
3. 建立版本管理机制
4. 开发效果评估体系
5. 建立人工审核流程

**交付物**:
- 反馈收集系统
- 知识库更新流程
- 效果评估报告

## 五、关键成功要素

### 5.1 知识库质量

**业务知识库**:
- ✅ 术语定义清晰、无歧义
- ✅ 指标口径明确、有计算公式
- ✅ 覆盖所有常用业务概念
- ✅ 定期更新维护

**数据资产知识库**:
- ✅ 表结构文档完整
- ✅ 字段含义清晰
- ✅ 表关联关系明确
- ✅ 包含使用建议和注意事项

**SQL 案例库**:
- ✅ 案例覆盖常见需求类型
- ✅ 每个案例有完整的需求描述
- ✅ SQL 代码有详细注释
- ✅ 包含最佳实践说明

### 5.2 Prompt 工程

**需求解析 Prompt**:
- 提取关键要素（指标、维度、筛选、时间）
- 识别业务术语
- 标记不确定项

**需求澄清 Prompt**:
- 基于模板生成澄清问题
- 避免过度提问
- 优先澄清关键歧义

**SQL 生成 Prompt**:
- 严格遵循知识库定义
- 参考相似案例
- 遵循最佳实践
- 添加必要注释

### 5.3 验证机制

**多层验证**:
1. 语法验证: SQL 语法是否正确
2. 逻辑验证: 是否符合需求
3. 口径验证: 是否符合业务定义
4. 性能验证: 是否有性能问题

### 5.4 反馈闭环

**收集维度**:
- SQL 准确性（是否一次通过）
- 需求理解准确性
- 澄清问题的有效性
- 用户满意度

**改进机制**:
- 错误案例归档
- 知识库补充
- Prompt 优化
- 流程改进

## 六、技术实现方案

### 6.1 目录结构

```
/workspace/
├── docs/                           # 文档
│   ├── architecture.md             # 本文档
│   ├── workflow.md                 # 工作流程说明
│   └── deployment.md               # 部署指南
│
├── knowledge/                      # 知识库（核心）
│   ├── business/                   # 业务知识
│   │   ├── glossary.md            # 术语表
│   │   ├── metrics/               # 指标定义
│   │   ├── dimensions/            # 维度定义
│   │   └── calculation_rules/     # 计算规则
│   │
│   ├── data_assets/               # 数据资产
│   │   ├── tables/                # 表文档
│   │   │   ├── ods/              # ODS 层
│   │   │   ├── dwd/              # DWD 层
│   │   │   ├── dws/              # DWS 层
│   │   │   └── ads/              # ADS 层
│   │   ├── relationships.md       # 表关联关系
│   │   ├── data_quality.md        # 数据质量说明
│   │   └── best_practices.md      # SQL 最佳实践
│   │
│   └── sql_examples/              # SQL 案例库
│       ├── user_analysis/         # 用户分析
│       ├── content_analysis/      # 内容分析
│       ├── trade_analysis/        # 交易分析
│       └── complex_queries/       # 复杂查询
│
├── skills/                         # AI 技能定义
│   ├── 01_requirement_parsing.md      # 需求解析
│   ├── 02_requirement_clarification.md # 需求澄清
│   ├── 03_knowledge_retrieval.md      # 知识检索
│   ├── 04_sql_generation.md           # SQL 生成
│   ├── 05_sql_validation.md           # SQL 验证
│   └── 06_result_explanation.md       # 结果解释
│
├── prompts/                        # Prompt 模板
│   ├── system_prompt.md           # 系统 Prompt
│   ├── clarification_prompts.md   # 澄清问题模板
│   └── generation_prompts.md      # SQL 生成模板
│
├── feedback/                       # 反馈数据
│   ├── corrections/               # 纠错记录
│   ├── new_cases/                 # 新案例
│   └── knowledge_gaps/            # 知识缺口
│
├── tests/                          # 测试用例
│   ├── test_cases.md              # 测试需求集
│   └── expected_sqls.md           # 期望的 SQL
│
└── scripts/                        # 辅助脚本
    ├── knowledge_validator.py     # 知识库验证
    └── sql_formatter.py           # SQL 格式化
```

### 6.2 知识库文档规范

#### 业务术语文档模板

```markdown
# 业务术语: [术语名称]

## 标准定义
[官方定义]

## 别名/黑话
- 别名1
- 别名2

## 业务含义
[详细解释]

## 数据口径
- 统计对象: 
- 统计范围:
- 去重规则:
- 时间范围:

## 相关指标
- 指标1
- 指标2

## 常见误区
[容易混淆的点]
```

#### 数据表文档模板

```markdown
# 表名: [table_name]

## 基本信息
- 表类型: ODS/DWD/DWS/ADS
- 更新频率: 实时/小时/天
- 数据范围: [起始时间 - 结束时间]
- 分区字段: [字段名]

## 表说明
[表的业务含义和用途]

## 字段列表

| 字段名 | 类型 | 说明 | 示例值 | 备注 |
|--------|------|------|--------|------|
| user_id | bigint | 用户ID | 123456 | 主键 |
| ... | ... | ... | ... | ... |

## 常用场景
1. 场景1: [说明]
2. 场景2: [说明]

## 关联表
- 与 table_x 通过 field_y 关联
- 与 table_z 通过 field_w 关联

## 注意事项
- 注意事项1
- 注意事项2

## 示例 SQL
[常用查询示例]
```

#### SQL 案例文档模板

```markdown
# 案例: [案例名称]

## 业务需求（原始）
[业务方的原始需求描述]

## 需求澄清

### 关键要素
- **指标**: [指标名称及定义]
- **维度**: [维度名称]
- **筛选条件**: [条件说明]
- **时间范围**: [时间说明]

### 澄清的问题
1. Q: [问题]
   A: [答案]
2. Q: [问题]
   A: [答案]

## 技术方案

### 数据表选择
- 主表: [表名] - [选择理由]
- 关联表: [表名] - [关联方式]

### 计算逻辑
[逻辑说明]

## SQL 语句

```sql
-- [SQL 说明]
SELECT 
    -- 维度字段
    date,
    user_type,
    
    -- 指标字段
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date >= '2024-01-01'
    AND date <= '2024-01-07'
GROUP BY 
    date,
    user_type
ORDER BY 
    date;
```

## 执行说明
- 预计扫描数据量: [说明]
- 预计执行时间: [说明]
- 注意事项: [说明]

## 变体需求
如果需求变化为 [变化描述]，SQL 调整为：
[调整说明]
```

### 6.3 Skills 文档规范

每个 Skill 文档定义 AI 在特定环节的行为：

```markdown
# Skill: [技能名称]

## 目标
[这个技能要达成什么目标]

## 触发条件
[什么时候使用这个技能]

## 输入
[需要什么输入信息]

## 处理步骤
1. 步骤1: [详细说明]
2. 步骤2: [详细说明]
3. ...

## 输出
[输出什么信息，格式是什么]

## 示例
[具体示例]

## 注意事项
[需要特别注意的点]
```

## 七、使用流程示例

### 示例 1: 简单需求

**用户输入**:
```
查询昨天的 DAU
```

**AI 处理流程**:

1. **需求解析**:
   - 指标: DAU
   - 时间: 昨天
   - 维度: 无
   - 筛选: 无

2. **需求澄清**:
   - 检查 glossary.md: DAU 定义明确
   - 检查 metrics/user_metrics.md: 计算规则明确
   - ✅ 无需澄清

3. **知识检索**:
   - 从 data_assets/tables/dws/dws_user_daily.md 找到合适的表
   - 从 sql_examples/user_analysis/dau_trend.md 找到参考案例

4. **SQL 生成**:
```sql
SELECT 
    COUNT(DISTINCT user_id) as dau
FROM 
    dws_user_daily
WHERE 
    date = DATE_SUB(CURRENT_DATE(), 1);
```

5. **SQL 验证**:
   - ✅ 语法正确
   - ✅ 符合 DAU 定义
   - ✅ 使用了汇总表，性能良好

6. **输出**:
   - SQL 语句
   - 说明: 使用 dws_user_daily 汇总表，已按用户 ID 去重

### 示例 2: 复杂需求

**用户输入**:
```
帮我看下最近一个月新用户的次留情况，按渠道分
```

**AI 处理流程**:

1. **需求解析**:
   - 指标: 次日留存率
   - 时间: 最近一个月
   - 维度: 渠道
   - 对象: 新用户

2. **需求澄清**:
   - ❓ "最近一个月" 是指过去 30 天还是本自然月？
   - ❓ "新用户" 是指注册时间在这个月的用户？
   - ❓ "次留" 是指次日留存率？
   - ❓ "按渠道分" 是指注册渠道还是活跃渠道？

3. **用户确认**:
   - 过去 30 天
   - 注册时间在这 30 天内的用户
   - 次日留存率
   - 注册渠道

4. **知识检索**:
   - 从 calculation_rules/retention.md 获取留存率计算规则
   - 从 tables/dwd/dwd_user_register.md 获取注册表信息
   - 从 tables/dwd/dwd_user_active.md 获取活跃表信息
   - 从 sql_examples/complex_queries/cohort_analysis.md 获取参考案例

5. **SQL 生成**:
```sql
-- 计算最近 30 天新用户的次日留存率，按注册渠道分组
WITH new_users AS (
    -- 获取最近 30 天的新注册用户
    SELECT 
        user_id,
        register_date,
        register_channel
    FROM 
        dwd_user_register
    WHERE 
        register_date >= DATE_SUB(CURRENT_DATE(), 30)
        AND register_date < CURRENT_DATE()
),
retention_users AS (
    -- 获取次日活跃用户
    SELECT 
        nu.user_id,
        nu.register_date,
        nu.register_channel
    FROM 
        new_users nu
    INNER JOIN 
        dwd_user_active ua
    ON 
        nu.user_id = ua.user_id
        AND ua.active_date = DATE_ADD(nu.register_date, 1)
)
SELECT 
    register_date,
    register_channel,
    COUNT(DISTINCT nu.user_id) as new_users_count,
    COUNT(DISTINCT ru.user_id) as retention_users_count,
    ROUND(COUNT(DISTINCT ru.user_id) * 100.0 / COUNT(DISTINCT nu.user_id), 2) as retention_rate
FROM 
    new_users nu
LEFT JOIN 
    retention_users ru
ON 
    nu.user_id = ru.user_id
    AND nu.register_date = ru.register_date
    AND nu.register_channel = ru.register_channel
GROUP BY 
    register_date,
    register_channel
ORDER BY 
    register_date,
    register_channel;
```

6. **SQL 验证**:
   - ✅ 符合留存率计算规则
   - ✅ 正确使用了 LEFT JOIN（避免遗漏未留存用户）
   - ✅ 时间范围处理正确
   - ✅ 去重逻辑正确

7. **输出**:
   - SQL 语句
   - 说明: 
     - 使用 CTE 提高可读性
     - 次日留存率 = 次日活跃用户数 / 新增用户数
     - 按注册日期和渠道分组
     - 结果包含: 日期、渠道、新增数、留存数、留存率

## 八、配合事项

### 你需要提供的信息

#### 1. 业务知识（优先级：高）
- [ ] 雪球的核心业务术语表（含黑话）
- [ ] 常用指标定义文档（DAU、MAU、留存率等）
- [ ] 指标计算规则文档
- [ ] 业务场景说明

**建议方式**: 
- 提供现有的数据字典文档
- 提供指标管理平台的导出数据
- 组织业务专家访谈，整理术语表

#### 2. 数据资产信息（优先级：高）
- [ ] 数据库表结构（DDL 或数据字典）
- [ ] 表和字段的业务含义说明
- [ ] 表之间的关联关系
- [ ] 数据更新频率和时效性

**建议方式**:
- 导出数据库元数据
- 提供现有的表结构文档
- 提供 ER 图或数据模型文档

#### 3. 历史 SQL 案例（优先级：高）
- [ ] 过去人工编写的 SQL 及对应需求
- [ ] 典型查询场景的 SQL
- [ ] 复杂查询的 SQL（含注释）

**建议方式**:
- 从工单系统导出历史需求和 SQL
- 整理常用查询的 SQL 模板
- 收集数据分析师的 SQL 代码库

#### 4. 反馈机制（优先级：中）
- [ ] SQL 准确性反馈渠道
- [ ] 需求理解偏差反馈
- [ ] 新业务概念补充流程

#### 5. 测试用例（优先级：中）
- [ ] 典型需求场景（20-30 个）
- [ ] 边界情况测试
- [ ] 复杂需求测试

### 协作方式建议

#### 方式 1: 迭代式构建（推荐）
1. **第一轮**: 我先创建完整的目录结构和模板
2. **第二轮**: 你提供 5-10 个核心术语和表，我填充示例
3. **第三轮**: 你提供 3-5 个真实需求，我们测试端到端流程
4. **后续**: 逐步补充知识库，持续优化

#### 方式 2: 批量导入
1. 你准备好所有文档和数据
2. 我一次性构建完整知识库
3. 进行全面测试和调优

#### 方式 3: 混合模式
1. 先搭建框架和核心知识
2. 小范围试点（如只支持用户分析类需求）
3. 验证效果后再扩展到其他业务线

## 九、成功标准

### 定量指标
- **SQL 一次通过率**: ≥ 85%（生成的 SQL 无需修改即可使用）
- **需求理解准确率**: ≥ 90%（正确理解业务需求）
- **响应时间**: ≤ 30 秒（从需求到 SQL）
- **知识库覆盖率**: ≥ 95%（覆盖常见需求场景）

### 定性指标
- AI 能够识别并澄清模糊需求
- 生成的 SQL 符合公司最佳实践
- 能够处理复杂的多表关联查询
- 能够给出清晰的 SQL 说明

## 十、风险和应对

### 风险 1: 知识库不完整
**影响**: SQL 生成不准确
**应对**: 
- 建立快速补充机制
- 优先补充高频需求相关知识
- 建立知识缺口追踪

### 风险 2: 业务变化快
**影响**: 知识库过时
**应对**:
- 建立定期更新机制
- 版本管理
- 变更通知流程

### 风险 3: 需求理解偏差
**影响**: 生成错误的 SQL
**应对**:
- 强化需求澄清环节
- 增加验证步骤
- 收集反馈持续优化

### 风险 4: 性能问题
**影响**: SQL 执行慢
**应对**:
- 在知识库中明确性能最佳实践
- 增加 SQL 性能检查
- 提供优化建议

## 十一、下一步行动

我建议我们从**阶段 1: 基础设施搭建**开始。我可以立即为你做以下事情：

### 立即可以做的:
1. ✅ 创建完整的目录结构
2. ✅ 创建所有文档模板
3. ✅ 编写核心 Skills 文档
4. ✅ 创建示例知识库（用假设数据演示）
5. ✅ 创建测试框架

### 需要你配合的:
1. 提供真实的业务术语表（哪怕是初版）
2. 提供核心数据表的结构信息
3. 提供 3-5 个真实的历史需求案例
4. 确认数据库类型（MySQL/PostgreSQL/Hive/ClickHouse 等）

---

**现在我可以立即开始创建整个框架体系，你觉得如何？**

或者你也可以先提供一些真实的业务信息，我可以直接填充到知识库中，这样更贴合实际。
