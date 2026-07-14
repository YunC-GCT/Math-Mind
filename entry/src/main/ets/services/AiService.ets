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
  DispatchPayload,
  Logger,
} from 'common';
import { Dispatcher } from 'agents';
import { NoteDao } from '../database/NoteDao';
import { DatabaseHelper } from 'common';

const log: Logger = new Logger('AiService');

export class AiService {
  // 拍照入口
  async capture(imageUri: string, userText?: string): Promise<KnowledgeUnit> {
    log.info('capture start, imageUri=' + imageUri);
    return this.dispatchAndInsert({
      kind: 'image',
      imageUri: imageUri,
      userText: userText,
    });
  }

  // 文本入口
  async captureText(text: string): Promise<KnowledgeUnit> {
    log.info('captureText start, len=' + text.length.toString());
    return this.dispatchAndInsert({
      kind: 'text',
      text: text,
    });
  }

  // 通用: dispatch → 校验 → 入库
  private async dispatchAndInsert(payload: DispatchPayload): Promise<KnowledgeUnit> {
    const req: DispatchRequest = { source: 'app', payload };
    const dispatcher = new Dispatcher();
    const result: DispatchResult = await dispatcher.dispatch(req);

    if (!result.success) {
      const errMsg: string = result.errorMessage ?? 'unknown error';
      log.error('dispatch failed: ' + errMsg);
      throw new Error('处理失败: ' + errMsg);
    }

    const unit: KnowledgeUnit = result.data as KnowledgeUnit;
    if (unit.id === undefined || unit.id === null || unit.id.length === 0) {
      throw new Error('处理失败: KnowledgeUnit.id 为空');
    }

    await this.insertNote(unit);

    log.info('done, note.id=' + unit.id
      + ', type=' + (unit.tags.length > 0 ? unit.tags[0] : '?')
      + ', durationMs=' + result.durationMs.toString());

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