// MindTrace - TruthCheckService
// 2026-09-05 · D2 Ticket #3 · 真值检查 façade
import { MvpTruthCheckResult } from '../models/TruthCheckResult';
import { KnowledgeModel } from './KnowledgeModel';

export class TruthCheckService {
  check(input: string): MvpTruthCheckResult {
    const legacy: KnowledgeModel = new KnowledgeModel();
    return legacy.truthCheck(input);
  }
}
