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

import { KnowledgeCategory } from '../models/KnowledgeCategory';
import { MvpTruthCheckResult, MvpTruthCheckItem } from '../models/TruthCheckResult';
import {
  KnowledgeUnitExt,
  createUnitExt,
  StructuredField,
  AiRawResponse,
} from '../models/KnowledgeUnitExt';
import {
  KnowledgeUnit,
  DifficultyLevel,
  ReviewStatus,
  LlmClient,
  ChatMessage,
} from 'common';

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

export class KnowledgeModel {

  /**
   * 主入口：AI 自分词 + 结构化 + 真值检验，返回主线 KnowledgeUnit。
   *
   * P0 修复: type/subject 不再被忽略，作为 hint 注入到 AI prompt。
   * TypeClassifier 已做过 3 类分类 (概念/计算/证明) + 学科判定 (高代/数分/几何)，
   * KnowledgeModel 不该再做完全独立的 5 类自分词 — 把分类作为 hint 给 AI 参考。
   */
  async structure(
    ocrText: string,
    type?: string,
    subject?: string,
    chapter: string = '',
  ): Promise<KnowledgeUnit> {
    const startTime: number = Date.now();

    // 尝试 AI 结构化；失败时用已有分类结果构造 fallback 笔记，不丢数据
    let aiRaw: AiRawResponse;
    try {
      aiRaw = await this.callAi(ocrText, type, subject);
    } catch (aiErr) {
      console.warn('[KnowledgeModel] AI call failed, using fallback: ' + (aiErr as Error).message);
      return this.buildFallbackFromClassify(ocrText, type, subject, chapter);
    }
    const ext: KnowledgeUnitExt = createUnitExt(aiRaw.category, aiRaw.title, ocrText);
    ext.fields = aiRaw.fields;
    ext.tags = this.buildTags(aiRaw);
    ext.difficulty = aiRaw.difficulty;
    ext.importance = aiRaw.importance;
    ext.source = chapter.length > 0 ? chapter : 'camera_capture';

    const truthResult: MvpTruthCheckResult = this.truthCheck(ocrText);
    ext.truthFlag = truthResult.truthFlag;
    if (!truthResult.truthFlag) {
      for (let i: number = 0; i < truthResult.details.length; i++) {
        const item: MvpTruthCheckItem = truthResult.details[i];
        if (!item.passed) {
          for (let j: number = 0; j < item.issues.length; j++) {
            ext.truthDetails.push('[' + item.checkName + '] ' + item.issues[j]);
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

  private toKnowledgeUnit(ext: KnowledgeUnitExt, createdAt: number): KnowledgeUnit {
    const summary: string = this.summaryFromFields(ext);
    const now: number = createdAt > 0 ? createdAt : Date.now();
    return {
      id: this.uuid(),
      title: ext.title,
      content: ext.content,
      summary: summary,
      tags: ext.tags,
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
  // 不调 AI，直接返回 KnowledgeUnit（标题来自 OCR 首行，标签来自分类结果）
  private buildFallbackFromClassify(
    ocrText: string, type?: string, subject?: string, chapter: string = '',
  ): KnowledgeUnit {
    const now: number = Date.now();
    const firstLine: string = ocrText.split('\n')[0].trim();
    const title: string = (firstLine.length > 3 && firstLine.length < 60)
      ? firstLine
      : (type !== undefined && type.length > 0 ? type : '笔记')
        + (subject !== undefined && subject.length > 0 ? ' · ' + subject : '');
    const tags: string[] = [];
    if (type !== undefined && type.length > 0) { tags.push(type); }
    if (subject !== undefined && subject.length > 0) { tags.push(subject); }
    if (chapter.length > 0) { tags.push(chapter); }
    const summary: string = ocrText.length > 100
      ? ocrText.substring(0, 100).replace(/[#*]/g, '').trim()
      : ocrText.replace(/[#*]/g, '').trim();

    console.info('[KnowledgeModel] fallback note created, title=' + title);
    return {
      id: this.uuid(),
      title: title,
      content: ocrText,
      summary: summary,
      tags: tags,
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
    let summary: string = '';
    for (let i: number = 0; i < ext.fields.length; i++) {
      if (ext.fields[i].value.length > 0) {
        summary = summary + ext.fields[i].value + '\n';
      }
      if (summary.length >= 100) {
        break;
      }
    }
    if (summary.length === 0) {
      summary = ext.content;
    }
    const cleaned: string = summary.replace(/[#*]/g, '').trim();
    return cleaned.length > 100 ? cleaned.substring(0, 100) : cleaned;
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
  private async callAi(ocrText: string, typeHint?: string, subjectHint?: string): Promise<AiRawResponse> {
    // P0 修复: 把 TypeClassifier 的分类结果作为 hint 注入 prompt
    const hint: string = (typeHint !== undefined && typeHint.length > 0) || (subjectHint !== undefined && subjectHint.length > 0)
      ? '\n\n## 分类 hint (来自 TypeClassifier 粗分类, AI 自行决定是否采纳)\n' +
        '- 粗分类: ' + (typeHint ?? '未知') + '\n' +
        '- 学科: ' + (subjectHint ?? '未知') + '\n' +
        '你可以参考, 也可以独立判断, 以你看到的题目内容为准。'
      : '';
    const prompt: string = this.buildPrompt(ocrText) + hint;

    const systemMsg: ChatMessage = { role: 'system', content: prompt };
    const truncatedText: string = ocrText.length > 1500 ? ocrText.substring(0, 1500) : ocrText;
    const userMsg: ChatMessage = { role: 'user', content: truncatedText };
    const messages: ChatMessage[] = [systemMsg, userMsg];

    console.info('[KnowledgeModel] callAi: systemPrompt=' + prompt.length.toString() + ' chars, userText=' + truncatedText.length.toString() + ' chars');
    let rawContent: string;
    try {
      const client: LlmClient = new LlmClient();
      rawContent = await client.call(messages);
      console.info('[KnowledgeModel] callAi response received, len=' + rawContent.length.toString());
    } catch (llmErr) {
      console.error('[KnowledgeModel] callAi LLM error: ' + (llmErr as Error).message);
      throw new Error('LLM 调用失败: ' + (llmErr as Error).message);
    }

    if (!rawContent || rawContent.length === 0) {
      console.error('[KnowledgeModel] callAi empty content after 200 OK');
      throw new Error('AI 返回为空:content 为空');
    }

    const parsed: Record<string, Object> = JSON.parse(rawContent) as Record<string, Object>;

    const aiRaw: AiRawResponse = {
      category: parsed['category'] as KnowledgeCategory,
      title: parsed['title'] as string,
      tags: parsed['tags'] as string[],
      difficulty: parsed['difficulty'] as number,
      importance: parsed['importance'] as number,
      fields: parsed['fields'] as StructuredField[],
    };

    return aiRaw;
  }
  // === Build AI Prompt ===

  buildPrompt(ocrText: string): string {
    return `You analyze math content. Return strict JSON only, no markdown.
Fields:
- category: concept/theorem/formula/proof/computation
- title: precise name or topic summary
- tags: 2-5 keywords
- difficulty: 1-5 (1=easy 5=hard)
- importance: 1-5 (1=low 5=core)
- fields: [{key, label, value}] per category:
  concept: definition/properties/examples/related_concepts
  theorem: statement/conditions/conclusion/proof_sketch/applications
  formula: expression/parameters/applicable_range/derivation/notes
  proof: proposition/given/proof_process/key_insight/conclusion
  computation: problem/steps/answer/method_summary/common_mistakes`;
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
    for (let i: number = 0; i < aiRaw.tags.length; i++) {
      const tag: string = aiRaw.tags[i];
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

    for (let i: number = 0; i < text.length; i++) {
      const ch: string = text[i];
      if (ch === '{') {
        braceDepth = braceDepth + 1;
        result = result + ch;
      } else if (ch === '}') {
        braceDepth = braceDepth - 1;
        if (braceDepth < 0) {
          errors.push('extra closing brace at position ' + String(i));
          braceDepth = 0;
        } else {
          result = result + ch;
        }
      } else {
        result = result + ch;
      }
    }

    if (braceDepth > 0) {
      errors.push('missing closing brace count: ' + String(braceDepth));
      for (let j: number = 0; j < braceDepth; j++) {
        result = result + '}';
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
    for (let i: number = 0; i < contradictions.length; i++) {
      if (text.indexOf(contradictions[i]) !== -1) {
        issues.push('contradictory equation: ' + contradictions[i]);
      }
    }
    if (text.indexOf('\u2260') !== -1) {
      issues.push('contains not-equal sign, please verify context');
    }
    const eqPatterns: string[] = ['x=x', 'X=X', 'a=a', 'A=A'];
    for (let j: number = 0; j < eqPatterns.length; j++) {
      if (text.indexOf(eqPatterns[j]) !== -1) {
        issues.push('identity equation: ' + eqPatterns[j]);
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
      for (let i: number = 0; i < braceResult.errors.length; i++) {
        issues.push(braceResult.errors[i]);
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
    for (let k: number = 0; k < latexFixes.length; k++) {
      const before: string = corrected;
      const target: string = latexFixes[k][0];
      const replacement: string = latexFixes[k][1];
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
