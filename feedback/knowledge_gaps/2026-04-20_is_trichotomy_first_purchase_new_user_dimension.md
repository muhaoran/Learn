# 知识缺口记录：首购品类分群维度缺失

- **日期**：2026-04-20
- **缺失类型**：维度（业务命名分群） + 附带表字段缺失
- **优先级**：高
- **状态**：处理中（主缺口已落盘为通用参数化维度 `first_purchase_category`，次缺口待补 DWS 字段）

---

## 原始需求

```
跑一下25年4月、5月，两个自然月内，首购品类为三分法的用户，截止到2026年4月16日，
新客人均三分法持仓。并给出分子分母的指标参数。
```

在编写分子指标（`new_user_trichotomy_holding_amount`）的 `where_named_values` 时，
需要引用一个"首购品类为三分法的新客"命名分群维度，检索后发现知识库不存在对应定义。

## 缺失内容描述

### 主缺口：维度 `is_trichotomy_first_purchase_new_user`（或更通用的 `first_purchase_category`）

- **缺失定位**：`knowledge/semantics/dimensions/` 下没有"首购品类分群"类维度
- **现状**：
  - `dimensions/is_trichotomy_user.yaml`：只描述"当前是否有三分法持仓"（快照维度，不含"首购"语义）
  - `dimensions/invest_account_code.yaml`：是字段级别的取值维度，不具备"新客 + 首购时间窗"的参数化分群能力
- **所需能力**：以 `(window_start, window_end, category_field, category_value)` 为参数，产出 `uid IN (...)` 的命名分群 SQL 条件
- **当前 AI 的临时处理**：在生成 SQL 时用内联 CTE（`old_buyers` + `first_buy_in_range` + `new_tri_users`）兜底实现，并在指标 YAML 的 `where_named_values` 中使用了 `is_trichotomy_first_purchase_new_user` 作为占位 `dimension_id`（该 ID 实际并未入库）

### 次缺口：`dws_evt_parent_money_first_trade_s` 字段未录入

- **缺失定位**：`knowledge/schema/tables/dws_evt_parent_money_first_trade.yaml` 的 `columns: []` 为空
- **影响**：
  - `events/first_fund_purchase.yaml` 虽已指向该 DWS 首购汇总表，但因字段未录入，AI 无法直接基于 DWS 取"首购日期 + 首购品类"
  - 被迫退化为在 DWD 父单表 `dwd_evt_parent_money_order_s` 上用 `ROW_NUMBER() + 历史分区反连接` 兜底识别"人生首购"，扫描量大、性能差
- **所需字段（推断，需业务侧确认）**：
  - `uid`（bigint）
  - `first_purchase_date`（date / varchar，人生首购日）
  - `first_purchase_invest_account_code`（varchar，首购子账户 / 品类）
  - `first_purchase_amount`（decimal，首购金额）
  - `first_purchase_pro_code` / `first_purchase_pro_type` 等产品维度
  - `dt`（date，分区）

---

## 缺失分类

**类型**：

- [x] 维度或命名标签 → `knowledge/semantics/dimensions/`
  - 推荐新增：`is_trichotomy_first_purchase_new_user.yaml`（专用命名分群，开箱即用）
  - 更佳方案：同时新增参数化维度 `first_purchase_category.yaml`（参数：`category_field`、`category_value`、`window_start`、`window_end`），上述专用维度可退化为其一个命名特化
- [x] 数据表 / 字段信息 → `knowledge/schema/tables/dws_evt_parent_money_first_trade.yaml`
  - 补齐 `columns` 列表；字段补齐后，新增维度的 `sql_condition` 可简化为单表过滤
- [x] 指标口径 → `knowledge/metrics/`
  - 未正式落盘：`trichotomy_first_purchase_new_user_count.yaml`（分母，count_distinct）
  - 未正式落盘：`new_user_trichotomy_holding_amount.yaml`（分子，sum_metric 快照型）

---

## 推荐落盘内容（维度定义草案）

### 方案 A：专用命名分群维度（开箱即用）

`knowledge/semantics/dimensions/is_trichotomy_first_purchase_new_user.yaml`

```yaml
dimension_id: "is_trichotomy_first_purchase_new_user"
name: "是否首购品类为三分法的新客"
entity: "user"
description: |
  参数化分群：在给定时间窗内人生首购（最早一笔公募主动买入）
  且首单 invest_account_code='TRICHOTOMY' 的去重用户。
aliases:
  - "三分法首购新客"
  - "首购即三分法的新客"
  - "首购品类为三分法的新客"

named_values:
  - value_id: "is_tri_first_purchase_new_user"
    name: "是"
    parameters:
      window_start:
        type: date
        description: "首购窗口起点（含）"
      window_end:
        type: date
        description: "首购窗口终点（含）"
    depends_on_events:
      - fund_purchase
    sql_condition: |
      uid IN (
        WITH old_buyers AS (
          SELECT DISTINCT uid
          FROM fundx_dwd.dwd_evt_parent_money_order_s
          WHERE dt < DATE ${window_start}
            AND is_private = 0
            AND trade_mode IN (1,2,3,4,5)
            AND substr(init_time,1,10) < ${window_start}
        ),
        first_buy_in_range AS (
          SELECT uid, invest_account_code,
                 ROW_NUMBER() OVER (
                   PARTITION BY uid
                   ORDER BY init_time ASC, batch_order_serial_no ASC
                 ) AS rn
          FROM fundx_dwd.dwd_evt_parent_money_order_s
          WHERE dt BETWEEN DATE ${window_start} AND DATE ${window_end}
            AND is_private = 0
            AND trade_mode IN (1,2,3,4,5)
            AND substr(init_time,1,10) BETWEEN ${window_start} AND ${window_end}
        )
        SELECT f.uid
        FROM first_buy_in_range f
        LEFT JOIN old_buyers o ON f.uid = o.uid
        WHERE f.rn = 1
          AND f.invest_account_code = 'TRICHOTOMY'
          AND o.uid IS NULL
      )
notes:
  - "DWS 首购汇总表字段补齐后，sql_condition 可简化为对 dws_evt_parent_money_first_trade_s 的单表过滤"
  - "'人生首购'口径：全历史父单中该 uid 最早一笔；如仅看'参与窗口内的首笔（不排除窗口前已有买入）'，应移除 old_buyers 反连接"
```

### 方案 B：通用参数化维度 + 命名特化（推荐长期方向）

- 新增 `knowledge/semantics/dimensions/first_purchase_category.yaml`
  - 参数：`category_field`（如 `invest_account_code`、`basi_type_name_trans`、`pro_type`）、`category_value`、`window_start`、`window_end`
- 保留 `is_trichotomy_first_purchase_new_user` 作为其在 `category_field=invest_account_code, category_value=TRICHOTOMY` 下的命名特化；也可再派生 `is_mixed_fund_first_purchase_new_user` 等

---

## 后续计划

- **负责人**：ChatBI 知识库维护人
- **关联知识库文件**：
  - `knowledge/semantics/dimensions/is_trichotomy_first_purchase_new_user.yaml`（待新增）
  - `knowledge/semantics/dimensions/first_purchase_category.yaml`（可选，长期推荐）
  - `knowledge/schema/tables/dws_evt_parent_money_first_trade.yaml`（待补 `columns`）
  - `knowledge/metrics/trichotomy_first_purchase_new_user_count.yaml`（待新增）
  - `knowledge/metrics/new_user_trichotomy_holding_amount.yaml`（待新增）
- **临时处理方式**：
  - 在维度未落盘前，AI 应在生成 SQL 时显式声明"此分群无命名维度，采用内联 CTE 实现"，并**不得**在指标 YAML 中使用未入库的 `dimension_id`
  - 本次已生成的 HTML 报告与 SQL 保持不变，SQL 使用内联 CTE 口径正确，仅指标 YAML 中的 `where_named_values` 属于占位，需待维度落盘后回填正式 `dimension_id`

## 完成情况

- [x] 已补充到知识库：新增通用参数化维度 `knowledge/semantics/dimensions/first_purchase_category.yaml`
      （覆盖"首购品类命中/未命中 + 可切换 category_field/category_value"的参数化分群；
      `is_trichotomy_first_purchase_new_user` 作为其命名特化使用，暂不额外落盘）
- [ ] 指标口径 `trichotomy_first_purchase_new_user_count` / `new_user_trichotomy_holding_amount`
      应用侧决定暂不落盘（metrics 先不入库）
- [ ] DWS 首购汇总表字段仍待补录；补录后维度内 `sql_condition` 可改写为对 DWS 的单表过滤
- [ ] 已验证 AI 可以正确处理相关需求（待下一次同类需求复测）

## 关联工单

- `feedback/new_cases/2026-04-20_trichotomy_first_purchase_new_user_holding.md`（同需求触发的新案例记录）
