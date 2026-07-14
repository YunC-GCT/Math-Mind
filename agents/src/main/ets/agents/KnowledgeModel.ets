// MathMind - KnowledgeModel (笔记结构化 + 真值检验 + 入库)
// 任务编号: C
// 责任: L
// 状态: TODO - 空壳,等待实现
// 依赖: A1 (NoteDao) + B1 (OcrTool) + B2 (TypeClassifier) 全部完成
//
// 接口约定 (D1_CAPTURE_CHAIN_PLAN.md 第五/六节):
//   structure(ocrText: string, classification: ClassificationResult):
//     Promise<KnowledgeUnit>
//
// 实现路径:
//   1) 根据 classification.type 选模板 (3 选 1):
//      - 概念 → concept_v1: ## 定义 / ## 性质 / ## 相关概念
//      - 计算 → computation_v1: ## 题目 / ## 解法 / ## 答案
//      - 证明 → proof_v1: ## 命题 / ## 证明 / ## 要点
//   2) title 取首句摘要 (≤30 字),前缀 【概念】/【计算】/【证明】
//   3) 构造 KnowledgeUnit (含 id/tags/truthFlag/timestamps/...)
//   4) truthCheck(ocrText) 返回 TruthCheckResult
//      - 括号配对 / 除零 / 恒等式 / 矛盾等式 / LaTeX 语法
//   5) NoteDao.insert(unit) → rowId → 回填 unit.id
//   6) 返回完整 KnowledgeUnit (UI 直接渲染)
//
// 验证方式: 传 OCR 文本 + 分类结果 → KnowledgeUnit → NoteDao.insert → 查回

import { KnowledgeUnit, DifficultyLevel, ReviewStatus } from 'common';

export class KnowledgeModel {
  // Stub 实现: 返回 mock KnowledgeUnit, 等 C 完成后替换为真实现
  async structure(
    ocrText: string,
    type: string,
    subject: string,
    chapter: string,
  ): Promise<KnowledgeUnit> {
    const now: number = Date.now();
    const unit: KnowledgeUnit = {
      id: 'mock-' + now.toString(16),
      title: '【' + type + '】' + subject + (chapter ? ' - ' + chapter : ''),
      content: ocrText,
      summary: ocrText.substring(0, 100),
      tags: [type, subject],
      difficulty: DifficultyLevel.EASY,
      source: 'capture',
      createdAt: now,
      updatedAt: now,
      reviewStatus: ReviewStatus.NEW,
      nextReviewAt: now + 86400000,
      intervalDays: 1,
      easeFactor: 2.5,
      repetitions: 0,
      prerequisites: [],
      related: [],
      embedding: [],
      userId: 'default',
      version: 1,
    };
    return unit;
  }
}
