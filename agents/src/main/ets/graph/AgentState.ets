// MindTrace - CaptureGraph 图状态与节点契约
// 2026-09-05 · D2 Ticket #12

import { ClassificationResult, KnowledgeUnit, TruthCheckResult } from 'common';

export type CaptureStep =
  | 'START'
  | 'capture'
  | 'classify'
  | 'structure'
  | 'truth_check'
  | 'persist'
  | 'END';

export interface CaptureGraphError {
  kind: string;
  message: string;
  step: CaptureStep;
  retriable: boolean;
  cause?: Object;
}

export interface AgentState {
  captureText: string;
  classification?: ClassificationResult;
  knowledgeUnit?: KnowledgeUnit;
  truthCheck?: TruthCheckResult;
  error?: CaptureGraphError;
  currentStep: CaptureStep;
  persist: boolean;
}

export interface CaptureNodeResult {
  state: AgentState;
}

export type CaptureNode = (state: AgentState) => Promise<CaptureNodeResult>;
