// ============================================================================
//  prototypes/chat/ChatSession.ets — 会话持久化管理(非 UI)
//  ----------------------------------------------------------------------------
//  职责: 封装 @kit.ArkData preferences,提供会话历史的读写。
//
//  接口:
//    sid()                        → string         生成唯一会话 ID(36 进制时间戳)
//    ChatSessionManager:
//      init(ctx)                  → ChatSession[]  从 preferences 加载
//      save(sessions)                            保存到 preferences
//
//  存储格式:
//    preferences name: "chat_history"
//    key:           "sessions"
//    value:         JSON.stringify([{id, name, messages: [{id, role, content, ts}]}])
//
//  依赖: @kit.ArkData.preferences
// ============================================================================

import { preferences } from "@kit.ArkData"
import { ChatSession } from "./ChatModels"

// 生成唯一会话 ID(36 进制时间戳,如 "lqz3k5x2")
export function sid(): string {
  return Date.now().toString(36)
}

export class ChatSessionManager {
  // preferences 引用
  private prefs: preferences.Preferences | null = null

  // 加载会话列表
  // 失败/空时返回默认 1 个空会话 "对话 1"
  async init(ctx: Context): Promise<ChatSession[]> {
    this.prefs = await preferences.getPreferences(ctx, "chat_history")
    const raw: string = this.prefs.getSync("sessions", "") as string
    if (raw && raw.length > 0) {
      try {
        const parsed: ChatSession[] = JSON.parse(raw) as ChatSession[]
        if (parsed.length > 0) {
          return parsed
        }
      } catch (e) {
        // 解析失败,降级用默认会话
      }
    }
    // 默认空会话
    return [{ id: "s1", name: "对话 1", messages: [] }]
  }

  // 保存会话列表(JSON 序列化)
  save(sessions: ChatSession[]): void {
    if (this.prefs) {
      try {
        this.prefs.putSync("sessions", JSON.stringify(sessions))
        this.prefs.flush()
      } catch (e) {
        // 保存失败,降级忽略
      }
    }
  }
}
