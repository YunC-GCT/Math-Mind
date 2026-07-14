// MathMind - KnowledgeModel (笔记结构化 + 真值检验)
// 任务编号: C
// 责任: Z
// 状态: 实现完成(2026-07-14) — 精简拍照链
//
// 接口:
//   structure(ocrText, type, subject, chapter): Promise<KnowledgeUnit>
//
// 实现:
//   1) 根据 type 选模板 (3选1)
//   2) 调 LlmClient 结构化 → Markdown
//   3) 真值检验(括号配对/除零/恒等式/矛盾等式)
//   4) 返回 KnowledgeUnit (入库由调用方 AiService 负责)

import {
  KnowledgeUnit,
  DifficultyLevel,
  ReviewStatus,
  TruthCheckResult,
  TruthFlag,
  LlmClient,
  ChatMessage,
} from 'common';

// 生成 UUID
function uuid(): string {
  return 'KB-' + Date.now().toString(36) + '-' + Math.random().toString(36).substring(2, 8);
}

// ===== 3 模板 =====

const TEMPLATE_CONCEPT: string = `你是一个数学知识结构化助手。请将以下数学概念文本整理为 Markdown 格式，使用以下结构:

## 定义
(核心概念的精确定义)

## 性质
(该概念的重要性质，每条一行)

## 相关概念
(与之相关的其他数学概念，每条一行)

输入文本:
`;

const TEMPLATE_COMPUTATION: string = `你是一个数学知识结构化助手。请将以下数学计算题整理为 Markdown 格式，使用以下结构:

## 题目
(原始题目描述)

## 解法
(详细解题步骤，分步列出)

## 答案
(最终结果)

输入文本:
`;

const TEMPLATE_PROOF: string = `你是一个数学知识结构化助手。请将以下数学证明题整理为 Markdown 格式，使用以下结构:

## 命题
(待证明的命题)

## 证明
(详细证明过程，分步列出)

## 要点
(证明中的关键方法和技巧，每条一行)

输入文本:
`;

export class KnowledgeModel {
  // 主入口: 结构化 + 真值检验 → KnowledgeUnit (不入库)
  async structure(
    ocrText: string,
    type: '概念' | '计算' | '证明',
    subject: '高等代数' | '数学分析' | '解析几何',
    chapter: string,
  ): Promise<KnowledgeUnit> {
    // Step 1: 选模板
    const template: string = this.pickTemplate(type);

    // Step 2: 调 LLM 结构化
    const messages: ChatMessage[] = [
      { role: 'system', content: '你是一个数学知识整理专家，请按指定格式整理内容，只返回整理后的 Markdown。' },
      { role: 'user', content: template + '\n\n' + ocrText },
    ];

    const client = new LlmClient();
    let content: string;
    try {
      content = await client.call(messages);
    } catch (e) {
      // LLM 不可用时使用原始文本 + 模板占位
      content = this.fallbackContent(type, ocrText);
    }

    // Step 3: 真值检验
    const truth: TruthCheckResult = this.truthCheck(ocrText);

    // Step 4: 生成 title (≤30字, 带前缀)
    const prefix: string = type === '概念' ? '【概念】' : type === '计算' ? '【计算】' : '【证明】';
    const rawTitle: string = ocrText.replace(/\s+/g, ' ').trim().substring(0, 30);
    const title: string = prefix + rawTitle;

    // Step 5: 生成摘要
    const summary: string = content.replace(/[#*]/g, '').trim().substring(0, 100);

    // Step 6: 构造 tags
    const tags: string[] = [type, subject];
    if (chapter.length > 0) {
      tags.push(chapter);
    }
    if (!truth.passed) {
      tags.push('待复核');
    }

    // Step 7: 构造 KnowledgeUnit
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

  // ===== 模板选择 =====
  private pickTemplate(type: string): string {
    if (type === '概念') {
      return TEMPLATE_CONCEPT;
    }
    if (type === '证明') {
      return TEMPLATE_PROOF;
    }
    return TEMPLATE_COMPUTATION;
  }

  // ===== LLM 降级 =====
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

  // ===== 真值检验 =====
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
      message = '真值检验发现问题: ' + flags.join(', ');
    }
    return { passed, flags, message };
  }

  private bracketsBalanced(text: string): boolean {
    let count: number = 0;
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);
      if (ch === '(' || ch === '（' || ch === '{' || ch === '[') {
        count++;
      } else if (ch === ')' || ch === '）' || ch === '}' || ch === ']') {
        count--;
        if (count < 0) {
          return false;
        }
      }
    }
    return count === 0;
  }

  private hasZeroDivision(text: string): boolean {
    const patterns: string[] = ['/0', '÷0', '÷ 0', '/ 0', '分母为零', '分母为0', '除以0', '除以 0'];
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