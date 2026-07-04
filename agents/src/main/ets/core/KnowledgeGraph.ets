// MathMind - 知识图谱 Agent
// 管理 KGNode / KGEdge 关系,提供图查询与遍历
// 创建: Z (W1 块 2 - 2026-07-04)

import { AgentTask, KGEdge, KGNode, KnowledgeUnit } from '../../common/src/main/ets/models/CommonTypes';
import { getLogger } from '../../common/src/main/ets/utils/logger';
import { uuid } from '../../common/src/main/ets/utils/uuid';

const log = getLogger('KG');

export class KnowledgeGraph {
  private nodes: Map<string, KGNode> = new Map();
  private edges: KGEdge[] = [];

  async handle(task: AgentTask): Promise<Record<string, string>> {
    log.info(`KG.handle intent=${task.type}`);
    switch (task.type) {
      case 'app_kg_explore':
        return this.handleExplore(task);
      case 'skill_card':
        return this.handleRelated(task);
      default:
        throw new Error(`KG does not handle intent: ${task.type}`);
    }
  }

  private handleExplore(task: AgentTask): Record<string, string> {
    const centerId = task.payload['centerId'];
    const depthStr = task.payload['depth'];
    const depth = depthStr ? parseInt(depthStr) : 2;

    const nodes: KGNode[] = [];
    const edges: KGEdge[] = [];
    const visited = new Set<string>();

    if (centerId) {
      const center = this.nodes.get(centerId);
      if (center) {
        this.bfs(center.id, depth, visited, nodes, edges);
      }
    } else {
      // 无中心:返回所有节点
      for (const n of this.nodes.values()) {
        nodes.push(n);
      }
      edges.push(...this.edges);
    }

    return {
      nodeCount: String(nodes.length),
      edgeCount: String(edges.length),
      nodes: JSON.stringify(nodes),
      edges: JSON.stringify(edges),
    };
  }

  private handleRelated(task: AgentTask): Record<string, string> {
    const unitId = task.payload['unitId'];
    if (!unitId) {
      return { related: '[]' };
    }
    const related = this.edges
      .filter((e) => e.from === unitId || e.to === unitId)
      .map((e) => (e.from === unitId ? e.to : e.from));
    return { related: JSON.stringify(related) };
  }

  // BFS 遍历
  private bfs(startId: string, depth: number, visited: Set<string>, nodes: KGNode[], edges: KGEdge[]): void {
    if (depth <= 0) {
      return;
    }
    const queue: Array<{ id: string; d: number }> = [{ id: startId, d: depth }];
    while (queue.length > 0) {
      const cur = queue.shift();
      if (!cur) {
        break;
      }
      if (visited.has(cur.id)) {
        continue;
      }
      visited.add(cur.id);
      const node = this.nodes.get(cur.id);
      if (node) {
        nodes.push(node);
      }
      if (cur.d > 1) {
        const next = this.edges.filter((e) => e.from === cur.id || e.to === cur.id);
        for (const e of next) {
          if (!edges.includes(e)) {
            edges.push(e);
          }
          const nextId = e.from === cur.id ? e.to : e.from;
          if (!visited.has(nextId)) {
            queue.push({ id: nextId, d: cur.d - 1 });
          }
        }
      }
    }
  }

  // 从 KnowledgeUnit 列表构建/更新图
  buildFromUnits(units: KnowledgeUnit[]): void {
    this.nodes.clear();
    this.edges = [];
    for (const u of units) {
      const node: KGNode = {
        id: u.id,
        unitId: u.id,
        label: u.title,
        cluster: u.tags[0] ?? 'default',
        centrality: 0,
        x: Math.random() * 100,
        y: Math.random() * 100,
      };
      this.nodes.set(u.id, node);

      // 前置边
      for (const p of u.prerequisites) {
        if (this.nodes.has(p)) {
          this.edges.push({ from: p, to: u.id, type: 'prerequisite', weight: 1.0 });
        }
      }
      // 相关边
      for (const r of u.related) {
        if (this.nodes.has(r)) {
          this.edges.push({ from: u.id, to: r, type: 'related', weight: 0.5 });
        }
      }
    }
    this.computeCentrality();
    log.info(`buildFromUnits count=${this.nodes.size} edges=${this.edges.length}`);
  }

  // 简化的中心度计算(基于度数)
  private computeCentrality(): void {
    const degree: Record<string, number> = {};
    for (const e of this.edges) {
      degree[e.from] = (degree[e.from] ?? 0) + 1;
      degree[e.to] = (degree[e.to] ?? 0) + 1;
    }
    let maxDeg = 1;
    for (const k in degree) {
      if (degree[k] > maxDeg) {
        maxDeg = degree[k];
      }
    }
    for (const n of this.nodes.values()) {
      n.centrality = (degree[n.id] ?? 0) / maxDeg;
    }
  }

  // 添加单个节点 + 边
  addNode(unit: KnowledgeUnit, related: string[] = []): string {
    const id = uuid();
    this.nodes.set(id, {
      id,
      unitId: unit.id,
      label: unit.title,
      cluster: unit.tags[0] ?? 'default',
      centrality: 0,
      x: Math.random() * 100,
      y: Math.random() * 100,
    });
    for (const r of related) {
      this.edges.push({ from: id, to: r, type: 'related', weight: 0.5 });
    }
    return id;
  }
}