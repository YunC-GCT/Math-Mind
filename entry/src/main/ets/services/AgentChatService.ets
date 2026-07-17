/**
 * AgentChatService.ets — AI 对话业务逻辑层
 *
 * 路径: entry/src/main/ets/services/AgentChatService.ets
 * 职责: 封装 LLM 对话、拍照整链、文本持久化等异步业务逻辑
 *       通过回调接口操作 UI 状态，不依赖任何 ArkUI 装饰器
 *
 * 依赖: common (LlmClient/LlmConfig/KnowledgeUnit), AiService
 *
 * 设计要点:
 *   - 纯逻辑类，可在非 UI 线程调用
 *   - 所有 UI 操作通过 AgentChatCallbacks 回调
 *   - AgentFloatWindow 只需创建 service + 绑定回调 → 调用方法
 */

import { KnowledgeUnit, LlmClient, LlmConfig } from 'common';
import { AiService } from './AiService';
import { common } from '@kit.AbilityKit';

// 服务回调接口：AgentChatService 通过此接口操作 UI 状态
export interface AgentChatCallbacks {
  // 添加一条 AI 消息到列表
  addAiMsg: (content: string) => void;
  // 通知笔记列表刷新
  bumpNotesVersion: () => void;
  // 设置 busy 状态
  setBusy: (v: boolean) => void;
  // 获取 UIAbilityContext (用于 AiService)
  getContext: () => common.UIAbilityContext;
}

export class AgentChatService {
  private cbs: AgentChatCallbacks;

  constructor(callbacks: AgentChatCallbacks) {
    this.cbs = callbacks;
  }

  // 图片 + 文字 → 整链 (OCR → 分类 → 结构化 → 入库)
  async captureReply(imageUri: string, userText: string): Promise<void> {
    this.cbs.setBusy(true);
    try {
      const configured: boolean = await LlmConfig.getInstance().isConfigured();
      if (!configured) {
        this.cbs.addAiMsg('⚠️ 请先在「我的 → 设置」中配置 API Key');
        this.cbs.setBusy(false);
        return;
      }
      const unit: KnowledgeUnit = await new AiService(this.cbs.getContext()).capture(imageUri, userText);
      this.cbs.bumpNotesVersion();
      this.cbs.addAiMsg('已识别并整理为知识点:\n' + unit.title + '\n\n' + unit.summary);
    } catch (e) {
      this.cbs.addAiMsg('图片处理失败: ' + ((e as Error).message ?? String(e)).substring(0, 120));
    } finally {
      this.cbs.setBusy(false);
    }
  }

  // 纯文字 → LLM 对话
  async realReply(userContent: string): Promise<void> {
    this.cbs.setBusy(true);
    try {
      const configured: boolean = await LlmConfig.getInstance().isConfigured();
      if (!configured) {
        this.cbs.addAiMsg('⚠️ 请先在「我的 → 设置」中配置 API Key');
        this.cbs.setBusy(false);
        return;
      }
      const client: LlmClient = new LlmClient();
      const reply: string = await client.call([
        {
          role: 'system',
          content: '你是 MathMind AI 助手,专门帮助用户解决数学问题。请用简洁清晰的中文回答,适当使用 LaTeX 公式。',
        },
        { role: 'user', content: userContent },
      ]);
      this.cbs.addAiMsg(reply);
      this.persistTextNote(userContent);
    } catch (e) {
      const errMsg: string = (e as Error).message ?? String(e);
      if (errMsg.indexOf('NO_API_KEY') >= 0) {
        this.cbs.addAiMsg('⚠️ 请先在「我的 → 设置」中配置 API Key');
      } else if (errMsg.indexOf('NETWORK_ERROR') >= 0) {
        this.cbs.addAiMsg('⚠️ 网络连接失败,请检查网络后重试');
      } else {
        this.cbs.addAiMsg('⚠️ AI 回复异常: ' + errMsg.substring(0, 100));
      }
    } finally {
      this.cbs.setBusy(false);
    }
  }

  // 文本持久化 (fire-and-forget, 不阻塞 UI)
  private persistTextNote(content: string): void {
    try {
      new AiService(this.cbs.getContext()).captureText(content).then((_unit: KnowledgeUnit): void => {
        console.info('[AgentChatService] text note persisted, id=' + _unit.id);
        this.cbs.bumpNotesVersion();
      }).catch((e: Error): void => {
        console.warn('[AgentChatService] text note persist failed: ' + e.message);
      });
    } catch (e) {
      console.warn('[AgentChatService] persistTextNote init failed: ' + (e as Error).message);
    }
  }
}
