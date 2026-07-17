// MathMind - AiService
//
// Semantic contract:
// - capture(imageUri, userText?) is the app entry for a photo/album image
//   that should be processed into a KnowledgeUnit.
// - It is not a plain chat call. The image path always enters the capture
//   pipeline: Dispatcher -> image/OCR/MCP recognition -> classification ->
//   knowledge structuring -> local persistence.
// - UI code should call capture() whenever the user sends an image.

import {
  KnowledgeUnit,
  DispatchRequest,
  DispatchResult,
  DispatchPayload,
  Logger,
} from 'common';
import { Dispatcher } from 'agents';
import { common } from '@kit.AbilityKit';
import { ImageUriResolver, ResolvedImageFile } from './ImageUriResolver';
import { NoteDao } from '../database/NoteDao';
import { DatabaseHelper } from 'common';

const log: Logger = new Logger('AiService');

export class AiService {
  private context?: common.UIAbilityContext;

  constructor(context?: common.UIAbilityContext) {
    this.context = context;
  }

  // Photo/album image entry: process the image into a persisted KnowledgeUnit.
  async capture(imageUri: string, userText?: string): Promise<KnowledgeUnit> {
    log.info('capture start, imageUri=' + imageUri);
    if (this.context === undefined) {
      throw new Error('AiService.capture requires UIAbilityContext to prepare image file');
    }

    const resolved: ResolvedImageFile = await new ImageUriResolver(this.context).resolve(imageUri);
    log.info('capture image prepared, localPath=' + resolved.localPath);

    return this.processAndPersist({
      kind: 'image',
      imageUri: resolved.localPath,
      userText: userText,
    });
  }

  // Text entry: same knowledge-ingestion contract, without image recognition.
  async captureText(text: string): Promise<KnowledgeUnit> {
    log.info('captureText start, len=' + text.length.toString());
    return this.processAndPersist({
      kind: 'text',
      text: text,
    });
  }

  private async processAndPersist(payload: DispatchPayload): Promise<KnowledgeUnit> {
    const req: DispatchRequest = { source: 'app', payload };
    const dispatcher: Dispatcher = new Dispatcher();
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
      throw new Error('保存笔记失败: ' + JSON.stringify(e));
    }
  }
}
