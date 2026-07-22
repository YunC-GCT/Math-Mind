// common HSP - public API 鍏ュ彛
// W1 锟?3: 鏆撮湶锟?Agent 涓氬姟鎵€闇€鐨勬渶灏忛泦(Dispatcher 锟?

// ========== 璁捐 Token (棰滆壊 / 灏哄 / 瀛楀彿) ==========
export {
  MINT, MINT_DARK, MINT_LIGHT, MINT_GLOW, MINT_BORDER,
  PURPLE, PURPLE_DARK, PURPLE_LIGHT, PINK, PINK_LIGHT, AMBER,
  BG_DARK, BG_CARD,
  SUBJECT_COLORS, TYPE_COLORS,
  TEXT, TEXT_2, TEXT_3, TEXT_4,
  BORDER,
  S_1, S_2, S_3, S_4, S_5, S_6,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL, F_2XL, F_3XL,
  SCREEN_W, SCREEN_H,
  HEADER_H, FAB_SIZE, HERO_RING_SIZE, NOTE_ICON_SIZE, DOT_SIZE, AVATAR_SIZE, AI_SETTINGS_BTN_H, CAM_SHUTTER_OUTER, CAM_SHUTTER_INNER, CAM_BTN_SIZE, CAM_ALBUM_SIZE, CAM_CONFIRM_H,
  TAB_BAR_HEIGHT, TAB_ICON_SIZE, TAB_BTN_RADIUS, AI_BTN_SIZE, AI_ICON_SIZE,
  DANGER, DANGER_BRIGHT, WARNING, SUCCESS,
  GLASS_8, GLASS_10, GLASS_14, CAM_OVERLAY_BG, CAM_PREVIEW_BG, CAM_MASK,
  OVERLAY_MASK, OVERLAY_MASK_SOLID,
  W_NORMAL, W_MEDIUM, W_SEMIBOLD, W_BOLD,
  LH_TIGHT, LH_BASE, LH_COMFORT, LH_LOOSE, LH_HEADING,
  SHADOW_FAB, SHADOW_GLOW_MINT, SHADOW_AI_BTN,
  DUR_INSTANT, DUR_FAST, DUR_BASE, DUR_SLOW, DUR_SLOWER, DUR_SLOWEST, DUR_BREATH,
} from './constants/ColorTokens';

// ========== Mock 绗旇鏁版嵁 (UI 寮€鍙戞湡) ==========
export {
  NoteItem, NOTES, stripMD, recentDate,
} from './data/MockNotes';

// ========== 笔记分类与取色 ==========
export {
  NOTE_TYPE_ALL_KEY,
  NOTE_TYPE_KEYS,
  noteTypeFilterKeys,
  typeChar, typeColor, typeGlassColor,
  subjectColor, subjectColorByIndex, subjectGlassColor, subjectBorderColor,
  glassToneColor, glassSurfaceColor, glassHighlightColor, glassShadowColor, borderToneColor,
  normalizeNoteType, isKnownNoteType,
} from './data/NoteTaxonomy';

// ========== 锟?Agent 鍏变韩绫诲瀷 (Dispatcher 锟? ==========
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

// ========== D1 鎷嶇収閾剧被锟?(锟?Agent 涓氬姟) ==========
export {
  ClassificationInput,
  ClassificationResult,
  TruthFlag,
  TruthCheckResult,
  DispatchRequest,
  DispatchResult,
  DispatchAnalysisResult,
  ApiResponse,
  API_CODE,
  CLASSIFY_CONFIDENCE_THRESHOLD,
} from './models/CaptureChain';
export type { ApiCode, DispatchPayload, ImagePayload, TextPayload, FilePayload, NoteCategory } from './models/CaptureChain';

// ========== 缁熶竴鏃ュ織 (Dispatcher 锟? ==========
export {
  LogLevel,
  Logger,
  defaultLog,
  getLogger,
} from './utils/logger';

// ========== LLM 鍏变韩鍩虹璁炬柦 (Z 2026-07-14) ==========
//   LlmConfig:  鍗曚緥,preferences 鎸佷箙锟?API key,UI 杈撳叆/璇诲彇鍏ュ彛
//   LlmClient:  OpenAI 鍏煎 HTTP 瀹㈡埛锟?鎵€锟?agent 缁熶竴璋冪敤
//   LlmError:   缁熶竴閿欒绫诲瀷,锟?kind 鍒嗙被(NO_API_KEY / NETWORK_ERROR / API_ERROR / ...)
//   LlmTypes:   ChatMessage / LlmCallOptions / LlmErrorKind
export { LlmConfig } from './llm/LlmConfig';
export { LlmClient } from './llm/LlmClient';
export { LlmGuard } from './llm/LlmGuard';
export { JSON_ONLY_RULES, LATEX_GENERATION_RULES, buildGuardRetryMessage } from './llm/LlmOutputRules';
export { LlmError } from './llm/LlmTypes';
export type {
  ChatMessage,
  LlmCallOptions,
  LlmErrorKind,
} from './llm/LlmTypes';
export type { LlmGuardJsonOptions, LlmGuardJsonResult, LlmGuardValidationResult, LlmJsonValidator } from './llm/LlmGuard';
export type { LlmCaller } from './llm/LlmGuard';

// ========== OCR 端点配置 (2026-07-17 P0 修复) ==========
//   OcrConfig:  单例, preferences 持久化 endpoint + enabled, 真机部署改 IP
export { OcrConfig } from './ocr/OcrConfig';
// ========== 锟斤拷锟捷匡拷 (锟斤拷锟斤拷锟斤拷锟斤拷锟斤拷) ==========
export { DatabaseHelper } from './DatabaseHelper';

// ========== 学习计划模型 ==========
export { StudyPlanItem } from './models/StudyPlan';

// ========== 文件 URI / MIME 共享工具 (消除 ImageUriResolver/OcrTool 重复) ==========
export { mimeFromExtension, extFromUri, fileNameFromUri } from './utils/FileUriUtils';
export { uuid, shortId } from './utils/uuid';
export { LatexRiskNormalizer } from './utils/LatexRiskNormalizer';
export type {
  LatexRiskLevel,
  LatexRenderMode,
  LatexSegmentKind,
  RenderSegment,
  LatexRiskResult,
} from './utils/LatexRiskNormalizer';

// ========== MM-MD-v1 内容渲染协议 ==========
export { ContentProtocol } from './render/ContentProtocol';
export { ContentExcerptBuilder } from './render/ContentExcerptBuilder';
export type {
  ContentProtocolRisk,
  ContentValidationResult,
} from './render/ContentProtocol';
