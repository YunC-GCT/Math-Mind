import { ClassificationResult, DispatchPayload } from 'common';
import { OcrTool } from '../mcp/tools/OcrTool';

const CLASSIFY_TEXT_LIMIT: number = 6000;

export interface TypeClassifierTextResult {
  // 原始输入文本：text payload 原文，或图片/文件 OCR 原文，已合并 userText。
  rawText: string;
  // 预处理后的文本：供 UI 展示、KnowledgeModel 结构化和后续分类逻辑使用。
  text: string;
  // 输入来源，用于调用方判断这次是否真的走了 OCR。
  kind: 'text' | 'image' | 'file';
}

/**
 * TypeClassifier 当前只负责“文本暴露”，不再做类型/学科识别。
 *
 * 推荐用法：
 *   const classifier = new TypeClassifier();
 *   const result = await classifier.recognizeText(payload, context);
 *   const textForDownstream = result.text;
 *
 * 兼容旧链路：
 *   const classification = await classifier.classify(payload, context);
 *   const textForDownstream = classification.ocrText ?? '';
 *
 * 返回约定：
 *   - recognizeText().rawText: OCR/输入原文，便于排查识别质量。
 *   - recognizeText().text: 轻量预处理后的文本，便于下游直接使用。
 *   - classify(): 只保留兼容 ClassificationResult 结构，type/subject/chapter 不表示真实分类。
 */
export class TypeClassifier {
  async recognizeText(payload: DispatchPayload, context?: Context): Promise<TypeClassifierTextResult> {
    const rawText: string = await this.extractText(payload, context);
    return {
      rawText: rawText,
      text: this.preprocessText(rawText),
      kind: payload.kind,
    };
  }

  async classify(payload: DispatchPayload, context?: Context): Promise<ClassificationResult> {
    const result: TypeClassifierTextResult = await this.recognizeText(payload, context);

    return {
      type: '概念',
      subject: '',
      chapter: '',
      confidence: 0,
      ocrText: result.text,
    };
  }

  private async extractText(payload: DispatchPayload, context?: Context): Promise<string> {
    if (payload.kind === 'text') { return payload.text; }
    let baseText: string = '';
    if (payload.kind === 'image') {
      const tool = new OcrTool();
      baseText = await tool.recognize(payload.imageUri);
      return this.mergeUserText(baseText, payload.userText);
    }
    if (payload.kind === 'file') {
      if (payload.mimeType.startsWith('image/')) {
        const tool = new OcrTool();
        baseText = await tool.recognize(payload.fileUri);
      }
      return this.mergeUserText(baseText, payload.userText);
    }
    return '';
  }

  private mergeUserText(ocrText: string, userText: string | undefined): string {
    const parts: string[] = [];
    if (ocrText.trim().length > 0) { parts.push(ocrText.trim()); }
    if (userText !== undefined && userText.trim().length > 0) {
      parts.push('User note:\n' + userText.trim());
    }
    return parts.join('\n\n');
  }

  private preprocessText(text: string): string {
    const normalized: string = text
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      .replace(/\u0000/g, '')
      .replace(/\uFFFD/g, '')
      .replace(/[ \t\f\v]+/g, ' ');
    const lines: string[] = normalized.split('\n');
    const kept: string[] = [];
    for (let i: number = 0; i < lines.length; i++) {
      const line: string = lines[i].trim();
      if (line.length === 0) {
        if (kept.length > 0 && kept[kept.length - 1].length > 0) {
          kept.push('');
        }
        continue;
      }
      if (this.isNoiseLine(line)) {
        continue;
      }
      kept.push(line);
    }
    let cleaned: string = kept.join('\n').trim();
    if (cleaned.length > CLASSIFY_TEXT_LIMIT) { cleaned = cleaned.substring(0, CLASSIFY_TEXT_LIMIT); }
    return cleaned;
  }

  private isNoiseLine(line: string): boolean {
    const lower: string = line.toLowerCase();
    if (this.matchesAny(lower, ['扫描全能王', 'camscanner', '水印', '拍照搜题', '作业帮', '小猿搜题'])) {
      return true;
    }
    if (line.length <= 2 && !this.hasMathSignal(line)) {
      return true;
    }
    return false;
  }

  private hasMathSignal(line: string): boolean {
    return /[0-9a-zA-Z+\-*/=<>≤≥∑∫√∞πθαβγδλμξ]/.test(line);
  }

  private matchesAny(text: string, needles: string[]): boolean {
    for (let i: number = 0; i < needles.length; i++) {
      if (text.indexOf(needles[i]) >= 0) { return true; }
    }
    return false;
  }
}
