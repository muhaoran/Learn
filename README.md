# 雪球 ChatBI 系统

[![Status](https://img.shields.io/badge/status-framework_ready-blue)]() [![Version](https://img.shields.io/badge/version-0.1-green)]()

> 智能数据分析系统 - 用自然语言生成准确的 SQL

---

## 🎯 项目目标

**使用者提交数据统计需求 → AI 自动生成完全准确、符合需求的 SQL**

### 核心价值

- ⚡ **效率提升**: 10-20 倍（从 10-30 分钟到 10-30 秒）
- 🎯 **准确保证**: 基于知识库，符合业务定义和数据口径
- 📚 **知识沉淀**: 将业务知识和经验系统化
- 🔄 **持续进化**: 通过反馈不断学习和优化

---

## 🚀 快速开始

### 🎯 第一次使用？从这里开始！

👉 **[START_HERE.md](START_HERE.md)** - 根据你的角色选择阅读路径

### 📖 5 分钟了解 ChatBI

阅读 [GETTING_STARTED.md](GETTING_STARTED.md)

### 📚 完整文档索引

查看 [INDEX.md](INDEX.md) - 快速找到你需要的文档

### 📊 系统总览（一页纸）

阅读 [docs/system_overview.md](docs/system_overview.md)

### 🎨 可视化理解

阅读 [VISUAL_GUIDE.md](VISUAL_GUIDE.md) - 用图表理解系统

---

## 📖 核心文档

| 文档 | 说明 | 适合人群 |
|------|------|----------|
| [系统总览](docs/system_overview.md) | 一页纸了解系统 | 所有人 ⭐ |
| [架构设计](docs/architecture.md) | 详细的系统架构 | 技术人员 ⭐ |
| [实施指南](docs/implementation_guide.md) | 如何实施 ChatBI | 项目负责人 ⭐ |
| [示例演示](docs/example_walkthrough.md) | 完整的使用示例 | 使用者 ⭐ |
| [数据收集清单](docs/data_collection_checklist.md) | 需要准备的数据 | 数据部门 ⭐ |

---

## 🏗️ 系统架构

```
用户需求（自然语言）
    ↓
需求解析 & 澄清
    ↓
知识库检索（业务知识 + 数据资产 + SQL 案例）
    ↓
SQL 生成
    ↓
SQL 验证（语法 + 逻辑 + 口径 + 性能）
    ↓
结果输出（SQL + 说明）
    ↓
反馈收集 & 持续优化
```

详见 [docs/architecture.md](docs/architecture.md)

---

## 📚 知识库体系

### 业务知识库
- 业务术语表（50+ 术语）
- 指标定义（30+ 指标）
- 维度定义（时间、用户等）
- 计算规则（留存率、DAU/MAU 等）

### 数据资产库
- 数据表结构（20+ 张表）
- 表关联关系
- SQL 最佳实践

### SQL 案例库
- 用户分析案例（30+ 案例）
- 内容分析案例
- 交易分析案例
- 复杂查询案例

详见 [knowledge/](knowledge/)

---

## 🎯 核心能力

1. **需求理解**: 理解业务术语和黑话
2. **主动澄清**: 识别模糊需求，主动提问
3. **知识驱动**: 基于知识库生成 SQL
4. **质量保证**: 多层验证机制
5. **可解释性**: 清晰的技术方案说明
6. **持续学习**: 从反馈中不断优化
7. **原始知识处理**: 自动将原始资料转换为结构化知识 ⭐新增

---

## 📊 使用示例

### 示例 1: 简单查询

```
用户: "查询昨天的 DAU"

AI: 
  需求理解: 查询昨天的日活跃用户数
  
  SQL 语句:
  SELECT date, COUNT(DISTINCT user_id) as dau
  FROM dws_user_daily
  WHERE date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    AND is_active = 1
  GROUP BY date;
  
  说明: 使用汇总表，查询速度 < 1 秒
```

### 示例 2: 复杂查询

```
用户: "分析 1 月份新用户的次留，按渠道分"

AI:
  需求理解: 查询 2024 年 1 月每天注册的新用户的次日留存率，按渠道分组
  
  SQL 语句: [使用 CTE 的复杂 SQL]
  
  技术方案: 
  - 使用注册表和行为表关联
  - 计算 D1 活跃用户数 / D0 新增用户数
  - 使用 LEFT JOIN 避免遗漏未留存用户
```

更多示例见 [docs/example_walkthrough.md](docs/example_walkthrough.md)

---

## 📁 项目结构

```
/workspace/
├── docs/                # 文档（9个核心文档）
├── knowledge/           # 知识库（业务知识 + 数据资产 + SQL 案例）⭐⭐⭐
├── raw_knowledge/       # 原始知识资料库（待处理的原始资料）⭐⭐
├── design_philosophy/   # 设计哲学（系统设计思路和内在逻辑）⭐⭐
├── skills/              # AI 技能定义（7个 Skill）⭐⭐
├── prompts/             # Prompt 模板
├── tests/               # 测试用例
└── feedback/            # 反馈收集
```

详见 [INDEX.md](INDEX.md)

---

## 🎬 下一步

### 当前状态

- ✅ 系统框架已搭建（55+个文件，20,000+行）
- ✅ 文档体系已完成（覆盖所有方面）
- ✅ 模板已创建（可直接使用）
- ✅ 原始知识处理模块已就绪 ⭐新增
- ✅ Trino 语法规范已明确 ⭐新增
- ⏳ 等待填充真实数据

### 📊 项目统计

查看 [PROJECT_STATS.md](PROJECT_STATS.md) 和 [FINAL_SUMMARY.md](FINAL_SUMMARY.md)

### 立即开始

**方式 1: 使用原始资料快速开始**（最简单）⭐推荐
1. 将你的原始资料（Excel、Word、SQL 等）放到 `raw_knowledge/` 对应文件夹
2. 告诉 AI "请处理 raw_knowledge/xxx"
3. AI 自动转换为结构化知识库
4. 立即开始使用

详见 [raw_knowledge/README.md](raw_knowledge/README.md)

**方式 2: 快速验证**
1. 提供最小数据集（5 术语 + 3 表 + 2 案例）
2. 1 周内验证可行性
3. 决定是否继续

**方式 3: 完整构建**
1. 准备完整数据
2. 2-4 周建立系统
3. 全面测试推广

详见 [docs/implementation_guide.md](docs/implementation_guide.md)

### 🎬 演示

查看 [DEMO.md](DEMO.md) 了解如何演示系统

---

## 📞 联系方式

**项目负责人**: [待补充]

**技术支持**: [待补充]

**问题反馈**: [待补充]

---

## 📄 许可证

[待补充]

---

## 🙏 致谢

感谢雪球数据部门的支持和贡献！

---

**让数据分析更简单、更高效！** 🚀
