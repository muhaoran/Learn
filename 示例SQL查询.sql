-- ============================================================================
-- 公募基金交易系统 - 示例SQL查询
-- 功能：查询指定账户的基金持仓明细及收益情况（包含基金详情和近期交易记录）
-- ============================================================================

-- 查询账户'A20240001'的所有基金持仓，按收益率降序排列
-- 关联基金信息表获取基金类型和管理公司
-- 同时统计每只基金的近期交易次数
SELECT 
    ap.account_id AS '账户ID',
    ap.account_name AS '账户名',
    ap.fund_code AS '基金代码',
    fi.fund_name AS '基金名称',
    fi.fund_type AS '基金类型',
    fi.fund_company AS '管理公司',
    fi.fund_manager AS '基金经理',
    fi.risk_level AS '风险等级',
    ap.total_share AS '持有份额',
    ap.available_share AS '可用份额',
    ap.frozen_share AS '冻结份额',
    ap.average_cost AS '持仓成本价',
    ap.current_nav AS '当前净值',
    ap.total_cost AS '总成本(元)',
    ap.market_value AS '当前市值(元)',
    ap.profit_loss AS '浮动盈亏(元)',
    CONCAT(ROUND(ap.profit_rate, 2), '%') AS '收益率',
    ap.accumulated_dividend AS '累计分红(元)',
    ap.first_purchase_date AS '首次购买日期',
    ap.holding_days AS '持有天数',
    ap.last_transaction_date AS '最近交易日期',
    COUNT(ft.transaction_id) AS '近30天交易次数',
    ap.position_status AS '持仓状态'
FROM 
    account_position ap
INNER JOIN 
    fund_info fi ON ap.fund_code = fi.fund_code
LEFT JOIN 
    fund_transaction ft ON ap.account_id = ft.account_id 
                       AND ap.fund_code = ft.fund_code
                       AND ft.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                       AND ft.transaction_status = 'CONFIRMED'
WHERE 
    ap.account_id = 'A20240001'
    AND ap.position_status = 'NORMAL'
    AND ap.total_share > 0
    AND fi.status = 'ACTIVE'
GROUP BY 
    ap.position_id,
    ap.account_id,
    ap.account_name,
    ap.fund_code,
    fi.fund_name,
    fi.fund_type,
    fi.fund_company,
    fi.fund_manager,
    fi.risk_level,
    ap.total_share,
    ap.available_share,
    ap.frozen_share,
    ap.average_cost,
    ap.current_nav,
    ap.total_cost,
    ap.market_value,
    ap.profit_loss,
    ap.profit_rate,
    ap.accumulated_dividend,
    ap.first_purchase_date,
    ap.holding_days,
    ap.last_transaction_date,
    ap.position_status
ORDER BY 
    ap.profit_rate DESC;

-- ============================================================================
-- 附加查询：该账户的资产汇总统计
-- ============================================================================
SELECT 
    ap.account_id AS '账户ID',
    ap.account_name AS '账户名',
    COUNT(DISTINCT ap.fund_code) AS '持仓基金数量',
    SUM(ap.total_share) AS '总持有份额',
    SUM(ap.total_cost) AS '总投入成本(元)',
    SUM(ap.market_value) AS '总市值(元)',
    SUM(ap.profit_loss) AS '总盈亏(元)',
    CONCAT(ROUND(
        (SUM(ap.profit_loss) / NULLIF(SUM(ap.total_cost), 0)) * 100, 2
    ), '%') AS '总收益率',
    SUM(ap.accumulated_dividend) AS '累计分红总额(元)',
    SUM(CASE WHEN ap.profit_loss > 0 THEN 1 ELSE 0 END) AS '盈利基金数',
    SUM(CASE WHEN ap.profit_loss < 0 THEN 1 ELSE 0 END) AS '亏损基金数'
FROM 
    account_position ap
WHERE 
    ap.account_id = 'A20240001'
    AND ap.position_status = 'NORMAL'
    AND ap.total_share > 0
GROUP BY 
    ap.account_id,
    ap.account_name;

-- ============================================================================
-- 附加查询：查询该账户最近10笔交易记录
-- ============================================================================
SELECT 
    ft.transaction_id AS '交易流水号',
    ft.transaction_date AS '交易日期',
    ft.confirm_date AS '确认日期',
    fi.fund_name AS '基金名称',
    CASE ft.transaction_type
        WHEN 'PURCHASE' THEN '申购'
        WHEN 'REDEMPTION' THEN '赎回'
        WHEN 'DIVIDEND' THEN '分红'
        WHEN 'CONVERSION' THEN '转换'
        ELSE ft.transaction_type
    END AS '交易类型',
    ft.transaction_amount AS '交易金额(元)',
    ft.transaction_share AS '交易份额',
    ft.unit_nav AS '单位净值',
    ft.fee_amount AS '手续费(元)',
    ft.actual_amount AS '实际金额(元)',
    CASE ft.channel
        WHEN 'ONLINE' THEN '网上'
        WHEN 'MOBILE' THEN '手机'
        WHEN 'COUNTER' THEN '柜台'
        WHEN 'THIRD_PARTY' THEN '第三方'
        ELSE ft.channel
    END AS '交易渠道',
    CASE ft.transaction_status
        WHEN 'PENDING' THEN '待确认'
        WHEN 'CONFIRMED' THEN '已确认'
        WHEN 'FAILED' THEN '失败'
        WHEN 'CANCELLED' THEN '已撤销'
        ELSE ft.transaction_status
    END AS '交易状态'
FROM 
    fund_transaction ft
INNER JOIN 
    fund_info fi ON ft.fund_code = fi.fund_code
WHERE 
    ft.account_id = 'A20240001'
ORDER BY 
    ft.transaction_time DESC
LIMIT 10;
