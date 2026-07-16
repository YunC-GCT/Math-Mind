/**
 * NoteDaoInterface.ets — NoteDao 接口定义
 *
 * KnowledgeModel MVP 只依赖这个接口，不直接依赖 NoteDao 实现类。
 * 这样测试时可以用 mock 替代，生产环境注入真实 NoteDao。
 *
 * 接口方法与 D1_CAPTURE_CHAIN_PLAN.md 约定一致:
 *   insert(unit: KnowledgeUnitExt): number  // 返回 rowId
 */
import { KnowledgeUnitExt } from './KnowledgeUnitExt';
export interface NoteDaoInterface {
    /** 插入一条知识单元，返回数据库生成的 rowId */
    insert(unit: KnowledgeUnitExt): Promise<number>;
    /**
     * 按 id 更新已有知识单元的全部字段
     * 用于用户在 UI 层修改 title / difficulty / importance 后写回数据库
     */
    update(unit: KnowledgeUnitExt): Promise<void>;
}
