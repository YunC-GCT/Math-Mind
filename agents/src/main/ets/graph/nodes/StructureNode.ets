// MindTrace - StructureNode
// 2026-09-05 · D2 Ticket #5
import { AgentState, CaptureNode, CaptureGraphError, CaptureNodeResult } from '../AgentState';
import { StructureService } from '../../agents/StructureService';

export class StructureNodeFactory {
  static create(service: StructureService): CaptureNode {
    return async (input: AgentState): Promise<CaptureNodeResult> => {
      try {
        const unit = await service.structure(input.captureText);
        const next: AgentState = {
          captureText: input.captureText,
          currentStep: input.currentStep,
          persist: input.persist,
          knowledgeUnit: unit,
        };
        return { state: next };
      } catch (e) {
        const error: CaptureGraphError = {
          kind: 'STRUCTURE_ERROR',
          message: (e as Error).message ?? String(e),
          step: 'structure',
          retriable: false,
        };
        const next: AgentState = {
          captureText: input.captureText,
          currentStep: input.currentStep,
          persist: input.persist,
          error: error,
        };
        return { state: next };
      }
    };
  }
}
