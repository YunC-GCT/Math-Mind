// MindTrace - Dispatcher (主 Agent 调度中枢) · D2 CaptureGraph host
// 2026-09-05 · D2 Ticket #2/5: dispatch() runs CaptureGraph
import { TypeClassifier } from '../agents/TypeClassifier';
import { StructureService } from '../agents/StructureService';
import { TruthCheckService } from '../agents/TruthCheckService';
import { Logger, KnowledgeUnit, DispatchRequest, DispatchResult, DispatchAnalysisResult, ClassificationResult } from 'common';
import type { DispatchPayload } from 'common';
import { AgentState, CaptureGraphError, CaptureStep } from '../graph/AgentState';
import { CaptureGraph } from '../graph/CaptureGraph';
import { OcrNodeFactory } from '../graph/nodes/OcrNode';
import { ClassifyNodeFactory } from '../graph/nodes/ClassifyNode';
import { StructureNodeFactory } from '../graph/nodes/StructureNode';
import { TruthCheckNodeFactory } from '../graph/nodes/TruthCheckNode';

const log = new Logger('Dispatcher');

export interface DispatchOptions {
  persist?: boolean;
  includeRawText?: boolean;
}

export class Dispatcher {
  private static sourceFromPayload(payload: DispatchPayload): string {
    if (payload.kind === 'image') { return 'camera_capture'; }
    if (payload.kind === 'text') { return 'manual'; }
    return 'file_import';
  }

  async analyze(req: DispatchRequest, context?: Context): Promise<DispatchAnalysisResult> {
    return await this.analyzeRequest(req, context);
  }

  async dispatch(req: DispatchRequest, context?: Context): Promise<DispatchResult> {
    return await this.dispatchRequest(req, context);
  }

  async routeDispatch(req: DispatchRequest, context?: Context): Promise<DispatchResult> {
    return await this.dispatch(req, context);
  }

  private async analyzeRequest(req: DispatchRequest, context?: Context): Promise<DispatchAnalysisResult> {
    const t0: number = Date.now();
    log.info('analyze enter, source=' + req.source + ', payload.kind=' + req.payload.kind);
    try {
      const classifier: TypeClassifier = new TypeClassifier();
      const classification: ClassificationResult = await classifier.classify(req.payload, context);
      let recognizedText: string = classification.ocrText ?? '';
      if (recognizedText.length === 0 && req.payload.kind === 'text') {
        recognizedText = req.payload.text;
      }
      return {
        success: true,
        route: 'D1',
        classification: classification,
        recognizedText: recognizedText,
        durationMs: Date.now() - t0,
      };
    } catch (e) {
      const errMsg: string = (e as Error).message ?? String(e);
      log.error('analyze failed: ' + errMsg);
      return {
        success: false,
        route: 'D1',
        errorMessage: '识别失败: ' + errMsg,
        durationMs: Date.now() - t0,
      };
    }
  }

  private async dispatchRequest(req: DispatchRequest, context?: Context): Promise<DispatchResult> {
    const t0: number = Date.now();
    log.info('dispatch enter, source=' + req.source + ', payload.kind=' + req.payload.kind);
    const initial: AgentState = {
      captureText: '',
      currentStep: 'START',
      persist: true,
    };
    const graph: CaptureGraph = this.buildGraph(req);
    const finalState: AgentState = await graph.run(initial, { persist: true });
    const error: CaptureGraphError | undefined = finalState.error;
    if (error !== undefined) {
      log.error('capture graph failed: ' + error.kind + ' step=' + error.step + ' msg=' + error.message);
      return {
        success: false,
        route: 'D1',
        errorMessage: error.message,
        durationMs: Date.now() - t0,
      };
    }
    const unit: KnowledgeUnit | undefined = finalState.knowledgeUnit;
    if (unit === undefined) {
      return {
        success: false,
        route: 'D1',
        errorMessage: 'capture graph did not produce a knowledge unit',
        durationMs: Date.now() - t0,
      };
    }
    return {
      success: true,
      route: 'D1',
      data: unit,
      durationMs: Date.now() - t0,
    };
  }

  private buildGraph(req: DispatchRequest): CaptureGraph {
    const graph: CaptureGraph = new CaptureGraph();
    const classifier: TypeClassifier = new TypeClassifier();
    const structure: StructureService = new StructureService();
    const truth: TruthCheckService = new TruthCheckService();
    graph.addNode('START', async (input: AgentState) => {
      const seed: AgentState = {
        captureText: this.seedText(req),
        currentStep: input.currentStep,
        persist: input.persist,
      };
      return { state: seed };
    });
    graph.addNode('capture', OcrNodeFactory.create(classifier));
    graph.addNode('classify', ClassifyNodeFactory.create(classifier));
    graph.addNode('structure', StructureNodeFactory.create(structure));
    graph.addNode('truth_check', TruthCheckNodeFactory.create(truth));
    graph.addNode('persist', async (input: AgentState) => ({ state: input }));
    graph.addEdge('START', 'capture');
    graph.addEdge('capture', 'classify');
    graph.addEdge('classify', 'structure');
    graph.addEdge('structure', 'truth_check');
    graph.addConditionalEdge('truth_check', (input: AgentState): CaptureStep => input.persist ? 'persist' : 'END');
    return graph;
  }

  private seedText(req: DispatchRequest): string {
    if (req.payload.kind === 'text') {
      return req.payload.text;
    }
    return '';
  }
}
