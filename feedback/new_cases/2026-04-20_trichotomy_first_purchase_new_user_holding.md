# 新需求类型记录：首购品类为三分法新客的人均三分法持仓

- **日期**：2026-04-20
- **复用预期**：高（"某窗口内首购品类=X 的新客，截止某日 X 品类人均持仓"是典型的"品类新客留存金额"分析范式）
- **优先级**：高
- **状态**：待处理

---

## 原始需求

```
跑一下25年4月、5月，两个自然月内，首购品类为三分法的用户，截止到2026年4月16日，新客人均三分法持仓。
并给出分子分母的指标参数。
```

## 需求拆解

- **新客定义**：人生第一笔公募主动买入落在 2025-04-01 ~ 2025-05-31
- **品类限定**：该首单的 `invest_account_code = 'TRICHOTOMY'`（首购即进入三分法）
- **观察时点**：2026-04-16（快照日）
- **指标**：新客在观察日的三分法子账户人均持仓金额
  - 分子：该新客群在 `dt='2026-04-16'`、`invest_account_code='TRICHOTOMY'`、`volume>0` 的持仓 amount 合计
  - 分母：该新客群去重数量

## 最终 SQL

```sql
WITH
old_buyers AS (
    SELECT DISTINCT uid
    FROM fundx_dwd.dwd_evt_parent_money_order_s
    WHERE dt < DATE '2025-04-01'
      AND is_private = 0
      AND trade_mode IN (1, 2, 3, 4, 5)
      AND substr(init_time, 1, 10) < '2025-04-01'
),
first_buy_in_range AS (
    SELECT
        uid,
        invest_account_code,
        init_time,
        ROW_NUMBER() OVER (
            PARTITION BY uid
            ORDER BY init_time ASC, batch_order_serial_no ASC
        ) AS rn
    FROM fundx_dwd.dwd_evt_parent_money_order_s
    WHERE dt BETWEEN DATE '2025-04-01' AND DATE '2025-05-31'
      AND is_private = 0
      AND trade_mode IN (1, 2, 3, 4, 5)
      AND substr(init_time, 1, 10) BETWEEN '2025-04-01' AND '2025-05-31'
),
new_tri_users AS (
    SELECT f.uid
    FROM first_buy_in_range f
    LEFT JOIN old_buyers o
           ON f.uid = o.uid
    WHERE f.rn = 1
      AND f.invest_account_code = 'TRICHOTOMY'
      AND o.uid IS NULL
),
tri_holding_0416 AS (
    SELECT
        uid,
        SUM(amount) AS tri_amount
    FROM fundx_dwd.dwd_ast_pub_daily_holding_detail_i
    WHERE dt = DATE '2026-04-16'
      AND invest_account_code = 'TRICHOTOMY'
      AND volume > 0
    GROUP BY uid
)
SELECT
    COUNT(DISTINCT u.uid)                                             AS denominator_new_user_cnt,
    COALESCE(SUM(h.tri_amount), 0)                                    AS numerator_tri_holding_amt,
    COALESCE(SUM(h.tri_amount), 0) / NULLIF(COUNT(DISTINCT u.uid), 0) AS avg_tri_holding_per_user
FROM new_tri_users u
LEFT JOIN tri_holding_0416 h
       ON h.uid = u.uid;
```

## 为什么是"新"需求

现有资产覆盖情况：
- `metrics/trichotomy_transfer_in_success_user_count` 是"迁入"视角，与"首购品类=三分法"不等价（前者不计买单直入三分法的用户）。
- `metrics/fund_purchase_user_count` 覆盖主动买入人数，但没有"限定首购 + 限定首购品类"的组合。
- `semantics/events/first_fund_purchase` 指向 `dws_evt_parent_money_first_trade_s`，但该 DWS 表字段尚未录入知识库，导致"人生首购 + 首购品类"无法直接从 DWS 取，需要在 DWD 父单上用 ROW_NUMBER + 历史排除来兜底。
- `semantics/dimensions/is_trichotomy_user` 只描述"当前是否有三分法持仓"，没有"首购品类=三分法"这个基于事件的分群维度。

因此这是一个典型的"首购品类分群 × 快照持仓金额 × 人均"组合比值指标，现有 metrics/dimensions 不能直接套用。

## 复用结构分析

抽象出的可复用范式：**"首购品类为 X 的新客，截止日 T 在 X 品类的人均持仓 / 留存金额 / 留存率"**。

可参数化要素：
- `first_purchase_window`：首购时间窗（start_date, end_date）
- `first_purchase_category`：首购品类标识（如 `invest_account_code`、`basi_type_name_trans`、`pro_type`）
- `first_purchase_category_value`：品类取值（如 `'TRICHOTOMY'`、`'混合型'`）
- `snapshot_date`：快照日 T
- `holding_filter`：快照侧过滤（品类限定、`volume > 0` 等）
- `numerator_agg`：分子聚合（SUM(amount) 留存金额 / COUNT(DISTINCT uid) 留存人数）

模板骨架：

```sql
WITH
old_buyers AS (
    SELECT DISTINCT uid
    FROM <fund_purchase_event_table>
    WHERE dt < DATE '<window_start>'
      AND <fund_purchase.type_condition>
      AND substr(init_time,1,10) < '<window_start>'
),
first_buy_in_range AS (
    SELECT
        uid,
        <first_purchase_category_field> AS category,
        init_time,
        ROW_NUMBER() OVER (
            PARTITION BY uid
            ORDER BY init_time ASC, <tiebreaker>
        ) AS rn
    FROM <fund_purchase_event_table>
    WHERE dt BETWEEN DATE '<window_start>' AND DATE '<window_end>'
      AND <fund_purchase.type_condition>
      AND substr(init_time,1,10) BETWEEN '<window_start>' AND '<window_end>'
),
new_category_users AS (
    SELECT f.uid
    FROM first_buy_in_range f
    LEFT JOIN old_buyers o ON f.uid = o.uid
    WHERE f.rn = 1
      AND f.category = '<first_purchase_category_value>'
      AND o.uid IS NULL
),
holding_snapshot AS (
    SELECT uid, SUM(amount) AS category_amount
    FROM <holding_snapshot_table>
    WHERE dt = DATE '<snapshot_date>'
      AND <holding_filter>
    GROUP BY uid
)
SELECT
    COUNT(DISTINCT u.uid)                                              AS denominator_cnt,
    COALESCE(SUM(h.category_amount), 0)                                AS numerator_amt,
    COALESCE(SUM(h.category_amount),0) / NULLIF(COUNT(DISTINCT u.uid),0) AS avg_per_user
FROM new_category_users u
LEFT JOIN holding_snapshot h ON h.uid = u.uid;
```

DWS 首购汇总表字段补齐后，该模板前两段 CTE 可替换为一次性查 `dws_evt_parent_money_first_trade_s` 以取 `first_purchase_date` + `first_purchase_category`，显著降低扫描量。

---

## 沉淀建议

**类型**：

- [x] 新指标 → `knowledge/metrics/trichotomy_first_purchase_new_user_count.yaml`
  - 指标名：首购品类为三分法的新客数
  - 计算口径：人生首购落在参数时间窗 且 首单 `invest_account_code='TRICHOTOMY'`
  - 复用的 pattern：`count_distinct`
- [x] 新指标 → `knowledge/metrics/new_user_trichotomy_holding_amount.yaml`
  - 指标名：新客三分法持仓金额（快照）
  - 计算口径：限定人群下，快照日 `invest_account_code='TRICHOTOMY' AND volume>0` 的 `SUM(amount)`
  - 复用的 pattern：`sum_metric`（快照型）
- [x] 新业务概念（维度）→ `knowledge/semantics/dimensions/first_purchase_category.yaml`
  - 类型：dimension
  - 名称：首购品类 / 首购子账户
- [x] 新计算模式候选 → 观察同类需求频次，待 2~3 次复用后抽象为 `knowledge/patterns/first_purchase_cohort_snapshot_ratio.yaml`
- [ ] 新表或字段 → 建议在 `knowledge/schema/tables/dws_evt_parent_money_first_trade.yaml` 补录 columns（至少需要 `uid`、`first_purchase_date`、`first_purchase_invest_account_code` 或等价字段）；补齐后本指标 SQL 可大幅简化

---

## 后续计划

- **负责人**：ChatBI 知识库维护人
- **关联知识库文件**：
  - `knowledge/metrics/trichotomy_first_purchase_new_user_count.yaml`（待新增）
  - `knowledge/metrics/new_user_trichotomy_holding_amount.yaml`（待新增）
  - `knowledge/semantics/dimensions/first_purchase_category.yaml`（待新增）
  - `knowledge/schema/tables/dws_evt_parent_money_first_trade.yaml`（待补录 columns）
- **临时处理方式**：在 DWS 首购表字段补齐前，按本案 SQL 的 DWD 兜底方案生成；老客排除分区扫描范围较大，必要时限制 `dt >= DATE '2020-01-01'` 等业务上线边界以加速。

## 完成情况

- [x] 已抽出可复用结构（见上方抽象模板）
- [ ] 已沉淀到对应的 `knowledge/` 文件
- [ ] 已验证沉淀后 AI 能正确处理同类需求
