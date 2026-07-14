// MathMind - LLM 共享类型定义
// 位置: common/src/main/ets/llm/LlmTypes.ets
// 责任: Z (Mavis)
// 创建: 2026-07-14 — 主 Agent 业务 LLM 调用基础设施
// 用途: LlmConfig + LlmClient 共享的类型,以及后续所有 agent 调 LLM 时的入参/出参
//
// 约束: ArkTS 1.1 严格语法
//   - 无 any / unknown
//   - 无 C 风格 for 循环
//   - 无 Record<string, T> 类型断言

// ==================== ChatMessage (单轮对话消息)====================
export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

// ==================== LlmRequestBody (OpenAI 兼容请求体)====================
export interface LlmRequestBody {
  model: string;
  messages: ChatMessage[];
  temperature: number;
  max_tokens: number;
  stream: boolean;
}

// ==================== LlmResponse (OpenAI 兼容响应,只取常用字段)====================
export interface LlmResponseChoice {
  index: number;
  message: ChatMessage;
  finish_reason: string;
}

export interface LlmResponseUsage {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

export interface LlmResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: LlmResponseChoice[];
  usage?: LlmResponseUsage;
}

// ==================== LlmError (统一错误)====================
export type LlmErrorKind =
  | 'NO_API_KEY'        // 未配置 API key
  | 'NOT_INITIALIZED'   // LlmConfig 未 init
  | 'NETWORK_ERROR'     // 网络/HTTP 层失败
  | 'API_ERROR'         // API 返回非 2xx
  | 'PARSE_ERROR'       // 响应 JSON 解析失败
  | 'EMPTY_RESPONSE'    // 响应内容为空
  | 'TIMEOUT';          // 超时

export class LlmError extends Error {
  public kind: LlmErrorKind;

  constructor(message: string, kind: LlmErrorKind) {
    super(message);
    this.kind = kind;
    this.name = 'LlmError';
  }
}

// ==================== LlmConfigInitResult (init 返回)====================
export interface LlmConfigInitResult {
  ok: boolean;
  message: string;
}

// ==================== LlmCallOptions (单次调用可选参数)====================
export interface LlmCallOptions {
  // 不指定则用 LlmConfig 的默认配置
  temperature?: number;
  maxTokens?: number;
  model?: string;
  timeoutMs?: number;
}
