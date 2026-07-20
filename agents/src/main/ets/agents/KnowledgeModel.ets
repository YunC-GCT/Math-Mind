/**
 * KnowledgeModel.ets — 知识结构化模型
 *
 * 职责：笔记结构化 + 真值检验；持久化由 entry 层 NoteDao 负责
 * 任务编号: C
 * 依赖: A1 (NoteDao) + B1 (OcrTool) 完成
 *
 * 接口约定:
 *   structure(ocrText: string): Promise<KnowledgeUnitExt>
 *
 * 实现路径（2026-07 新版）:
 *   1) AI 自分词 → 判断最小类（概念/定理/公式/证明题/计算题）
 *   2) AI 按各类 Schema 填充结构化字段
 *   3) 构造 KnowledgeUnitExt (含 id/tags/fields/truthFlag/...)
 *   4) truthCheck(ocrText) 返回 MvpTruthCheckResult
 *   5) 转换为主线 KnowledgeUnit 返回
 *
 * ArkTS 严格模式约束:
 *   - 不使用 any/unknown
 *   - 不使用 as const
 *   - 对象字面量有显式类型
 *   - 不使用解构赋值
 *   - 不使用 spread 运算符
 *   - 不使用嵌套函数
 */

import type { KnowledgeCategory } from '../models/KnowledgeCategory';
import { MvpTruthCheckResult, MvpTruthCheckItem } from '../models/TruthCheckResult';
import {
  KnowledgeUnitExt,
  createUnitExt,
  StructuredField,
  AiRawResponse,
} from '../models/KnowledgeUnitExt';
import {
  DifficultyLevel,
  isKnownNoteType,
  LlmClient,
  normalizeNoteType,
  NOTE_TYPE_KEYS,
  ReviewStatus,
} from 'common';
import type {
  ChatMessage,
  ClassificationResult,
  KnowledgeUnit,
} from 'common';
import { TypeClassifier } from './TypeClassifier';

// truthCheck internal interfaces
interface BracePairingResult {
  valid: boolean;
  errors: string[];
  correctedText: string;
}

interface LatexCheckDetail {
  hasError: boolean;
  issues: string[];
  correctedBody: string;
}

interface DivisionByZeroCheck {
  hasIssue: boolean;
  issues: string[];
}

interface EquationCheckResult {
  hasIssue: boolean;
  issues: string[];
}

const KNOWLEDGE_INPUT_LIMIT: number = 12000;
const KNOWLEDGE_MAX_TOKENS: number = 12000;
const KNOWLEDGE_TIMEOUT_MS: number = 300000;
const KNOWLEDGE_CLASSIFY_HINT_TIMEOUT_MS: number = 10000;
const KNOWLEDGE_HINT_CONFIDENCE_MIN: number = 0.55;
const KNOWLEDGE_FALLBACK_CATEGORY: KnowledgeCategory = '概念';
const KNOWLEDGE_FALLBACK_SUBJECT: string = '其它';

export class KnowledgeModel {

  /**
   * 主入口：AI 自分词 + 结构化 + 真值检验，返回主线 KnowledgeUnit。
   *
   * TypeClassifier 负责 OCR/文本提取，也可提供五分类 hint。
   * type/subject 仍作为可选 hint 保留给兼容调用方；未传入时由 KnowledgeModel 短超时获取 hint 后自行结构化。
   */
  async structure(
    ocrText: string,
    type?: string,
    subject?: string,
    chapter: string = '',
  ): Promise<KnowledgeUnit> {
    const startTime: number = Date.now();
    const classificationHint: ClassificationResult = await this.resolveClassificationHint(
      ocrText,
      type,
      subject,
      chapter,
    );
    const hasExternalType: boolean = type !== undefined && type.trim().length > 0;
    const hasNoExternalHint: boolean = type === undefined && subject === undefined && chapter.length === 0;
    const canUseClassifierType: boolean = hasNoExternalHint
      && classificationHint.confidence >= KNOWLEDGE_HINT_CONFIDENCE_MIN;
    const typeHint: string | undefined = hasExternalType || canUseClassifierType
      ? classificationHint.type
      : undefined;
    const subjectHint: string | undefined = classificationHint.subject !== KNOWLEDGE_FALLBACK_SUBJECT
      ? classificationHint.subject
      : undefined;
    const chapterHint: string = classificationHint.chapter ?? chapter;

    // 尝试 AI 结构化；失败时暂时沿用 fallback 笔记，不丢数据。
    // TODO: 后续改为结构化失败直接返回错误，由上层阻止入库，避免生成低质量占位笔记。
    let aiRaw: AiRawResponse;
    try {
      aiRaw = await this.callAi(
        ocrText,
        typeHint,
        subjectHint,
        chapterHint,
        classificationHint.confidence,
      );
    } catch (aiErr) {
      console.warn('[KnowledgeModel] AI call failed, using fallback: ' + (aiErr as Error).message);
      return this.buildFallbackFromClassify(
        ocrText,
        classificationHint.type,
        classificationHint.subject,
        chapterHint,
      );
    }
    const ext: KnowledgeUnitExt = createUnitExt(aiRaw.category, aiRaw.subject, aiRaw.title, ocrText);
    ext.fields = aiRaw.fields;
    ext.tags = this.buildTags(aiRaw);
    ext.difficulty = aiRaw.difficulty;
    ext.importance = aiRaw.importance;
    ext.source = chapterHint.length > 0 ? chapterHint : 'camera_capture';

    const truthResult: MvpTruthCheckResult = this.truthCheck(ocrText);
    ext.truthFlag = truthResult.truthFlag;
    if (!truthResult.truthFlag) {
      for (const item of truthResult.details) {
        if (!item.passed) {
          for (const issue of item.issues) {
            ext.truthDetails.push('[' + item.checkName + '] ' + issue);
          }
        }
      }
    }
    this.markNeedsUserInput(ext, aiRaw);

    const unit: KnowledgeUnit = this.toKnowledgeUnit(ext, startTime);
    console.info('[KnowledgeModel] structure done: id=' + unit.id
      + ' title=' + unit.title
      + ' category=' + ext.type
      + ' tags=' + JSON.stringify(unit.tags)
      + ' contentLen=' + unit.content.length.toString()
      + ' summary=' + unit.summary
      + ' aiFields=' + aiRaw.fields.length.toString());
    return unit;
  }

  async structureWithClassification(
    ocrText: string,
    classification: ClassificationResult,
  ): Promise<KnowledgeUnit> {
    return await this.structure(
      ocrText,
      classification.type,
      classification.subject,
      classification.chapter ?? '',
    );
  }

  private toKnowledgeUnit(ext: KnowledgeUnitExt, createdAt: number): KnowledgeUnit {
    const summary: string = this.summaryFromFields(ext);
    const now: number = createdAt > 0 ? createdAt : Date.now();
    return {
      id: this.uuid(),
      title: ext.title,
      content: this.contentFromFields(ext),
      summary: summary,
      tags: ext.tags,
      subject: ext.subject,
      category: ext.type,
      difficulty: this.toDifficultyLevel(ext.difficulty),
      source: ext.source.length > 0 ? ext.source : 'camera_capture',
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
      userId: ext.userId,
      version: 1,
    };
  }

  // AI 调用失败 fallback: 用 TypeClassifier 已有分类结果构造基础笔记
  // TODO: 后续删除该 fallback，改成显式失败，不再自动创建笔记。
  // 不调 AI，直接返回 KnowledgeUnit（标题来自 OCR 首行，标签来自分类结果）
  private buildFallbackFromClassify(
    ocrText: string, type?: string, subject?: string, chapter: string = '',
  ): KnowledgeUnit {
    const now: number = Date.now();
    const fallbackCategory: KnowledgeCategory = this.normalizeCategory(type ?? '', undefined);
    const fallbackSubject: string = this.normalizeSubject(subject ?? '', undefined);
    const firstLine: string = ocrText.split('\n')[0].trim();
    const title: string = (firstLine.length > 3 && firstLine.length < 60)
      ? firstLine
      : fallbackCategory + ' · ' + fallbackSubject;
    const tags: string[] = [];
    tags.push(fallbackCategory);
    if (chapter.length > 0) { tags.push(chapter); }
    const fallbackSummaryLimit: number = 500;
    const summary: string = ocrText.length > fallbackSummaryLimit
      ? ocrText.substring(0, fallbackSummaryLimit).replace(/[#*]/g, '').trim()
      : ocrText.replace(/[#*]/g, '').trim();

    console.info('[KnowledgeModel] fallback note created, title=' + title);
    return {
      id: this.uuid(),
      title: title,
      content: '## 内容\n' + ocrText,
      summary: summary,
      tags: tags,
      subject: fallbackSubject,
      category: fallbackCategory,
      difficulty: DifficultyLevel.MEDIUM,
      source: chapter.length > 0 ? chapter : 'camera_capture',
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
  }

  private summaryFromFields(ext: KnowledgeUnitExt): string {
    const summaryLimit: number = 500;
    let summary: string = '';
    for (const field of ext.fields) {
      if (field.value.length > 0) {
        summary = summary + field.value + '\n';
      }
      if (summary.length >= summaryLimit) {
        break;
      }
    }
    if (summary.length === 0) {
      summary = ext.content;
    }
    const cleaned: string = summary.replace(/[#*]/g, '').trim();
    return cleaned.length > summaryLimit ? cleaned.substring(0, summaryLimit).trim() : cleaned;
  }

  private toDifficultyLevel(value: number): DifficultyLevel {
    if (value <= 1) { return DifficultyLevel.EASY; }
    if (value === 2 || value === 3) { return DifficultyLevel.MEDIUM; }
    if (value === 4) { return DifficultyLevel.HARD; }
    return DifficultyLevel.EXPERT;
  }

  private uuid(): string {
    return 'KB-' + Date.now().toString(36) + '-' + Math.random().toString(36).substring(2, 8);
  }
  private async callAi(
    ocrText: string,
    typeHint?: string,
    subjectHint?: string,
    chapterHint: string = '',
    confidenceHint: number = 0,
  ): Promise<AiRawResponse> {
    // 可选分类 hint：TypeClassifier 只提供软参考，KnowledgeModel 仍按正文独立结构化。
    const hint: string = (typeHint !== undefined && typeHint.length > 0) || (subjectHint !== undefined && subjectHint.length > 0)
      ? '\n\n## 分类 hint (来自 TypeClassifier 粗分类, AI 自行决定是否采纳)\n' +
        '- 粗分类: ' + (typeHint ?? '未知') + '\n' +
        '- 学科: ' + (subjectHint ?? '未知') + '\n' +
        '- 章节/知识点: ' + (chapterHint.length > 0 ? chapterHint : '未知') + '\n' +
        '- 置信度: ' + confidenceHint.toString() + '\n' +
        '优先用它减少五类歧义；如果正文证据更强, 以正文为准。'
      : '';
    const prompt: string = this.buildPrompt(ocrText) + hint;

    const systemMsg: ChatMessage = { role: 'system', content: prompt };
    const userText: string = ocrText.length > KNOWLEDGE_INPUT_LIMIT ? ocrText.substring(0, KNOWLEDGE_INPUT_LIMIT) : ocrText;
    const userMsg: ChatMessage = { role: 'user', content: userText };
    const messages: ChatMessage[] = [systemMsg, userMsg];

    console.info('[KnowledgeModel] callAi: systemPrompt=' + prompt.length.toString() + ' chars, userText=' + userText.length.toString() + ' chars');
    let rawContent: string;
    try {
      const client: LlmClient = new LlmClient();
      rawContent = await client.call(messages, {
        maxTokens: KNOWLEDGE_MAX_TOKENS,
        timeoutMs: KNOWLEDGE_TIMEOUT_MS,
      });
      console.info('[KnowledgeModel] callAi response received, len=' + rawContent.length.toString());
    } catch (llmErr) {
      console.error('[KnowledgeModel] callAi LLM error: ' + (llmErr as Error).message);
      throw new Error('LLM 调用失败: ' + (llmErr as Error).message);
    }

    if (!rawContent || rawContent.length === 0) {
      console.error('[KnowledgeModel] callAi empty content after 200 OK');
      throw new Error('AI 返回为空:content 为空');
    }

    let jsonStr: string = rawContent.trim();
    const codeMatch: RegExpMatchArray | null = jsonStr.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (codeMatch !== null && codeMatch.length >= 2) { jsonStr = codeMatch[1].trim(); }
    const braceMatch: RegExpMatchArray | null = jsonStr.match(/\{[\s\S]*\}/);
    if (braceMatch !== null) { jsonStr = braceMatch[0]; }
    const parsed: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;

    const aiRaw: AiRawResponse = {
      category: this.normalizeCategory(String(parsed['category'] ?? ''), typeHint),
      subject: this.normalizeSubject(String(parsed['subject'] ?? ''), subjectHint),
      title: this.normalizeTitle(String(parsed['title'] ?? ''), userText),
      tags: this.normalizeStringArray(parsed['tags']),
      difficulty: this.normalizeScore(Number(parsed['difficulty'] ?? 3)),
      importance: this.normalizeScore(Number(parsed['importance'] ?? 3)),
      fields: this.normalizeFields(parsed['fields']),
    };

    return aiRaw;
  }
  // === Build AI Prompt ===

  buildPrompt(ocrText: string): string {
    const categories: string = NOTE_TYPE_KEYS.join(' / ');
    return `你是数学学习笔记结构化助手。只返回纯 JSON 文本，不要用 \`\`\`json\`\`\` 代码块包裹。
语言: 默认全部使用中文。
字段:
- category: 必须从 ${categories} 这五类中选择，不要返回 concept/theorem/formula/proof/computation
- subject: 学科名称由你自主判断（如"高等数学"/"线性代数"/"初中数学"），无法判断时返回"其它"
- title: 严谨名称或题目摘要
- tags: 返回 2-4 个中文关键词（具体概念/方法/技巧），学科名请填在 subject 字段。示例: ["二次函数", "配方法", "顶点", "对称轴"]
- difficulty: 1-5，1=简单，5=困难
- importance: 1-5，1=低，5=核心
- fields: 按 category 返回结构化字段数组 [{key, label, value}]
  概念: 定义/性质/示例/相关概念
  定理: 陈述/条件/结论/证明思路/应用
  公式: 表达式/参数/适用范围/推导/备注
  证明题: 命题/已知/证明过程/关键思路/结论
  计算题: 问题/步骤/答案/方法总结/常见错误
以上为各分类的标准字段，必须全部包含且不得增减，字段顺序可调整。

渲染要求:
- 行内短公式用 $...$ 包裹，如 $x^2 + y^2 = r^2$。
- 重要的独立公式用 $$...$$ 包裹并单独成行，如：
  $$
  \frac{-b \pm \sqrt{b^2-4ac}}{2a}
  $$
- 尽量一个字段对应一个页面分区。
- 保留完整信息，不要把原题和关键步骤摘要丢失。`;
  }
  /**
   * 合并标签：AI 返回的标签 + 最小类名，去重
   *
   * @param aiRaw - AI 原始响应
   * @returns 去重后的标签数组
   */
  private buildTags(aiRaw: AiRawResponse): string[] {
    const tags: string[] = [];
    tags.push(aiRaw.category);
    for (const tag of aiRaw.tags) {
      if (tags.indexOf(tag) === -1) {
        tags.push(tag);
      }
    }
    return tags;
  }

  /**
   * 标记需要用户确认的字段（标题/难度/重要性）
   * 证明题和计算题的标题由 AI 总结，用户可以修改
   *
   * @param unit - 正在构建的知识单元
   * @param aiRaw - AI 原始响应
   */
  private markNeedsUserInput(unit: KnowledgeUnitExt, aiRaw: AiRawResponse): void {
    if (aiRaw.category === '证明题' || aiRaw.category === '计算题') {
      unit.needsUserInput.push('title');
    }
    unit.needsUserInput.push('difficulty');
    unit.needsUserInput.push('importance');
  }

  private contentFromFields(ext: KnowledgeUnitExt): string {
    const sections: string[] = [];
    for (const field of ext.fields) {
      const label: string = field.label.trim().length > 0 ? field.label.trim() : field.key.trim();
      const value: string = field.value.trim();
      if (value.length > 0) {
        sections.push('## ' + label + '\n' + value);
      }
    }
    const raw: string = ext.content.trim();
    if (raw.length > 0) {
      sections.push('## 原文\n' + raw);
    }
    if (sections.length === 0) {
      return ext.content;
    }
    return sections.join('\n\n');
  }

  private normalizeCategory(value: string, fallback?: string): KnowledgeCategory {
    const normalized: string = normalizeNoteType(value);
    if (isKnownNoteType(normalized)) {
      return normalized as KnowledgeCategory;
    }
    if (fallback !== undefined) {
      const fallbackType: string = normalizeNoteType(fallback);
      if (isKnownNoteType(fallbackType)) {
        return fallbackType as KnowledgeCategory;
      }
    }
    return KNOWLEDGE_FALLBACK_CATEGORY;
  }

  private normalizeSubject(value: string, fallback?: string): string {
    const subject: string = value.trim();
    if (subject.length > 0 && subject !== '未知' && subject !== 'null' && subject !== 'undefined') {
      return subject;
    }
    if (fallback !== undefined) {
      const fallbackSubject: string = fallback.trim();
      if (fallbackSubject.length > 0 && fallbackSubject !== '未知') {
        return fallbackSubject;
      }
    }
    return KNOWLEDGE_FALLBACK_SUBJECT;
  }

  private normalizeTitle(value: string, fallbackText: string): string {
    const title: string = value.trim();
    if (title.length > 0 && title !== '未知' && title !== 'null' && title !== 'undefined') {
      return title;
    }
    const firstLine: string = fallbackText.split('\n')[0].trim();
    if (firstLine.length > 0 && firstLine.length <= 60) {
      return firstLine;
    }
    return '数学笔记';
  }

  private normalizeScore(value: number): number {
    if (value >= 1 && value <= 5) {
      return value;
    }
    return 3;
  }

  private normalizeStringArray(value: Object | undefined): string[] {
    const result: string[] = [];
    if (value === undefined || value === null || !Array.isArray(value)) {
      return result;
    }
    const items: Object[] = value as Object[];
    for (const item of items) {
      const text: string = String(item).trim();
      if (text.length > 0 && result.indexOf(text) < 0) {
        result.push(text);
      }
    }
    return result;
  }

  private normalizeFields(value: Object | undefined): StructuredField[] {
    const result: StructuredField[] = [];
    if (value === undefined || value === null || !Array.isArray(value)) {
      return result;
    }
    const items: Object[] = value as Object[];
    for (const item of items) {
      const record: Record<string, Object> = item as Record<string, Object>;
      const key: string = String(record['key'] ?? '').trim();
      const label: string = String(record['label'] ?? '').trim();
      const fieldValue: string = String(record['value'] ?? '').trim();
      if ((key.length > 0 || label.length > 0) && fieldValue.length > 0) {
        result.push({
          key: key.length > 0 ? key : label,
          label: label.length > 0 ? label : key,
          value: fieldValue,
        });
      }
    }
    return result;
  }

  private async resolveClassificationHint(
    ocrText: string,
    type?: string,
    subject?: string,
    chapter: string = '',
  ): Promise<ClassificationResult> {
    const externalHint: ClassificationResult = this.buildExternalHint(ocrText, type, subject, chapter);
    if (type !== undefined || subject !== undefined || chapter.length > 0) {
      return externalHint;
    }
    try {
      const classifier = new TypeClassifier();
      const classified: ClassificationResult = await classifier.classifyText(
        ocrText,
        KNOWLEDGE_CLASSIFY_HINT_TIMEOUT_MS,
      );
      return this.mergeClassificationHint(externalHint, classified);
    } catch (e) {
      console.warn('[KnowledgeModel] TypeClassifier hint skipped: ' + ((e as Error).message ?? String(e)));
      return externalHint;
    }
  }

  private buildExternalHint(
    ocrText: string,
    type?: string,
    subject?: string,
    chapter: string = '',
  ): ClassificationResult {
    return {
      type: this.normalizeCategory(type ?? '', undefined),
      subject: this.normalizeSubject(subject ?? '', undefined),
      chapter: chapter,
      confidence: type !== undefined || subject !== undefined || chapter.length > 0 ? 0.8 : 0,
      ocrText: ocrText,
    };
  }

  private mergeClassificationHint(
    base: ClassificationResult,
    classified: ClassificationResult,
  ): ClassificationResult {
    const result: ClassificationResult = {
      type: base.type,
      subject: base.subject,
      chapter: base.chapter ?? '',
      confidence: base.confidence,
      ocrText: classified.ocrText ?? base.ocrText,
    };
    if (classified.confidence >= KNOWLEDGE_HINT_CONFIDENCE_MIN) {
      result.type = this.normalizeCategory(classified.type, base.type);
      result.confidence = classified.confidence;
    }
    if (classified.subject.trim().length > 0 && classified.subject !== KNOWLEDGE_FALLBACK_SUBJECT) {
      result.subject = classified.subject.trim();
    }
    if ((classified.chapter ?? '').trim().length > 0) {
      result.chapter = (classified.chapter ?? '').trim();
    }
    return result;
  }

  /**
   * 执行 4 项数学真值检验：括号配对、除零检测、等式矛盾、LaTeX 语法
   *
   * @param ocrText - 输入文本
   * @returns MvpTruthCheckResult（检验结果 + 自动修正）
   */
  truthCheck(ocrText: string): MvpTruthCheckResult {
    if (!ocrText || ocrText.trim().length === 0) {
      const emptyItem: MvpTruthCheckItem = {
        checkName: 'emptyInput',
        passed: false,
        issues: ['input text is empty'],
      };
      return {
        truthFlag: false,
        details: [emptyItem],
        correctedText: undefined,
      };
    }

    const details: MvpTruthCheckItem[] = [];
    let corrected: string = ocrText;
    let allPassed: boolean = true;

    const braceResult: BracePairingResult = this.checkBracePairing(corrected);
    const braceItem: MvpTruthCheckItem = {
      checkName: 'bracketPair',
      passed: braceResult.valid,
      issues: braceResult.errors,
    };
    details.push(braceItem);
    if (!braceResult.valid) {
      allPassed = false;
      corrected = braceResult.correctedText;
    }

    const divByZero: DivisionByZeroCheck = this.checkDivisionByZero(corrected);
    const divItem: MvpTruthCheckItem = {
      checkName: 'divisionByZero',
      passed: !divByZero.hasIssue,
      issues: divByZero.issues,
    };
    details.push(divItem);
    if (divByZero.hasIssue) {
      allPassed = false;
    }

    const eqResult: EquationCheckResult = this.checkEquation(corrected);
    const eqItem: MvpTruthCheckItem = {
      checkName: 'equationCheck',
      passed: !eqResult.hasIssue,
      issues: eqResult.issues,
    };
    details.push(eqItem);
    if (eqResult.hasIssue) {
      allPassed = false;
    }

    const latexDetail: LatexCheckDetail = this.checkLatexInternal(corrected);
    const latexItem: MvpTruthCheckItem = {
      checkName: 'latexSyntax',
      passed: !latexDetail.hasError,
      issues: latexDetail.issues,
    };
    details.push(latexItem);
    if (latexDetail.hasError) {
      allPassed = false;
    }
    if (latexDetail.correctedBody !== corrected) {
      corrected = latexDetail.correctedBody;
    }

    return {
      truthFlag: allPassed,
      details: details,
      correctedText: corrected !== ocrText ? corrected : undefined,
    };
  }

  checkBracePairing(text: string): BracePairingResult {
    const errors: string[] = [];
    let braceDepth: number = 0;
    let result: string = '';
    let idx: number = 0;

    while (idx < text.length) {
      const ch: string = text[idx];
      if (ch === '{') {
        braceDepth = braceDepth + 1;
        result = result + ch;
      } else if (ch === '}') {
        braceDepth = braceDepth - 1;
        if (braceDepth < 0) {
          errors.push('extra closing brace at position ' + String(idx));
          braceDepth = 0;
        } else {
          result = result + ch;
        }
      } else {
        result = result + ch;
      }
      idx = idx + 1;
    }

    if (braceDepth > 0) {
      errors.push('missing closing brace count: ' + String(braceDepth));
      let fillCount: number = 0;
      while (fillCount < braceDepth) {
        result = result + '}';
        fillCount = fillCount + 1;
      }
    }

    return {
      valid: errors.length === 0,
      errors: errors,
      correctedText: result,
    };
  }

  checkDivisionByZero(text: string): DivisionByZeroCheck {
    const issues: string[] = [];
    if (text.indexOf('/0') !== -1) {
      issues.push('possible division by zero: /0');
    }
    return {
      hasIssue: issues.length > 0,
      issues: issues,
    };
  }
  checkEquation(text: string): EquationCheckResult {
    const issues: string[] = [];
    const contradictions: string[] = ['1=0', '0=1', '2=1', '1=2', '0=2', '2=0'];
    for (const contradiction of contradictions) {
      if (text.indexOf(contradiction) !== -1) {
        issues.push('contradictory equation: ' + contradiction);
      }
    }
    if (text.indexOf('\u2260') !== -1) {
      issues.push('contains not-equal sign, please verify context');
    }
    const eqPatterns: string[] = ['x=x', 'X=X', 'a=a', 'A=A'];
    for (const pattern of eqPatterns) {
      if (text.indexOf(pattern) !== -1) {
        issues.push('identity equation: ' + pattern);
        break;
      }
    }
    return {
      hasIssue: issues.length > 0,
      issues: issues,
    };
  }
  checkLatexInternal(body: string): LatexCheckDetail {
    const issues: string[] = [];
    let corrected: string = body;

    const braceResult: BracePairingResult = this.checkBracePairing(corrected);
    if (!braceResult.valid) {
      for (const error of braceResult.errors) {
        issues.push(error);
      }
      corrected = braceResult.correctedText;
    }

    const leftCount: number = this.countOccurrences(corrected, '\\left');
    const rightCount: number = this.countOccurrences(corrected, '\\right');
    if (leftCount !== rightCount) {
      issues.push('\\left and \\right count mismatch: ' + String(leftCount) + ':' + String(rightCount));
    }

    const latexFixes: string[][] = [
      ['\\fract{', '\\frac{'],
      ['\\sqt{', '\\sqrt{'],
      ['\\begin{align*}', '\\begin{aligned}'],
    ];
    for (const fix of latexFixes) {
      const before: string = corrected;
      const target: string = fix[0];
      const replacement: string = fix[1];
      if (corrected.indexOf(target) !== -1) {
        corrected = corrected.split(target).join(replacement);
        if (corrected !== before) {
          issues.push('auto fixed: ' + target + ' -> ' + replacement);
        }
      }
    }

    corrected = this.patchIntegralDx(corrected, issues);

    return {
      hasError: issues.length > 0,
      issues: issues,
      correctedBody: corrected,
    };
  }
  // === Utility methods ===

  private countOccurrences(text: string, pattern: string): number {
    let count: number = 0;
    let pos: number = text.indexOf(pattern);
    while (pos !== -1) {
      count = count + 1;
      pos = text.indexOf(pattern, pos + 1);
    }
    return count;
  }

  private patchIntegralDx(text: string, issues: string[]): string {
    let result: string = text;
    const intPattern: string = '\\int_{';
    const dxPattern: string = 'dx';
    let searchPos: number = 0;
    while (true) {
      const intIdx: number = result.indexOf(intPattern, searchPos);
      if (intIdx === -1) {
        break;
      }
      const closeIdx: number = result.indexOf('}', intIdx + intPattern.length);
      if (closeIdx === -1) {
        break;
      }
      const hatOpen: number = result.indexOf('^{', closeIdx);
      if (hatOpen === -1) {
        break;
      }
      const hatClose: number = result.indexOf('}', hatOpen + 2);
      if (hatClose === -1) {
        break;
      }
      const afterIntegral: string = result.substring(hatClose + 1);
      const trimmedAfter: string = afterIntegral.trim();
      if (
        trimmedAfter.indexOf(dxPattern) !== 0 &&
        trimmedAfter.indexOf('\\,dx') !== 0 &&
        trimmedAfter.indexOf('\\, dx') !== 0
      ) {
        result =
          result.substring(0, hatClose + 1) +
          ' \\, dx' +
          result.substring(hatClose + 1);
        issues.push('自动修正: 积分表达式补充 \\, dx');
      }
      searchPos = hatClose + 1;
    }
    return result;
  }
}
