// MathMind - TypeClassifier (����/ѧ�Ʒ�����)
// ������: B2
// ����: Z
// ״̬: ʵ�����(2026-07-14) �� ����������, DeepSeek 3��3����
//
// �ӿ�:
//   classify(payload: DispatchPayload): Promise<ClassificationResult>
//
// ʵ��:
//   1) �� payload.kind ����: image �� mock OCR, text �� ֱ����, file �� mock OCR
//   2) cleanText ��ϴ
//   3) �� LlmClient.call() �� DeepSeek-V3 ����
//   4) ���� JSON �� ClassificationResult

import { ClassificationResult, DispatchPayload, LlmClient, LlmError, ChatMessage } from 'common';

const CLASSIFY_PROMPT: string = `����һ����ѧ��Ŀ�����������������ı����з��࣬���� JSON ��ʽ��

�������:
- type: ֻ���� "����"��"����"��"֤��" ֮һ
- subject: ֻ���� "�ߵȴ���"��"��ѧ����"��"��������" ֮һ
- chapter: �½�����(��"����ʽ"��"����"��"΢����ֵ����"), �޷��ж�ʱ�ÿ��ַ���
- confidence: 0.0-1.0 �����Ŷ�

���ظ�ʽ(ֻ���� JSON, ��Ҫ��������):
{"type":"����","subject":"�ߵȴ���","chapter":"����ʽ","confidence":0.92}`;

export class TypeClassifier {
  async classify(payload: DispatchPayload): Promise<ClassificationResult> {
    // Step 1: �� kind ��ȡ�ı�
    let ocrText: string;
    if (payload.kind === 'text') {
      ocrText = payload.text;
    } else if (payload.kind === 'image') {
      // MVP: �� ML Kit OCR, ��ռλ�ı� + userText
      ocrText = payload.userText ?? 'mock OCR text from image';
    } else {
      // payload.kind === 'file'
      ocrText = payload.userText ?? 'mock OCR text from file';
    }

    // Step 2: ��ϴ�ı�
    const cleaned: string = this.cleanText(ocrText);

    // Step 3: �� LLM ����
    const messages: ChatMessage[] = [
      { role: 'system', content: CLASSIFY_PROMPT },
      { role: 'user', content: '�����������ѧ�ı�:\n\n' + cleaned },
    ];

    const client = new LlmClient();
    let raw: string;
    try {
      raw = await client.call(messages);
    } catch (e) {
      // ����: API ������ʱ���ص����� mock
      if (e instanceof LlmError && e.kind === 'NO_API_KEY') {
        return {
          type: '概念',
          subject: '高等代数',
          chapter: '',
          confidence: 0.3,
          ocrText: cleaned,
        };
      }
      throw new Error(e instanceof Error ? e.message : String(e));
    }

    // Step 4: ���� JSON
    const result: ClassificationResult = this.parseResult(raw, cleaned);
    return result;
  }

  // ��ϴ�ı�: ȥ����հס��ض�
  private cleanText(text: string): string {
    let t: string = text.replace(/\s+/g, ' ').trim();
    if (t.length > 1000) {
      t = t.substring(0, 1000);
    }
    return t;
  }

  // ���� LLM ���ص� JSON
  private parseResult(raw: string, ocrText: string): ClassificationResult {
    // ���Դ���Ӧ����ȡ JSON
    let jsonStr: string = raw.trim();
    // ȥ�����ܵ� markdown ��������
    const codeMatch: RegExpMatchArray | null = jsonStr.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (codeMatch !== null && codeMatch.length >= 2) {
      jsonStr = codeMatch[1].trim();
    }
    // �� { ... } �����
    const braceMatch: RegExpMatchArray | null = jsonStr.match(/\{[\s\S]*\}/);
    if (braceMatch !== null) {
      jsonStr = braceMatch[0];
    }

    try {
      const parsed = JSON.parse(jsonStr) as Record<string, string>;
      const type: string = parsed.type ?? '概念';
      const validTypes: string[] = ['概念', '计算', '证明'];
      const finalType: string = validTypes.indexOf(type) >= 0 ? type : '概念';

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
      // JSON ����ʧ�� �� ��������Ĭ��
      return {
        type: '概念',
        subject: '高等代数',
        chapter: '',
        confidence: 0.3,
        ocrText: ocrText,
      };
    }
  }
}