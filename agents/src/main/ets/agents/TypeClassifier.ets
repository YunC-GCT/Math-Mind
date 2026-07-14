// MathMind - TypeClassifier (类型/学科分类器)
// 任务编号: B2
// 责任: Z
// 状态: 实现完成(2026-07-14) — 精简拍照链, DeepSeek 3×3分类
//
// 接口:
//   classify(payload: DispatchPayload): Promise<ClassificationResult>
//
// 实现:
//   1) 按 payload.kind 分流: image → mock OCR, text → 直接用, file → mock OCR
//   2) cleanText 清洗
//   3) 调 LlmClient.call() → DeepSeek-V3 分类
//   4) 解析 JSON → ClassificationResult

import { ClassificationResult, DispatchPayload, LlmClient, LlmError, ChatMessage } from 'common';

const CLASSIFY_PROMPT: string = `你是一个数学题目分类器。请对输入的文本进行分类，返回 JSON 格式。

分类规则:
- type: 只能是 "概念"、"计算"、"证明" 之一
- subject: 只能是 "高等代数"、"数学分析"、"解析几何" 之一
- chapter: 章节名称(如"行列式"、"极限"、"微分中值定理"), 无法判断时用空字符串
- confidence: 0.0-1.0 的置信度

返回格式(只返回 JSON, 不要其他文字):
{"type":"计算","subject":"高等代数","chapter":"行列式","confidence":0.92}`;

export class TypeClassifier {
  async classify(payload: DispatchPayload): Promise<ClassificationResult> {
    // Step 1: 按 kind 提取文本
    let ocrText: string;
    if (payload.kind === 'text') {
      ocrText = payload.text;
    } else if (payload.kind === 'image') {
      // MVP: 无 ML Kit OCR, 用占位文本 + userText
      ocrText = payload.userText ?? 'mock OCR text from image';
    } else {
      // payload.kind === 'file'
      ocrText = payload.userText ?? 'mock OCR text from file';
    }

    // Step 2: 清洗文本
    const cleaned: string = this.cleanText(ocrText);

    // Step 3: 调 LLM 分类
    const messages: ChatMessage[] = [
      { role: 'system', content: CLASSIFY_PROMPT },
      { role: 'user', content: '请分类以下数学文本:\n\n' + cleaned },
    ];

    const client = new LlmClient();
    let raw: string;
    try {
      raw = await client.call(messages);
    } catch (e) {
      // 降级: API 不可用时返回低置信 mock
      if (e instanceof LlmError && e.kind === 'NO_API_KEY') {
        return {
          type: '计算',
          subject: '高等代数',
          chapter: '',
          confidence: 0.3,
          ocrText: cleaned,
        };
      }
      throw e;
    }

    // Step 4: 解析 JSON
    const result: ClassificationResult = this.parseResult(raw, cleaned);
    return result;
  }

  // 清洗文本: 去多余空白、截断
  private cleanText(text: string): string {
    let t: string = text.replace(/\s+/g, ' ').trim();
    if (t.length > 1000) {
      t = t.substring(0, 1000);
    }
    return t;
  }

  // 解析 LLM 返回的 JSON
  private parseResult(raw: string, ocrText: string): ClassificationResult {
    // 尝试从响应中提取 JSON
    let jsonStr: string = raw.trim();
    // 去掉可能的 markdown 代码块包裹
    const codeMatch: RegExpMatchArray | null = jsonStr.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (codeMatch !== null && codeMatch.length >= 2) {
      jsonStr = codeMatch[1].trim();
    }
    // 找 { ... } 最外层
    const braceMatch: RegExpMatchArray | null = jsonStr.match(/\{[\s\S]*\}/);
    if (braceMatch !== null) {
      jsonStr = braceMatch[0];
    }

    try {
      const parsed = JSON.parse(jsonStr) as Record<string, string>;
      const type: string = parsed.type ?? '计算';
      const validTypes: string[] = ['概念', '计算', '证明'];
      const finalType: string = validTypes.indexOf(type) >= 0 ? type : '计算';

      const subject: string = parsed.subject ?? '高等代数';
      const validSubjects: string[] = ['高等代数', '数学分析', '解析几何'];
      const finalSubject: string = validSubjects.indexOf(subject) >= 0 ? subject : '高等代数';

      const chapter: string = parsed.chapter ?? '';
      const conf: number = parseFloat(parsed.confidence ?? '0.7');
      const confidence: number = isNaN(conf) ? 0.7 : Math.max(0, Math.min(1, conf));

      return {
        type: finalType as '概念' | '计算' | '证明',
        subject: finalSubject as '高等代数' | '数学分析' | '解析几何',
        chapter: chapter,
        confidence: confidence,
        ocrText: ocrText,
      };
    } catch (e) {
      // JSON 解析失败 → 降级返回默认
      return {
        type: '计算',
        subject: '高等代数',
        chapter: '',
        confidence: 0.3,
        ocrText: ocrText,
      };
    }
  }
}