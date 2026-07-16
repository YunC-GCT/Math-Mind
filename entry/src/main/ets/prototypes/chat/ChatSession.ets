// chat/ChatSession.ets — 会话持久化管理
import { preferences } from "@kit.ArkData"

interface ChatMsg { id: number; role: string; content: string; ts: number }
interface Session { id: string; name: string; messages: ChatMsg[] }

export function sid(): string { return Date.now().toString(36) }

export class ChatSessionManager {
  private prefs: preferences.Preferences | null = null

  async init(ctx: Context): Promise<Session[]> {
    this.prefs = await preferences.getPreferences(ctx, "chat_history")
    const raw = this.prefs.getSync("sessions", "") as string
    if (raw && raw.length > 0) {
      try { const parsed = JSON.parse(raw) as Session[]; if (parsed.length > 0) return parsed } catch (e) {}
    }
    return [{ id: "s1", name: "\u5BF9\u8BDD 1", messages: [] }]
  }

  save(sessions: Session[]): void {
    if (this.prefs) { try { this.prefs.putSync("sessions", JSON.stringify(sessions)); this.prefs.flush() } catch (e) {} }
  }
}
