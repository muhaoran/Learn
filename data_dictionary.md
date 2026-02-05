# 数据字典文档

## 项目信息
- **项目名称**: 业务管理系统
- **数据库类型**: MySQL 8.0
- **字符集**: UTF-8
- **创建日期**: 2026-02-05
- **版本**: 1.0

---

## 表清单

| 序号 | 表名 | 中文名称 | 说明 |
|------|------|----------|------|
| 1 | tb_user | 用户表 | 存储系统用户基本信息 |
| 2 | tb_role | 角色表 | 存储系统角色信息 |
| 3 | tb_permission | 权限表 | 存储系统权限信息 |
| 4 | tb_user_role | 用户角色关联表 | 用户与角色的多对多关系 |
| 5 | tb_role_permission | 角色权限关联表 | 角色与权限的多对多关系 |
| 6 | tb_product | 产品表 | 存储产品信息 |
| 7 | tb_order | 订单表 | 存储订单主信息 |
| 8 | tb_order_item | 订单明细表 | 存储订单商品明细 |
| 9 | tb_system_log | 系统日志表 | 记录系统操作日志 |
| 10 | tb_system_config | 系统配置表 | 存储系统配置参数 |

---

## 1. tb_user (用户表)

### 表说明
存储系统用户的基本信息，包括登录凭证、个人信息等。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| user_id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 用户ID |
| username | VARCHAR | 50 | - | NO | UNI | - | 用户名（登录账号） |
| password | VARCHAR | 128 | - | NO | - | - | 密码（加密存储） |
| real_name | VARCHAR | 50 | - | YES | - | NULL | 真实姓名 |
| email | VARCHAR | 100 | - | YES | - | NULL | 邮箱地址 |
| mobile | VARCHAR | 20 | - | YES | - | NULL | 手机号码 |
| gender | TINYINT | 1 | - | YES | - | 0 | 性别（0:未知,1:男,2:女） |
| avatar | VARCHAR | 255 | - | YES | - | NULL | 头像URL |
| status | TINYINT | 1 | - | NO | - | 1 | 状态（0:禁用,1:启用） |
| last_login_time | DATETIME | - | - | YES | - | NULL | 最后登录时间 |
| last_login_ip | VARCHAR | 50 | - | YES | - | NULL | 最后登录IP |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |
| is_deleted | TINYINT | 1 | - | NO | - | 0 | 逻辑删除（0:否,1:是） |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | user_id | 主键索引 |
| uk_username | 唯一索引 | username | 用户名唯一 |
| idx_email | 普通索引 | email | 邮箱查询 |
| idx_mobile | 普通索引 | mobile | 手机号查询 |
| idx_create_time | 普通索引 | create_time | 创建时间查询 |

---

## 2. tb_role (角色表)

### 表说明
存储系统角色信息，用于权限管理。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| role_id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 角色ID |
| role_code | VARCHAR | 50 | - | NO | UNI | - | 角色编码 |
| role_name | VARCHAR | 100 | - | NO | - | - | 角色名称 |
| description | VARCHAR | 500 | - | YES | - | NULL | 角色描述 |
| sort_order | INT | 11 | - | YES | - | 0 | 排序号 |
| status | TINYINT | 1 | - | NO | - | 1 | 状态（0:禁用,1:启用） |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |
| is_deleted | TINYINT | 1 | - | NO | - | 0 | 逻辑删除（0:否,1:是） |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | role_id | 主键索引 |
| uk_role_code | 唯一索引 | role_code | 角色编码唯一 |
| idx_status | 普通索引 | status | 状态查询 |

---

## 3. tb_permission (权限表)

### 表说明
存储系统权限信息，包括菜单、按钮等操作权限。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| permission_id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 权限ID |
| parent_id | BIGINT | 20 | - | NO | - | 0 | 父权限ID（0表示顶级） |
| permission_code | VARCHAR | 100 | - | NO | UNI | - | 权限编码 |
| permission_name | VARCHAR | 100 | - | NO | - | - | 权限名称 |
| permission_type | TINYINT | 1 | - | NO | - | 1 | 权限类型（1:菜单,2:按钮,3:接口） |
| url | VARCHAR | 255 | - | YES | - | NULL | 权限URL/路由 |
| icon | VARCHAR | 100 | - | YES | - | NULL | 图标 |
| sort_order | INT | 11 | - | YES | - | 0 | 排序号 |
| status | TINYINT | 1 | - | NO | - | 1 | 状态（0:禁用,1:启用） |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |
| is_deleted | TINYINT | 1 | - | NO | - | 0 | 逻辑删除（0:否,1:是） |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | permission_id | 主键索引 |
| uk_permission_code | 唯一索引 | permission_code | 权限编码唯一 |
| idx_parent_id | 普通索引 | parent_id | 父权限查询 |
| idx_type | 普通索引 | permission_type | 类型查询 |

---

## 4. tb_user_role (用户角色关联表)

### 表说明
用户与角色的多对多关联关系表。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 主键ID |
| user_id | BIGINT | 20 | - | NO | - | - | 用户ID |
| role_id | BIGINT | 20 | - | NO | - | - | 角色ID |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | id | 主键索引 |
| uk_user_role | 唯一索引 | user_id, role_id | 用户角色唯一 |
| idx_user_id | 普通索引 | user_id | 用户查询 |
| idx_role_id | 普通索引 | role_id | 角色查询 |

### 外键约束

| 约束名 | 字段 | 关联表 | 关联字段 | 说明 |
|--------|------|--------|----------|------|
| fk_user_role_user | user_id | tb_user | user_id | 关联用户表 |
| fk_user_role_role | role_id | tb_role | role_id | 关联角色表 |

---

## 5. tb_role_permission (角色权限关联表)

### 表说明
角色与权限的多对多关联关系表。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 主键ID |
| role_id | BIGINT | 20 | - | NO | - | - | 角色ID |
| permission_id | BIGINT | 20 | - | NO | - | - | 权限ID |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | id | 主键索引 |
| uk_role_permission | 唯一索引 | role_id, permission_id | 角色权限唯一 |
| idx_role_id | 普通索引 | role_id | 角色查询 |
| idx_permission_id | 普通索引 | permission_id | 权限查询 |

### 外键约束

| 约束名 | 字段 | 关联表 | 关联字段 | 说明 |
|--------|------|--------|----------|------|
| fk_role_perm_role | role_id | tb_role | role_id | 关联角色表 |
| fk_role_perm_permission | permission_id | tb_permission | permission_id | 关联权限表 |

---

## 6. tb_product (产品表)

### 表说明
存储产品/商品的基本信息。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| product_id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 产品ID |
| product_code | VARCHAR | 50 | - | NO | UNI | - | 产品编码 |
| product_name | VARCHAR | 200 | - | NO | - | - | 产品名称 |
| category | VARCHAR | 50 | - | YES | - | NULL | 产品分类 |
| brand | VARCHAR | 100 | - | YES | - | NULL | 品牌 |
| price | DECIMAL | 10 | 2 | NO | - | 0.00 | 单价 |
| cost | DECIMAL | 10 | 2 | YES | - | 0.00 | 成本价 |
| stock | INT | 11 | - | NO | - | 0 | 库存数量 |
| unit | VARCHAR | 20 | - | YES | - | '件' | 单位 |
| description | TEXT | - | - | YES | - | NULL | 产品描述 |
| image_url | VARCHAR | 500 | - | YES | - | NULL | 产品图片URL |
| status | TINYINT | 1 | - | NO | - | 1 | 状态（0:下架,1:上架） |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |
| is_deleted | TINYINT | 1 | - | NO | - | 0 | 逻辑删除（0:否,1:是） |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | product_id | 主键索引 |
| uk_product_code | 唯一索引 | product_code | 产品编码唯一 |
| idx_product_name | 普通索引 | product_name | 产品名称查询 |
| idx_category | 普通索引 | category | 分类查询 |
| idx_status | 普通索引 | status | 状态查询 |

---

## 7. tb_order (订单表)

### 表说明
存储订单主表信息。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| order_id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 订单ID |
| order_no | VARCHAR | 50 | - | NO | UNI | - | 订单号 |
| user_id | BIGINT | 20 | - | NO | - | - | 用户ID |
| total_amount | DECIMAL | 12 | 2 | NO | - | 0.00 | 订单总金额 |
| discount_amount | DECIMAL | 10 | 2 | YES | - | 0.00 | 优惠金额 |
| actual_amount | DECIMAL | 12 | 2 | NO | - | 0.00 | 实付金额 |
| payment_method | TINYINT | 1 | - | YES | - | 1 | 支付方式（1:微信,2:支付宝,3:银行卡） |
| payment_status | TINYINT | 1 | - | NO | - | 0 | 支付状态（0:未支付,1:已支付,2:已退款） |
| payment_time | DATETIME | - | - | YES | - | NULL | 支付时间 |
| order_status | TINYINT | 1 | - | NO | - | 1 | 订单状态（1:待支付,2:待发货,3:已发货,4:已完成,5:已取消） |
| shipping_address | VARCHAR | 500 | - | YES | - | NULL | 收货地址 |
| receiver_name | VARCHAR | 50 | - | YES | - | NULL | 收货人姓名 |
| receiver_phone | VARCHAR | 20 | - | YES | - | NULL | 收货人电话 |
| remark | VARCHAR | 500 | - | YES | - | NULL | 订单备注 |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |
| is_deleted | TINYINT | 1 | - | NO | - | 0 | 逻辑删除（0:否,1:是） |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | order_id | 主键索引 |
| uk_order_no | 唯一索引 | order_no | 订单号唯一 |
| idx_user_id | 普通索引 | user_id | 用户查询 |
| idx_payment_status | 普通索引 | payment_status | 支付状态查询 |
| idx_order_status | 普通索引 | order_status | 订单状态查询 |
| idx_create_time | 普通索引 | create_time | 创建时间查询 |

### 外键约束

| 约束名 | 字段 | 关联表 | 关联字段 | 说明 |
|--------|------|--------|----------|------|
| fk_order_user | user_id | tb_user | user_id | 关联用户表 |

---

## 8. tb_order_item (订单明细表)

### 表说明
存储订单商品明细信息。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| item_id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 明细ID |
| order_id | BIGINT | 20 | - | NO | - | - | 订单ID |
| product_id | BIGINT | 20 | - | NO | - | - | 产品ID |
| product_name | VARCHAR | 200 | - | NO | - | - | 产品名称（快照） |
| product_code | VARCHAR | 50 | - | YES | - | NULL | 产品编码（快照） |
| price | DECIMAL | 10 | 2 | NO | - | 0.00 | 单价（快照） |
| quantity | INT | 11 | - | NO | - | 1 | 购买数量 |
| subtotal | DECIMAL | 12 | 2 | NO | - | 0.00 | 小计金额 |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | item_id | 主键索引 |
| idx_order_id | 普通索引 | order_id | 订单查询 |
| idx_product_id | 普通索引 | product_id | 产品查询 |

### 外键约束

| 约束名 | 字段 | 关联表 | 关联字段 | 说明 |
|--------|------|--------|----------|------|
| fk_order_item_order | order_id | tb_order | order_id | 关联订单表 |
| fk_order_item_product | product_id | tb_product | product_id | 关联产品表 |

---

## 9. tb_system_log (系统日志表)

### 表说明
记录系统操作日志，用于审计和问题追踪。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| log_id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 日志ID |
| user_id | BIGINT | 20 | - | YES | - | NULL | 操作用户ID |
| username | VARCHAR | 50 | - | YES | - | NULL | 操作用户名 |
| operation | VARCHAR | 100 | - | NO | - | - | 操作类型 |
| method | VARCHAR | 200 | - | YES | - | NULL | 请求方法 |
| params | TEXT | - | - | YES | - | NULL | 请求参数 |
| result | TEXT | - | - | YES | - | NULL | 返回结果 |
| ip_address | VARCHAR | 50 | - | YES | - | NULL | IP地址 |
| user_agent | VARCHAR | 500 | - | YES | - | NULL | 用户代理 |
| execution_time | INT | 11 | - | YES | - | 0 | 执行时长(ms) |
| status | TINYINT | 1 | - | NO | - | 1 | 状态（0:失败,1:成功） |
| error_msg | TEXT | - | - | YES | - | NULL | 错误信息 |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | log_id | 主键索引 |
| idx_user_id | 普通索引 | user_id | 用户查询 |
| idx_operation | 普通索引 | operation | 操作类型查询 |
| idx_create_time | 普通索引 | create_time | 创建时间查询 |
| idx_status | 普通索引 | status | 状态查询 |

---

## 10. tb_system_config (系统配置表)

### 表说明
存储系统配置参数，支持动态配置。

### 字段清单

| 字段名 | 数据类型 | 长度 | 小数位 | 允许空 | 主键 | 默认值 | 说明 |
|--------|----------|------|--------|--------|------|--------|------|
| config_id | BIGINT | 20 | - | NO | PRI | AUTO_INCREMENT | 配置ID |
| config_key | VARCHAR | 100 | - | NO | UNI | - | 配置键 |
| config_value | TEXT | - | - | YES | - | NULL | 配置值 |
| config_type | VARCHAR | 20 | - | YES | - | 'string' | 配置类型（string,number,boolean,json） |
| group_name | VARCHAR | 50 | - | YES | - | 'default' | 配置分组 |
| description | VARCHAR | 500 | - | YES | - | NULL | 配置描述 |
| is_system | TINYINT | 1 | - | NO | - | 0 | 是否系统配置（0:否,1:是） |
| status | TINYINT | 1 | - | NO | - | 1 | 状态（0:禁用,1:启用） |
| create_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME | - | - | NO | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

### 索引

| 索引名 | 索引类型 | 字段 | 说明 |
|--------|----------|------|------|
| PRIMARY | 主键 | config_id | 主键索引 |
| uk_config_key | 唯一索引 | config_key | 配置键唯一 |
| idx_group_name | 普通索引 | group_name | 分组查询 |
| idx_status | 普通索引 | status | 状态查询 |

---

## 表关系图

```
tb_user (用户表)
  ├─→ tb_user_role (用户角色关联)
  └─→ tb_order (订单表)

tb_role (角色表)
  ├─→ tb_user_role (用户角色关联)
  └─→ tb_role_permission (角色权限关联)

tb_permission (权限表)
  └─→ tb_role_permission (角色权限关联)

tb_product (产品表)
  └─→ tb_order_item (订单明细)

tb_order (订单表)
  └─→ tb_order_item (订单明细)

tb_system_log (系统日志表) - 独立表

tb_system_config (系统配置表) - 独立表
```

---

## 命名规范

### 表命名规范
- 统一使用小写字母
- 使用下划线分隔单词
- 表名前缀：tb_
- 使用有意义的英文单词

### 字段命名规范
- 统一使用小写字母
- 使用下划线分隔单词
- 主键命名：表名_id
- 外键命名：关联表名_id
- 时间字段：create_time, update_time
- 逻辑删除字段：is_deleted
- 状态字段：status

### 索引命名规范
- 主键索引：PRIMARY
- 唯一索引：uk_字段名
- 普通索引：idx_字段名
- 复合索引：idx_字段1_字段2

---

## 数据类型说明

| 数据类型 | 说明 | 适用场景 |
|----------|------|----------|
| BIGINT | 长整型 | 主键、大数值 |
| INT | 整型 | 数量、排序号 |
| TINYINT | 微整型 | 状态、标志位 |
| VARCHAR | 可变长字符串 | 普通文本 |
| TEXT | 长文本 | 大段文本 |
| DECIMAL | 定点数 | 金额、价格 |
| DATETIME | 日期时间 | 时间戳 |

---

## 维护说明

### 版本记录

| 版本号 | 修改日期 | 修改人 | 修改内容 |
|--------|----------|--------|----------|
| 1.0 | 2026-02-05 | System | 初始版本，创建10张基础表 |

### 备注
1. 所有表都包含逻辑删除字段 `is_deleted`，便于数据恢复
2. 所有表都包含 `create_time` 和 `update_time` 时间戳
3. 涉及金额的字段统一使用 DECIMAL 类型，保证精度
4. 状态字段统一使用 TINYINT 类型，并在说明中注明枚举值
5. 主键统一使用 BIGINT 类型，支持大数据量
6. 外键约束建议在应用层控制，数据库层可选择性添加

---

**文档结束**
