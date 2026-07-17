import { ClassificationResult, DispatchPayload, LlmClient, LlmError, ChatMessage } from 'common';
import { OcrTool } from '../mcp/tools/OcrTool';

type NoteType = '概念' | '计算' | '证明';
type SubjectType = '高等代数' | '数学分析' | '解析几何';

const TYPE_CONCEPT: NoteType = '概念';
const TYPE_CALCULATION: NoteType = '计算';
const TYPE_PROOF: NoteType = '证明';

const SUBJECT_ALGEBRA: SubjectType = '高等代数';
const SUBJECT_ANALYSIS: SubjectType = '数学分析';
const SUBJECT_GEOMETRY: SubjectType = '解析几何';

const CLASSIFY_PROMPT: string = `You classify OCR text from a math note or problem.
Return strict JSON only, with no markdown.

Fields:
- type: one of "concept", "calculation", "proof"
- subject: one of "advanced_algebra", "math_analysis", "analytic_geometry"
- chapter: short chapter/topic name, or empty string if unsure
- confidence: number from 0 to 1

Classification hints:
- definitions, concepts, properties, formulas used as knowledge points => concept
- compute, solve, evaluate, find, examples, answers => calculation
- prove, proof, show that, demonstrate => proof`;

export class TypeClassifier {
  async classify(payload: DispatchPayload): Promise<ClassificationResult> {
    const ocrText: string = await this.extractText(payload);
    const cleaned: string = this.cleanText(ocrText);

    const messages: ChatMessage[] = [
      { role: 'system', content: CLASSIFY_PROMPT },
      { role: 'user', content: cleaned },
    ];

    const client = new LlmClient();
    try {
      const raw: string = await client.call(messages, {
        maxTokens: 128,
        timeoutMs: 3000,
      });
      return this.parseResult(raw, cleaned);
    } catch (e) {
      if (e instanceof LlmError && e.kind === 'NO_API_KEY') {
        return this.ruleFallback(cleaned, 0.5);
      }
      return this.ruleFallback(cleaned, 0.4);
    }
  }

  private async extractText(payload: DispatchPayload): Promise<string> {
    if (payload.kind === 'text') {
      return payload.text;
    }

    let baseText: string = '';
    if (payload.kind === 'image') {
      const tool = new OcrTool();
      baseText = await tool.recognize(payload.imageUri);
      return this.mergeUserText(baseText, payload.userText);
    }

    if (payload.mimeType.startsWith('image/')) {
      const tool = new OcrTool();
      baseText = await tool.recognize(payload.fileUri);
    }
    return this.mergeUserText(baseText, payload.userText);
  }

  private mergeUserText(ocrText: string, userText: string | undefined): string {
    const parts: string[] = [];
    if (ocrText.trim().length > 0) {
      parts.push(ocrText.trim());
    }
    if (userText !== undefined && userText.trim().length > 0) {
      parts.push('User note:\n' + userText.trim());
    }
    return parts.join('\n\n');
  }

  private cleanText(text: string): string {
    let t: string = text.replace(/\s+/g, ' ').trim();
    if (t.length > 2000) {
      t = t.substring(0, 2000);
    }
    return t;
  }

  private parseResult(raw: string, ocrText: string): ClassificationResult {
    let jsonStr: string = raw.trim();
    const codeMatch: RegExpMatchArray | null = jsonStr.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (codeMatch !== null && codeMatch.length >= 2) {
      jsonStr = codeMatch[1].trim();
    }
    const braceMatch: RegExpMatchArray | null = jsonStr.match(/\{[\s\S]*\}/);
    if (braceMatch !== null) {
      jsonStr = braceMatch[0];
    }

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

  private ruleFallback(text: string, confidence: number): ClassificationResult {
    return {
      type: this.ruleType(text),
      subject: this.ruleSubject(text),
      chapter: '',
      confidence: confidence,
      ocrText: text,
    };
  }

  private ruleType(text: string): NoteType {
    const lower: string = text.toLowerCase();
    if (this.containsAny(lower, ['prove', 'proof', 'show that', '证明', '求证'])) {
      return TYPE_PROOF;
    }
    if (this.containsAny(lower, ['calculate', 'compute', 'solve', 'evaluate', 'find', '求', '计算', '解'])) {
      return TYPE_CALCULATION;
    }
    return TYPE_CONCEPT;
  }

  private ruleSubject(text: string): SubjectType {
    const lower: string = text.toLowerCase();
    if (this.containsAny(lower, ['matrix', 'determinant', 'eigen', 'rank', '矩阵', '行列式', '特征值'])) {
      return SUBJECT_ALGEBRA;
    }
    if (this.containsAny(lower, ['integral', 'limit', 'derivative', 'series', '\\int', '\\sum', '极限', '积分', '导数', '级数'])) {
      return SUBJECT_ANALYSIS;
    }
    if (this.containsAny(lower, ['curve', 'surface', 'plane', 'vector', 'geometry', '曲线', '曲面', '平面', '向量'])) {
      return SUBJECT_GEOMETRY;
    }
    return SUBJECT_ALGEBRA;
  }

  private mapType(value: string): NoteType {
    const lower: string = value.toLowerCase();
    if (lower === 'proof' || value === '证明') {
      return TYPE_PROOF;
    }
    if (lower === 'calculation' || lower === 'compute' || value === '计算') {
      return TYPE_CALCULATION;
    }
    return TYPE_CONCEPT;
  }

  private mapSubject(value: string, text: string): SubjectType {
    const lower: string = value.toLowerCase();
    if (lower === 'math_analysis' || value === '数学分析') {
      return SUBJECT_ANALYSIS;
    }
    if (lower === 'analytic_geometry' || value === '解析几何') {
      return SUBJECT_GEOMETRY;
    }
    if (lower === 'advanced_algebra' || value === '高等代数') {
      return SUBJECT_ALGEBRA;
    }
    return this.ruleSubject(text);
  }

  private containsAny(text: string, needles: string[]): boolean {
    for (let i = 0; i < needles.length; i++) {
      if (text.indexOf(needles[i]) >= 0) {
        return true;
      }
    }
    return false;
  }
}
