// MindTrace - PromptBuilder
// 2026-09-05 · D2 Ticket #3 · prompt construction façade
import { KnowledgeModel } from './KnowledgeModel';

export class PromptBuilder {
  private readonly model: KnowledgeModel = new KnowledgeModel();

  build(input: string): string {
    return this.model.buildPrompt(input);
  }
}
