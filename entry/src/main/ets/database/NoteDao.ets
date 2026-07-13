// MathMind - NoteDao (关系型数据库访问层)
// 任务编号: A1
// 责任: Mavis(我)
// 状态: TODO - 空壳,等待实现
// 依赖: 无 (A 阶段基础设施,可与 A2 并行)
//
// 接口约定 (D1_CAPTURE_CHAIN_PLAN.md):
//   insert(unit: KnowledgeUnit): number            // 返回 rowId
//   queryById(id: string): KnowledgeUnit | null    // 按主键查询
//
// 验证方式: 调用 insert → 返回 rowId → queryById 查回
//
// KnowledgeUnit interface 已在 common/src/main/ets/models/CommonTypes.ets 定义
// 建表 SQL 已在 common/src/main/ets/DatabaseHelper.ets 具备 (后续补)
// RdbStore API 路径: @ohos.data.relationalStore

export class NoteDao {
  // TODO(A1): 实现 insert + queryById
}
