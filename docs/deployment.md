# ChatBI 部署指南

> 本文档说明如何部署和配置 ChatBI 系统

---

## 部署方式

### 方式 1: Cursor + Rules（推荐用于验证和小规模使用）

#### 适用场景
- 快速验证可行性
- 小团队使用（< 10 人）
- 手动交互式使用

#### 部署步骤

**步骤 1: 准备环境**
```bash
# 克隆项目
git clone [repo_url]
cd chatbi

# 确认 Cursor 已安装
```

**步骤 2: 配置知识库**
1. 填充 `knowledge/business/` 中的业务知识
2. 填充 `knowledge/data_assets/` 中的数据表信息
3. 填充 `knowledge/sql_examples/` 中的 SQL 案例

**步骤 3: 配置 AI 规则**

`.cursorrules` 文件已经配置好，包含：
- AI 的角色定位
- 工作流程
- 行为规范

**步骤 4: 开始使用**
1. 在 Cursor 中打开项目
2. 打开 Chat 面板
3. 输入数据需求
4. AI 自动读取知识库，生成 SQL

#### 优点
- ✅ 部署简单，无需额外开发
- ✅ 利用 Cursor 的 AI 能力
- ✅ 可以实时调整知识库

#### 缺点
- ❌ 需要手动交互
- ❌ 不适合大规模使用
- ❌ 无法自动化

---

### 方式 2: Cloud Agent（推荐用于生产环境）

#### 适用场景
- 大规模使用（10+ 人）
- 需要自动化处理
- 集成到工作流

#### 部署步骤

**步骤 1: 准备 GitHub 仓库**
```bash
# 项目已经在 GitHub
# 确保知识库已填充
```

**步骤 2: 配置 Cloud Agent**

在 Cursor Dashboard 中配置 Cloud Agent：
1. 关联 GitHub 仓库
2. 配置触发条件（如 Issue 创建）
3. 配置权限和密钥

**步骤 3: 创建 Issue 模板**

`.github/ISSUE_TEMPLATE/data_request.md`:
```markdown
---
name: 数据需求
about: 提交数据统计需求
title: '[数据需求] '
labels: data-request
---

## 需求描述

[请描述你的数据需求]

## 补充信息（可选）

- 时间范围: 
- 分析维度: 
- 特殊要求: 

---

<!-- Cloud Agent 会自动处理此需求并生成 SQL -->
```

**步骤 4: 使用**
1. 用户创建 Issue，描述需求
2. Cloud Agent 自动触发
3. AI 读取知识库，生成 SQL
4. 在 Issue 中回复 SQL 和说明

#### 优点
- ✅ 自动化处理
- ✅ 可以并发处理多个需求
- ✅ 集成到工作流
- ✅ 有完整的记录（Issue 历史）

#### 缺点
- ❌ 需要配置 Cloud Agent
- ❌ 有一定的学习成本

---

### 方式 3: 独立服务（长期方案）

#### 适用场景
- 需要深度定制
- 需要集成到内部系统
- 需要更多功能（如 SQL 执行、结果可视化）

#### 架构设计

```
┌─────────────┐
│   用户界面   │ (Web UI / API / Slack Bot)
└──────┬──────┘
       │
┌──────▼──────┐
│  API 服务   │ (FastAPI / Flask)
└──────┬──────┘
       │
┌──────▼──────┐
│  核心引擎   │
│  - 需求解析  │
│  - 知识检索  │
│  - SQL 生成  │
│  - SQL 验证  │
└──────┬──────┘
       │
┌──────▼──────┐
│   知识库    │ (文件系统 / 数据库)
└─────────────┘
```

#### 技术栈建议

**后端**:
- Python + FastAPI
- LangChain (知识检索)
- SQLAlchemy (数据库连接)

**前端**:
- React + TypeScript
- Ant Design (UI 组件)

**知识库**:
- 文件系统（Markdown）
- 或向量数据库（如 Pinecone, Weaviate）

**AI**:
- OpenAI API
- 或 Anthropic Claude API

#### 部署步骤

1. **开发 API 服务**
   - 实现需求解析接口
   - 实现知识检索接口
   - 实现 SQL 生成接口

2. **开发前端界面**
   - 需求输入界面
   - SQL 展示界面
   - 历史记录界面

3. **部署**
   - 部署后端服务
   - 部署前端应用
   - 配置数据库连接

4. **集成**
   - 集成到内部数据平台
   - 配置 SSO 登录
   - 配置权限控制

#### 优点
- ✅ 完全自定义
- ✅ 可以添加更多功能
- ✅ 更好的用户体验
- ✅ 可以集成到内部系统

#### 缺点
- ❌ 开发成本高
- ❌ 维护成本高
- ❌ 需要更多技术能力

---

## 配置说明

### 数据库连接配置

**配置文件**: `config/database.yaml` (需要创建)

```yaml
database:
  type: mysql  # mysql/postgresql/hive/clickhouse
  host: your-db-host
  port: 3306
  database: your-database
  user: your-user
  password: ${DB_PASSWORD}  # 使用环境变量
  
  # 连接池配置
  pool_size: 10
  max_overflow: 20
  
  # 查询配置
  query_timeout: 60  # 秒
  max_rows: 100000   # 最大返回行数
```

**安全建议**:
- 使用只读账号
- 密码使用环境变量或密钥管理服务
- 限制可访问的数据库和表

### AI 配置

**配置文件**: `config/ai.yaml` (需要创建)

```yaml
ai:
  provider: openai  # openai/anthropic/azure
  model: gpt-4
  api_key: ${OPENAI_API_KEY}  # 使用环境变量
  
  # 生成配置
  temperature: 0.1  # 低温度，提高确定性
  max_tokens: 4000
  
  # 知识库配置
  knowledge_base_path: ./knowledge
  
  # 缓存配置
  enable_cache: true
  cache_ttl: 3600  # 秒
```

### 知识库配置

**配置文件**: `config/knowledge.yaml` (需要创建)

```yaml
knowledge:
  # 知识库路径
  base_path: ./knowledge
  
  # 业务知识
  business:
    glossary: knowledge/business/glossary.md
    metrics: knowledge/business/metrics/
    dimensions: knowledge/business/dimensions/
    calculation_rules: knowledge/business/calculation_rules/
  
  # 数据资产
  data_assets:
    tables: knowledge/data_assets/tables/
    relationships: knowledge/data_assets/relationships.md
    best_practices: knowledge/data_assets/best_practices.md
  
  # SQL 案例
  sql_examples:
    user_analysis: knowledge/sql_examples/user_analysis/
    content_analysis: knowledge/sql_examples/content_analysis/
    trade_analysis: knowledge/sql_examples/trade_analysis/
    complex_queries: knowledge/sql_examples/complex_queries/
  
  # 更新配置
  auto_reload: true  # 自动重载知识库
  reload_interval: 300  # 秒
```

---

## 环境变量

### 必需的环境变量

```bash
# AI 配置
export OPENAI_API_KEY="your-api-key"

# 数据库配置
export DB_PASSWORD="your-db-password"

# 可选：日志配置
export LOG_LEVEL="INFO"
```

### 环境变量管理

**开发环境**: 使用 `.env` 文件

```bash
# .env
OPENAI_API_KEY=your-api-key
DB_PASSWORD=your-db-password
```

**生产环境**: 使用密钥管理服务
- AWS Secrets Manager
- Azure Key Vault
- HashiCorp Vault

---

## 权限配置

### 数据库权限

**推荐**: 使用只读账号

```sql
-- 创建只读用户
CREATE USER 'chatbi_readonly'@'%' IDENTIFIED BY 'password';

-- 授予查询权限
GRANT SELECT ON database_name.* TO 'chatbi_readonly'@'%';

-- 限制特定表（如果需要）
GRANT SELECT ON database_name.table1 TO 'chatbi_readonly'@'%';
GRANT SELECT ON database_name.table2 TO 'chatbi_readonly'@'%';
```

### 用户权限

**配置文件**: `config/permissions.yaml` (需要创建)

```yaml
permissions:
  # 用户组
  groups:
    - name: data_team
      users: [user1, user2, user3]
      access:
        - all_tables
    
    - name: business_team
      users: [user4, user5]
      access:
        - dws_tables  # 只能访问汇总表
        - ads_tables
  
  # 表访问控制
  table_access:
    dwd_user_behavior:
      allowed_groups: [data_team]
    
    dws_user_daily:
      allowed_groups: [data_team, business_team]
  
  # 敏感字段
  sensitive_fields:
    - password
    - id_card
    - phone_number
```

---

## 监控和日志

### 日志配置

**日志级别**:
- DEBUG: 详细的调试信息
- INFO: 一般信息（推荐）
- WARNING: 警告信息
- ERROR: 错误信息

**日志内容**:
- 用户需求
- 生成的 SQL
- 执行时间
- 错误信息

**日志文件**:
```
logs/
├── chatbi.log          # 主日志
├── sql_generation.log  # SQL 生成日志
├── errors.log          # 错误日志
└── access.log          # 访问日志
```

### 监控指标

**业务指标**:
- 每日请求数
- SQL 生成成功率
- 平均响应时间
- 用户满意度

**技术指标**:
- API 响应时间
- 数据库查询时间
- 错误率
- 系统资源使用

**监控工具**:
- Prometheus + Grafana
- ELK Stack (日志分析)
- 或内部监控系统

---

## 备份和恢复

### 知识库备份

**备份内容**:
- `knowledge/` 目录
- `skills/` 目录
- `prompts/` 目录
- 配置文件

**备份频率**: 每天

**备份方式**:
- Git 版本控制
- 或定期打包备份

### 反馈数据备份

**备份内容**:
- `feedback/` 目录

**备份频率**: 每周

---

## 性能优化

### 知识库优化

1. **索引优化**:
   - 为常用术语建立索引
   - 为常用表建立索引

2. **缓存优化**:
   - 缓存常用的知识库查询
   - 缓存相似需求的结果

3. **分级加载**:
   - 优先加载高频知识
   - 按需加载低频知识

### SQL 生成优化

1. **模板复用**:
   - 对于相似需求，复用 SQL 模板
   - 只修改参数部分

2. **并行处理**:
   - 知识检索并行化
   - 多个需求并行处理

---

## 安全措施

### 1. 输入验证

- 检查输入长度
- 过滤恶意输入
- 防止 SQL 注入（虽然只生成 SELECT）

### 2. 输出过滤

- 检查生成的 SQL 类型（只允许 SELECT）
- 检查是否访问敏感字段
- 检查是否超出权限范围

### 3. 审计日志

记录所有操作：
- 谁提交了需求
- 生成了什么 SQL
- 是否执行了 SQL
- 执行结果如何

---

## 故障处理

### 常见问题

#### 问题 1: AI 无法连接

**症状**: AI 不响应或报错

**排查**:
1. 检查 API Key 是否正确
2. 检查网络连接
3. 检查 API 配额

**解决**:
- 更新 API Key
- 检查网络配置
- 升级 API 套餐

#### 问题 2: 知识库读取失败

**症状**: AI 说找不到知识库

**排查**:
1. 检查文件路径是否正确
2. 检查文件权限
3. 检查文件格式

**解决**:
- 修正文件路径
- 修改文件权限
- 修复文件格式错误

#### 问题 3: SQL 生成不准确

**症状**: 生成的 SQL 不符合需求

**排查**:
1. 检查知识库是否完整
2. 检查业务定义是否清晰
3. 检查是否有相似案例

**解决**:
- 补充知识库
- 优化业务定义
- 添加相似案例

#### 问题 4: 性能问题

**症状**: 响应时间过长

**排查**:
1. 检查知识库大小
2. 检查 AI 响应时间
3. 检查数据库查询时间

**解决**:
- 优化知识库结构
- 启用缓存
- 优化数据库查询

---

## 升级和维护

### 版本管理

**版本号规则**: `major.minor.patch`

- **major**: 重大架构变更
- **minor**: 功能增加、知识库扩充
- **patch**: 问题修复、小优化

**示例**:
- v0.1: 初始版本（框架）
- v0.2: 补充知识库
- v1.0: 正式发布
- v1.1: 功能增强
- v1.1.1: 问题修复

### 升级流程

1. **准备**:
   - 备份当前版本
   - 准备升级内容
   - 编写升级文档

2. **测试**:
   - 在测试环境升级
   - 运行测试用例
   - 验证功能

3. **发布**:
   - 在生产环境升级
   - 通知用户
   - 监控运行状态

4. **回滚**:
   - 如有问题，立即回滚
   - 分析问题原因
   - 修复后重新发布

### 维护计划

**每日**:
- 监控系统运行状态
- 处理错误和异常

**每周**:
- 处理用户反馈
- 补充知识库
- 优化系统

**每月**:
- 评估系统效果
- 分析准确率
- 制定优化计划
- 更新文档

---

## 灾难恢复

### 备份策略

**备份内容**:
- 知识库文件
- 配置文件
- 反馈数据
- 日志文件

**备份频率**:
- 知识库: 每天（Git 自动备份）
- 反馈数据: 每周
- 日志: 每月归档

**备份位置**:
- Git 仓库
- 云存储（如 S3）
- 本地备份

### 恢复流程

1. **识别问题**
2. **确定恢复点**
3. **恢复数据**:
   ```bash
   # 从 Git 恢复
   git checkout <commit_hash>
   
   # 或从备份恢复
   cp -r backup/knowledge/ ./knowledge/
   ```
4. **验证恢复**
5. **恢复服务**

---

## 扩展性

### 水平扩展

**Cloud Agent 方式**:
- 自动并发处理多个 Issue
- 无需额外配置

**独立服务方式**:
- 部署多个服务实例
- 使用负载均衡
- 共享知识库（只读）

### 功能扩展

**可以扩展的功能**:
1. **SQL 执行**: 自动执行生成的 SQL，返回结果
2. **结果可视化**: 自动生成图表
3. **定时任务**: 定期执行某些查询
4. **告警**: 指标异常时自动告警
5. **报表**: 自动生成数据报表

---

## 成本估算

### Cloud Agent 方式

**成本构成**:
- Cursor Cloud Agent 费用: [根据实际使用量]
- AI API 费用: 约 $0.01-0.05 / 请求
- 存储费用: 几乎为 0

**月成本估算**（假设每天 20 个请求）:
- AI API: 20 × 30 × $0.03 = $18
- Cloud Agent: [根据套餐]
- **总计**: 约 $20-50 / 月

### 独立服务方式

**成本构成**:
- 服务器费用: $50-200 / 月
- AI API 费用: $20-100 / 月
- 数据库费用: $20-100 / 月
- 开发维护: 人力成本

**月成本估算**:
- 基础设施: $100-400 / 月
- 人力: 0.2-0.5 人月

---

## 常见问题

### Q: 如何选择部署方式？

A: 
- **小规模、快速验证**: 方式 1 (Cursor + Rules)
- **中大规模、生产使用**: 方式 2 (Cloud Agent)
- **需要深度定制**: 方式 3 (独立服务)

### Q: 部署需要多长时间？

A: 
- 方式 1: < 1 天（主要是填充知识库）
- 方式 2: 1-3 天（配置 + 测试）
- 方式 3: 2-4 周（开发 + 测试 + 部署）

### Q: 需要什么技术能力？

A: 
- 方式 1: 基础的 Markdown 编辑能力
- 方式 2: 基础的 Git 和 GitHub 使用能力
- 方式 3: 全栈开发能力

---

## 维护日志

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2024-01-01 | AI | 创建部署指南 |
