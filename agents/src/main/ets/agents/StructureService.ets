// MindTrace - StructureService
// 2026-09-05 · D2 Ticket #3 · 结构化 façade
import { ClassificationResult, KnowledgeUnit } from 'common';
import { KnowledgeModel } from './KnowledgeModel';

export class StructureService {
  private readonly model: KnowledgeModel = new KnowledgeModel();

  async structure(
    ocrText: string,
    type?: string,
    subject?: string,
    chapter: string = '',
    source: string = 'camera_capture',
  ): Promise<KnowledgeUnit> {
    return await this.model.structure(ocrText, type, subject, chapter, source);
  }

  async structureWithClassification(
    ocrText: string,
    classification: ClassificationResult,
    source: string = 'camera_capture',
  ): Promise<KnowledgeUnit> {
    return await this.model.structureWithClassification(ocrText, classification, source);
  }
}
