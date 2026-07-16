/**
 * ==========================================================================
 *  ChatSession.ets — 会话持久化工具类 (非UI)
 *  ==========================================================================
 *  职责: 封装 preferences API, 提供会话历史的读写。
 *
 *  接口:
 *    ChatSessionManager
 *      init(ctx)     → Session[]  从 preferences 加载会话列表
 *      save(sessions)             保存会话列表到 preferences
 *
 *    sid()           → string     生成唯一会话 ID (36进制时间戳)
 *
 *  存储格式:
 *    preferences key: "chat_history"
 *    value: JSON.stringify([{id, name, messages: [{id, role, content, ts}]}])
 *
 *  依赖: @kit.ArkData.preferences
 * ==========================================================================
 */// chat/ChatSession.ets — 会话持久化管理
import { preferences } from "@kit.ArkData"
import { ChatSession } from "./ChatModels"

export function sid(): string { return Date.now().toString(36) }

export class ChatSessionManager {
  private prefs: preferences.Preferences | null = null

  async init(ctx: Context): Promise<ChatSession[]> {
    this.prefs = await preferences.getPreferences(ctx, "chat_history")
    const raw = this.prefs.getSync("sessions", "") as string
    if (raw && raw.length > 0) {
      try { const parsed = JSON.parse(raw) as ChatSession[]; if (parsed.length > 0) return parsed } catch (e) {}
    }
    return [{ id: "s1", name: "\u5BF9\u8BDD 1", messages: [] }]
  }

  save(sessions: ChatSession[]): void {
    if (this.prefs) { try { this.prefs.putSync("sessions", JSON.stringify(sessions)); this.prefs.flush() } catch (e) {} }
  }
}
