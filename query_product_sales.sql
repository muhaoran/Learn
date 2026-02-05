-- 商品销售排行榜查询
-- 功能：统计热销商品信息，包含销量、评价、库存预警等

SELECT 
    p.id AS 商品ID,
    p.name AS 商品名称,
    c.name AS 所属分类,
    p.price AS 当前售价,
    p.original_price AS 原价,
    CONCAT(ROUND((p.original_price - p.price) / p.original_price * 100, 1), '%') AS 折扣率,
    p.sales_count AS 总销量,
    p.stock AS 当前库存,
    CASE 
        WHEN p.stock = 0 THEN '缺货'
        WHEN p.stock < 10 THEN '库存告急'
        WHEN p.stock < 50 THEN '库存偏低'
        ELSE '库存充足'
    END AS 库存状态,
    COUNT(DISTINCT r.id) AS 评论数量,
    IFNULL(AVG(r.rating), 0) AS 平均评分,
    SUM(oi.quantity) AS 近期销量,
    SUM(oi.subtotal) AS 近期销售额,
    CASE 
        WHEN p.status = 1 THEN '在售'
        ELSE '已下架'
    END AS 商品状态
FROM 
    products p
    INNER JOIN categories c ON p.category_id = c.id
    LEFT JOIN reviews r ON p.id = r.product_id AND r.status = 1
    LEFT JOIN order_items oi ON p.id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.id 
        AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        AND o.status IN (1, 2, 3)  -- 已付款、已发货、已完成
WHERE 
    p.status = 1
    AND c.status = 1
GROUP BY 
    p.id, p.name, c.name, p.price, p.original_price, 
    p.sales_count, p.stock, p.status
HAVING 
    总销量 > 0
ORDER BY 
    近期销量 DESC, 平均评分 DESC
LIMIT 50;

-- 使用说明：
-- 1. 查询在售商品的销售排行榜，按近30天销量排序
-- 2. 包含价格、折扣、库存预警、评价等关键指标
-- 3. 可用于商品运营分析、库存管理、促销策略制定
-- 4. 建议每日定时执行，监控热销商品动态
