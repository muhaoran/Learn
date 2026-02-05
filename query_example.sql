-- 电商平台数据查询示例
-- 功能：查询用户的订单统计信息，包含商品详情和评价情况

SELECT 
    u.id AS 用户ID,
    u.username AS 用户名,
    u.email AS 邮箱,
    COUNT(DISTINCT o.id) AS 订单总数,
    SUM(o.actual_amount) AS 累计消费金额,
    AVG(o.actual_amount) AS 平均订单金额,
    COUNT(DISTINCT CASE WHEN o.status = 3 THEN o.id END) AS 已完成订单数,
    COUNT(DISTINCT r.id) AS 评论总数,
    AVG(r.rating) AS 平均评分,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS 购买分类
FROM 
    users u
    LEFT JOIN orders o ON u.id = o.user_id
    LEFT JOIN order_items oi ON o.id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.id
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN reviews r ON u.id = r.user_id
WHERE 
    u.status = 1
    AND o.created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY 
    u.id, u.username, u.email
HAVING 
    订单总数 > 0
ORDER BY 
    累计消费金额 DESC
LIMIT 100;

-- 说明：
-- 1. 此查询统计最近6个月内有购买行为的用户消费情况
-- 2. 包含订单数量、金额、完成情况、评价等维度
-- 3. 按累计消费金额降序排列，取前100名用户
-- 4. 可用于用户价值分析、VIP用户筛选等业务场景
