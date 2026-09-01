// ============================================================================
//  overlays/AgentFloatWindow/chat/ChatModels.ets — AI 浮窗数据类型定义
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
  role: 'user' | 'ai'

  // 消息内容
  content: string

  // 时间戳
  ts: number

  // 是否正在流式生成中 (仅 ai 消息)
  streaming: boolean

  // 思考链内容 (DeepSeek 思考模式, 仅 ai 消息)
  reasoning: string

  // 思考面板是否展开 (仅 ai 消息, 默认收起)
  reasoningExpanded?: boolean
}

export type ChatStatusStep =
  'intent_check' |
  'reply_context_load' |
  'reply_model_call' |
  'image_message_save' |
  'image_recognize' |
  'image_material_save' |
  'note_intent_check' |
  'note_context_load' |
  'note_source_prepare' |
  'note_material_summary' |
  'note_structure_save' |
  'note_finalize' |
  'completed'

export interface ChatStatusMeta {
  step: ChatStatusStep
  title: string
  detail: string
}

export interface ChatSession {
  // 会话唯一 id(36 进制时间戳)
  id: string

  // 会话名称
  name: string

  // 该会话下的消息列表
  messages: ChatMsg[]
}
