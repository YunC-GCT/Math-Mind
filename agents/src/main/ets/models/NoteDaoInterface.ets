/**
 * NoteDaoInterface.ets — NoteDao 接口定义
 *
 * KnowledgeModel MVP 只依赖这个接口，不直接依赖 NoteDao 实现类。
 * 这样测试时可以用 mock 替代，生产环境注入真实 NoteDao。
 *
 * 接口方法与 D1_CAPTURE_CHAIN_PLAN.md 约定一致:
 *   insert(unit: KnowledgeUnitExt): Promise<number>  // 异步返回 rowId
 */

import { KnowledgeUnitExt } from './KnowledgeUnitExt';

export interface NoteDaoInterface {
  insert(unit: KnowledgeUnitExt): Promise<number>;
}
