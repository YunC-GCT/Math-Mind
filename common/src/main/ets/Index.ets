// common HSP - public API 入口
// W1 块 3: 暴露主 Agent 业务所需的最小集(Dispatcher 用)

// ========== 设计 Token (颜色 / 尺寸 / 字号) ==========
export {
  MINT, MINT_DARK, MINT_LIGHT, MINT_GLOW, MINT_BORDER,
  PURPLE, PURPLE_DARK, PURPLE_LIGHT, PINK, AMBER,
  BG_DARK, BG_CARD,
  SUBJECT_COLORS, TYPE_COLORS,
  TEXT, TEXT_2, TEXT_3, TEXT_4,
  BORDER,
  S_1, S_2, S_3, S_4, S_5, S_6,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL, F_2XL, F_3XL,
  SCREEN_W, SCREEN_H,
} from './constants/ColorTokens';

// ========== Mock 笔记数据 (UI 开发期) ==========
export {
  NoteItem, NOTES, stripMD, recentDate,
  typeChar, typeColor, subjectColor,
} from './data/MockNotes';

// ========== 主 Agent 共享类型 (Dispatcher 用) ==========
export {
  KnowledgeUnit,
  ReviewRecord,
  KGNode,
  KGEdge,
} from './models/CommonTypes';
export {
  DifficultyLevel,
  ConfidenceLevel,
  ReviewStatus,
  IntentType,
  AgentTask,
  AgentResponse,
  ApiError,
} from './models/CommonTypes';

// ========== D1 拍照链类型 (主 Agent 业务) ==========
export {
  ClassificationInput,
  ClassificationResult,
  TruthFlag,
  TruthCheckResult,
  DispatchRequest,
  DispatchResult,
  ApiResponse,
  API_CODE,
  CLASSIFY_CONFIDENCE_THRESHOLD,
} from './models/CaptureChain';
export type { ApiCode, DispatchPayload, DispatchPayloadImage, DispatchPayloadText, DispatchPayloadFile } from './models/CaptureChain';

// ========== 统一日志 (Dispatcher 用) ==========
export {
  LogLevel,
  Logger,
  defaultLog,
  getLogger,
} from './utils/logger';

// ========== LLM 共享基础设施 (Z 2026-07-14) ==========
//   LlmConfig:  单例,preferences 持久化 API key,UI 输入/读取入口
//   LlmClient:  OpenAI 兼容 HTTP 客户端,所有 agent 统一调用
//   LlmError:   统一错误类型,带 kind 分类(NO_API_KEY / NETWORK_ERROR / API_ERROR / ...)
//   LlmTypes:   ChatMessage / LlmCallOptions / LlmErrorKind
export { LlmConfig } from './llm/LlmConfig';
export { LlmClient } from './llm/LlmClient';
export { LlmError } from './llm/LlmTypes';
export type { ChatMessage, LlmCallOptions, LlmErrorKind } from './llm/LlmTypes';
