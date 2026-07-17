/**
 * KnowledgeModelMVP.ets — KnowledgeModel MVP 实现
 *
 * 职责：笔记结构化 + 真值检验 + 入库
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
 *   5) NoteDao.insert(unit) → rowId → 回填 unit.id
 *   6) 返回完整 KnowledgeUnitExt (UI 直接渲染)
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
import { NoteDaoInterface } from '../models/NoteDaoInterface';
import { LlmClient, ChatMessage } from 'common';

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

export class KnowledgeModelMVP {

  private noteDao: NoteDaoInterface;

  constructor(noteDao: NoteDaoInterface) {
    this.noteDao = noteDao;
  }

  /**
   * 主入口：AI 自分词 + 结构化 + 真值检验 + 入库
   *
   * @param ocrText - OCR 识别后的数学文本
   * @returns 完整的 KnowledgeUnitExt（含 type/fields/truthFlag/id）
   */
  async structure(ocrText: string): Promise<KnowledgeUnitExt> {
    const startTime: number = Date.now();

    // Step 1: Call AI (via shared LlmClient)
    const aiRaw: AiRawResponse = await this.callAi(ocrText);

    // Step 2: Build KnowledgeUnitExt
    const unit: KnowledgeUnitExt = createUnitExt(
      aiRaw.category,
      aiRaw.title,
      ocrText,
    );
    unit.fields = aiRaw.fields;
    unit.tags = this.buildTags(aiRaw);
    unit.difficulty = aiRaw.difficulty;
    unit.importance = aiRaw.importance;

    // Step 3: Truth check
    const truthResult: MvpTruthCheckResult = this.truthCheck(ocrText);
    unit.truthFlag = truthResult.truthFlag;
    if (!truthResult.truthFlag) {
      for (let i: number = 0; i < truthResult.details.length; i++) {
        const item: MvpTruthCheckItem = truthResult.details[i];
        if (!item.passed) {
          for (let j: number = 0; j < item.issues.length; j++) {
            unit.truthDetails.push('[' + item.checkName + '] ' + item.issues[j]);
          }
        }
      }
    }

    // Step 4: Mark fields needing user input
    this.markNeedsUserInput(unit, aiRaw);

    // Step 5: Insert via NoteDao (async)
    try {
      const rowId: number = await this.noteDao.insert(unit);
      unit.id = String(rowId);
    } catch (err) {
      console.error('[KnowledgeModelMVP] NoteDao.insert ' + '\u5931\u8D25\uFF1A ' + err);
      unit.id = 'pending_' + String(startTime);
    }

    // Step 6: Return
    const elapsed: number = Date.now() - startTime;
    console.info(
      '[KnowledgeModelMVP] structure ' + '\u5B8C\u6210\u3002' +
      '\u8017\u65F6 ' + String(elapsed) + 'ms, ' +
      'category=' + aiRaw.category + ', ' +
      'truthFlag=' + String(unit.truthFlag)
    );

    return unit;
  }

  /**
   * 调用 LlmClient 向 DeepSeek 发送结构化请求
   * AI 返回 JSON 格式的自分词结果 + 结构化字段
   *
   * @param ocrText - 输入文本
   * @returns AiRawResponse（分类/标题/字段/难度/重要性）
   */
  private async callAi(ocrText: string): Promise<AiRawResponse> {
    const prompt: string = this.buildPrompt(ocrText);

    const systemMsg: ChatMessage = { role: 'system', content: prompt };
    const userMsg: ChatMessage = { role: 'user', content: ocrText };
    const messages: ChatMessage[] = [systemMsg, userMsg];

    const client: LlmClient = new LlmClient();
    const rawContent: string = await client.call(messages);

    if (!rawContent || rawContent.length === 0) {
      throw new Error('AI ' + '\u8FD4\u56DE\u4E3A\u7A7A\uFF1Acontent \u4E3A\u7A7A');
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
    return '你是一名数学知识整理专家。请分析用户输入的数学内容，完成以下任务：\n' +
      '\n' +
      '## 1. 自分词（分类）\n' +
      '判断这段内容属于哪个最小类（只选一个）：\n' +
      '- **概念**：数学定义、名词解释\n' +
      '- **定理**：已被证明的真命题、定理\n' +
      '- **公式**：数学表达式、公式\n' +
      '- **证明题**：需要证明的命题及其证明过程\n' +
      '- **计算题**：需要数值计算或求解的问题\n' +
      '\n' +
      '## 2. 标题\n' +
      '- 概念/定理/公式 → 给出严谨的标准名称（如"质数""勾股定理""求根公式"）\n' +
      '- 证明题/计算题 → AI 概括总结题目（如"证明√2是无理数""计算三阶行列式"）\n' +
      '\n' +
      '## 3. 填充该类的结构化字段\n' +
      '\n' +
      '### 概念\n' +
      '- definition: 核心定义\n' +
      '- properties: 关键性质/特征（分点列举）\n' +
      '- examples: 典型例子\n' +
      '- related_concepts: 关联概念\n' +
      '\n' +
      '### 定理\n' +
      '- statement: 定理表述\n' +
      '- conditions: 适用条件/前提\n' +
      '- conclusion: 结论\n' +
      '- proof_sketch: 证明思路\n' +
      '- applications: 常见应用\n' +
      '\n' +
      '### 公式\n' +
      '- expression: 公式表达式（用 LaTeX）\n' +
      '- parameters: 参数含义说明\n' +
      '- applicable_range: 适用范围/前提\n' +
      '- derivation: 简单推导\n' +
      '- notes: 注意事项\n' +
      '\n' +
      '### 证明题\n' +
      '- proposition: 要证明的命题\n' +
      '- given: 已知条件\n' +
      '- proof_process: 逐步证明过程\n' +
      '- key_insight: 关键思路/突破口\n' +
      '- conclusion: 最终结论\n' +
      '\n' +
      '### 计算题\n' +
      '- problem: 题目描述\n' +
      '- steps: 解题步骤\n' +
      '- answer: 最终答案\n' +
      '- method_summary: 解题方法归纳\n' +
      '- common_mistakes: 易错点\n' +
      '\n' +
      '## 4. 难度和重要程度\n' +
      '- difficulty: 1~5（整数），1=简单 5=困难\n' +
      '- importance: 1~5（整数），1=低 5=核心\n' +
      '\n' +
      '## 5. 标签\n' +
      '生成 2~5 个标签，包含最小类名和内容关键词。\n' +
      '\n' +
      '## 输出格式\n' +
      '严格按以下 JSON 格式输出，不要包含任何其他文字：\n' +
      '{\n' +
      '  "category": "概念|定理|公式|证明题|计算题",\n' +
      '  "title": "标题",\n' +
      '  "tags": ["标签1", "标签2"],\n' +
      '  "difficulty": 3,\n' +
      '  "importance": 4,\n' +
      '  "fields": [\n' +
      '    { "key": "字段名", "label": "显示名", "value": "内容" }\n' +
      '  ]\n' +
      '}';
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
        issues: ['输入文本为空，跳过真值检验'],
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

    // Check 1: Bracket pairing
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

    // Check 2: Division by zero
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

    // Check 3: Equation check
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

    // Check 4: LaTeX syntax
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

  /**
   * 检查花括号 {} 是否配对，缺的自动补，多的自动删
   *
   * @param text - 输入文本
   * @returns 检查结果 + 修正后的文本
   */
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
          errors.push('位置 ' + String(i) + ': 多余的闭合花括号 }（已自动移除）');
          braceDepth = 0;
        } else {
          result = result + ch;
        }
      } else {
        result = result + ch;
      }
    }

    if (braceDepth > 0) {
      errors.push('缺少 ' + String(braceDepth) + ' 个闭合花括号 }（已在末尾自动补充）');
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

  /**
   * 检测除零风险：/0、除以零、分母为零等模式
   *
   * @param text - 输入文本
   * @returns 检测结果
   */
  checkDivisionByZero(text: string): DivisionByZeroCheck {
    const issues: string[] = [];
    if (text.indexOf('除以0') !== -1 || text.indexOf('除以零') !== -1) {
      issues.push('检测到"除以0/除以零"——请确认分母不为零');
    }
    const slashZeroIdx: number = text.indexOf('/0');
    if (slashZeroIdx !== -1) {
      const after: string = text.substring(slashZeroIdx + 2);
      if (after.length === 0 || isNaN(Number(after[0]))) {
        issues.push('检测到 "/0" 表达式，可能存在除零风险');
      }
    }
    if (text.indexOf('分母为0') !== -1 || text.indexOf('分母为零') !== -1) {
      issues.push('检测到"分母为0/分母为零"——请确认分母不为零');
    }
    return {
      hasIssue: issues.length > 0,
      issues: issues,
    };
  }

  /**
   * 检测矛盾等式（1=0）和恒等式（x=x）
   *
   * @param text - 输入文本
   * @returns 检测结果
   */
  checkEquation(text: string): EquationCheckResult {
    const issues: string[] = [];
    const contradictions: string[] = ['1=0', '0=1', '2=1', '1=2', '0=2', '2=0'];
    for (let i: number = 0; i < contradictions.length; i++) {
      if (text.indexOf(contradictions[i]) !== -1) {
        issues.push('检测到明显矛盾等式: "' + contradictions[i] + '"');
      }
    }
    if (text.indexOf('≠') !== -1) {
      issues.push('文本包含不等号 ≠，请确认该内容为正确知识而非矛盾陈述');
    }
    const eqPatterns: string[] = ['x=x', 'X=X', 'a=a', 'A=A'];
    for (let j: number = 0; j < eqPatterns.length; j++) {
      if (text.indexOf(eqPatterns[j]) !== -1) {
        issues.push('检测到恒等式 "' + eqPatterns[j] + '"，请确认是否为目标知识');
        break;
      }
    }
    return {
      hasIssue: issues.length > 0,
      issues: issues,
    };
  }

  /**
   * LaTeX 语法检查：\left/\right 配对、常见拼写修正、积分补 dx
   *
   * @param body - 输入文本
   * @returns 检查结果 + 自动修正后的文本
   */
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
      issues.push(
        '\\left 和 \\right 数量不匹配（' +
        String(leftCount) + ' : ' + String(rightCount) + '）'
      );
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
          issues.push('自动修正: ' + target + ' → ' + replacement);
        }
      }
    }

    corrected = this.patchIntegralDx(corrected, issues);

    const hasRealError: boolean = issues.length > 0;

    return {
      hasError: hasRealError,
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
