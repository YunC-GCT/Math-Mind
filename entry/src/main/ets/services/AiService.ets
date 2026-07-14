// MathMind - AiService (拍照/调用 Dispatcher 胶水层 + 入库)
// 任务编号: E1
// 责任: Z
// 状态: 实现完成(2026-07-14) — 精简拍照链
//
// 流程:
//   imageUri → Dispatcher.dispatch()
//     → TypeClassifier.classify() → LlmClient 分类
//     → KnowledgeModel.structure() → LlmClient 结构化 + 真值检验
//   ← KnowledgeUnit → NoteDao.insert() → RDB 写入

import {
  KnowledgeUnit,
  DispatchRequest,
  DispatchResult,
  Logger,
} from 'common';
import { Dispatcher } from 'agents';
import { NoteDao } from '../database/NoteDao';
import { DatabaseHelper } from 'common';

const log: Logger = new Logger('AiService');

export class AiService {
  // 拍照入口: 传入图片 URI → 返回完整 KnowledgeUnit (已入库)
  async capture(imageUri: string, userText?: string): Promise<KnowledgeUnit> {
    log.info('capture start, imageUri=' + imageUri);

    const req: DispatchRequest = {
      source: 'app',
      payload: {
        kind: 'image',
        imageUri: imageUri,
        userText: userText,
      },
    };

    const dispatcher = new Dispatcher();
    const result: DispatchResult = await dispatcher.dispatch(req);

    if (!result.success) {
      const errMsg: string = result.errorMessage ?? 'unknown error';
      log.error('capture failed: ' + errMsg);
      throw new Error('拍照处理失败: ' + errMsg);
    }

    const unit: KnowledgeUnit = result.data as KnowledgeUnit;
    if (unit.id === undefined || unit.id === null || unit.id.length === 0) {
      throw new Error('拍照处理失败: KnowledgeUnit.id 为空');
    }

    // 入库
    await this.insertNote(unit);

    log.info('capture done, note.id=' + unit.id
      + ', type=' + (unit.tags.length > 0 ? unit.tags[0] : '?')
      + ', durationMs=' + result.durationMs.toString());

    return unit;
  }

  // 文本入口: 直接传文本 → Dispatcher
  async captureText(text: string): Promise<KnowledgeUnit> {
    log.info('captureText start, len=' + text.length.toString());

    const req: DispatchRequest = {
      source: 'app',
      payload: {
        kind: 'text',
        text: text,
      },
    };

    const dispatcher = new Dispatcher();
    const result: DispatchResult = await dispatcher.dispatch(req);

    if (!result.success) {
      throw new Error('文本处理失败: ' + (result.errorMessage ?? 'unknown error'));
    }

    const unit: KnowledgeUnit = result.data as KnowledgeUnit;

    // 入库
    await this.insertNote(unit);

    log.info('captureText done, note.id=' + unit.id);
    return unit;
  }

  // 内部: 入库
  private async insertNote(unit: KnowledgeUnit): Promise<void> {
    try {
      const rdb = DatabaseHelper.getStore();
      if (rdb !== null) {
        const dao = new NoteDao(rdb);
        const rowId: number = await dao.insert(unit);
        log.info('NoteDao.insert ok, rowId=' + rowId.toString());
      }
    } catch (e) {
      log.error('NoteDao.insert failed: ' + JSON.stringify(e));
    }
  }
}