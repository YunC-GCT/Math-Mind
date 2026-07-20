// MathMind - Dispatcher (主 Agent 调度中枢) · 精简拍照链
// 任务编号: D
// 责任: Z + Mavis
// 状态: 实现完成(2026-07-14) · 升级 DispatchPayload signature
//
// 职责:
//   接收 DispatchRequest → 调 TypeClassifier 提取文本 → 调 KnowledgeModel → 返回 KnowledgeUnit
//
// 通信模式(按 AGENT_COMMUNICATION.md):
//   - 同进程 import 调函数,无 HTTP / 无 MCP / 无 JWT
//   - 调用方: AiService.capture(imageUri, userText?) 内部 new Dispatcher().dispatch(req)
//
// 精简拍照链(D1 · 7 文件中的 1 个):
//   1) new TypeClassifier().classify(req.payload) → ClassificationResult(含预处理后的 ocrText)
//   2) new KnowledgeModel().structure(ocrText) → KnowledgeUnit
//   3) 失败 catch → errorMessage(不抛异常,UI 用 Toast 提示)
//
// 不做的(按 DISPATCHER_TONIGHT.md 边界):
//   - L1 关键词匹配(只有一个意图,不需要)
//   - L2 DeepSeek 语义兜底(不需要二次判断)
//   - 6 路分发(只 D1,S1 阶段再加 D2-D6)
//   - MCP Client 调用(直接 import Agent)
//   - 4 级失败降级(失败返 errorMessage 即可)
//   - 置信度门控(由 KnowledgeModel.structure 内部决定)
//
// 依赖状态(2026-07-14):
//   - TypeClassifier: stub 接 DispatchPayload, D 接手时填真实现
//   - KnowledgeModel: stub 返 18 字段 mock KnowledgeUnit, L 接手时填真实现
//   当前 build 应过,运行 mock 返数据,等 D/L 完成后跑通真链
//
// 验证方式(等 D 和 L 完成后):
//   const dispatcher = new Dispatcher();
//   const result = await dispatcher.dispatch({
//     source: 'app',
//     payload: { kind: 'image', imageUri: 'file://mock/photo.jpg', userText: '整理成笔记' },
//   });
//   // result.success === true, result.data 是 KnowledgeUnit

import { TypeClassifier, TypeClassifierTextResult } from '../agents/TypeClassifier';
import { KnowledgeModel } from '../agents/KnowledgeModel';
import {
  Logger,
  KnowledgeUnit,
  DispatchRequest,
  DispatchResult,
  DispatchAnalysisResult,
  ClassificationResult,
  ReviewStatus,
  DifficultyLevel,
} from 'common';

const log = new Logger('Dispatcher');

// ==================== 主类 ====================

export class Dispatcher {
  // 只做 OCR + 分类，不调用 KnowledgeModel，不生成笔记
  async analyze(req: DispatchRequest, context?: Context): Promise<DispatchAnalysisResult> {
    const t0: number = Date.now();
    log.info('analyze enter, source=' + req.source
      + ', payload.kind=' + req.payload.kind);

    try {
      const classifier = new TypeClassifier();
      const classification: ClassificationResult = await classifier.classify(req.payload, context);
      let recognizedText: string = classification.ocrText ?? '';
      if (recognizedText.length === 0 && req.payload.kind === 'text') {
        recognizedText = req.payload.text;
      }

      return {
        success: true,
        route: 'D1',
        classification: classification,
        recognizedText: recognizedText,
        durationMs: Date.now() - t0,
      };
    } catch (e) {
      const errMsg: string = (e as Error).message ?? String(e);
      log.error('analyze failed: ' + errMsg);
      return {
        success: false,
        route: 'D1',
        errorMessage: '识别失败: ' + errMsg,
        durationMs: Date.now() - t0,
      };
    }
  }

  // 主入口(精简拍照链 D1)
  // context: 由 AiService 显式传入, 避免 agent 层调用 getContext()
  async dispatch(req: DispatchRequest, context?: Context): Promise<DispatchResult> {
    const t0: number = Date.now();
    log.info('dispatch enter, source=' + req.source
      + ', payload.kind=' + req.payload.kind);

    try {
      // Step 1: OCR/文本提取。类型识别已下沉到 KnowledgeModel，这里只暴露识别内容。
      const classifier = new TypeClassifier();
      const recognized: TypeClassifierTextResult = await classifier.recognizeText(req.payload, context);
      log.info('recognized text prepared, length=' + recognized.text.length.toString());

      // Step 2: 拿识别文本；文本输入如果被预处理成空，fallback 到 payload.text。
      // P0 修复 v2: OCR 空时不再把中文占位符传给 KnowledgeModel
      //   改为在 Dispatcher 层直接构造 fallback KnowledgeUnit，
      //   不调 AI——避免 LLM 把错误提示当数学题处理。
      let ocrText: string = recognized.text;
      if (ocrText === '') {
        if (req.payload.kind === 'text') {
          ocrText = req.payload.text;
          log.info('ocrText fallback to payload.text (text kind)');
        } else {
          // image / file 拿到空 ocrText — 跳过 AI，直接返回 fallback 笔记框架
          log.warn('OCR 返回空, 跳过 KnowledgeModel, 构造 fallback KnowledgeUnit, payload.kind=' + req.payload.kind);
          const fallbackUnit: KnowledgeUnit = this.buildFallbackUnit(
            '概念',
            '',
            '',
          );
          return {
            success: true,
            route: 'D1',
            data: fallbackUnit,
            durationMs: Date.now() - t0,
          };
        }
      }

      // Step 3: 建模 + 真值检验(由 KnowledgeModel 内部完成)
      const model = new KnowledgeModel();
      const unit: KnowledgeUnit = await model.structure(ocrText);
      log.info('structure done, note.id=' + unit.id);

      // Step 4: 返回成功
      return {
        success: true,
        route: 'D1',
        data: unit,
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

  // 兼容旧接口名(原 D 任务规划用 routeDispatch)
  async routeDispatch(req: DispatchRequest, context?: Context): Promise<DispatchResult> {
    return await this.dispatch(req, context);
  }

  // OCR 空 fallback: 不调 AI, 直接构造最小 KnowledgeUnit 框架
  // 避免把中文错误提示当数学题喂给 LLM
  private buildFallbackUnit(type: string, subject: string, chapter: string): KnowledgeUnit {
    const now: number = Date.now();
    const title: string = (type.length > 0 ? type : '未分类题目')
      + (subject.length > 0 ? ' · ' + subject : '')
      + ' (待补充)';
    return {
      id: 'KB-FB-' + now.toString(36) + '-' + Math.random().toString(36).substring(2, 8),
      title: title,
      content: '## 内容\n[OCR 未识别到内容，请人工补充题目详情]',
      summary: 'OCR 暂不可达，已保存框架笔记，请手动编辑补充',
      tags: [type, chapter].filter((s: string): boolean => s.length > 0),
      subject: subject,
      category: type,
      difficulty: DifficultyLevel.MEDIUM,
      source: 'camera_capture',
      createdAt: now,
      updatedAt: now,
      reviewStatus: ReviewStatus.NEW,
      nextReviewAt: now + 24 * 60 * 60 * 1000,
      intervalDays: 1,
      easeFactor: 2.5,
      repetitions: 0,
      prerequisites: [],
      related: [],
      embedding: [],
      userId: '',
      version: 1,
    };
  }
}
