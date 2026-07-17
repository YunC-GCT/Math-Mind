// MathMind - Dispatcher (主 Agent 调度中枢) · 精简拍照链
// 任务编号: D
// 责任: Z + Mavis
// 状态: 实现完成(2026-07-14) · 升级 DispatchPayload signature
//
// 职责:
//   接收 DispatchRequest → 调 TypeClassifier → 调 KnowledgeModel → 返回 KnowledgeUnit
//
// 通信模式(按 AGENT_COMMUNICATION.md):
//   - 同进程 import 调函数,无 HTTP / 无 MCP / 无 JWT
//   - 调用方: AiService.capture(imageUri, userText?) 内部 new Dispatcher().dispatch(req)
//
// 精简拍照链(D1 · 7 文件中的 1 个):
//   1) new TypeClassifier().classify(req.payload) → ClassificationResult(含 ocrText)
//   2) new KnowledgeModel().structure(ocrText, type, subject, chapter) → KnowledgeUnit
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

import { TypeClassifier } from '../agents/TypeClassifier';
import { KnowledgeModel } from '../agents/KnowledgeModel';
import {
  Logger,
  KnowledgeUnit,
  DispatchRequest,
  DispatchResult,
  ClassificationResult,
} from 'common';

const log = new Logger('Dispatcher');

// ==================== 主类 ====================

export class Dispatcher {
  // 主入口(精简拍照链 D1)
  async dispatch(req: DispatchRequest): Promise<DispatchResult> {
    const t0: number = Date.now();
    log.info('dispatch enter, source=' + req.source
      + ', payload.kind=' + req.payload.kind);

    try {
      // Step 1: 分类(图片走 OCR+分类,文本直接分类,TypeClassifier 内部判断)
      const classifier = new TypeClassifier();
      const classification: ClassificationResult = await classifier.classify(req.payload);
      log.info('classification done, type=' + classification.type
        + ', subject=' + classification.subject
        + ', confidence=' + classification.confidence.toString());

      // Step 2: 拿 ocrText(优先用 classification 返的,fallback 到 payload.text)
      // P0 修复: 即使 OCR 失败(空 ocrText), 也不再直接失败。
      //   改为传 placeholder 给 KnowledgeModel, 让它能生成"待人工补充"的笔记框架。
      //   用户体验: 拍照后即使 OCR 不通, 也能看到 AI 给的题目标题/分类, 不再"假成功"也不"假失败"。
      let ocrText: string = classification.ocrText ?? '';
      if (ocrText === '') {
        if (req.payload.kind === 'text') {
          ocrText = req.payload.text;
          log.info('ocrText fallback to payload.text (text kind)');
        } else {
          // image / file 拿到空 ocrText, 走 placeholder 兜底
          // 让 KnowledgeModel 仍能产出一个"待补充内容"的 KnowledgeUnit 框架
          ocrText = '[OCR 暂不可达, 请人工补充题目内容]';
          log.warn('OCR 返回空, 使用 placeholder 兜底, payload.kind=' + req.payload.kind);
        }
      }

      // Step 3: 建模 + 真值检验 + 入库(由 KnowledgeModel 内部完成)
      const model = new KnowledgeModel();
      const unit: KnowledgeUnit = await model.structure(
        ocrText,
        classification.type,
        classification.subject,
        classification.chapter ?? '',
      );
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
  async routeDispatch(req: DispatchRequest): Promise<DispatchResult> {
    return await this.dispatch(req);
  }
}
