# ChatBI 目录结构说明

> 完整的目录结构和文件说明

---

## 📁 完整目录树

```
/workspace/
│
├── 📄 README.md                          # 项目简介和快速导航
├── 📄 GETTING_STARTED.md                 # 5分钟快速开始指南
├── 📄 INDEX.md                           # 完整文档索引
├── 📄 PROJECT_SUMMARY.md                 # 项目总结
├── 📄 DIRECTORY_STRUCTURE.md             # 本文档（目录结构说明）
├── 📄 .cursorrules                       # Cursor AI 规则配置
├── 📄 .gitignore                         # Git 忽略配置
│
├── 📁 docs/                              # 📚 文档目录
│   ├── 📄 system_overview.md            # 系统总览（一页纸）⭐
│   ├── 📄 architecture.md               # 系统架构设计（详细）⭐
│   ├── 📄 workflow.md                   # 工作流程详解
│   ├── 📄 implementation_guide.md       # 实施指南（路线图）⭐
│   ├── 📄 quick_start.md                # 快速开始指南
│   ├── 📄 example_walkthrough.md        # 完整示例演示 ⭐
│   ├── 📄 data_collection_checklist.md  # 数据收集清单 ⭐
│   ├── 📄 knowledge_contribution_guide.md # 知识库贡献指南
│   └── 📄 faq.md                        # 常见问题
│
├── 📁 knowledge/                         # 🧠 知识库（系统核心）⭐⭐⭐
│   │
│   ├── 📁 business/                     # 业务知识库
│   │   ├── 📄 glossary.md              # 业务术语表（50+术语）
│   │   │
│   │   ├── 📁 metrics/                 # 指标定义
│   │   │   ├── 📄 user_metrics.md     # 用户指标（DAU, MAU, 留存等）
│   │   │   ├── 📄 content_metrics.md  # 内容指标（发帖数, 互动数等）
│   │   │   └── 📄 trade_metrics.md    # 交易指标
│   │   │
│   │   ├── 📁 dimensions/              # 维度定义
│   │   │   ├── 📄 time_dimensions.md  # 时间维度（日周月、相对时间等）
│   │   │   └── 📄 user_dimensions.md  # 用户维度（新老用户、用户分层等）
│   │   │
│   │   └── 📁 calculation_rules/       # 计算规则
│   │       ├── 📄 retention.md        # 留存率计算规则（详细）
│   │       └── 📄 dau_mau.md         # DAU/MAU 计算规则
│   │
│   ├── 📁 data_assets/                 # 数据资产库
│   │   ├── 📁 tables/                  # 数据表文档
│   │   │   ├── 📄 TABLE_TEMPLATE.md   # 表文档模板
│   │   │   │
│   │   │   ├── 📁 ods/                # ODS 层（原始数据层）
│   │   │   │   └── [待补充]
│   │   │   │
│   │   │   ├── 📁 dwd/                # DWD 层（明细数据层）
│   │   │   │   ├── 📄 dwd_user_behavior.md   # 用户行为明细表（示例）
│   │   │   │   └── 📄 dwd_user_register.md   # 用户注册表（示例）
│   │   │   │
│   │   │   ├── 📁 dws/                # DWS 层（汇总数据层）
│   │   │   │   └── 📄 dws_user_daily.md     # 用户日度汇总表（示例）
│   │   │   │
│   │   │   └── 📁 ads/                # ADS 层（应用数据层）
│   │   │       └── [待补充]
│   │   │
│   │   ├── 📄 relationships.md        # 表关联关系图
│   │   └── 📄 best_practices.md       # SQL 编写最佳实践
│   │
│   └── 📁 sql_examples/               # SQL 案例库
│       ├── 📄 EXAMPLE_TEMPLATE.md     # SQL 案例模板
│       │
│       ├── 📁 user_analysis/          # 用户分析案例
│       │   ├── 📄 dau_trend.md       # DAU 趋势分析
│       │   ├── 📄 retention.md       # 次日留存率分析
│       │   └── 📄 new_user_analysis.md # 新增用户分析
│       │
│       ├── 📁 content_analysis/       # 内容分析案例
│       │   └── [待补充]
│       │
│       ├── 📁 trade_analysis/         # 交易分析案例
│       │   └── [待补充]
│       │
│       └── 📁 complex_queries/        # 复杂查询案例
│           └── [待补充]
│
├── 📁 skills/                          # 🎯 AI 技能定义 ⭐⭐
│   ├── 📄 01_requirement_parsing.md       # 需求解析技能
│   ├── 📄 02_requirement_clarification.md # 需求澄清技能
│   ├── 📄 03_knowledge_retrieval.md       # 知识检索技能
│   ├── 📄 04_sql_generation.md            # SQL 生成技能
│   ├── 📄 05_sql_validation.md            # SQL 验证技能
│   └── 📄 06_result_explanation.md        # 结果解释技能
│
├── 📁 prompts/                         # 💬 Prompt 模板
│   └── 📄 system_prompt.md            # 系统 Prompt（AI 的核心指令）
│
├── 📁 tests/                           # 🧪 测试
│   └── 📄 test_cases.md               # 测试用例集（基础/中等/复杂/边界）
│
├── 📁 feedback/                        # 📊 反馈收集系统
│   ├── 📄 README.md                   # 反馈系统说明
│   │
│   ├── 📁 corrections/                # SQL 纠错记录
│   │   └── 📄 CORRECTION_TEMPLATE.md # 纠错记录模板
│   │
│   ├── 📁 knowledge_gaps/             # 知识缺口记录
│   │   └── 📄 KNOWLEDGE_GAP_TEMPLATE.md # 知识缺口模板
│   │
│   ├── 📁 new_cases/                  # 新案例收集
│   │   └── [待补充]
│   │
│   └── 📁 improvements/               # 改进建议
│       └── [待补充]
│
└── 📁 scripts/                         # 🔧 辅助脚本（未来）
    └── [待开发]
```

---

## 📊 文件统计

### 已创建文件

| 类型 | 数量 | 说明 |
|------|------|------|
| 📄 核心文档 | 5 | README, GETTING_STARTED, INDEX, PROJECT_SUMMARY, DIRECTORY_STRUCTURE |
| 📄 系统文档 | 9 | docs/ 目录下的文档 |
| 📄 业务知识 | 8 | 术语、指标、维度、计算规则 |
| 📄 数据资产 | 6 | 表模板、示例表、关联关系、最佳实践 |
| 📄 SQL 案例 | 4 | 案例模板 + 3 个示例案例 |
| 📄 Skills | 6 | 6 个核心 Skill 定义 |
| 📄 配置文件 | 2 | .cursorrules, system_prompt.md |
| 📄 测试反馈 | 4 | 测试用例、反馈模板 |
| **总计** | **44** | **44 个文件** |

### 目录统计

| 一级目录 | 二级目录 | 三级目录 | 说明 |
|----------|----------|----------|------|
| docs/ | - | - | 9 个文档 |
| knowledge/ | business/ | metrics/, dimensions/, calculation_rules/ | 业务知识 |
| knowledge/ | data_assets/ | tables/ods/dwd/dws/ads/ | 数据资产 |
| knowledge/ | sql_examples/ | user_analysis/, content_analysis/, trade_analysis/, complex_queries/ | SQL 案例 |
| skills/ | - | - | 6 个 Skill |
| prompts/ | - | - | 1 个 Prompt |
| tests/ | - | - | 1 个测试文档 |
| feedback/ | corrections/, knowledge_gaps/, new_cases/, improvements/ | - | 反馈系统 |

---

## 📝 文件类型说明

### 📄 文档类文件 (.md)

**用途**: 提供说明、指南、规范

**分类**:
- **入口文档**: README, GETTING_STARTED, INDEX
- **设计文档**: architecture, workflow
- **指南文档**: implementation_guide, quick_start
- **知识文档**: glossary, metrics, tables
- **模板文档**: TABLE_TEMPLATE, EXAMPLE_TEMPLATE

### 📄 配置类文件

**用途**: 配置 AI 行为

**文件**:
- `.cursorrules`: Cursor AI 的规则
- `prompts/system_prompt.md`: AI 的系统 Prompt

### 📁 目录说明

| 目录 | 用途 | 重要性 |
|------|------|--------|
| `docs/` | 存放系统文档 | ⭐⭐ |
| `knowledge/` | 存放知识库（系统核心） | ⭐⭐⭐ |
| `skills/` | 定义 AI 技能 | ⭐⭐ |
| `prompts/` | Prompt 模板 | ⭐⭐ |
| `tests/` | 测试用例 | ⭐ |
| `feedback/` | 反馈收集 | ⭐ |
| `scripts/` | 辅助脚本（未来） | ⭐ |

---

## 🔍 如何找到文件

### 按用途查找

**我想了解系统**:
- 快速了解: `GETTING_STARTED.md`
- 深入了解: `docs/system_overview.md`
- 架构设计: `docs/architecture.md`

**我想使用系统**:
- 使用指南: `docs/quick_start.md`
- 使用示例: `docs/example_walkthrough.md`
- 常见问题: `docs/faq.md`

**我想实施系统**:
- 实施指南: `docs/implementation_guide.md`
- 数据收集: `docs/data_collection_checklist.md`

**我想查询知识**:
- 业务术语: `knowledge/business/glossary.md`
- 指标定义: `knowledge/business/metrics/`
- 数据表: `knowledge/data_assets/tables/`
- SQL 案例: `knowledge/sql_examples/`

**我想贡献内容**:
- 贡献指南: `docs/knowledge_contribution_guide.md`
- 各类模板: `knowledge/` 下的 TEMPLATE 文件

**我想了解技术实现**:
- AI 技能: `skills/`
- 系统 Prompt: `prompts/system_prompt.md`
- AI 规则: `.cursorrules`

### 按角色查找

**决策者/管理者**:
1. `docs/system_overview.md` - 了解价值
2. `docs/implementation_guide.md` - 了解投入
3. `PROJECT_SUMMARY.md` - 了解进展

**项目负责人**:
1. `docs/architecture.md` - 了解架构
2. `docs/implementation_guide.md` - 制定计划
3. `docs/data_collection_checklist.md` - 准备数据

**数据分析师（使用者）**:
1. `GETTING_STARTED.md` - 快速上手
2. `docs/example_walkthrough.md` - 学习示例
3. `docs/quick_start.md` - 使用指南

**数据开发（维护者）**:
1. `docs/knowledge_contribution_guide.md` - 如何贡献
2. `knowledge/` - 知识库内容
3. `feedback/` - 反馈记录

**技术开发**:
1. `docs/architecture.md` - 系统架构
2. `skills/` - AI 技能定义
3. `prompts/system_prompt.md` - 系统 Prompt

---

## 📋 文件清单（按目录）

### 根目录（5个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| README.md | ~100 | 项目简介 | ✅ 完成 |
| GETTING_STARTED.md | ~200 | 快速开始 | ✅ 完成 |
| INDEX.md | ~250 | 文档索引 | ✅ 完成 |
| PROJECT_SUMMARY.md | ~500 | 项目总结 | ✅ 完成 |
| DIRECTORY_STRUCTURE.md | ~300 | 本文档 | ✅ 完成 |

### docs/ 目录（9个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| system_overview.md | ~400 | 系统总览 | ✅ 完成 |
| architecture.md | ~800 | 架构设计 | ✅ 完成 |
| workflow.md | ~400 | 工作流程 | ✅ 完成 |
| implementation_guide.md | ~600 | 实施指南 | ✅ 完成 |
| quick_start.md | ~200 | 快速开始 | ✅ 完成 |
| example_walkthrough.md | ~700 | 示例演示 | ✅ 完成 |
| data_collection_checklist.md | ~400 | 数据收集 | ✅ 完成 |
| knowledge_contribution_guide.md | ~300 | 贡献指南 | ✅ 完成 |
| faq.md | ~400 | 常见问题 | ✅ 完成 |

### knowledge/business/ 目录（8个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| glossary.md | ~300 | 术语表（含示例） | ✅ 模板+示例 |
| metrics/user_metrics.md | ~300 | 用户指标 | ✅ 模板+示例 |
| metrics/content_metrics.md | ~150 | 内容指标 | ✅ 模板 |
| metrics/trade_metrics.md | ~100 | 交易指标 | ✅ 模板 |
| dimensions/time_dimensions.md | ~250 | 时间维度 | ✅ 完成 |
| dimensions/user_dimensions.md | ~150 | 用户维度 | ✅ 模板 |
| calculation_rules/retention.md | ~400 | 留存率规则 | ✅ 完成 |
| calculation_rules/dau_mau.md | ~300 | DAU/MAU 规则 | ✅ 完成 |

### knowledge/data_assets/ 目录（6个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| tables/TABLE_TEMPLATE.md | ~200 | 表文档模板 | ✅ 完成 |
| tables/dws/dws_user_daily.md | ~300 | 用户日度表（示例） | ✅ 示例 |
| tables/dwd/dwd_user_behavior.md | ~350 | 用户行为表（示例） | ✅ 示例 |
| tables/dwd/dwd_user_register.md | ~250 | 用户注册表（示例） | ✅ 示例 |
| relationships.md | ~400 | 表关联关系 | ✅ 完成 |
| best_practices.md | ~400 | SQL 最佳实践 | ✅ 完成 |

### knowledge/sql_examples/ 目录（4个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| EXAMPLE_TEMPLATE.md | ~200 | 案例模板 | ✅ 完成 |
| user_analysis/dau_trend.md | ~250 | DAU 趋势案例 | ✅ 完成 |
| user_analysis/retention.md | ~350 | 留存分析案例 | ✅ 完成 |
| user_analysis/new_user_analysis.md | ~300 | 新增分析案例 | ✅ 完成 |

### skills/ 目录（6个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| 01_requirement_parsing.md | ~400 | 需求解析 | ✅ 完成 |
| 02_requirement_clarification.md | ~350 | 需求澄清 | ✅ 完成 |
| 03_knowledge_retrieval.md | ~400 | 知识检索 | ✅ 完成 |
| 04_sql_generation.md | ~350 | SQL 生成 | ✅ 完成 |
| 05_sql_validation.md | ~450 | SQL 验证 | ✅ 完成 |
| 06_result_explanation.md | ~300 | 结果解释 | ✅ 完成 |

### prompts/ 目录（1个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| system_prompt.md | ~400 | 系统 Prompt | ✅ 完成 |

### tests/ 目录（1个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| test_cases.md | ~300 | 测试用例框架 | ✅ 完成 |

### feedback/ 目录（3个文件）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| README.md | ~200 | 反馈系统说明 | ✅ 完成 |
| corrections/CORRECTION_TEMPLATE.md | ~150 | 纠错模板 | ✅ 完成 |
| knowledge_gaps/KNOWLEDGE_GAP_TEMPLATE.md | ~150 | 知识缺口模板 | ✅ 完成 |

### 配置文件（2个）

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| .cursorrules | ~200 | Cursor AI 规则 | ✅ 完成 |
| .gitignore | ~10 | Git 忽略配置 | ✅ 已存在 |

---

## 📈 完成度统计

### 总体完成度

- ✅ **系统设计**: 100% 完成
- ✅ **文档体系**: 100% 完成
- ✅ **知识库框架**: 100% 完成
- ⏳ **知识库内容**: 30% 完成（有模板和示例，待填充真实数据）
- ✅ **Skills 定义**: 100% 完成
- ✅ **测试框架**: 100% 完成
- ✅ **反馈机制**: 100% 完成

### 知识库完成度

| 类型 | 模板 | 示例 | 真实数据 | 完成度 |
|------|------|------|----------|--------|
| 业务术语 | ✅ | ✅ (10个) | ⏳ | 30% |
| 指标定义 | ✅ | ✅ (10个) | ⏳ | 30% |
| 数据表 | ✅ | ✅ (3张) | ⏳ | 20% |
| SQL 案例 | ✅ | ✅ (3个) | ⏳ | 10% |
| 计算规则 | ✅ | ✅ (2个) | ⏳ | 40% |

---

## 🎯 下一步工作

### 待完成的工作

#### 高优先级

1. **填充知识库**
   - [ ] 补充真实的业务术语（50+）
   - [ ] 补充真实的指标定义（30+）
   - [ ] 补充真实的数据表（20+）
   - [ ] 补充真实的 SQL 案例（30+）

2. **测试验证**
   - [ ] 使用测试用例测试
   - [ ] 使用真实需求测试
   - [ ] 评估准确率

3. **优化调整**
   - [ ] 根据测试结果优化
   - [ ] 补充缺失的知识
   - [ ] 修复发现的问题

#### 中优先级

4. **扩展知识库**
   - [ ] 补充更多术语（100+）
   - [ ] 补充更多指标（50+）
   - [ ] 补充更多表（50+）
   - [ ] 补充更多案例（100+）

5. **功能增强**
   - [ ] 优化澄清策略
   - [ ] 增加 SQL 优化建议
   - [ ] 支持更复杂的需求

#### 低优先级

6. **工具开发**
   - [ ] 知识库验证脚本
   - [ ] SQL 格式化工具
   - [ ] 自动化测试脚本

---

## 📌 重要说明

### 当前状态

**✅ 已完成**:
- 完整的系统架构设计
- 完整的知识库框架（目录、模板、示例）
- 完整的 AI 技能定义
- 完整的文档体系
- 完整的测试和反馈框架

**⏳ 待完成**:
- 填充真实的业务数据
- 测试验证
- 优化调整

### 可以开始使用了吗？

**可以！** 但需要先：
1. 填充知识库（至少最小数据集）
2. 配置数据库信息
3. 简单测试验证

**最快路径**:
1. 提供 5 个术语 + 3 张表 + 2 个案例
2. 我填充到知识库
3. 测试 2-3 个需求
4. 1-2 天内看到效果

---

## 📊 项目价值

### 已创建的资产

1. **系统架构**: 一套完整的 ChatBI 架构设计
2. **知识库框架**: 可直接使用的知识库结构
3. **AI 技能**: 6 个标准化的 AI 行为定义
4. **文档体系**: 40+ 个文档，覆盖所有方面
5. **最佳实践**: SQL 编写规范、验证标准等

### 可复用性

这套框架不仅适用于雪球，也适用于：
- 其他公司的 ChatBI 系统
- 类似的 AI + 知识库项目
- 数据分析自动化项目

只需要替换业务知识和数据资产即可。

---

## 🎓 设计哲学

### 1. 以终为始

**目标**: 使用者提交需求 → AI 生成准确的 SQL

所有设计都围绕这个目标展开。

### 2. 知识驱动

**理念**: AI 的能力来自知识库，不是"智能"本身

因此，知识库是系统的核心。

### 3. 标准化

**理念**: 通过标准化提高质量和一致性

- 标准的工作流程
- 标准的文档格式
- 标准的 SQL 规范

### 4. 可进化

**理念**: 系统应该能够持续学习和改进

- 反馈收集
- 知识更新
- 系统优化

### 5. 人机协作

**理念**: AI 不是替代人类，而是增强人类

- AI 处理常规需求
- 人类处理复杂需求
- 人类专注于高价值工作

---

## 📞 联系方式

**项目负责人**: [待补充]

**知识库负责人**: [待补充]

**技术支持**: [待补充]

---

## 🔄 维护日志

| 日期 | 版本 | 主要内容 | 文件数 |
|------|------|----------|--------|
| 2024-01-01 | v0.1 | 完成项目框架和文档体系 | 44 |

---

**项目框架已完成，等待填充真实数据！** 🎉
