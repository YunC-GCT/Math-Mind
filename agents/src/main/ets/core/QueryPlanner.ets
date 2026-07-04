// MathMind - 查询规划 Agent
// 解析用户提问 → RAG 策略(检索 + 生成)
// 创建: Z (W1 块 2 - 2026-07-04)

import { AgentTask } from '../../common/src/main/ets/models/CommonTypes';
import { getLogger } from '../../common/src/main/ets/utils/logger';

const log = getLogger('QueryPlanner');

export type QueryStrategy = 'simple_lookup' | 'rag_kg' | 'rag_vector' | 'multi_hop';

export interface QueryPlan {
  query: string;
  strategy: QueryStrategy;
  topK: number;
  needContext: boolean;
  estimatedTokens: number;
}

export class QueryPlanner {
  async handle(task: AgentTask): Promise<Record<string, string>> {
    log.info(`QueryPlanner.handle intent=${task.type}`);
    switch (task.type) {
      case 'app_query':
        return this.handleQuery(task);
      case 'skill_ask':
        return this.handleQuery(task);
      case 'skill_voice_query':
        return this.handleQuery(task);
      default:
        throw new Error(`QueryPlanner does not handle intent: ${task.type}`);
    }
  }

  private handleQuery(task: AgentTask): Record<string, string> {
    const query = task.payload['query'] ?? '';
    if (query.length === 0) {
      throw new Error('query is required');
    }

    const plan = this.plan(query);

    // W1 阶段:只返回 plan + 占位 answer
    // W2 接入 APIClient + EmbeddingClient + DeepSeekClient
    return {
      query,
      strategy: plan.strategy,
      topK: String(plan.topK),
      needContext: String(plan.needContext),
      estimatedTokens: String(plan.estimatedTokens),
      answer: '[W1 占位] RAG 检索将接入服务层后输出',
      sources: '[]',
    };
  }

  // 决策策略
  plan(query: string): QueryPlan {
    const len = query.length;
    const hasQuestionMark = query.includes('?') || query.includes('?') || query.includes('吗');
    const hasEntity = this.detectEntity(query);
    const isComplex = len > 50 || (query.split(/[,;;、]/).length >= 3);

    if (len < 5) {
      return {
        query,
        strategy: 'simple_lookup',
        topK: 1,
        needContext: false,
        estimatedTokens: 50,
      };
    }
    if (isComplex) {
      return {
        query,
        strategy: 'multi_hop',
        topK: 8,
        needContext: true,
        estimatedTokens: 2000,
      };
    }
    if (hasEntity) {
      return {
        query,
        strategy: 'rag_kg',
        topK: 5,
        needContext: true,
        estimatedTokens: 1000,
      };
    }
    if (hasQuestionMark) {
      return {
        query,
        strategy: 'rag_vector',
        topK: 5,
        needContext: true,
        estimatedTokens: 1000,
      };
    }
    return {
      query,
      strategy: 'simple_lookup',
      topK: 3,
      needContext: false,
      estimatedTokens: 200,
    };
  }

  // 简单实体识别(关键字命中)
  private detectEntity(query: string): boolean {
    const entities = ['定义', '定理', '公式', '证明', '推导', '步骤', '方法', '区别', '什么是', '怎么算'];
    for (const e of entities) {
      if (query.includes(e)) {
        return true;
      }
    }
    return false;
  }
}