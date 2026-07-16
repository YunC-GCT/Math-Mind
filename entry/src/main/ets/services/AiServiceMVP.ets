// MathMind - AiServiceMVP (拍照/调用 DispatcherMVP 胶水层)
// 任务编号: E1
// 责任: L (基于 Z 原版修改)
// 状态: MVP 集成版(2026-07-16) - 使用 RDB 存储
//
// 流程:
//   imageUri → DispatcherMVP.dispatch()
//     → TypeClassifier.classify() → 仅取 ocrText
//     → KnowledgeModelMVP.structure() → AI 自分词(5类) + 结构化 + 真值检验
//   ← KnowledgeUnitExt → NoteDaoMVP 直接入库(RDB, 兼容 KnowledgeUnitExt)
//
// 与原版 AiService.ets 的区别:
//   1) 使用 DispatcherMVP 替代 Dispatcher
//   2) 使用 NoteDaoMVP 直接存 KnowledgeUnitExt(无需转换适配器)
//   3) 不再有独立的 insertNote() — MVP 内部完成入库
//   4) 返回 KnowledgeUnitExt 而非 KnowledgeUnit

import {
  DispatchRequest,
  DispatchPayload,
  Logger,
} from 'common';
import { common } from '@kit.AbilityKit';
import { DispatcherMVP } from 'agents';
import {
  KnowledgeUnitExt,
  NoteDaoInterface,
} from 'agents';
import { NoteDaoMVP } from '../database/NoteDaoMVP';

const log: Logger = new Logger('AiServiceMVP');

// ==================== NoteDao 适配器 (直接转发 KnowledgeUnitExt) ====================
// NoteDaoMVP 直接支持 KnowledgeUnitExt，此适配器仅用于符合 NoteDaoInterface 签名

class NoteDaoAdapter implements NoteDaoInterface {
  private realDao: NoteDaoMVP;

  constructor(dao: NoteDaoMVP) {
    this.realDao = dao;
  }

  async insert(unit: KnowledgeUnitExt): Promise<number> {
    return await this.realDao.insert(unit);
  }

  /**
   * 将 update 转发给真实 NoteDaoMVP 实现
   * NoteDaoAdapter 本身不包含业务逻辑，只做接口适配
   */
  async update(unit: KnowledgeUnitExt): Promise<void> {
    return await this.realDao.update(unit);
  }
}

// ==================== 主类 ====================

export class AiServiceMVP {
  private dispatcher: DispatcherMVP;

  constructor(context: common.UIAbilityContext) {
    const dao: NoteDaoMVP = new NoteDaoMVP(context);
    const adapter: NoteDaoAdapter = new NoteDaoAdapter(dao);
    this.dispatcher = new DispatcherMVP(adapter);
  }

  /**
   * 拍照入口：接收图片 URI，调用 MVP 管线处理后返回结构化结果
   *
   * @param imageUri - 图片文件路径
   * @param userText - 用户补充的文字（可选）
   * @returns 结构化知识单元 KnowledgeUnitExt
   */
  async capture(imageUri: string, userText?: string): Promise<KnowledgeUnitExt> {
    log.info('capture start, imageUri=' + imageUri);
    return this.dispatchAndReturn({
      kind: 'image',
      imageUri: imageUri,
      userText: userText,
    });
  }

  /**
   * 文本入口：接收纯文本，调用 MVP 管线处理后返回结构化结果
   *
   * @param text - 用户输入的数学文本
   * @returns 结构化知识单元 KnowledgeUnitExt
   */
  async captureText(text: string): Promise<KnowledgeUnitExt> {
    log.info('captureText start, len=' + text.length.toString());
    return this.dispatchAndReturn({
      kind: 'text',
      text: text,
    });
  }

  // 通用: dispatch → 校验 → 返回(入库由 MVP 内部完成)
  private async dispatchAndReturn(payload: DispatchPayload): Promise<KnowledgeUnitExt> {
    const req: DispatchRequest = { source: 'app', payload };
    const result = await this.dispatcher.dispatch(req);

    if (!result.success) {
      const errMsg: string = result.errorMessage ?? 'unknown error';
      log.error('dispatch failed: ' + errMsg);
      throw new Error('处理失败: ' + errMsg);
    }

    const unit: KnowledgeUnitExt | null = this.dispatcher.lastUnit;
    if (unit === null || unit.id.length === 0) {
      throw new Error('处理失败: KnowledgeUnitExt.id 为空');
    }

    log.info('done, note.id=' + unit.id
      + ', category=' + unit.type
      + ', truthFlag=' + unit.truthFlag.toString()
      + ', durationMs=' + result.durationMs.toString());

    return unit;
  }
}
