// ============================================================================
//  services/AiService.ets — 拍照→AI 整链入口
//  ----------------------------------------------------------------------------
//  职责: 拍照/选图/文本的统一入口,把外部输入转成 KnowledgeUnit 并入库。
//
//  接口约定:
//    - capture(imageUri, userText?): Promise<KnowledgeUnit>
//        拍照/相册的入口。绝不只走 LLM 对话,必须进入 capture pipeline:
//        Dispatcher -> image/OCR/MCP 识别 -> 分类 -> 知识结构化 -> 入库。
//    - captureText(text): Promise<KnowledgeUnit>
//        文本入口。同样的知识入库契约,跳过图像识别。
//
//  UI 端约束: 凡是发图的,都必须调 capture() 而不是 LLM 对话。
//
//  整链调用链:
//    ImageUriResolver.resolve(uri)  // file:// URI 复制到沙箱
//    -> Dispatcher.dispatch(payload)  // 调度中枢
//      -> TypeClassifier.classify()   // OCR + DeepSeek 3×3 分类
//        -> OcrTool.recognize()       // 本地 FastAPI HTTP OCR
//      -> KnowledgeModel.structure()  // 模板填充 + 真值检验
//    -> NoteDao.insert(unit)         // RDB 持久化
//  ============================================================================

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
  // UIAbilityContext 引用,capture() 准备图片文件时用
  private context?: common.UIAbilityContext;

  constructor(context?: common.UIAbilityContext) {
    this.context = context;
  }

  // 拍照/相册入口:把图片处理成 KnowledgeUnit 并持久化
  async capture(imageUri: string, userText?: string): Promise<KnowledgeUnit> {
    log.info('capture start, imageUri=' + imageUri);
    if (this.context === undefined) {
      throw new Error('AiService.capture 需要 UIAbilityContext 来准备图片文件');
    }

    // 1) 把 file:// URI 复制到沙箱(本地路径,OCR/Dao 都能访问)
    const resolved: ResolvedImageFile = await new ImageUriResolver(this.context).resolve(imageUri);
    log.info('capture 图片已准备,本地路径=' + resolved.localPath);

    // 2) 走整链
    return this.processAndPersist({
      kind: 'image',
      imageUri: resolved.localPath,
      userText: userText,
    });
  }

  // 文本入口:同样的知识入库契约,跳过图像识别
  async captureText(text: string): Promise<KnowledgeUnit> {
    log.info('captureText start, 长度=' + text.length.toString());
    return this.processAndPersist({
      kind: 'text',
      text: text,
    });
  }

  // 内部: 调度 -> 校验 -> 入库
  private async processAndPersist(payload: DispatchPayload): Promise<KnowledgeUnit> {
    // 1) 构造调度请求
    const req: DispatchRequest = { source: 'app', payload };

    // 2) 调度 Dispatcher(类型严格 ArkTS 1.1,显式标注)
    const dispatcher: Dispatcher = new Dispatcher();
    const result: DispatchResult = await dispatcher.dispatch(req);

    // 3) 调度失败 → 抛错(UI 用 Toast 提示)
    if (!result.success) {
      const errMsg: string = result.errorMessage ?? 'unknown error';
      log.error('dispatch 失败: ' + errMsg);
      throw new Error('处理失败: ' + errMsg);
    }

    // 4) 校验 KnowledgeUnit.id 必须存在
    const unit: KnowledgeUnit = result.data as KnowledgeUnit;
    if (unit.id === undefined || unit.id === null || unit.id.length === 0) {
      throw new Error('处理失败: KnowledgeUnit.id 为空');
    }

    // 5) 持久化
    await this.insertNote(unit);

    log.info('done, 笔记 id=' + unit.id
      + ', 类型=' + (unit.tags.length > 0 ? unit.tags[0] : '?')
      + ', 耗时 ms=' + result.durationMs.toString());

    return unit;
  }

  // 内部: 入库(RDB)
  private async insertNote(unit: KnowledgeUnit): Promise<void> {
    try {
      const rdb = DatabaseHelper.getStore();
      if (rdb !== null) {
        const dao: NoteDao = new NoteDao(rdb);
        const rowId: number = await dao.insert(unit);
        log.info('NoteDao.insert 成功,rowId=' + rowId.toString());
      }
    } catch (e) {
      log.error('NoteDao.insert 失败: ' + JSON.stringify(e));
      throw new Error('保存笔记失败: ' + JSON.stringify(e));
    }
  }
}
