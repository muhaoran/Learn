# ChatBI 项目文档索引

> 快速找到你需要的文档

---

## 🚀 新手入门

| 文档 | 说明 | 适合人群 |
|------|------|----------|
| [GETTING_STARTED.md](GETTING_STARTED.md) | 5分钟快速开始 | 所有人 |
| [docs/system_overview.md](docs/system_overview.md) | 系统总览（一页纸） | 决策者、管理者 |
| [docs/example_walkthrough.md](docs/example_walkthrough.md) | 完整示例演示 | 使用者 |
| [docs/quick_start.md](docs/quick_start.md) | 快速开始指南 | 使用者 |

---

## 📋 规划和设计

| 文档 | 说明 | 适合人群 |
|------|------|----------|
| [docs/architecture.md](docs/architecture.md) | 系统架构设计 | 技术人员、项目负责人 |
| [docs/workflow.md](docs/workflow.md) | 工作流程详解 | 技术人员 |
| [docs/implementation_guide.md](docs/implementation_guide.md) | 实施指南 | 项目负责人 |

---

## 📚 知识库

### 业务知识

| 文档 | 说明 |
|------|------|
| [knowledge/business/glossary.md](knowledge/business/glossary.md) | 业务术语表 |
| [knowledge/business/metrics/user_metrics.md](knowledge/business/metrics/user_metrics.md) | 用户指标定义 |
| [knowledge/business/metrics/content_metrics.md](knowledge/business/metrics/content_metrics.md) | 内容指标定义 |
| [knowledge/business/metrics/trade_metrics.md](knowledge/business/metrics/trade_metrics.md) | 交易指标定义 |
| [knowledge/business/dimensions/time_dimensions.md](knowledge/business/dimensions/time_dimensions.md) | 时间维度定义 |
| [knowledge/business/dimensions/user_dimensions.md](knowledge/business/dimensions/user_dimensions.md) | 用户维度定义 |
| [knowledge/business/calculation_rules/retention.md](knowledge/business/calculation_rules/retention.md) | 留存率计算规则 |
| [knowledge/business/calculation_rules/dau_mau.md](knowledge/business/calculation_rules/dau_mau.md) | DAU/MAU 计算规则 |

### 数据资产

| 文档 | 说明 |
|------|------|
| [knowledge/data_assets/tables/TABLE_TEMPLATE.md](knowledge/data_assets/tables/TABLE_TEMPLATE.md) | 表文档模板 |
| [knowledge/data_assets/tables/dws/dws_user_daily.md](knowledge/data_assets/tables/dws/dws_user_daily.md) | 用户日度汇总表（示例） |
| [knowledge/data_assets/tables/dwd/dwd_user_behavior.md](knowledge/data_assets/tables/dwd/dwd_user_behavior.md) | 用户行为明细表（示例） |
| [knowledge/data_assets/tables/dwd/dwd_user_register.md](knowledge/data_assets/tables/dwd/dwd_user_register.md) | 用户注册表（示例） |
| [knowledge/data_assets/relationships.md](knowledge/data_assets/relationships.md) | 表关联关系 |
| [knowledge/data_assets/best_practices.md](knowledge/data_assets/best_practices.md) | SQL 最佳实践 |

### SQL 案例

| 文档 | 说明 |
|------|------|
| [knowledge/sql_examples/EXAMPLE_TEMPLATE.md](knowledge/sql_examples/EXAMPLE_TEMPLATE.md) | SQL 案例模板 |
| [knowledge/sql_examples/user_analysis/dau_trend.md](knowledge/sql_examples/user_analysis/dau_trend.md) | DAU 趋势分析 |
| [knowledge/sql_examples/user_analysis/retention.md](knowledge/sql_examples/user_analysis/retention.md) | 次日留存率分析 |
| [knowledge/sql_examples/user_analysis/new_user_analysis.md](knowledge/sql_examples/user_analysis/new_user_analysis.md) | 新增用户分析 |

---

## 🎯 Skills（AI 技能）

| 文档 | 说明 |
|------|------|
| [skills/01_requirement_parsing.md](skills/01_requirement_parsing.md) | 需求解析技能 |
| [skills/02_requirement_clarification.md](skills/02_requirement_clarification.md) | 需求澄清技能 |
| [skills/03_knowledge_retrieval.md](skills/03_knowledge_retrieval.md) | 知识检索技能 |
| [skills/04_sql_generation.md](skills/04_sql_generation.md) | SQL 生成技能 |
| [skills/05_sql_validation.md](skills/05_sql_validation.md) | SQL 验证技能 |
| [skills/06_result_explanation.md](skills/06_result_explanation.md) | 结果解释技能 |

---

## 🧪 测试和反馈

| 文档 | 说明 |
|------|------|
| [tests/test_cases.md](tests/test_cases.md) | 测试用例 |
| [feedback/README.md](feedback/README.md) | 反馈系统说明 |
| [feedback/corrections/CORRECTION_TEMPLATE.md](feedback/corrections/CORRECTION_TEMPLATE.md) | SQL 纠错模板 |
| [feedback/knowledge_gaps/KNOWLEDGE_GAP_TEMPLATE.md](feedback/knowledge_gaps/KNOWLEDGE_GAP_TEMPLATE.md) | 知识缺口模板 |

---

## 📖 配置和规则

| 文档 | 说明 |
|------|------|
| [.cursorrules](.cursorrules) | Cursor AI 规则 |
| [prompts/system_prompt.md](prompts/system_prompt.md) | 系统 Prompt |

---

## 🔧 贡献和维护

| 文档 | 说明 |
|------|------|
| [docs/knowledge_contribution_guide.md](docs/knowledge_contribution_guide.md) | 知识库贡献指南 |
| [docs/data_collection_checklist.md](docs/data_collection_checklist.md) | 数据收集清单 |

---

## 📊 按角色查看

### 我是决策者/管理者

**推荐阅读**:
1. [docs/system_overview.md](docs/system_overview.md) - 了解系统价值和投入产出
2. [docs/implementation_guide.md](docs/implementation_guide.md) - 了解实施计划
3. [docs/example_walkthrough.md](docs/example_walkthrough.md) - 看实际效果

### 我是项目负责人

**推荐阅读**:
1. [docs/architecture.md](docs/architecture.md) - 了解系统架构
2. [docs/implementation_guide.md](docs/implementation_guide.md) - 制定实施计划
3. [docs/data_collection_checklist.md](docs/data_collection_checklist.md) - 准备数据
4. [docs/workflow.md](docs/workflow.md) - 了解工作流程

### 我是数据分析师（使用者）

**推荐阅读**:
1. [GETTING_STARTED.md](GETTING_STARTED.md) - 快速开始
2. [docs/quick_start.md](docs/quick_start.md) - 使用指南
3. [docs/example_walkthrough.md](docs/example_walkthrough.md) - 学习示例
4. [knowledge/sql_examples/](knowledge/sql_examples/) - 查看案例

### 我是数据开发（知识库维护者）

**推荐阅读**:
1. [docs/knowledge_contribution_guide.md](docs/knowledge_contribution_guide.md) - 如何贡献
2. [knowledge/business/](knowledge/business/) - 业务知识库
3. [knowledge/data_assets/](knowledge/data_assets/) - 数据资产库
4. [feedback/](feedback/) - 反馈记录

### 我是技术开发

**推荐阅读**:
1. [docs/architecture.md](docs/architecture.md) - 系统架构
2. [skills/](skills/) - AI 技能定义
3. [prompts/system_prompt.md](prompts/system_prompt.md) - 系统 Prompt
4. [.cursorrules](.cursorrules) - AI 规则

---

## 📁 目录结构

```
/workspace/
├── README.md                       # 项目简介
├── GETTING_STARTED.md              # 快速开始
├── INDEX.md                        # 本文档（索引）
├── .cursorrules                    # Cursor AI 规则
│
├── docs/                           # 文档
│   ├── system_overview.md          # 系统总览 ⭐
│   ├── architecture.md             # 架构设计 ⭐
│   ├── workflow.md                 # 工作流程
│   ├── implementation_guide.md     # 实施指南 ⭐
│   ├── quick_start.md              # 快速开始
│   ├── example_walkthrough.md      # 示例演示 ⭐
│   ├── knowledge_contribution_guide.md  # 贡献指南
│   └── data_collection_checklist.md     # 数据收集清单 ⭐
│
├── knowledge/                      # 知识库 ⭐⭐⭐
│   ├── business/                   # 业务知识
│   │   ├── glossary.md            # 术语表
│   │   ├── metrics/               # 指标定义
│   │   ├── dimensions/            # 维度定义
│   │   └── calculation_rules/     # 计算规则
│   │
│   ├── data_assets/               # 数据资产
│   │   ├── tables/                # 表文档
│   │   ├── relationships.md       # 表关联
│   │   └── best_practices.md      # 最佳实践
│   │
│   └── sql_examples/              # SQL 案例
│       ├── user_analysis/         # 用户分析
│       ├── content_analysis/      # 内容分析
│       ├── trade_analysis/        # 交易分析
│       └── complex_queries/       # 复杂查询
│
├── skills/                         # AI 技能 ⭐⭐
│   ├── 01_requirement_parsing.md
│   ├── 02_requirement_clarification.md
│   ├── 03_knowledge_retrieval.md
│   ├── 04_sql_generation.md
│   ├── 05_sql_validation.md
│   └── 06_result_explanation.md
│
├── prompts/                        # Prompt 模板
│   └── system_prompt.md
│
├── tests/                          # 测试
│   └── test_cases.md
│
└── feedback/                       # 反馈
    ├── corrections/               # 纠错记录
    ├── new_cases/                 # 新案例
    ├── knowledge_gaps/            # 知识缺口
    └── improvements/              # 改进建议
```

**⭐ 标记**: 重要程度
- ⭐⭐⭐ 最重要
- ⭐⭐ 很重要
- ⭐ 重要

---

## 🔍 快速查找

### 我想了解...

- **系统是什么**: [docs/system_overview.md](docs/system_overview.md)
- **如何使用**: [GETTING_STARTED.md](GETTING_STARTED.md)
- **如何实施**: [docs/implementation_guide.md](docs/implementation_guide.md)
- **看实际效果**: [docs/example_walkthrough.md](docs/example_walkthrough.md)
- **系统架构**: [docs/architecture.md](docs/architecture.md)
- **工作流程**: [docs/workflow.md](docs/workflow.md)

### 我想查询...

- **业务术语**: [knowledge/business/glossary.md](knowledge/business/glossary.md)
- **指标定义**: [knowledge/business/metrics/](knowledge/business/metrics/)
- **数据表结构**: [knowledge/data_assets/tables/](knowledge/data_assets/tables/)
- **SQL 案例**: [knowledge/sql_examples/](knowledge/sql_examples/)

### 我想贡献...

- **如何贡献**: [docs/knowledge_contribution_guide.md](docs/knowledge_contribution_guide.md)
- **数据收集清单**: [docs/data_collection_checklist.md](docs/data_collection_checklist.md)
- **模板文件**: 各目录下的 TEMPLATE 文件

---

## 📞 联系方式

**项目负责人**: [姓名] - [邮箱]

**知识库负责人**: [姓名] - [邮箱]

**技术支持**: [姓名] - [邮箱]

---

## 🔄 更新日志

| 日期 | 版本 | 主要更新 |
|------|------|----------|
| 2024-01-01 | v0.1 | 创建项目框架 |

---

## 📌 重要提示

### 当前状态

- ✅ 框架已搭建
- ✅ 模板已创建
- ⏳ 等待填充真实数据

### 下一步

1. 填充知识库（参考 [docs/data_collection_checklist.md](docs/data_collection_checklist.md)）
2. 测试验证（参考 [tests/test_cases.md](tests/test_cases.md)）
3. 优化改进
4. 推广使用

---

**有任何问题，请随时联系我们！**
