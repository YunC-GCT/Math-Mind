// agents HSP - public API 入口（MVP 版）
// 旧管线 (KnowledgeModel / Dispatcher / AiService) 已移除
//
// MVP 管线:
//   TypeClassifier(仅取ocrText) → KnowledgeModelMVP(自分词5类+结构化+真值检验+入库)
//   → ContextLink(上下文关联) → KnowledgeUnitExt
//
// 版本
//   v0.0.4 (MVP 切换): 旧 KnowledgeModel/Dispatcher 替换为 MVP 版
export const AGENTS_VERSION = 'v0.0.4';

// 主 Agent 调度中枢(MVP 版)
export { DispatcherMVP } from './core/DispatcherMVP';

// 子 Agent — MVP 版知识建模(5类自分词 + 结构化 + 真值检验 + 入库)
export { KnowledgeModelMVP } from './agents/KnowledgeModelMVP';
export { TypeClassifier } from './agents/TypeClassifier';
export { OcrTool } from './mcp/tools/OcrTool';
export type { OcrRecognitionResult } from './mcp/tools/OcrTool';

// 子 Agent(ContextLink — 上下文关联)
export { ContextLink } from './agents/ContextLink';
export type { KnowledgeLinkResult } from './models/KnowledgeLinkTypes';

// MVP 模型类型
export { KnowledgeUnitExt } from './models/KnowledgeUnitExt';
export type { StructuredField, AiRawResponse } from './models/KnowledgeUnitExt';
export { createUnitExt } from './models/KnowledgeUnitExt';
export { NoteDaoInterface } from './models/NoteDaoInterface';
export { KnowledgeCategory } from './models/KnowledgeCategory';
export type { MvpTruthCheckResult, MvpTruthCheckItem } from './models/TruthCheckResult';

// 重新导出 DispatchPayload 类型
export type { DispatchPayload } from 'common';
