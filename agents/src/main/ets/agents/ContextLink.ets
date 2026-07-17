/**
 * ContextLink.ets — ③ 上下文关联 Agent
 *
 * 职责（MVP 简化版 — 纯本地 RDB，不做 LLM 语义相似度）：
 * 1. 字段提取：title/content/tags/type
 * 2. 定理匹配器：关键词模糊匹配已有笔记
 * 3. 考点匹配器：标签索引匹配
 * 4. 历史错题匹配器：同 type + Jaccard 标签重叠度 > 0.5
 * 5. 合并去重排序：定理 > 考点 > 历史错题
 *
 * 适配 mathmind_ver2 (2026-07)：基于 KnowledgeUnitExt + KnowledgeLinkResult
 */

import { KnowledgeUnitExt } from '../models/KnowledgeUnitExt';
import { KnowledgeLinkResult, emptyLinkResult } from '../models/KnowledgeLinkTypes';
import { Logger } from 'common';

// ── 内部接口（ArkTS 严格模式禁止内联对象字面量类型声明） ──

interface ExtractedFields {
  readonly title: string;
  readonly content: string;
  readonly tags: string[];
  readonly type: string;
}



const log = new Logger('ContextLink');

export class ContextLink {
  /**
   * 主入口：输入结构化知识单元 → 输出关联链接
   *
   * @param unit - 已结构化的知识单元（KnowledgeModel 输出）
   * @returns 关联结果（定理/考点/历史错题）
   */
  async link(unit: KnowledgeUnitExt): Promise<KnowledgeLinkResult> {
    const t0: number = Date.now();
    log.info('ContextLink.link enter, type=' + unit.type + ', title=' + unit.title);

    try {
      // Step 1: 字段提取
      const fields: ExtractedFields = this.extractFields(unit);

      // Step 2: 3 维度关联（当前为 Stub，后续接入 RDB 后填充）
      const theoremNames: string[] = await this.matchTheorems(fields);
      const conceptNames: string[] = await this.matchConcepts(fields);
      const relatedTags: string[] = await this.matchRelatedTags(fields);
      const similarNoteIds: string[] = await this.matchSimilarNotes(unit);

      // Step 3: 合并去重排序
      const result: KnowledgeLinkResult = this.mergeResults(
        theoremNames, conceptNames, relatedTags, similarNoteIds,
      );

      log.info('ContextLink.link done, theorems=' + String(theoremNames.length)
        + ', concepts=' + String(conceptNames.length)
        + ', similar=' + String(similarNoteIds.length)
        + ', duration=' + String(Date.now() - t0) + 'ms');
      return result;
    } catch (e) {
      const errMsg: string = (e as Error).message ?? String(e);
      log.error('ContextLink.link failed: ' + errMsg);
      return emptyLinkResult();
    }
  }

  /** 字段提取 */
  private extractFields(unit: KnowledgeUnitExt): ExtractedFields {
    const result: ExtractedFields = {
      title: unit.title,
      content: unit.content,
      tags: unit.tags,
      type: unit.type,
    };
    return result;
  }

  /**
   * 定理匹配器：对 title/content 提取关键词，模糊匹配已有笔记
   * TODO: 接入 RDB 后，SELECT id, title FROM notes WHERE title LIKE '%关键词%'
   */
  private async matchTheorems(fields: ExtractedFields): Promise<string[]> {
    // TODO: 实现定理模糊匹配
    // 从 title/content 中提取数学关键词 → 查询已有定理笔记
    return [];
  }

  /**
   * 概念匹配器：关键词索引匹配
   * TODO: 接入 RDB 后，按 tags + type 索引匹配概念类笔记
   */
  private async matchConcepts(fields: ExtractedFields): Promise<string[]> {
    // TODO: 基于 tags 匹配已有概念笔记
    return [];
  }

  /**
   * 关联标签匹配：从 content 中提取考点关键词
   * TODO: 接入 RDB 后，关联考点标签
   */
  private async matchRelatedTags(fields: ExtractedFields): Promise<string[]> {
    // TODO: 从 content 提取考点关键词
    return [];
  }

  /**
   * 历史错题匹配器：同 type + Jaccard > 0.5
   * TODO: SELECT id FROM notes WHERE type = unit.type
   *       → 逐个计算 Jaccard(tags) → 筛选 > 0.5
   */
  private async matchSimilarNotes(unit: KnowledgeUnitExt): Promise<string[]> {
    // TODO: 实现 Jaccard 相似度匹配
    return [];
  }

  /** 合并去重排序：定理名 > 概念名 > 关联标签 > 相似错题 */
  private mergeResults(
    theoremNames: string[],
    conceptNames: string[],
    relatedTags: string[],
    similarNoteIds: string[],
  ): KnowledgeLinkResult {
    return {
      theoremNames: theoremNames,
      conceptNames: conceptNames,
      relatedTags: relatedTags,
      similarNoteIds: similarNoteIds,
    };
  }
}
