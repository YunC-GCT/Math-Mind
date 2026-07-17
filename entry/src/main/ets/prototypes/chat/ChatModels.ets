// ============================================================================
//  prototypes/chat/ChatModels.ets — AI 浮窗数据类型定义
//  ----------------------------------------------------------------------------
//  职责: 统一 AgentFloatWindow 子组件共享的数据结构。
//
//  类型:
//    ChatMsg:     单条消息 {id, role, content, ts}
//    ChatSession: 会话 {id, name, messages[]}
//  ============================================================================

export interface ChatMsg {
  // 消息唯一 id(用 Date.now * 1000 + random)
  id: number

  // 角色: "user" | "ai"
  role: string

  // 消息内容
  content: string

  // 时间戳
  ts: number
}

export interface ChatSession {
  // 会话唯一 id(36 进制时间戳)
  id: string

  // 会话名称
  name: string

  // 该会话下的消息列表
  messages: ChatMsg[]
}
