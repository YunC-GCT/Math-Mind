// MindTrace - OcrNode
// 2026-09-05 · D2 Ticket #4
import { AgentState, CaptureNode, CaptureNodeResult } from '../AgentState';
import { TypeClassifier, TypeClassifierTextResult } from '../../agents/TypeClassifier';

export class OcrNodeFactory {
  static create(classifier: TypeClassifier): CaptureNode {
    return async (input: AgentState): Promise<CaptureNodeResult> => {
      const recognized: TypeClassifierTextResult = await classifier.recognizeText(input.captureText as never);
      const next: AgentState = {
        captureText: recognized.text,
        currentStep: input.currentStep,
        persist: input.persist,
      };
      return { state: next };
    };
  }
}
