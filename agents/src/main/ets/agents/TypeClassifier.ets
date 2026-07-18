import { ClassificationResult, DispatchPayload, LlmClient, LlmError, ChatMessage, NoteCategory } from 'common';
import { OcrTool } from '../mcp/tools/OcrTool';

const CLASSIFY_MAX_TOKENS: number = 512;
const CLASSIFY_TIMEOUT_MS: number = 30000;
const CLASSIFY_TEXT_LIMIT: number = 6000;

const CLASSIFY_PROMPT: string = `You classify OCR text from a math note or problem.
Return strict JSON only, with no markdown.

Fields:
- type: one of "概念", "定理", "公式", "证明题", "计算题"
  (概念=definitions/properties, 定理=theorems, 公式=formulas, 证明题=proof problems, 计算题=computation)
- subject: math subject in Chinese (e.g. 高等代数, 数学分析, 解析几何, 概率论, 数论...)
- chapter: short chapter/topic name, or empty string
- confidence: number from 0 to 1`;

export class TypeClassifier {
  async classify(payload: DispatchPayload, context?: Context): Promise<ClassificationResult> {
    const ocrText: string = await this.extractText(payload, context);
    const cleaned: string = this.cleanText(ocrText);

    const messages: ChatMessage[] = [
      { role: 'system', content: CLASSIFY_PROMPT },
      { role: 'user', content: cleaned },
    ];

    const client: LlmClient = new LlmClient();
    try {
      const raw: string = await client.call(messages, {
        maxTokens: CLASSIFY_MAX_TOKENS,
        timeoutMs: CLASSIFY_TIMEOUT_MS,
      });
      return this.parseResult(raw, ocrText);
    } catch (e) {
      if (e instanceof LlmError && e.kind === 'NO_API_KEY') {
        return this.ruleFallback(cleaned, 0.5, ocrText);
      }
      return this.ruleFallback(cleaned, 0.4, ocrText);
    }
  }

  private async extractText(payload: DispatchPayload, context?: Context): Promise<string> {
    if (payload.kind === 'text') { return payload.text; }
    let baseText: string = '';
    if (payload.kind === 'image') {
      const tool = new OcrTool(context);
      baseText = await tool.recognize(payload.imageUri);
      return this.mergeUserText(baseText, payload.userText);
    }
    if (payload.kind === 'file') {
      if (payload.mimeType.startsWith('image/')) {
        const tool = new OcrTool(context);
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

  private cleanText(text: string): string {
    let t: string = text.replace(/\s+/g, ' ').trim();
    if (t.length > CLASSIFY_TEXT_LIMIT) { t = t.substring(0, CLASSIFY_TEXT_LIMIT); }
    return t;
  }

  private parseResult(raw: string, ocrText: string): ClassificationResult {
    let jsonStr: string = raw.trim();
    const codeMatch: RegExpMatchArray | null = jsonStr.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (codeMatch !== null && codeMatch.length >= 2) { jsonStr = codeMatch[1].trim(); }
    const braceMatch: RegExpMatchArray | null = jsonStr.match(/\{[\s\S]*\}/);
    if (braceMatch !== null) { jsonStr = braceMatch[0]; }
    try {
      const parsed = JSON.parse(jsonStr) as Record<string, string>;
      const confidenceRaw: string = parsed.confidence ?? '0.7';
      const conf: number = parseFloat(confidenceRaw);
      const confidence: number = isNaN(conf) ? 0.7 : Math.max(0, Math.min(1, conf));
      return {
        type: this.mapType(parsed.type ?? ''),
        subject: this.mapSubject(parsed.subject ?? '', ocrText),
        chapter: parsed.chapter ?? '',
        confidence: confidence,
        ocrText: ocrText,
      };
    } catch (e) {
      return this.ruleFallback(ocrText, 0.4);
    }
  }

  private ruleFallback(text: string, confidence: number, fullText: string = ''): ClassificationResult {
    return {
      type: this.ruleType(text),
      subject: this.ruleSubject(text),
      chapter: '',
      confidence: confidence,
      ocrText: fullText.length > 0 ? fullText : text,
    };
  }

  private ruleType(text: string): NoteCategory {
    const lower: string = text.toLowerCase();
    if (this.containsAny(lower, ['prove', 'proof', '求证', '证明'])) { return '证明题'; }
    if (this.containsAny(lower, ['calculate', 'compute', 'solve', 'evaluate', 'find', '求', '计算', '解'])) { return '计算题'; }
    if (this.containsAny(lower, ['theorem', 'lemma', '定理', '引理'])) { return '定理'; }
    if (this.containsAny(lower, ['formula', 'equation', 'expression', '公式', '表达式'])) { return '公式'; }
    return '概念';
  }

  // LLM 自由判定学科 → 直接返回；ruleFallback 用关键词推断默认三门
  private ruleSubject(text: string): string {
    const lower: string = text.toLowerCase();
    if (this.containsAny(lower, ['matrix', 'determinant', 'eigen', 'rank', '矩阵', '行列式', '特征值'])) { return '高等代数'; }
    if (this.containsAny(lower, ['integral', 'limit', 'derivative', 'series', '\\int', '\\sum', '极限', '积分', '导数', '级数'])) { return '数学分析'; }
    if (this.containsAny(lower, ['curve', 'surface', 'plane', 'vector', 'geometry', '曲线', '曲面', '平面', '向量'])) { return '解析几何'; }
    return '数学';
  }

  private mapType(value: string): NoteCategory {
    const lower: string = value.toLowerCase();
    if (lower === '证明题' || lower === 'proof') { return '证明题'; }
    if (lower === '计算题' || lower === 'calculation' || lower === 'compute') { return '计算题'; }
    if (lower === '定理' || lower === 'theorem') { return '定理'; }
    if (lower === '公式' || lower === 'formula') { return '公式'; }
    return '概念';
  }

  // LLM 返回的学科直接透传，无法匹配时 fallback 到 ruleSubject
  private mapSubject(value: string, text: string): string {
    const cleaned: string = value.trim();
    if (cleaned.length > 0) { return cleaned; }
    return this.ruleSubject(text);
  }

  private containsAny(text: string, needles: string[]): boolean {
    for (let i = 0; i < needles.length; i++) {
      if (text.indexOf(needles[i]) >= 0) { return true; }
    }
    return false;
  }
}
