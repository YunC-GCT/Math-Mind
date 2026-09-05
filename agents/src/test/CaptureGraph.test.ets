// MindTrace - CaptureGraph 最小闭环行为测试
// 2026-09-05 · D2 Ticket #12

import { describe, it, expect } from '@ohos/hypium';
import { CaptureGraph } from '../main/ets/graph/CaptureGraph';
import { AgentState, CaptureGraphError, CaptureNode, CaptureNodeResult, CaptureStep } from '../main/ets/graph/AgentState';

function state(persist: boolean = true): AgentState {
  const initial: AgentState = {
    captureText: 'x + 1 = 2',
    currentStep: 'START',
    persist,
  };
  return initial;
}

function addNode(graph: CaptureGraph, step: CaptureStep, value: string): void {
  const node: CaptureNode = async (input: AgentState): Promise<CaptureNodeResult> => {
    const updated: AgentState = {
      captureText: input.captureText + value,
      currentStep: input.currentStep,
      persist: input.persist,
    };
    if (input.classification !== undefined) {
      updated.classification = input.classification;
    }
    if (input.knowledgeUnit !== undefined) {
      updated.knowledgeUnit = input.knowledgeUnit;
    }
    if (input.truthCheck !== undefined) {
      updated.truthCheck = input.truthCheck;
    }
    if (input.error !== undefined) {
      updated.error = input.error;
    }
    const result: CaptureNodeResult = { state: updated };
    return result;
  };
  graph.addNode(step, node);
}

async function persistErrorStub(input: AgentState): Promise<CaptureNodeResult> {
  const error: CaptureGraphError = {
    kind: 'PERSIST_ERROR',
    message: 'must not run',
    step: 'persist',
    retriable: false,
  };
  const next: AgentState = {
    captureText: input.captureText,
    currentStep: input.currentStep,
    persist: input.persist,
    error: error,
  };
  const result: CaptureNodeResult = { state: next };
  return result;
}

async function structureErrorStub(input: AgentState): Promise<CaptureNodeResult> {
  const error: CaptureGraphError = {
    kind: 'STRUCTURE_ERROR',
    message: 'invalid json',
    step: 'structure',
    retriable: false,
  };
  const next: AgentState = {
    captureText: input.captureText,
    currentStep: input.currentStep,
    persist: input.persist,
    error: error,
  };
  const result: CaptureNodeResult = { state: next };
  return result;
}

export default function captureGraphTest(): void {
  describe('CaptureGraph.minimum_loop', () => {
    it('persist_false_skips_persist_node', 0, async () => {
      const graph: CaptureGraph = new CaptureGraph();
      addNode(graph, 'START', 'c');
      addNode(graph, 'capture', 'l');
      addNode(graph, 'classify', 's');
      addNode(graph, 'structure', 't');
      addNode(graph, 'truth_check', 'p');
      graph.addNode('persist', persistErrorStub);
      graph.addEdge('START', 'capture');
      graph.addEdge('capture', 'classify');
      graph.addEdge('classify', 'structure');
      graph.addEdge('structure', 'truth_check');
      graph.addConditionalEdge('truth_check', (input: AgentState) => input.persist ? 'persist' : 'END');
      const result: AgentState = await graph.run(state(false));
      expect(result.error).assertUndefined();
      expect(result.persist).assertFalse();
      expect(result.currentStep).assertEqual('END');
    });

    it('default_path_reaches_persist', 0, async () => {
      const graph: CaptureGraph = new CaptureGraph();
      graph.addNode('START', async (input: AgentState) => {
        const result: AgentState = {
          captureText: input.captureText,
          currentStep: input.currentStep,
          persist: input.persist,
        };
        return { state: result };
      });
      graph.addNode('capture', async (input: AgentState) => ({ state: input }));
      graph.addNode('classify', async (input: AgentState) => ({ state: input }));
      graph.addNode('structure', async (input: AgentState) => ({ state: input }));
      graph.addNode('truth_check', async (input: AgentState) => ({ state: input }));
      graph.addNode('persist', async (input: AgentState) => {
        const result: AgentState = {
          captureText: input.captureText,
          currentStep: 'persist',
          persist: input.persist,
        };
        return { state: result };
      });
      graph.addEdge('START', 'capture');
      graph.addEdge('capture', 'classify');
      graph.addEdge('classify', 'structure');
      graph.addEdge('structure', 'truth_check');
      graph.addConditionalEdge('truth_check', (input: AgentState) => input.persist ? 'persist' : 'END');
      const result: AgentState = await graph.run(state());
      expect(result.currentStep).assertEqual('persist');
      expect(result.error).assertUndefined();
    });

    it('node_error_short_circuits_to_end', 0, async () => {
      const graph: CaptureGraph = new CaptureGraph();
      graph.addNode('START', structureErrorStub);
      graph.addEdge('START', 'END');
      const result: AgentState = await graph.run(state(false));
      expect(result.error?.kind).assertEqual('STRUCTURE_ERROR');
      expect(result.currentStep).assertEqual('END');
    });
  });
}
