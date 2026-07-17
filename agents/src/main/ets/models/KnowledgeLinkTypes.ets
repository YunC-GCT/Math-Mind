/**
 * KnowledgeLinkTypes.ets — ContextLink 关联结果类型定义
 *
 * ContextLink ③ 的输出类型：
 *   对 KnowledgeUnitExt 进行 3 维度关联后，返回此结构。
 *   UI 层可据此展示"相关定理""关联概念""同类错题"等区块。
 */

/**
 * 上下文关联结果
 *
 * 由 ContextLink.link() 返回，包含 4 类关联信息。
 */
export interface KnowledgeLinkResult {
  /** 关联定理名称列表（LIKE 模糊匹配已有笔记） */
  readonly theoremNames: string[];
  /** 关联概念名称列表（关键词索引匹配） */
  readonly conceptNames: string[];
  /** 关联考点/标签（从 content 提取） */
  readonly relatedTags: string[];
  /** 同类历史笔记 ID 列表（Jaccard 标签重叠度 > 0.5） */
  readonly similarNoteIds: string[];
}

/**
 * 创建空的 KnowledgeLinkResult（默认值）
 *
 * @returns 各项均为空数组的关联结果
 */
export function emptyLinkResult(): KnowledgeLinkResult {
  return {
    theoremNames: [],
    conceptNames: [],
    relatedTags: [],
    similarNoteIds: [],
  };
}
