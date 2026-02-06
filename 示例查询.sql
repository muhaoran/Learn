-- ============================================================
-- 示例SQL查询：查询用户订单详情及关联信息
-- ============================================================
-- 功能说明：
-- 查询2026年1月份已支付的订单信息，包含：
-- 1. 用户基本信息（用户名、邮箱、手机号）
-- 2. 用户角色信息
-- 3. 订单详细信息（订单号、金额、状态等）
-- 4. 按实付金额降序排列，取前10条记录
-- ============================================================

SELECT 
    -- 用户信息
    u.id AS user_id,
    u.username,
    u.email,
    u.phone,
    u.real_name,
    r.role_name,
    
    -- 订单信息
    o.id AS order_id,
    o.order_no,
    o.order_status,
    CASE o.order_status
        WHEN 1 THEN '待支付'
        WHEN 2 THEN '已支付'
        WHEN 3 THEN '配送中'
        WHEN 4 THEN '已完成'
        WHEN 5 THEN '已取消'
        ELSE '未知状态'
    END AS order_status_name,
    
    o.payment_method,
    CASE o.payment_method
        WHEN 'alipay' THEN '支付宝'
        WHEN 'wechat' THEN '微信支付'
        WHEN 'bank' THEN '银行卡'
        ELSE '其他'
    END AS payment_method_name,
    
    o.payment_time,
    o.transaction_id,
    
    -- 金额信息
    o.product_amount AS 商品总金额,
    o.discount_amount AS 优惠金额,
    o.shipping_fee AS 运费,
    o.paid_amount AS 实付金额,
    
    -- 收货信息
    o.recipient_name AS 收货人,
    o.recipient_phone AS 收货电话,
    CONCAT(o.province, o.city, o.district, o.recipient_address) AS 完整地址,
    
    -- 物流信息
    o.tracking_no AS 物流单号,
    o.shipping_time AS 发货时间,
    
    -- 订单创建时间
    DATE_FORMAT(o.created_at, '%Y-%m-%d %H:%i:%s') AS 下单时间,
    
    -- 计算订单完成时长（小时）
    TIMESTAMPDIFF(HOUR, o.created_at, o.completed_time) AS 完成时长_小时

FROM 
    orders o
    
    -- 关联用户表
    INNER JOIN users u ON o.user_id = u.id
    
    -- 左关联角色表（用户可能没有角色）
    LEFT JOIN roles r ON u.role_id = r.id

WHERE 
    -- 查询条件：2026年1月份的订单
    o.created_at >= '2026-01-01 00:00:00'
    AND o.created_at < '2026-02-01 00:00:00'
    
    -- 已支付的订单
    AND o.payment_status = 1
    
    -- 订单状态不是已取消
    AND o.order_status != 5
    
    -- 用户账户状态正常
    AND u.status = 1
    
    -- 实付金额大于0
    AND o.paid_amount > 0
    
    -- 未被软删除的记录
    AND o.deleted_at IS NULL
    AND u.deleted_at IS NULL

-- 排序：按实付金额降序，相同金额按支付时间升序
ORDER BY 
    o.paid_amount DESC,
    o.payment_time ASC

-- 限制返回前10条记录
LIMIT 10;


-- ============================================================
-- 扩展查询1：统计用户订单汇总信息
-- ============================================================

SELECT 
    u.id AS user_id,
    u.username,
    u.email,
    r.role_name,
    
    -- 订单统计
    COUNT(o.id) AS 订单总数,
    SUM(CASE WHEN o.order_status = 4 THEN 1 ELSE 0 END) AS 已完成订单数,
    SUM(CASE WHEN o.order_status = 5 THEN 1 ELSE 0 END) AS 已取消订单数,
    
    -- 金额统计
    SUM(o.paid_amount) AS 累计消费金额,
    AVG(o.paid_amount) AS 平均订单金额,
    MAX(o.paid_amount) AS 最大订单金额,
    MIN(o.paid_amount) AS 最小订单金额,
    
    -- 时间信息
    MIN(o.created_at) AS 首次下单时间,
    MAX(o.created_at) AS 最近下单时间,
    
    -- 用户等级判断（根据消费金额）
    CASE 
        WHEN SUM(o.paid_amount) >= 10000 THEN 'VIP会员'
        WHEN SUM(o.paid_amount) >= 5000 THEN '金牌会员'
        WHEN SUM(o.paid_amount) >= 1000 THEN '银牌会员'
        ELSE '普通会员'
    END AS 会员等级

FROM 
    users u
    
    -- 左关联订单表（包含没有订单的用户）
    LEFT JOIN orders o ON u.id = o.user_id AND o.deleted_at IS NULL
    
    -- 左关联角色表
    LEFT JOIN roles r ON u.role_id = r.id

WHERE 
    u.status = 1
    AND u.deleted_at IS NULL

-- 按用户分组
GROUP BY 
    u.id, u.username, u.email, r.role_name

-- 只显示有订单的用户
HAVING 
    订单总数 > 0

-- 按累计消费金额降序
ORDER BY 
    累计消费金额 DESC

LIMIT 20;


-- ============================================================
-- 扩展查询2：热销产品排行（关联订单数据）
-- ============================================================

SELECT 
    p.id AS product_id,
    p.product_code,
    p.product_name,
    p.brand,
    p.category_id,
    
    -- 价格信息
    p.selling_price AS 售价,
    p.cost_price AS 成本价,
    (p.selling_price - p.cost_price) AS 单品利润,
    
    -- 库存信息
    p.stock_quantity AS 当前库存,
    p.sales_count AS 总销量,
    
    -- 标签
    CASE WHEN p.is_hot = 1 THEN '热销' ELSE '' END AS 热销标签,
    CASE WHEN p.is_new = 1 THEN '新品' ELSE '' END AS 新品标签,
    CASE WHEN p.is_recommended = 1 THEN '推荐' ELSE '' END AS 推荐标签,
    
    -- 状态
    CASE p.status
        WHEN 0 THEN '已下架'
        WHEN 1 THEN '在售'
        WHEN 2 THEN '缺货'
        ELSE '未知'
    END AS 商品状态,
    
    -- 计算利润率
    ROUND((p.selling_price - p.cost_price) / p.cost_price * 100, 2) AS 利润率_百分比,
    
    -- 计算预计总利润
    ROUND((p.selling_price - p.cost_price) * p.sales_count, 2) AS 预计总利润

FROM 
    products p

WHERE 
    p.status = 1  -- 在售商品
    AND p.deleted_at IS NULL
    AND p.selling_price > 0

-- 按销量降序
ORDER BY 
    p.sales_count DESC,
    p.view_count DESC

LIMIT 15;


-- ============================================================
-- 扩展查询3：用户权限完整查询（多表关联）
-- ============================================================

SELECT 
    u.id AS user_id,
    u.username,
    u.email,
    u.real_name,
    
    -- 角色信息
    r.role_name,
    r.role_code,
    r.level AS role_level,
    
    -- 权限信息
    p.permission_name,
    p.permission_code,
    CASE p.permission_type
        WHEN 1 THEN '菜单'
        WHEN 2 THEN '按钮'
        WHEN 3 THEN '接口'
        ELSE '未知'
    END AS permission_type_name,
    p.route_path,
    p.api_url,
    p.api_method

FROM 
    users u
    
    -- 关联角色
    INNER JOIN roles r ON u.role_id = r.id
    
    -- 关联角色权限中间表（假设存在）
    -- INNER JOIN role_permissions rp ON r.id = rp.role_id
    
    -- 关联权限表
    INNER JOIN permissions p ON p.id > 0  -- 这里需要通过中间表关联
    
WHERE 
    u.status = 1
    AND u.deleted_at IS NULL
    AND r.status = 1
    AND r.deleted_at IS NULL
    AND p.status = 1
    AND p.deleted_at IS NULL
    
    -- 指定用户
    AND u.username = 'admin'

ORDER BY 
    p.parent_id ASC,
    p.sort_order ASC;
