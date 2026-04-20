# 新需求类型记录

- **日期**：[YYYY-MM-DD]
- **复用预期**：高 / 中 / 低（预计未来出现的频次）
- **优先级**：高 / 中 / 低
- **状态**：待处理 / 处理中 / 已完成

---

## 原始需求

```
[用户的原始需求]
```

## 最终 SQL（已验证）

```sql
[验证正确的 SQL]
```

## 为什么是"新"需求

[为什么现有 metrics / patterns / semantics 无法直接覆盖这个需求；与已有案例的差异在哪里]

## 复用结构分析

[把这次 SQL 中可被复用的结构抽出来，作为 pattern 模板的雏形；标注出哪些是参数（指标对象、维度、时间范围、过滤条件等），哪些是固定结构]

```sql
-- 抽象后的模板示意
[抽象 SQL]
```

---

## 沉淀建议

**类型**（可多选）：

- [ ] 新指标 → 补充到 `knowledge/metrics/[指标名].yaml`
  - 指标名：[name]
  - 计算口径：[summary]
  - 复用的 pattern：[pattern_id]
- [ ] 新计算模式 → 补充到 `knowledge/patterns/[pattern_id].md`
  - pattern_id：[id]
  - 适用场景：[summary]
  - 模板参数：[params]
- [ ] 新业务概念（实体/事件/维度）→ 补充到 `knowledge/semantics/`
  - 类型：entity / event / dimension
  - 名称：[name]
- [ ] 新表或字段 → 补充到 `knowledge/schema/tables/[table].yaml`
- [ ] 其他：[说明]

---

## 后续计划

- **负责人**：[姓名]
- **计划完成**：[YYYY-MM-DD]
- **关联知识库文件**：[预计新增/修改的路径]
- **临时处理方式**：[在沉淀前若再次出现同类需求如何处理]

## 完成情况

- [ ] 已抽出可复用结构
- [ ] 已沉淀到对应的 `knowledge/` 文件
- [ ] 已验证沉淀后 AI 能正确处理同类需求
