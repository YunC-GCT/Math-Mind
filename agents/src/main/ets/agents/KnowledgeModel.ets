// MathMind - KnowledgeModel (�ʼǽṹ�� + ��ֵ����)
// ������: C
// ����: Z
// ״̬: ʵ�����(2026-07-14) �� ����������
//
// �ӿ�:
//   structure(ocrText, type, subject, chapter): Promise<KnowledgeUnit>
//
// ʵ��:
//   1) ���� type ѡģ�� (3ѡ1)
//   2) �� LlmClient �ṹ�� �� Markdown
//   3) ��ֵ����(�������/����/���ʽ/ì�ܵ�ʽ)
//   4) ���� KnowledgeUnit (����ɵ��÷� AiService ����)

import {
  KnowledgeUnit,
  DifficultyLevel,
  ReviewStatus,
  TruthCheckResult,
  TruthFlag,
  LlmClient,
  ChatMessage,
} from 'common';

// ���� UUID
function uuid(): string {
  return 'KB-' + Date.now().toString(36) + '-' + Math.random().toString(36).substring(2, 8);
}

// ===== 3 ģ�� =====

const TEMPLATE_CONCEPT: string = `����һ����ѧ֪ʶ�ṹ�����֡��뽫������ѧ�����ı�����Ϊ Markdown ��ʽ��ʹ�����½ṹ:

## ����
(���ĸ���ľ�ȷ����)

## ����
(�ø������Ҫ���ʣ�ÿ��һ��)

## ��ظ���
(��֮��ص�������ѧ���ÿ��һ��)

�����ı�:
`;

const TEMPLATE_COMPUTATION: string = `����һ����ѧ֪ʶ�ṹ�����֡��뽫������ѧ����������Ϊ Markdown ��ʽ��ʹ�����½ṹ:

## ��Ŀ
(ԭʼ��Ŀ����)

## �ⷨ
(��ϸ���ⲽ�裬�ֲ��г�)

## ��
(���ս��)

�����ı�:
`;

const TEMPLATE_PROOF: string = `����һ����ѧ֪ʶ�ṹ�����֡��뽫������ѧ֤��������Ϊ Markdown ��ʽ��ʹ�����½ṹ:

## ����
(��֤��������)

## ֤��
(��ϸ֤�����̣��ֲ��г�)

## Ҫ��
(֤���еĹؼ������ͼ��ɣ�ÿ��һ��)

�����ı�:
`;

export class KnowledgeModel {
  // �����: �ṹ�� + ��ֵ���� �� KnowledgeUnit (�����)
  async structure(
    ocrText: string,
    type: '概念' | '计算' | '证明',
    subject: '高等代数' | '数学分析' | '解析几何',
    chapter: string,
  ): Promise<KnowledgeUnit> {
    // Step 1: ѡģ��
    const template: string = this.pickTemplate(type);

    // Step 2: �� LLM �ṹ��
    const messages: ChatMessage[] = [
      { role: 'system', content: '����һ����ѧ֪ʶ����ר�ң��밴ָ����ʽ�������ݣ�ֻ���������� Markdown��' },
      { role: 'user', content: template + '\n\n' + ocrText },
    ];

    const client = new LlmClient();
    let content: string;
    try {
      content = await client.call(messages);
    } catch (e) {
      // LLM ������ʱʹ��ԭʼ�ı� + ģ��ռλ
      content = this.fallbackContent(type, ocrText);
    }

    // Step 3: ��ֵ����
    const truth: TruthCheckResult = this.truthCheck(ocrText);

    // Step 4: ���� title (��30��, ��ǰ׺)
    const prefix: string = type === '概念' ? '【概念】' : type === '计算' ? '【计算】' : '【证明】';
    const rawTitle: string = ocrText.replace(/\s+/g, ' ').trim().substring(0, 30);
    const title: string = prefix + rawTitle;

    // Step 5: ����ժҪ
    const summary: string = content.replace(/[#*]/g, '').trim().substring(0, 100);

    // Step 6: ���� tags
    const tags: string[] = [type, subject];
    if (chapter.length > 0) {
      tags.push(chapter);
    }
    if (!truth.passed) {
      tags.push('������');
    }

    // Step 7: ���� KnowledgeUnit
    const now: number = Date.now();
    const unit: KnowledgeUnit = {
      id: uuid(),
      title: title,
      content: content,
      summary: summary,
      tags: tags,
      difficulty: DifficultyLevel.MEDIUM,
      source: 'camera_capture',
      createdAt: now,
      updatedAt: now,
      reviewStatus: ReviewStatus.NEW,
      nextReviewAt: now + 24 * 60 * 60 * 1000,
      intervalDays: 1,
      easeFactor: 2.5,
      repetitions: 0,
      prerequisites: [],
      related: [],
      embedding: [],
      userId: '',
      version: 1,
    };

    return unit;
  }

  // ===== ģ��ѡ�� =====
  private pickTemplate(type: string): string {
    if (type === '概念') {
      return TEMPLATE_CONCEPT;
    }
    if (type === '证明') {
      return TEMPLATE_PROOF;
    }
    return TEMPLATE_COMPUTATION;
  }

  // ===== LLM ���� =====
  private fallbackContent(type: string, ocrText: string): string {
    const sections: string[] = [];
    if (type === '概念') {
      sections.push('## 定义', '', ocrText, '', '## 性质', '', '## 相关概念');
    } else if (type === '计算') {
      sections.push('## 题目', '', ocrText, '', '## 解法', '', '## 答案');
    } else {
      sections.push('## 命题', '', ocrText, '', '## 证明', '', '## 要点');
    }
    return sections.join('\n');
  }

  // ===== ��ֵ���� =====
  truthCheck(text: string): TruthCheckResult {
    const flags: TruthFlag[] = [];

    if (!this.bracketsBalanced(text)) {
      flags.push('括号不配对');
    }
    if (this.hasZeroDivision(text)) {
      flags.push('除零');
    }
    if (this.hasIdentity(text)) {
      flags.push('恒等式');
    }
    if (this.hasContradiction(text)) {
      flags.push('矛盾等式');
    }
    if (text.trim().length < 5) {
      flags.push('无明确题目');
    }

    const passed: boolean = flags.length === 0;
    let message: string = '';
    if (!passed) {
      message = '��ֵ���鷢������: ' + flags.join(', ');
    }
    return { passed, flags, message };
  }

  private bracketsBalanced(text: string): boolean {
    let count: number = 0;
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);
      if (ch === '(' || ch === '��' || ch === '{' || ch === '[') {
        count++;
      } else if (ch === ')' || ch === '��' || ch === '}' || ch === ']') {
        count--;
        if (count < 0) {
          return false;
        }
      }
    }
    return count === 0;
  }

  private hasZeroDivision(text: string): boolean {
    const patterns: string[] = ['/0', '��0', '�� 0', '/ 0', '��ĸΪ��', '��ĸΪ0', '����0', '���� 0'];
    for (let i = 0; i < patterns.length; i++) {
      if (text.indexOf(patterns[i]) >= 0) {
        return true;
      }
    }
    return false;
  }

  private hasIdentity(text: string): boolean {
    const re: RegExp = /(\d+|[a-zA-Z])\s*=\s*\1/g;
    const match: RegExpMatchArray | null = text.match(re);
    return match !== null && match.length > 0;
  }

  private hasContradiction(text: string): boolean {
    const re: RegExp = /(\d+)\s*=\s*(\d+)/g;
    let m: RegExpExecArray | null;
    while ((m = re.exec(text)) !== null) {
      if (m.length >= 3 && m[1] !== m[2]) {
        return true;
      }
    }
    return false;
  }
}