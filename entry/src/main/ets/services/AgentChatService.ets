import { KnowledgeUnit, ClassificationResult, LlmClient, LlmConfig, ChatMessage } from 'common';
import { common } from '@kit.AbilityKit';
import { AiService } from './AiService';
import { AgentMemoryService } from './AgentMemoryService';

type TextIntent = 'note_generation' | 'chat';

export interface AgentChatCallbacks {
  addAiMsg: (content: string) => void;
  bumpNotesVersion: () => void;
  setBusy: (v: boolean) => void;
  getContext: () => common.UIAbilityContext;
  getConversationText: (excludeLatestUser: boolean) => string;
  getSessionId: () => string;
}

export class AgentChatService {
  private cbs: AgentChatCallbacks;
  private memory: AgentMemoryService | null = null;

  constructor(callbacks: AgentChatCallbacks) {
    this.cbs = callbacks;
  }

  async captureReply(imageUri: string, userText: string): Promise<void> {
    const sessionId: string = this.currentSessionId();
    await this.safeSaveUserMessage(sessionId, userText.trim().length > 0 ? userText : '[图片]');
    this.cbs.setBusy(true);
    try {
      const result: ClassificationResult = await new AiService(this.cbs.getContext()).analyzeImage(imageUri, userText);
      await this.safeSaveOcrResult(sessionId, imageUri, userText, result);
      await this.addAiMessage(sessionId, this.formatAnalyzeReply(result));
    } catch (e) {
      await this.addAiMessage(sessionId, '图片识别失败: ' + AgentChatService.errorMessage(e).substring(0, 120));
    } finally {
      this.cbs.setBusy(false);
    }
  }

  async realReply(userContent: string): Promise<void> {
    const intent: TextIntent = await this.classifyTextIntent(userContent);
    if (intent === 'note_generation') {
      await this.generateNoteFromConversation(userContent);
      return;
    }

    const sessionId: string = this.currentSessionId();
    const memoryContext: string = await this.safeGetContextForReply(sessionId);
    const learnerProfileContext: string = await this.safeGetLearnerProfileContext(sessionId);
    await this.safeSaveUserMessage(sessionId, userContent);
    this.cbs.setBusy(true);
    try {
      const configured: boolean = await LlmConfig.getInstance().isConfigured();
      if (!configured) {
        await this.addAiMessage(sessionId, '⚠️ 请先在「我的 → 设置」中配置 API Key');
        return;
      }
      const client: LlmClient = new LlmClient();
      const reply: string = await client.call(this.buildReplyMessages(memoryContext, learnerProfileContext, userContent), {
        maxTokens: 4096,
        timeoutMs: 120000,
      });
      await this.addAiMessage(sessionId, reply);
      await this.safeUpdateLearnerProfileIfNeeded(sessionId);
      await this.safeSummarizeIfNeeded(sessionId);
    } catch (e) {
      const errMsg: string = AgentChatService.errorMessage(e);
      if (errMsg.indexOf('NO_API_KEY') >= 0) {
        await this.addAiMessage(sessionId, '⚠️ 请先在「我的 → 设置」中配置 API Key');
      } else if (errMsg.indexOf('NETWORK_ERROR') >= 0) {
        await this.addAiMessage(sessionId, '⚠️ 网络连接失败，请检查网络后重试');
      } else {
        await this.addAiMessage(sessionId, '⚠️ AI 回复异常: ' + errMsg.substring(0, 100));
      }
    } finally {
      this.cbs.setBusy(false);
    }
  }

  private async generateNoteFromConversation(userInstruction: string): Promise<void> {
    const sessionId: string = this.currentSessionId();
    const intent: TextIntent = await this.classifyTextIntent(userInstruction);
    if (intent !== 'note_generation') {
      console.warn('[AgentChatService] blocked note generation without explicit intent');
      return;
    }
    const memoryContext: string = await this.safeGetContextForNoteGeneration(sessionId);
    await this.safeSaveUserMessage(sessionId, userInstruction);
    this.cbs.setBusy(true);
    try {
      const configured: boolean = await LlmConfig.getInstance().isConfigured();
      if (!configured) {
        await this.addAiMessage(sessionId, '⚠️ 请先在「我的 → 设置」中配置 API Key');
        return;
      }

      let conversation: string = memoryContext.trim();
      if (conversation.length === 0) {
        conversation = this.cbs.getConversationText(true).trim();
      }
      if (conversation.length === 0) {
        await this.addAiMessage(sessionId, '当前会话还没有可整理的内容');
        return;
      }

      const summary: string = await this.summarizeConversation(conversation, userInstruction);
      const unit: KnowledgeUnit = await new AiService(this.cbs.getContext()).captureText(summary);
      this.cbs.bumpNotesVersion();
      await this.safeMarkPendingMaterialUsed(sessionId);
      await this.addAiMessage(sessionId, '已生成笔记：' + unit.title);
      await this.safeSummarizeIfNeeded(sessionId);
    } catch (e) {
      const errMsg: string = AgentChatService.errorMessage(e);
      await this.addAiMessage(sessionId, '生成笔记失败: ' + errMsg.substring(0, 120));
    } finally {
      this.cbs.setBusy(false);
    }
  }

  private async summarizeConversation(conversation: string, userInstruction: string): Promise<string> {
    const clipped: string = this.clip(conversation, 32000);
    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: '你负责把 MathMind 当前对话整理成 KnowledgeModel.structure 可直接使用的“完整笔记原材料”，不是短摘要。请用稳定、结构化的中文输出，包含：主题/标题候选、原题或原始材料、关键公式、推导/步骤、结论、易错点、用户补充、上下文来源。不要丢数学细节，不要只给一句总结，不要输出 markdown 代码块，不要编造对话中没有的信息；无法确定的内容标注为“未提供”或省略。',
      },
      {
        role: 'user',
        content: '用户生成指令:\n' + userInstruction + '\n\n当前记忆上下文:\n' + clipped,
      },
    ];
    const client: LlmClient = new LlmClient();
    return await client.call(messages, {
      maxTokens: 8192,
      timeoutMs: 120000,
    });
  }

  private buildReplyMessages(memoryContext: string, learnerProfileContext: string, userContent: string): ChatMessage[] {
    let systemPrompt: string = '你是 MathMind AI 数学助手。回答要求：\n'
      + '1. 先判断用户当前意图，再结合 Learner profile 的生效水平调整解释密度；不要把所有问题套成同一种结构。\n'
      + '2. 当前用户明确要求“详细讲”“像小白一样讲”“直接给答案”“不要展开”时，本轮优先服从当前指令，而不是画像。\n'
      + '3. beginner：少术语，多直观解释、例子和关键易错点；步骤可以更细，但仍要避免空泛寒暄。\n'
      + '4. novice：默认给思路、必要步骤和结论；只在概念题、用户困惑或关键门槛处补直观解释，不要每题都写完整四段式。\n'
      + '5. advanced：默认直接给公式、推导主线、结论和边界条件；压缩基础定义、直观比喻和常见误区，除非用户要求展开。\n'
      + '6. 简单事实或短计算：先给答案，再用 1-3 个短步骤说明理由。\n'
      + '7. 总结/整理/复盘：使用标题和要点，覆盖核心结论、原因、方法、待补充内容；不要只输出一句总结。\n'
      + '8. 信息不足时先说明缺少什么，可以基于上文给出合理假设；无法确定时追问，不编造题目或结论。\n'
      + '9. 不要主动生成笔记；只有系统已判定用户明确要保存/生成笔记时，才会走笔记生成链路。\n'
      + '10. 数学符号用 Unicode 或 LaTeX，排版要便于手机端阅读。LaTeX 必须带 delimiter：行内公式用 $...$，展示公式用 $$...$$；不要输出裸 \\mu、\\sigma、\\text{erf}，不要用单独的 [ ] 包公式。';
    const profileContext: string = learnerProfileContext.trim();
    if (profileContext.length > 0) {
      systemPrompt += '\n\n用户画像如下，只用于控制解释密度和回答粒度，不要在回答中复述画像：\n' + profileContext;
    }
    const context: string = memoryContext.trim();
    if (context.length > 0) {
      systemPrompt += '\n\n可参考的会话记忆如下，只在相关时使用，不要主动生成笔记：\n' + this.clip(context, 12000);
    }
    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: systemPrompt,
      },
      {
        role: 'user',
        content: userContent,
      },
    ];
    return messages;
  }

  private async classifyTextIntent(userContent: string): Promise<TextIntent> {
    const normalized: string = userContent.trim();
    if (normalized.length === 0) { return 'chat'; }
    if (this.hasNoteGenerationDenyIntent(normalized)) { return 'chat'; }
    if (this.hasExplicitNoteGenerationIntent(normalized)) { return 'note_generation'; }
    if (!this.shouldUseRemoteIntentClassifier(normalized)) { return 'chat'; }

    try {
      const configured: boolean = await LlmConfig.getInstance().isConfigured();
      if (!configured) { return 'chat'; }
      const messages: ChatMessage[] = this.buildIntentMessages(normalized);
      const raw: string = await new LlmClient().call(messages, {
        maxTokens: 80,
        timeoutMs: 30000,
      });
      return this.parseTextIntent(raw);
    } catch (e) {
      console.warn('[AgentChatService] text intent classify failed: ' + AgentChatService.errorMessage(e));
      return 'chat';
    }
  }

  private buildIntentMessages(userContent: string): ChatMessage[] {
    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: 'Classify the MathMind user message intent. Return strict JSON only: {"intent":"note_generation"} or {"intent":"chat"}. note_generation means the user wants current/previous/provided content turned into saveable learning material, such as a note, knowledge point, notebook entry, retained problem record, or material to store for later review. This includes natural requests like remembering/saving the above problem as study material even if the wording is informal. Return chat for normal Q&A, explanation, calculation, practice generation, casual chat, or temporary summarization/organization where the user only wants an answer and does not imply saving or forming reusable learning material. If uncertain, return chat.',
      },
      {
        role: 'user',
        content: userContent,
      },
    ];
    return messages;
  }

  private parseTextIntent(raw: string): TextIntent {
    const jsonText: string = this.extractJsonObject(raw);
    if (jsonText.length === 0) { return 'chat'; }
    try {
      const parsed: Record<string, Object> = JSON.parse(jsonText) as Record<string, Object>;
      const value: Object | undefined = parsed['intent'];
      if (typeof value === 'string' && value === 'note_generation') {
        return 'note_generation';
      }
    } catch (e) {
      console.warn('[AgentChatService] parse intent json failed: ' + AgentChatService.errorMessage(e));
    }
    return 'chat';
  }

  private extractJsonObject(raw: string): string {
    const trimmed: string = raw.trim();
    const codeMatch: RegExpMatchArray | null = trimmed.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    let source: string = trimmed;
    if (codeMatch !== null && codeMatch.length >= 2) {
      source = codeMatch[1].trim();
    }
    const braceMatch: RegExpMatchArray | null = source.match(/\{[\s\S]*\}/);
    if (braceMatch !== null && braceMatch.length > 0) {
      return braceMatch[0];
    }
    return '';
  }

  private shouldUseRemoteIntentClassifier(text: string): boolean {
    const intentWords: string[] = [
      '生成',
      '创建',
      '新建',
      '整理',
      '保存',
      '存',
      '记',
      '总结',
      '归纳',
      '提炼',
      '收进',
      '加入',
      '转成',
      '转为',
      '做成',
      '笔记',
      '知识点',
      '上面',
      '上文',
      '刚才',
      '这段',
      '这些',
      '内容',
    ];
    return this.includesAny(text, intentWords);
  }

  private hasNoteGenerationDenyIntent(text: string): boolean {
    const denyPhrases: string[] = [
      '不要生成',
      '别生成',
      '无需生成',
      '不用生成',
      '不要创建',
      '别创建',
      '不要保存',
      '别保存',
      '不要记',
      '别记',
      '不用记',
      '不要笔记',
      '不用笔记',
      '无需笔记',
    ];
    return this.includesAny(text, denyPhrases);
  }

  private hasExplicitNoteGenerationIntent(text: string): boolean {
    const phrases: string[] = [
      '生成笔记',
      '创建笔记',
      '新建笔记',
      '整理成笔记',
      '整理为笔记',
      '保存为笔记',
      '保存成笔记',
      '总结成笔记',
      '总结为笔记',
      '归纳成笔记',
      '归纳为笔记',
      '做成笔记',
      '转成笔记',
      '转为笔记',
      '记一下',
      '记下',
      '记下来',
      '帮我记下来',
      '这个记下来',
      '把这个记下来',
      '把这题记下来',
      '把上面记下来',
      '把刚才记下来',
      '收进笔记',
      '加入笔记',
      '存到笔记',
      '存进笔记',
      '留作笔记',
      '保存这个知识点',
      '把这个知识点存起来',
      '这个知识点存起来',
      '知识点存起来',
      '生成知识点',
      '整理成知识点',
      '整理为知识点',
      '总结成知识点',
      '总结为知识点',
      '提炼成知识点',
      '提炼为知识点',
    ];
    if (this.includesAny(text, phrases)) { return true; }

    const createActions: string[] = ['生成', '创建', '新建'];
    const transformActions: string[] = ['整理成', '整理为', '保存为', '保存成', '总结成', '总结为', '归纳成', '归纳为', '做成', '转成', '转为', '提炼成', '提炼为', '收进', '加入', '存到', '存进', '留作'];
    const noteTargets: string[] = ['笔记', '知识点'];
    const rememberActions: string[] = ['记', '保存', '存'];
    const currentTargets: string[] = ['这个', '这题', '上面', '上文', '刚才', '这段', '这些', '知识点'];
    return this.hasActionNearTarget(text, createActions, noteTargets, 4)
      || this.hasActionNearTarget(text, transformActions, noteTargets, 6)
      || this.hasActionNearTarget(text, currentTargets, rememberActions, 8);
  }

  private formatAnalyzeReply(result: ClassificationResult): string {
    const ocrText: string = (result.ocrText ?? '').trim();
    const body: string = ocrText.length > 0 ? this.clip(ocrText, 1600) : '未识别到可展示文本';
    const chapter: string = result.chapter !== undefined && result.chapter.length > 0 ? result.chapter : '未识别';
    return '已识别内容，暂不生成笔记。\n\n'
      + '类型：' + result.type + '\n'
      + '学科：' + result.subject + '\n'
      + '章节：' + chapter + '\n'
      + '置信度：' + result.confidence.toString() + '\n\n'
      + '识别内容：\n' + body + '\n\n'
      + '需要保存时，请发送“生成笔记”或“整理成笔记”。';
  }

  private includesAny(text: string, phrases: string[]): boolean {
    for (const phrase of phrases) {
      if (text.indexOf(phrase) >= 0) { return true; }
    }
    return false;
  }

  private hasActionNearTarget(text: string, actions: string[], targets: string[], maxGap: number): boolean {
    for (const action of actions) {
      let actionIndex: number = text.indexOf(action);
      while (actionIndex >= 0) {
        const afterAction: number = actionIndex + action.length;
        for (const target of targets) {
          const targetIndex: number = text.indexOf(target, afterAction);
          if (targetIndex >= 0 && targetIndex - afterAction <= maxGap) {
            return true;
          }
        }
        actionIndex = text.indexOf(action, afterAction);
      }
    }
    return false;
  }

  private clip(text: string, limit: number): string {
    if (text.length <= limit) { return text; }
    return text.substring(0, limit) + '\n...';
  }

  private currentSessionId(): string {
    const sessionId: string = this.cbs.getSessionId();
    return sessionId.length > 0 ? sessionId : 's1';
  }

  private getMemory(): AgentMemoryService {
    if (this.memory === null) {
      this.memory = new AgentMemoryService(this.cbs.getContext());
    }
    return this.memory;
  }

  private async addAiMessage(sessionId: string, content: string): Promise<void> {
    this.cbs.addAiMsg(content);
    await this.safeSaveAssistantMessage(sessionId, content);
  }

  private async safeSaveUserMessage(sessionId: string, content: string): Promise<void> {
    try {
      await this.getMemory().saveMessage(sessionId, 'user', content);
    } catch (e) {
      console.warn('[AgentChatService] save user memory failed: ' + AgentChatService.errorMessage(e));
    }
  }

  private async safeSaveAssistantMessage(sessionId: string, content: string): Promise<void> {
    try {
      await this.getMemory().saveMessage(sessionId, 'assistant', content);
    } catch (e) {
      console.warn('[AgentChatService] save assistant memory failed: ' + AgentChatService.errorMessage(e));
    }
  }

  private async safeSaveOcrResult(
    sessionId: string,
    imageUri: string,
    userText: string,
    result: ClassificationResult,
  ): Promise<void> {
    try {
      await this.getMemory().saveOcrResult(sessionId, imageUri, userText, result);
    } catch (e) {
      console.warn('[AgentChatService] save ocr memory failed: ' + AgentChatService.errorMessage(e));
    }
  }

  private async safeGetContextForReply(sessionId: string): Promise<string> {
    try {
      return await this.getMemory().getContextForReply(sessionId);
    } catch (e) {
      console.warn('[AgentChatService] load reply memory failed: ' + AgentChatService.errorMessage(e));
      return '';
    }
  }

  private async safeGetContextForNoteGeneration(sessionId: string): Promise<string> {
    try {
      return await this.getMemory().getContextForNoteGeneration(sessionId);
    } catch (e) {
      console.warn('[AgentChatService] load note memory failed: ' + AgentChatService.errorMessage(e));
      return '';
    }
  }

  private async safeGetLearnerProfileContext(sessionId: string): Promise<string> {
    try {
      return await this.getMemory().getLearnerProfileContext(sessionId);
    } catch (e) {
      console.warn('[AgentChatService] load learner profile failed: ' + AgentChatService.errorMessage(e));
      return '';
    }
  }

  private async safeUpdateLearnerProfileIfNeeded(sessionId: string): Promise<void> {
    try {
      await this.getMemory().updateLearnerProfileIfNeeded(sessionId);
    } catch (e) {
      console.warn('[AgentChatService] update learner profile failed: ' + AgentChatService.errorMessage(e));
    }
  }

  private async safeMarkPendingMaterialUsed(sessionId: string): Promise<void> {
    try {
      await this.getMemory().markPendingMaterialUsed(sessionId);
    } catch (e) {
      console.warn('[AgentChatService] mark pending memory failed: ' + AgentChatService.errorMessage(e));
    }
  }

  private async safeSummarizeIfNeeded(sessionId: string): Promise<void> {
    try {
      await this.getMemory().summarizeSessionIfNeeded(sessionId);
    } catch (e) {
      console.warn('[AgentChatService] summarize memory failed: ' + AgentChatService.errorMessage(e));
    }
  }

  private static errorMessage(e: Object): string {
    const message: string | undefined = (e as Error).message;
    if (message !== undefined && message.length > 0) {
      return message;
    }
    return JSON.stringify(e);
  }
}
