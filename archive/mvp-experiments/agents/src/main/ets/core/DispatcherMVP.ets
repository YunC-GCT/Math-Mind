// MathMind - DispatcherMVP (主 Agent 调度中枢) · KnowledgeModelMVP 版
// 任务编号: D
// 责任: L (基于 Z + Mavis 原版修改)
// 状态: MVP 集成版(2026-07-16)
//
// 职责:
//   接收 DispatchRequest → 调 TypeClassifier(仅取ocrText) → 调 KnowledgeModelMVP → 返回 KnowledgeUnitExt
//
// 与原版 Dispatcher.ets 的区别:
//   1) 使用 KnowledgeModelMVP 替代旧 KnowledgeModel
//   2) MVP 自己做 AI 自分词(5 类),不再需要 TypeClassifier 的分类结果
//   3) MVP 内部完成 truthCheck + NoteDao.insert, 调用方无需再入库
//   4) 构造函数接收 NoteDaoInterface, 传给 MVP 用于入库
//
// 依赖状态(2026-07-16):
//   - TypeClassifier: 仅用于提取 ocrText(图片时 OCR,文本时返回 payload.text)
//   - KnowledgeModelMVP: 已实现 — AI 自分词 + 真值检验 + 入库

import { TypeClassifier } from '../agents/TypeClassifier';
import { KnowledgeModelMVP } from '../agents/KnowledgeModelMVP';
import {
  NoteDaoInterface,
} from '../models/NoteDaoInterface';
import {
  KnowledgeUnitExt,
} from '../models/KnowledgeUnitExt';
import {
  Logger,
  DispatchRequest,
  DispatchResult,
  ClassificationResult,
} from 'common';

const log = new Logger('DispatcherMVP');

// ==================== 主类 ====================

export class DispatcherMVP {
  private noteDao: NoteDaoInterface;
  // 最后一次成功调用的 KnowledgeUnitExt 结果, 供调用方读取
  public lastUnit: KnowledgeUnitExt | null = null;

  constructor(noteDao: NoteDaoInterface) {
    this.noteDao = noteDao;
  }

  /**
   * 主入口：提取 ocrText → KnowledgeModelMVP 自分词+结构化+入库
   *
   * @param req - 调度请求（含 payload 和来源标识）
   * @returns DispatchResult（成功时 lastUnit 保存结果）
   */
  async dispatch(req: DispatchRequest): Promise<DispatchResult> {
    const t0: number = Date.now();
    log.info('dispatch enter, source=' + req.source
      + ', payload.kind=' + req.payload.kind);

    try {
      // Step 1: 提取 ocrText(图片走 OCR,文本直接取 payload.text)
      const classifier = new TypeClassifier();
      const classification: ClassificationResult = await classifier.classify(req.payload);
      log.info('ocrText extracted, confidence=' + classification.confidence.toString());

      // Step 2: 处理 ocrText 为空的情况
      let ocrText: string = classification.ocrText ?? '';
      if (ocrText === '') {
        if (req.payload.kind === 'text') {
          ocrText = req.payload.text;
          log.info('ocrText fallback to payload.text (text kind)');
        } else {
          return {
            success: false,
            route: 'D1',
            errorMessage: 'TypeClassifier 未返回 ocrText,且 payload 非 text 类型无法 fallback',
            durationMs: Date.now() - t0,
          };
        }
      }

      // Step 3: KnowledgeModelMVP 自分词 + 结构化 + 真值检验 + 入库(一次性完成)
      const model = new KnowledgeModelMVP(this.noteDao);
      const unit: KnowledgeUnitExt = await model.structure(ocrText);
      log.info('structure done, note.id=' + unit.id
        + ', category=' + unit.type
        + ', truthFlag=' + unit.truthFlag.toString());

      // Step 4: 存入 lastUnit 供调用方读取, 返回成功
      this.lastUnit = unit;
      return {
        success: true,
        route: 'D1',
        durationMs: Date.now() - t0,
      };
    } catch (e) {
      // 失败:返回错误信息(不抛异常,UI 用 errorMessage 提示)
      const errMsg: string = (e as Error).message ?? String(e);
      log.error('dispatch failed: ' + errMsg);
      return {
        success: false,
        route: 'D1',
        errorMessage: '拍照处理失败: ' + errMsg,
        durationMs: Date.now() - t0,
      };
    }
  }
}
