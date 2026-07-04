// MathMind - 任务分发器
// 根据 IntentType 路由到合适的 Agent(ReviewAgent / QueryPlanner / KG)
// 创建: Z (W1 块 2 - 2026-07-04)

import { AgentResponse, AgentTask, IntentType } from '../../common/src/main/ets/models/CommonTypes';
import { getLogger } from '../../common/src/main/ets/utils/logger';
import { uuid } from '../../common/src/main/ets/utils/uuid';
import { ReviewAgent } from './ReviewAgent';
import { KnowledgeGraph } from './KnowledgeGraph';
import { QueryPlanner } from './QueryPlanner';

const log = getLogger('Dispatcher');

// 入口类型 → Agent 路由表
const INTENT_TO_AGENT: Record<string, string> = {
  // 复习类 → ReviewAgent
  [IntentType.APP_REVIEW]: 'ReviewAgent',
  [IntentType.SKILL_QUICK_REVIEW]: 'ReviewAgent',
  [IntentType.SKILL_FLASH]: 'ReviewAgent',
  [IntentType.CARD_TODAY]: 'ReviewAgent',

  // 提问类 → QueryPlanner
  [IntentType.APP_QUERY]: 'QueryPlanner',
  [IntentType.SKILL_ASK]: 'QueryPlanner',
  [IntentType.SKILL_VOICE_QUERY]: 'QueryPlanner',

  // KG 类 → KnowledgeGraph
  [IntentType.APP_KG_EXPLORE]: 'KnowledgeGraph',
  [IntentType.SKILL_CARD]: 'KnowledgeGraph',

  // 添加类 → ReviewAgent(也负责入库)
  [IntentType.SKILL_ADD]: 'ReviewAgent',

  // 元数据类 → ReviewAgent(简化处理)
  [IntentType.APP_HISTORY]: 'ReviewAgent',
  [IntentType.APP_SETTINGS]: 'ReviewAgent',
  [IntentType.SKILL_REMIND]: 'ReviewAgent',
  [IntentType.CARD_STREAK]: 'ReviewAgent',
  [IntentType.CARD_NEW]: 'ReviewAgent',
  [IntentType.CARD_PROGRESS]: 'ReviewAgent',
};

export class Dispatcher {
  private reviewAgent: ReviewAgent;
  private kg: KnowledgeGraph;
  private planner: QueryPlanner;

  constructor() {
    this.reviewAgent = new ReviewAgent();
    this.kg = new KnowledgeGraph();
    this.planner = new QueryPlanner();
  }

  // 根据 IntentType 找 Agent 名
  resolveAgentName(intent: IntentType): string {
    return INTENT_TO_AGENT[intent] ?? 'ReviewAgent';
  }

  // 主入口
  async dispatch(task: AgentTask): Promise<AgentResponse> {
    const startTs = Date.now();
    const agentName = this.resolveAgentName(task.type);
    log.info(`dispatch task=${task.id} intent=${task.type} → ${agentName}`);

    try {
      let data: Record<string, string> = {};

      switch (agentName) {
        case 'ReviewAgent':
          data = await this.reviewAgent.handle(task);
          break;
        case 'KnowledgeGraph':
          data = await this.kg.handle(task);
          break;
        case 'QueryPlanner':
          data = await this.planner.handle(task);
          break;
        default:
          throw new Error(`Unknown agent: ${agentName}`);
      }

      return {
        taskId: task.id,
        success: true,
        data,
        errorMessage: '',
        durationMs: Date.now() - startTs,
        agentName,
      };
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : String(e);
      log.error(`dispatch failed task=${task.id} err=${errMsg}`);
      return {
        taskId: task.id,
        success: false,
        data: {},
        errorMessage: errMsg,
        durationMs: Date.now() - startTs,
        agentName,
      };
    }
  }

  // 快捷构造 task
  static buildTask(intent: IntentType, payload: Record<string, string>, caller: string): AgentTask {
    return {
      id: uuid(),
      type: intent,
      payload,
      priority: 5,
      deadline: Date.now() + 30 * 1000,
      caller,
      createdAt: Date.now(),
    };
  }
}