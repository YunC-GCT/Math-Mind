import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ClassificationResult, ChatMessage, DatabaseHelper, LlmClient, LlmConfig } from 'common';
import { AgentMemoryDao } from '../database/AgentMemoryDao';
import { ChatMessageDao } from '../database/ChatMessageDao';
import {
  AgentMemoryRecord,
  ChatMessageRecord,
  ChatRole,
} from '../models/AgentMemoryModels';

const RECENT_REPLY_LIMIT: number = 28;
const RECENT_NOTE_LIMIT: number = 100;
const SUMMARY_THRESHOLD: number = 30;
const SUMMARY_UPDATE_MESSAGE_GAP: number = 16;
const REPLY_CONTEXT_LIMIT: number = 12000;
const NOTE_CONTEXT_LIMIT: number = 32000;
const SUMMARY_CONTEXT_LIMIT: number = 24000;

export class AgentMemoryService {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async saveMessage(sessionId: string, role: ChatRole, content: string): Promise<void> {
    const text: string = content.trim();
    if (sessionId.length === 0 || text.length === 0) {
      return;
    }
    const now: number = Date.now();
    const record: ChatMessageRecord = {
      id: AgentMemoryService.newId('msg'),
      sessionId: sessionId,
      role: role,
      content: text,
      createdAt: now,
    };
    const store: relationalStore.RdbStore = await this.getStore();
    await new ChatMessageDao(store).insert(record);
  }

  async savePendingNoteMaterial(sessionId: string, content: string, source: string): Promise<void> {
    const text: string = content.trim();
    if (sessionId.length === 0 || text.length === 0) {
      return;
    }
    const now: number = Date.now();
    const record: AgentMemoryRecord = {
      id: AgentMemoryService.newId('mem'),
      sessionId: sessionId,
      type: 'pending_note',
      content: text,
      source: source,
      used: 0,
      createdAt: now,
      updatedAt: now,
    };
    const store: relationalStore.RdbStore = await this.getStore();
    await new AgentMemoryDao(store).insert(record);
  }

  async saveOcrResult(
    sessionId: string,
    imageUri: string,
    userText: string,
    result: ClassificationResult,
  ): Promise<void> {
    const lines: string[] = [];
    const instruction: string = userText.trim();
    const ocrText: string = (result.ocrText ?? '').trim();
    const chapter: string = result.chapter !== undefined && result.chapter.length > 0 ? result.chapter : '';
    lines.push('图片识别材料');
    if (instruction.length > 0) {
      lines.push('用户补充: ' + instruction);
    }
    lines.push('类型: ' + result.type);
    lines.push('学科: ' + result.subject);
    if (chapter.length > 0) {
      lines.push('章节: ' + chapter);
    }
    lines.push('置信度: ' + result.confidence.toString());
    if (ocrText.length > 0) {
      lines.push('OCR:');
      lines.push(ocrText);
    }
    await this.savePendingNoteMaterial(sessionId, lines.join('\n'), imageUri);
  }

  async getContextForReply(sessionId: string): Promise<string> {
    const store: relationalStore.RdbStore = await this.getStore();
    const memoryDao: AgentMemoryDao = new AgentMemoryDao(store);
    const messageDao: ChatMessageDao = new ChatMessageDao(store);
    const summary: AgentMemoryRecord | null = await memoryDao.queryLatestSummary(sessionId);
    const messages: ChatMessageRecord[] = await messageDao.queryRecent(sessionId, RECENT_REPLY_LIMIT);
    return AgentMemoryService.buildContextText(summary, [], messages, REPLY_CONTEXT_LIMIT);
  }

  async getContextForNoteGeneration(sessionId: string): Promise<string> {
    const store: relationalStore.RdbStore = await this.getStore();
    const memoryDao: AgentMemoryDao = new AgentMemoryDao(store);
    const messageDao: ChatMessageDao = new ChatMessageDao(store);
    const summary: AgentMemoryRecord | null = await memoryDao.queryLatestSummary(sessionId);
    const pendingNotes: AgentMemoryRecord[] = await memoryDao.queryPendingNotes(sessionId);
    const messages: ChatMessageRecord[] = await messageDao.queryRecent(sessionId, RECENT_NOTE_LIMIT);
    return AgentMemoryService.buildContextText(summary, pendingNotes, messages, NOTE_CONTEXT_LIMIT);
  }

  async summarizeSessionIfNeeded(sessionId: string): Promise<void> {
    const store: relationalStore.RdbStore = await this.getStore();
    const memoryDao: AgentMemoryDao = new AgentMemoryDao(store);
    const existingSummary: AgentMemoryRecord | null = await memoryDao.queryLatestSummary(sessionId);

    const messages: ChatMessageRecord[] = await new ChatMessageDao(store).queryAll(sessionId);
    if (messages.length <= SUMMARY_THRESHOLD) {
      return;
    }

    const messagesAfterSummary: ChatMessageRecord[] = AgentMemoryService.messagesAfterSummary(messages, existingSummary);
    if (existingSummary !== null && messagesAfterSummary.length < SUMMARY_UPDATE_MESSAGE_GAP) {
      return;
    }

    const configured: boolean = await LlmConfig.getInstance().isConfigured();
    if (!configured) {
      return;
    }

    const content: string = AgentMemoryService.buildSummarySource(existingSummary, messages, messagesAfterSummary);
    const llmMessages: ChatMessage[] = [
      {
        role: 'system',
        content: '请把 MathMind 当前会话更新为后续对话可用的 session summary。输出稳定、结构化、信息密集的中文摘要，保留：题目/原始材料、关键公式、用户目标、已识别 OCR 材料、已讲解结论、待整理内容、未解决问题。避免寒暄、评价和重复；不要编造没有出现在材料里的信息；如果某项没有信息可省略。已有 summary 只是参考，请结合新增消息生成一份最新 summary。',
      },
      {
        role: 'user',
        content: content,
      },
    ];
    const summaryText: string = await new LlmClient().call(llmMessages, {
      maxTokens: 2048,
      timeoutMs: 120000,
    });
    const now: number = Date.now();
    const summaryRecord: AgentMemoryRecord = {
      id: AgentMemoryService.newId('sum'),
      sessionId: sessionId,
      type: 'summary',
      content: summaryText,
      source: 'session',
      used: 0,
      createdAt: now,
      updatedAt: now,
    };
    await memoryDao.insert(summaryRecord);
  }

  async markPendingMaterialUsed(sessionId: string): Promise<void> {
    const store: relationalStore.RdbStore = await this.getStore();
    await new AgentMemoryDao(store).markPendingUsed(sessionId);
  }

  private async getStore(): Promise<relationalStore.RdbStore> {
    let store: relationalStore.RdbStore | null = DatabaseHelper.getStore();
    if (store === null) {
      store = await DatabaseHelper.init(this.context);
    }
    return store;
  }

  private static buildContextText(
    summary: AgentMemoryRecord | null,
    pendingNotes: AgentMemoryRecord[],
    messages: ChatMessageRecord[],
    limit: number,
  ): string {
    const parts: string[] = [];
    if (summary !== null && summary.content.trim().length > 0) {
      parts.push('Session summary:\n' + summary.content.trim());
    }
    if (pendingNotes.length > 0) {
      const pendingLines: string[] = [];
      for (const pending of pendingNotes) {
        if (pending.content.trim().length > 0) {
          pendingLines.push(pending.content.trim());
        }
      }
      if (pendingLines.length > 0) {
        parts.push('Pending note materials:\n' + pendingLines.join('\n\n'));
      }
    }
    if (messages.length > 0) {
      parts.push('Recent messages:\n' + AgentMemoryService.formatMessages(messages, limit));
    }
    return AgentMemoryService.clip(parts.join('\n\n'), limit);
  }

  private static buildSummarySource(
    existingSummary: AgentMemoryRecord | null,
    messages: ChatMessageRecord[],
    messagesAfterSummary: ChatMessageRecord[],
  ): string {
    const parts: string[] = [];
    if (existingSummary !== null && existingSummary.content.trim().length > 0) {
      parts.push('Existing session summary:\n' + existingSummary.content.trim());
      parts.push('New messages after existing summary:\n'
        + AgentMemoryService.formatMessages(messagesAfterSummary, SUMMARY_CONTEXT_LIMIT));
    } else {
      parts.push('Session messages:\n' + AgentMemoryService.formatMessages(messages, SUMMARY_CONTEXT_LIMIT));
    }
    return AgentMemoryService.clip(parts.join('\n\n'), SUMMARY_CONTEXT_LIMIT);
  }

  private static messagesAfterSummary(
    messages: ChatMessageRecord[],
    summary: AgentMemoryRecord | null,
  ): ChatMessageRecord[] {
    if (summary === null) {
      return messages;
    }
    const result: ChatMessageRecord[] = [];
    for (const message of messages) {
      if (message.createdAt > summary.createdAt) {
        result.push(message);
      }
    }
    return result;
  }

  private static formatMessages(messages: ChatMessageRecord[], limit: number): string {
    const lines: string[] = [];
    let size: number = 0;
    for (const message of messages) {
      const roleLabel: string = AgentMemoryService.roleLabel(message.role);
      const line: string = roleLabel + ': ' + message.content.trim();
      if (line.length > 0) {
        lines.push(line);
        size += line.length;
      }
      if (size >= limit) {
        break;
      }
    }
    return AgentMemoryService.clip(lines.join('\n\n'), limit);
  }

  private static roleLabel(role: ChatRole): string {
    if (role === 'assistant') {
      return 'AI';
    }
    if (role === 'system') {
      return 'System';
    }
    return 'User';
  }

  private static clip(text: string, limit: number): string {
    if (text.length <= limit) {
      return text;
    }
    return text.substring(0, limit) + '\n...';
  }

  private static newId(prefix: string): string {
    return prefix + '_' + Date.now().toString() + '_' + Math.floor(Math.random() * 1000000).toString();
  }
}
