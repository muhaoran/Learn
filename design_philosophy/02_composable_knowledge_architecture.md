# 可组合知识架构设计

> 解决「维护 1000 个指标」问题的根本思路：用有限词汇 × 有限语法，覆盖无限的指标组合空间。

---

## 一、问题来源

### 当前设计的核心矛盾

旧版四层架构（术语→维度→指标→计算规则）在理念上是对的，但在信息组织方式上存在一个根本问题：

**它把「组合结果」当成了知识单元。**

每新增一个指标（如「私域客户 7 日内首购率」），就需要写一份完整文档，重新描述一遍大量在其他指标里已经写过的信息（首购定义、时间计算方式、JOIN 逻辑……）。

这导致：

- **信息重复**：同一业务语义在术语、指标、计算规则中各写一遍
- **维护爆炸**：条目数 n → 需要维护的「文档之间的一致性边」接近组合增长
- **排错困难**：AI 出错时，无法快速定位是哪一层、哪一条定义有问题
- **无法穷尽**：1000 个指标 = 1000 份文档，几乎不可能全部维护

### 核心洞察

> 1000 个指标，不是 1000 份独立知识。
> 它们是**少量语义原子 × 少量计算模式**的组合空间。

```
10 个计算模式
×  ~100 个语义原子（事件、分群、维度）
=  理论上覆盖绝大多数业务指标
```

正确的知识结构，应该维护的是**原子和组合规则**，而不是组合出来的结果。

---

## 二、新架构：四层各司其职

```
数据字典（Schema）    → 「有什么」    纯事实，描述仓库
业务语义（Semantics） → 「是什么意思」 业务原子，唯一权威
计算模式（Pattern）   → 「怎么算」    通用计算结构
指标目录（Metric）    → 「是哪个组合」 极薄的声明式配置
```

**关键原则**：每一层只做一件事，信息不跨层重复。指标目录（Metric） 是最薄的一层，不写定义，只写「用哪个模式、填哪些原子」。

---

## 三、各层详解

### 数据字典（Schema）

**职责**：描述数据仓库里客观存在什么，不含任何业务判断。

**内容**：表名、字段名、类型、分区键、更新频率、表间关联键。

**维护方**：数仓工程师，理论上可从 Metastore 自动生成，人工维护量极低。

```yaml
table: fundx_dwd.dwd_evt_parent_money_order_s
partition: dt
granularity: 一行 = 一笔父单
columns:
  uid: bigint
  batch_order_serial_no: string
  init_time: string         # 下单时间（字符串）
  init_amount: decimal
  flavor: string            # 交易渠道编码
  trade_mode: string        # 交易模式（申购/认购/定投…）
```

**边界**：只说「字段叫什么」，不说「哪种 trade_mode 组合叫主动买入」。

---

### 业务语义（Semantics）—— 核心层

**职责**：把业务语言翻译成数据条件。这是**整个系统的单一权威来源**，是真正需要投入精力维护的地方。

**内容**：三类语义原子，以实体为锚点组织。

```
实体（Entity）      → 「谁/什么」    是业务过程和维度的锚点
业务过程（Event）   → 「发生了什么」  绑定到实体
维度（Dimension）   → 「实体的属性」  绑定到实体
```

---

#### 实体（Entity）

定义业务中的核心对象。是 业务过程和维度 的**锚点**——事件「发生在」某个实体上，维度「描述」某个实体。

**边界规则**：
- 只定义实体的**业务身份**（是什么）和**主键**（怎么唯一标识）
- 不定义属性（属于 维度（Dimension）），不定义行为（属于 业务过程（Event））
- 实体的属性往往分散在多张表里，每个维度（B2）自己声明来自哪张表、如何 JOIN——实体不需要也无法枚举所有属性表
- `anchor_tables` 是可选的字典：key 自定义命名（如 `profile` / `holding`），value 为对应宽表；指标通过 `anchor_table: <key>` 引用其中一张。没有宽表时留空即可

```yaml
entity_id: customer
name: 蛋卷客户
description: 在蛋卷完成开户的账户主体，是大多数交易/触达指标的统计对象
primary_key: uid                   # 规范主键字段名，COUNT DISTINCT 时优先使用
id_aliases: [dj_uid]               # 可选：不同表中主键字段名不一致时列出等价字段名
anchor_tables:                     # 可选：按用途命名的宽表字典，指标用 anchor_table: <key> 引用
  profile: fundx_dwd.dwd_pat_user_info_s
aliases: [客户, 蛋卷用户, 蛋卷 uid, uid]
# 客户属性（开户渠道、私域标签、所属小雪等）分散在多张表，由各维度定义自行声明
```

```yaml
entity_id: fund_product
name: 基金/组合产品
description: 蛋卷上架销售的公募基金或投顾组合产品
primary_key: pro_code
anchor_tables:
  base: fundx_dwd.dwd_pro_stock_base_info_s
aliases: [产品, 基金, 组合, pro_code]
```

```yaml
entity_id: fund_order
name: 公募买入父单
description: 客户发起的一笔公募买入父单（含申购/认购/定投等多种 trade_mode）
primary_key: batch_order_serial_no
# anchor_table 留空：父单属性分散在多张事实表，无统一宽表
aliases: [父单, 买入订单, 申购单, order]
```

---

#### 业务过程（Event）

定义「发生了什么业务过程」，对应 OneData 的「业务过程」。

**边界规则**：
- 业务过程（Event） 只回答「这个业务过程对应哪张表的哪些行」，**不加任何业务属性过滤条件**
- 如果一张表只存一种事件（如开户清洗表专存开户），直接指向表即可，不需要任何条件
- 如果多种事件共存一张表（如父单表存了申购/认购/定投/转换多种 trade_mode），才需要 `trade_mode IN (...)` 这样的**类型识别条件**——这是区分「哪种事件」的标识，不是业务属性的过滤
- 像 `order_status = 'success'` 这类**属性过滤**不属于 业务过程（Event），应作为 维度（Dimension）的命名取值

```yaml
# 专用表：直接指向表，无需条件
event_id: account_open
name: 客户开户
entity: customer                  # 这个事件发生在哪个实体上
description: 客户在蛋卷完成开户这一业务过程（不区分后续是否实际交易）
source_table: data_product.product_fund_uid_register_source_cleaning_s
aliases: [开户, 注册, 新开户]
```

```yaml
# 多事件共存表：需要类型识别条件区分不同业务过程
event_id: place_fund_order
name: 公募主动买入
entity: customer
description: 客户在父单表中发生主动买入类下单（申购/认购等，不含定投自动扣款）
source_table: fundx_dwd.dwd_evt_parent_money_order_s
type_condition: trade_mode IN ('apply','subscribe')
aliases: [买入, 下单, 主动申购]
```

```yaml
event_id: wechat_sop_reach
name: 企微 SOP 触达
entity: customer
description: 公募小雪 SOP 节点向客户成功发送一条触达消息
source_table: fundx_ods.ods_fundx_socialcrm_wechat_reach_record_s_trans
type_condition: status = 'success'
aliases: [触达, SOP 发送, 推送]
```

---

#### 维度（Dimension）

实体的业务属性，是语义层的**原材料**。对应 OneData 的「维度」。

**边界规则**：
- **绑定实体，不绑定事件**：`flavor`（开户渠道）是「客户」实体的属性，不是「开户事件」独有的。绑到实体后，所有涉及客户的指标都能使用，无需重复定义
- **只定义属性本身，不预设用法**：是做过滤（WHERE）还是分组（GROUP BY），由 指标目录（Metric） 指标配方在组合时决定，不在维度定义里写
- **维度值必须是有限离散的分类值**：连续值（如下单金额、持仓天数）不是维度，如需分组须先 CASE WHEN 分桶，分桶结果才是维度值
- **枚举值按需维护**：高基数字段（如开户渠道有上百个 flavor 值）无需列举，AI 直接推断。低基数枚举字段若每个值有独立业务含义，用 `known_values` 记录，帮助 AI 翻译自然语言（如「外部渠道客户」→ `WHERE flavor_type = 'external'`）
- **`source_table` 的适用范围**：仅用于有 `sql_expr` 的实体属性维度（告诉 AI 去哪张表取字段）。若维度只有 `named_values` 子查询，`sql_condition` 本身已包含表信息，顶层不需要声明 `source_table`
- **维度的两种场景**：① **实体属性**（有 `sql_expr`，值可从表中直接读取或 CASE WHEN 计算，`named_values` 可选，用于某些取值需要显式 SQL 条件时）；② **计算属性**（无 `sql_expr`，值无法从字段直接读取，用自包含子查询的 `named_values` 定义每个取值的归属条件，AI 直接使用不推导）
- **参数化原则**：若命名取值存在「同一模式、不同参数值」的变体（如 7天/14天/30天），必须用 `parameters` 参数化，在 指标目录（Metric）配方里传入具体值——逐一枚举等于在业务语义（Semantics）中重新制造维护爆炸

```yaml
# 类型一：简单维度，只需定义属性和来源，不需要枚举值，带语义标注的数据字典
#数据字典（Schema）由数仓工程师维护，关注表结构
#业务语义（Semantics）由业务/分析师维护，关注语义
dimension_id: open_channel
name: 开户渠道
entity: customer                    # 描述哪个实体
sql_expr: flavor
source_table: data_product.product_fund_uid_register_source_cleaning_s
join_key: uid                       # 与实体主键的关联方式
aliases: [渠道, 开户渠道, flavor]
```

> **设计决策备注**：简单维度与数据字典（Schema）存在重叠——字段名、表名、关联键在数据字典（Schema）里已有。业务语义（Semantics）中的简单维度额外增加的只有三项：业务名称、实体归属、别名（用于自然语言理解）。
>
> 保留简单维度作为独立的业务语义（Semantics）概念的理由：**维护主体不同**。数据字典（Schema）由数仓工程师维护，关注表结构；业务语义（Semantics）由业务/分析师维护，关注语义。合并后权责不清。若未来数据字典工具本身支持业务标注（business_name、entity、aliases），简单维度可直接从业务语义（Semantics）移除，由数据字典（Schema）承接。

```yaml
# 实体属性（CASE WHEN）：将原始字段分桶为离散分类值，用 known_values 记录枚举含义
# AI 看到 known_values 后，自动将"外部渠道客户"翻译为 WHERE sql_expr = '外部'
dimension_id: open_channel_type
name: 开户渠道大类
entity: customer
sql_expr: >
  CASE
    WHEN flavor_type IN ('external') THEN '外部'
    WHEN flavor_type IN ('internal') THEN '内部'
    ELSE '自然流量'
  END
source_table: data_product.product_fund_uid_register_source_cleaning_s
join_key: uid
aliases: [渠道大类, 渠道类型]

known_values:
  - value: "外部"
    name: "外部渠道"
  - value: "内部"
    name: "内部渠道"
  - value: "自然流量"
    name: "自然流量"
```

```yaml
# 场景二：计算属性，值无法从字段直接读取，用子查询定义每个取值的归属条件
# sql_condition 是完整的自包含子查询，AI 直接嵌入 WHERE，不再推导
# depends_on_events 仅作文档说明，不影响 sql_condition 的展开
#
# 重要：如果命名取值存在「同一模式、不同参数」的变体（如7天/14天/30天），
# 必须参数化，不能逐一枚举——枚举等于重新制造维护爆炸问题
dimension_id: customer_computed_tags
name: 客户计算标签
entity: customer

named_values:
  - value_id: daily_buyer
    name: 当日下单客户
    depends_on_events: [place_fund_order]
    sql_condition: >
      uid IN (
        SELECT uid FROM fundx_dwd.dwd_evt_parent_money_order_s
        WHERE dt = ${target_date}
      )
    aliases: [当日买入, 日活跃下单]

  - value_id: first_purchase_within_n_days
    name: 开户后N天内首购客户
    parameters:
      n: {type: integer, description: 开户后的天数窗口}
    depends_on_events: [account_open]
    sql_condition: >
      uid IN (
        SELECT r.uid
        FROM data_product.product_fund_uid_register_source_cleaning_s r
        JOIN fundx_dwd.dwd_evt_parent_money_order_s o
          ON r.uid = o.uid
         AND substr(o.init_time, 1, 10) >= r.open_date
         AND substr(o.init_time, 1, 10)
             <= date_format(date_add('day', ${n}, date(r.open_date)), '%Y-%m-%d')
      )
    aliases: [N日首购]
```

---

**业务语义（Semantics）的规模预估**：

| 类型 | 预估数量 | 说明 |
|------|----------|------|
| 实体（Entity） | 5–15 个 | 客户、基金产品、父单、定投计划、企微好友… 数量少且稳定 |
| 事件（Event） | 20–40 个 | 开户、买入、定投执行、SOP 触达、建联、私聊… |
| 维度（Dimension） | 30–50 个 | 开户渠道、产品大类、私域分群、SOP 业务线… |
| 命名维度取值 | 20–50 个 | 仅限 SQL 为计算表达式的业务概念，简单字段取值不维护 |
| **合计** | **~100 个** | 可穷尽、可维护 |

---

### 计算模式（Pattern）

**职责**：定义可复用的参数化 SQL 计算结构，**不含任何具体业务语义**。

**原则**：通用、业务无关，只关心「怎么算」。每个参数必须标注接受哪类业务语义（Semantics）引用——这是计算模式（Pattern）和业务语义（Semantics）协作的接口契约。

**参数类型约定（更好懂版）**：

先记两条总规则：

- **类型标注不是 SQL 类型，而是“你这个参数要传哪类知识对象”。**
- **`Dimension` 是属性轴，`NamedValue` 是该属性轴下的命名取值（标签）**。两者不是同一层级概念。

| 类型标注 | 参数输入形式（抽象） | SQL 展开结果（抽象） |
|---------|-------------------|--------------------|
| `Entity` | 传入一个实体标识 | 展开为该实体定义的主键字段 |
| `Event` | 传入一个事件标识 | 展开为该事件定义的来源表与事件条件 |
| `Dimension` | 传入一个或多个维度标识（属性轴） | 展开为维度定义的表达式，用于 `SELECT/GROUP BY` |
| `NamedValue` | 传入某个维度下的命名取值标识（可带参数） | 展开为该命名取值定义的过滤条件（含参数替换） |
| `integer / date / ...` | 传入字面量参数 | 直接替换模板变量 |

注：若参数类型声明为 `A | B`，表示该参数可传 A 或 B，并按实际传入类型选择对应展开规则。

**把上表翻成一句话**：

- `entity` 决定“按谁去重”（展开为该实体定义的主键字段，如 `uid`）。
- `group_by` 用 `Dimension`（按属性轴分组）。
- **过滤条件**在需求解析阶段可先抽象为一个"`filter_by`"概念；落到 Pattern 契约里，会展开为两个字段：
  - `event`：限定统计范围对应的业务过程，展开为 `FROM <表>` 与 `WHERE <type_condition>`。
  - `where_named_values` / `where_dimension_values`：对维度"命名取值"或"具体值"的过滤，展开为 `AND sql_condition` / `AND sql_expr = 'value'`。
- `integer/date` 这类普通参数只负责“填模板空位”。

---

```yaml
pattern_id: count_distinct
name: 去重计数
description: 统计满足条件的去重实体数（如日下单客户数、新开户客户数）
parameters:
  entity:
    type: Entity
    description: 统计哪类实体，决定 COUNT DISTINCT 使用哪个主键
  event:
    type: Event
    description: 统计范围对应的业务过程；展开为 FROM 表 + WHERE type_condition
  where_named_values:
    type: Dimension.NamedValue[]
    required: false
    description: 按命名分群过滤（多条取交集）
  where_dimension_values:
    type: list<{dimension_id, value}>
    required: false
    description: 按维度字段具体值过滤
  time_window:
    type: date_expression
    description: 时间范围（如 date = ${target_date}）
  group_by:
    type: Dimension[]
    required: false
    description: 可选分组维度，展开为 GROUP BY + SELECT 字段
sql_template: |
  SELECT
    ${group_by.expr, ...}                       -- 展开分组字段（若有）
    COUNT(DISTINCT ${entity.primary_key}) AS cnt
  FROM ${event.source_table}
  WHERE ${time_window}
    ${AND event.type_condition}
    ${AND where_dimension_values.sql_expr = value, ...}
    ${AND where_named_values.sql_condition, ...}
  ${GROUP BY group_by.expr, ...}                -- 展开分组（若有）
```

---

```yaml
pattern_id: cohort_retention
name: 队列留存率
description: 基准队列在 offset_days 天后的留存率
parameters:
  entity:
    type: Entity
    description: 统计主体（传入实体标识，展开为该实体的主键字段）
  cohort_event:
    type: Event
    description: D0 基准事件（定义同期群，如开户事件），决定基准表与基准日期字段
  retain_event:
    type: Event
    required: false
    description: D+N 留存判定事件（如 place_fund_order）；不填则默认从 entity 的 anchor_tables 取数
  retain_where_named_values:
    type: Dimension.NamedValue[]
    required: false
    description: 留存判断的命名分群过滤（多条取交集）
  retain_where_dimension_values:
    type: list<{dimension_id, value}>
    required: false
    description: 留存判断的维度取值过滤
  cohort_date:
    type: date_expr
    description: 基准日期条件（如 open_date = '2024-01-01'）
  offset_days:
    type: integer
    description: 留存窗口天数（1=次日，7=7日）
  group_by:
    type: Dimension[]
    required: false
    description: 可选分组维度
sql_template: |
  WITH cohort AS (
    SELECT
      ${entity.primary_key},
      ${cohort_event.date_field} AS cohort_date
      ${, group_by.expr ...}                          -- 展开分组字段（若有）
    FROM ${cohort_event.source_table}
    WHERE ${cohort_date}
  ),
  retained AS (
    SELECT DISTINCT ${entity.primary_key}
    FROM ${retain_event.source_table OR entity.anchor_tables[<key>]}
    WHERE ${AND retain_event.type_condition}
      ${AND retain_where_*.sql_condition, ...}
      AND date IN (SELECT date_add('day', ${offset_days}, cohort_date) FROM cohort)
  )
  SELECT
    ${group_by.expr, ...}
    COUNT(DISTINCT r.${entity.primary_key}) * 1.0
      / NULLIF(COUNT(DISTINCT c.${entity.primary_key}), 0) AS retention_rate
  FROM cohort c
  LEFT JOIN retained r USING (${entity.primary_key})
  ${GROUP BY group_by.expr, ...}
```

> 参数名历史：早期版本曾用 `base` / `retain` / `base_date_field`，已统一为 `cohort_event` / `retain_event` / `cohort_date`；以 [knowledge/patterns/cohort_retention.yaml](../knowledge/patterns/cohort_retention.yaml) 为唯一口径。

---

```yaml
pattern_id: sum_metric
name: 求和指标
description: 对事件中的某个度量字段求和（如下单金额、SOP 触达条数）
parameters:
  sum_field:
    type: string
    description: 求和的字段名（如 init_amount）
  event:
    type: Event
    required: false
    description: 事件型指标必填；快照型指标用 entity + anchor_table 代替
  entity:
    type: Entity
    required: false
    description: 快照型指标统计实体
  anchor_table:
    type: string (entity.anchor_tables 的 key)
    required: false
    description: 快照型指标使用的锚表 key
  where_named_values:
    type: Dimension.NamedValue[]
    required: false
    description: 按命名分群过滤
  where_dimension_values:
    type: list<{dimension_id, value}>
    required: false
    description: 按维度字段具体值过滤
  time_window:
    type: date_expression
    description: 时间范围
  group_by:
    type: Dimension[]
    required: false
    description: 可选分组维度
sql_template: |
  SELECT
    ${group_by.expr, ...}
    SUM(${sum_field}) AS total
  FROM ${event.source_table | entity.anchor_tables[anchor_table]}
  WHERE ${time_window}
    ${AND event.type_condition}
    ${AND where_dimension_values.sql_expr = value, ...}
    ${AND where_named_values.sql_condition, ...}
  ${GROUP BY group_by.expr, ...}
```

---

**计算模式（Pattern）的规模预估**：

| 模式 | 典型指标覆盖 |
|------|------------|
| count_distinct | 日下单客户数 / 新开户客户数 / 近 N 日下单客户（滚动窗口）|
| cohort_retention | 新客次月复购 / 7 日内首购 / 开户后 N 日复购 |
| sum_metric | 下单金额 / SOP 成功触达条数 / 近 N 日求和（滚动窗口）|
| 比值类（无独立模式）| SOP 触达后 7 日内首购率（分子分母各用 count_distinct / sum_metric 计算）|
| **合计 ~8–12 个** | **覆盖大部分常见业务指标** |

---

### 指标目录（Metric）

**职责**：声明「这个指标 = 哪个模式 + 哪些语义原子的组合」。

**原则**：极薄，不写定义、不写 SQL，只写配方。AI 通过 语义 + 模式（Semantics+Pattern） 推导出完整 SQL。

**指标目录（Metric）的字段结构 = 通用字段 + 模式专属字段**：

| 字段 | 类型 | 是否必填 | 说明 |
|------|------|---------|------|
| `metric_id` | string | 必填 | 唯一标识符 |
| `name` | string | 必填 | 业务名称 |
| `pattern` | 计算模式（Pattern） ID | 必填 | 使用哪个计算模式 |
| `entity` | 实体（Entity） ID | 必填 | 统计主体（决定 COUNT DISTINCT 的主键）|
| `group_by` | 维度（Dimension） ID[] | 可选 | 分组维度，对所有模式通用 |
| `extends` | 指标目录（Metric） ID | 可选 | 继承另一个指标配方，只覆盖差异字段 |
| *(模式专属字段)* | 由 pattern 决定 | 按 pattern 要求 | 参考 计算模式（Pattern）中该 pattern 的参数定义 |

**模式专属字段不是「不标准」，而是「按 pattern 的接口契约填参数」**——就像调用不同函数时入参不同，是正常设计。每个 pattern 在 计算模式（Pattern）里已声明了需要哪些参数及其类型，指标目录（Metric） 只是在调用。

```yaml
metric_id: daily_buying_customer
name: 日下单客户数
pattern: count_distinct
entity: customer              # 实体（Entity）
event: fund_purchase          # 业务过程（Event）→ FROM + type_condition
time_window: dt = ${target_date}
```

```yaml
metric_id: d1_repurchase_new_customer
name: 新开户客户次日复购率
pattern: cohort_retention
entity: customer
cohort_event: customer_open   # 基准事件：开户
cohort_date: open_date = ${target_date}
retain_event: place_fund_order  # 留存事件
retain_where_named_values:
  - dimension_id: customer_lifecycle
    value_id: new_customer    # 「新开户客户（开户后 ≤30 天）」命名分群
offset_days: 1
```

```yaml
metric_id: d1_repurchase_new_customer_by_channel
name: 新开户客户次日复购率（按开户渠道）
extends: d1_repurchase_new_customer
group_by: [open_channel]      # 维度（Dimension）
```

**指标目录（Metric）的真正职责**：

指标目录（Metric） **不需要枚举所有 1000 个指标**。它只需要记录满足以下任一条件的指标：

1. **有正式业务命名**，需要锁死口径防止歧义
2. **计算方式有例外**，偏离通用模式
3. **高频使用**，需要作为「标准答案」对齐上下文

大多数临时查询（「外部渠道客户 14 日复购按产品大类」），AI 可以直接从 业务语义 + 计算模式（Semantics + Pattern） 即时组合，**不需要在 指标目录（Metric）中预先定义**。

---

## 四、为什么这样设计是 MECE 且解耦的

### 层与层之间的边界

| 边界 | 左侧说什么 | 右侧说什么 |
|------|-----------|-----------|
| 数据字典 ↔ 业务语义 | 「字段名叫 trade_mode，类型是 string」 | 「trade_mode IN (...) 这个组合是业务过程 place_fund_order」 |
| 数据字典 ↔ 业务语义 | 「表里有 flavor 字段」 | 「flavor 是 customer 实体的维度，别名是开户渠道」 |
| 数据字典 ↔ 业务语义 | 「product_fund_uid_register_source_cleaning_s 有 uid 主键」 | 「uid 是实体 customer 的 primary_key」 |
| 业务语义 ↔ 计算模式 | 「实体/业务过程/维度展开后是什么 SQL 条件」 | 「cohort_retention 模板怎么拼装这些条件」 |
| 计算模式 ↔ 指标目录 | 通用参数化模板，不含任何业务 ID | 具体配方：指定 pattern + 填入实体/业务过程/维度的 ID |

每一层只知道自己层的事，向下引用，不向上渗透。

### 修改影响范围精确

| 场景 | 现有方案 | 新方案 |
|------|----------|--------|
| 「主动买入」trade_mode 口径变更 | 修改多处文档（glossary + metrics + calculation_rules） | 修改 业务语义（Semantics）的 `place_fund_order`（1处） |
| 新增「30 日复购」指标 | 新写一份完整文档 | 指标目录（Metric） 加一行 `offset_days: 30` |
| 复购率公式逻辑调整 | 修改所有复购相关计算规则 | 修改 计算模式（Pattern）的 `cohort_retention` 模板（1处） |
| AI 生成 SQL 出错 | 不知道是哪层的问题 | 精确定位：业务语义（Semantics）/ 计算模式（Pattern）/ 指标目录（Metric）|

---

## 五、AI 的推导路径

```
用户：「昨天外部渠道新开户客户的次日复购」
           ↓
指标目录（Metric）：找到最相近的指标配方（或即时组合）
  pattern: cohort_retention
  entity: customer
  cohort_event: customer_open        ← 业务过程（Event） ID
  cohort_date: open_date = ${target_date}
  retain_event: place_fund_order     ← 业务过程（Event） ID
  retain_where_named_values:
    - dimension_id: customer_lifecycle
      value_id: external_new_customer ← 维度（Dimension） 命名取值 ID
  offset_days: 1
  group_by: [open_channel]           ← 维度（Dimension） ID
           ↓
计算模式（Pattern）：cohort_retention 模板，按参数类型解析各引用
           ↓
业务语义（Semantics）展开：
  entity: customer
    → 实体（Entity）：primary_key = uid
  cohort_event: customer_open
    → 业务过程（Event）：source_table = <开户事件表>，date_field = open_date
  retain_event: place_fund_order
    → 业务过程（Event）：source_table = fundx_dwd.dwd_evt_parent_money_order_s
               type_condition = trade_mode IN ('apply','subscribe')
  retain_where_named_values.external_new_customer
    → 维度（Dimension） 命名取值：sql_condition = (开户后 ≤30 天且 flavor_type='external' 的子查询)
  group_by: open_channel
    → 维度（Dimension）：sql_expr = flavor，
                        source_table = data_product.product_fund_uid_register_source_cleaning_s
           ↓
数据字典（Schema）：验证表名、字段名、分区键存在
           ↓
生成 SQL，每个片段可追溯到具体的业务语义定义
```

**排错路径**：SQL 出错时，检查点精确独立：
- **实体（Entity）**：`customer` 的 `primary_key` 对吗？
- **业务过程（Event）**：`place_fund_order` 的 `type_condition` 包含了哪些 trade_mode？
- **维度（Dimension）**：`external_new_customer` 的 `sql_condition` 是否正确？`open_channel` 字段来自哪张表？
- **计算模式（Pattern）**：`cohort_retention` 的 JOIN 类型和时间计算逻辑对吗？
- **指标目录（Metric）**：`offset_days` 填的是 1 还是 7？`cohort_event` 和 `retain_event` 引用对了吗？

五个独立检查点，不需要全文档 diff。

---

## 六、与现有设计 / OneData 的对应关系

### 与现有知识库的对应

新架构不是推翻现有工作，而是对信息的**重新组织方式**：

| 现有层 | 对应新层 | 需要做的事 |
|--------|----------|------------|
| glossary.md 中的别名/黑话部分 | 业务语义（Semantics）的 aliases 字段 | 整合进语义原子定义 |
| glossary.md 中的数据口径部分 | 业务语义（Semantics）的 sql_condition | 提炼成精确的 SQL 条件 |
| dimensions/ | 业务语义（Semantics）的维度（Dimension）原子 | 简化为字段映射 |
| metrics/ 中的计算公式 | 计算模式（Pattern） + 指标目录（Metric）配方 | 抽象出模式，指标变成一行配方 |
| calculation_rules/ | 计算模式（Pattern）（带参数的 SQL 模板） | 去掉具体指标的例子，变成通用模板 |

### 与 OneData 方法论的对应

本框架与 OneData 的核心思路一脉相承，差别主要在工程表达形式：

| 本框架 | OneData 概念 | 说明 |
|--------|-------------|------|
| 实体（Entity） | **业务对象 / 维度主表** | 业务过程和维度 的锚点；OneData 中对应维度建模里的实体主表 |
| 业务过程（Event） | **业务过程** | 几乎完全一致，都是最原子的业务活动 |
| 维度（Dimension） | **维度** | 直接对应，实体的业务属性 |
| 维度（Dimension） 命名维度取值 | **修饰词** | OneData 的修饰词 = 维度某个具名取值的封装，两者等价 |
| 计算模式（Pattern） | **度量 + 统计方式** | OneData 中度量关注「算什么」，Pattern 关注「怎么算」 |
| 指标目录（Metric） 指标配方 | **派生指标** | 原子指标 + 修饰词 + 时间周期，结构完全对应 |

**关键差异**：OneData 在业务过程和派生指标之间有一层「**原子指标**」（业务过程 + 度量），本框架目前将其隐含在 计算模式（Pattern）里，未显式命名。如果业务复杂度增加、存在大量共享「中间计算结果」的场景，可以考虑补充这一层。

---

## 七、维护成本对比

### 新增一个标准指标（如「私域客户 7 日复购率」）

**现有方案**：写一份包含定义、口径、SQL、注意事项的完整文档（~50 行）

**新方案**：
```yaml
metric_id: d7_repurchase_private_domain
name: 私域客户7日复购率
pattern: cohort_retention
entity: customer
cohort_event: customer_open    # 基准事件：开户
cohort_date: open_date = ${target_date}
retain_event: place_fund_order # 业务过程（Event）
retain_where_named_values:
  - dimension_id: customer_lifecycle
    value_id: private_domain_customer  # 维度命名取值，已在业务语义（Semantics）中定义
offset_days: 7
```

### 修改「公募主动买入」的范围

**现有方案**：搜索所有文档中提到「主动买入」的地方，逐一修改，容易遗漏

**新方案**：修改 业务语义（Semantics）中 `place_fund_order` 的 `type_condition` 一处，所有依赖它的指标自动更新

### 真正需要持续维护的内容

| 层 | 维护频率 | 维护成本 |
|----|----------|----------|
| 数据字典（Schema） | 随数仓变动 | 低，可自动化 |
| 业务语义（Semantics） | 口径有争议时 | 中，但数量有上限（~100条） |
| 计算模式（Pattern） | 极少（通用模式稳定） | 低 |
| 指标目录（Metric） | 新增「命名指标」时 | 极低（每条 4–8 行配置） |

---

## 八、设计原则总结

1. **单一事实来源**：每个业务语义只在一个地方定义（业务语义（Semantics）），不在多层重复描述
2. **组合而非枚举**：知识库的价值在于「组合能力」，不在于「预存答案数量」
3. **越高层越薄**：指标目录（Metric） 是最薄的一层，不应该承载定义职责
4. **可穷尽的边界**：真正需要维护的原子（业务语义（Semantics））和模式（计算模式（Pattern））是有限的
5. **改一处，影响全局**：口径变更只动业务语义（Semantics），模式调整只动计算模式（Pattern）

---

## 九、尚待讨论的问题

**业务过程（Event）多表来源**

当前设计假设一个业务过程对应一张表的一批行（`source_table` 为单值），但存在若干边界场景：

| 场景 | 例子 | 当前设计能否处理 |
|------|------|----------------|
| 按业务线/产品分表 | 公募父单 + 私募父单分表存储 | ❌ |
| 历史表 + 现状表 | `dwd_evt_parent_money_order_2023` + `..._2024` | ❌ |
| 事件识别需要跨表 JOIN | 「首购」= 父单表 JOIN 首购汇总表 | ❌ |
| 多事件共存一张表（已覆盖） | 父单表按 `trade_mode` 区分申购/认购/定投 | ✅ |

**待讨论**：两种可行扩展方向，各有取舍——
- **方案 A**：`source_table` 支持数组，隐含 `UNION ALL` 语义，结构化、仅解决分表场景
- **方案 B**：引入 `source_sql` 字段，允许任意子查询，灵活但退化为「把 SQL 藏进语义层」，与设计原则有张力

---

**业务语义（Semantics）粒度与边界**
- 业务过程（Event）的粒度如何决定？（「申购」和「认购」分开还是合并成「主动买入」？合并的依据是什么？）
- 维度（Dimension）命名取值的参数化边界：哪些情况应该参数化（如 `purchased_within_n_days`），哪些应该具名定义（如 `new_customer`）？判断标准是「业务上有没有独立命名」还是「是否存在变体」？
- 简单维度与数据字典（Schema）的合并条件：如果数据字典工具支持业务标注，两者何时可以合并？

**实体（Entity）相关**
- 当实体没有 `anchor_table` 时，AI 如何决定 JOIN 起点？是从每个维度的 `source_table` 逐一推导，还是需要其他规则？
- 跨实体的指标（如「每个产品的平均买入客户数」涉及 fund_product 和 customer 两个实体）应该在哪层处理？

**计算模式（Pattern） 与测试**
- 计算模式（Pattern）的模式如何测试？模板参数组合的正确性如何验证？
- `group_by` 参数涉及 JOIN，不同维度来自不同表，JOIN 顺序和去重是否会有问题？

**指标目录（Metric） 边界**
- 哪些指标需要在指标目录（Metric）「命名锁定」，哪些可以即时推导？锁定的判断标准是口径争议历史还是使用频率？

**迁移**
- 现有文档（glossary、metrics、calculation_rules）如何向新架构迁移？渐进重构还是一次性重写？

---

**维护日志**

| 日期 | 内容 |
|------|------|
| 2026-04-09 | 初稿，基于与团队的架构讨论整理 |
| 2026-04-09 | 迭代：引入 实体（Entity）层；B2 合并分群与维度；计算模式（Pattern） 参数类型系统化；指标目录（Metric） 示例对齐新参数名 |
| 2026-04-09 | 补充「业务过程多表来源」为待讨论问题，列出方案 A（数组+UNION ALL）和方案 B（source_sql）的取舍 |
| 2026-04-14 | 迭代维度设计：明确维度值必须是有限离散分类值；将"字段级维度/计算标签"改为"实体属性/计算属性"；新增 `known_values` 概念；实体新增 `id_aliases` 字段；`sum_metric` 新增 `extra_conditions` 参数，修正 `time_window` 仅用于时间过滤的语义 |
| 2026-04-20 | 清理虚构通用增长示例（user/post/order/DAU/留存）替换为本仓库真实业务示例（蛋卷客户/基金产品/公募买入父单/SOP 触达/复购等），所有示例表名对齐 `knowledge/schema/tables/` 中真实表 |
| 2026-04-20 | 进一步收敛：去除 Pattern 规模表中尚未落地的 funnel / period_over_period / 月活跃客户数 / 渠道转化率 等未确认条目；`cohort_retention.entity.description` 中的「通常是 user」改为中性描述 |
| 2026-04-20 | 结构性对齐：（1）`cohort_retention` 参数统一为 `cohort_event`/`retain_event`/`cohort_date`，示例 Metric 同步重写；（2）Pattern 示例中的 `filter_by` 拆分为 `event` + `where_named_values` + `where_dimension_values` 三个字段，解析阶段仍保留 `filter_by` 抽象；（3）实体示例 `anchor_table: <string>` 改为字典 `anchor_tables: {<key>: <table>}`，与 `knowledge/semantics/templates/entity.yaml` 对齐 |
