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

    // Step 1: Call AI (via shared LlmClient); 失败时 fallback 规则兜底
    // P0 防护: 网络超时 / API Key 过期 / 模型返回空内容 均不会导致崩溃
    // catch 块调用 ruleFallback() 用简单关键词规则生成降级结果，保证演示不中断
    let aiRaw: AiRawResponse;
    try {
      aiRaw = await this.callAi(ocrText);
    } catch (e) {
      console.warn('[KnowledgeModelMVP] AI 调用失败，使用规则兜底: ' + String(e));
      aiRaw = this.ruleFallback(ocrText);
    }

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
      throw new Error('AI 返回为空：content 为空');
    }

    // 解析 JSON：三层防护
    //   ① 剥离 markdown 代码块包裹（```json ... ```）
    //   ② 提取第一个 { 到最后一个 } 之间的内容（容错 AI 额外文字）
    //   ③ JSON.parse 失败时抛可控错误，由上层 structure() 的 catch 统一兜底
    let parsed: Record<string, Object>;
    try {
      let cleaned: string = rawContent.trim();
      // 尝试匹配 ```json ... ``` 或 ``` ... ``` 代码块
      const codeBlockMatch: RegExpMatchArray | null = cleaned.match(/```(?:json)?\s*([\s\S]*?)```/);
      if (codeBlockMatch !== null && codeBlockMatch.length >= 2) {
        cleaned = codeBlockMatch[1].trim();
      }
      // 容错：只取最外层 {} 之间的内容
      const braceStart: number = cleaned.indexOf('{');
      const braceEnd: number = cleaned.lastIndexOf('}');
      if (braceStart !== -1 && braceEnd > braceStart) {
        cleaned = cleaned.substring(braceStart, braceEnd + 1);
      }
      parsed = JSON.parse(cleaned) as Record<string, Object>;
    } catch (e) {
      // 此处不静默吞错，而是抛异常让上层 structure() 统一走 ruleFallback
      throw new Error('AI 返回内容无法解析为 JSON，已触发规则兜底');
    }

    // P0 防护: category 白名单校验
    // AI 可能返回 "例题"、"微积分" 等不在 5 类之内的值，默认降级为 "概念"
    const VALID_CATEGORIES: string[] = ['概念', '定理', '公式', '证明题', '计算题'];
    const rawCategory: string = (parsed['category'] as string) ?? '';
    const category: KnowledgeCategory = VALID_CATEGORIES.indexOf(rawCategory) !== -1
      ? rawCategory as KnowledgeCategory
      : '概念';

    const aiRaw: AiRawResponse = {
      category: category,
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
   * AI 调用失败时的规则兜底：关键词判断分类 + 简单 fallback
   *
   * 触发条件：
   *   - 网络超时 / API Key 过期 → LlmClient 抛异常
   *   - AI 返回空内容 → callAi 抛异常
   *   - AI 返回非 JSON → JSON.parse 抛异常
   *   - 以上异常被 structure() 的 catch 捕获后调用本方法
   *
   * 分类规则（优先级从高到低）：
   *   1. 含"证明"/"求证" → 证明题
   *   2. 含"计算"/"求解"/"求" → 计算题
   *   3. 含"定理" → 定理
   *   4. 含"="且不含"请" → 公式（避免"请计算"误判为公式）
   *   5. 兜底 → 概念
   *
   * @param ocrText - 输入文本
   * @returns AiRawResponse（规则生成的分类结果，difficulty/importance 默认 3）
   */
  private ruleFallback(ocrText: string): AiRawResponse {
    const trimmed: string = ocrText.trim();

    // 1. 关键词优先级链判断 category
    let category: KnowledgeCategory = '概念';
    if (trimmed.indexOf('证明') !== -1 || trimmed.indexOf('求证') !== -1) {
      category = '证明题';
    } else if (
      trimmed.indexOf('计算') !== -1 ||
      trimmed.indexOf('求解') !== -1 ||
      trimmed.indexOf('求') !== -1
    ) {
      category = '计算题';
    } else if (trimmed.indexOf('定理') !== -1) {
      category = '定理';
    } else if (
      trimmed.indexOf('=') !== -1 &&
      trimmed.indexOf('请') === -1
    ) {
      category = '公式';
    }

    // 2. title 取原文前 30 字（过长则截断加省略号）
    const title: string = trimmed.length > 30 ? trimmed.substring(0, 30) + '...' : trimmed;

    // 3. 占位结构化字段：整个原文塞进一个 raw 字段，UI 可以原样展示
    const fallbackFields: StructuredField[] = [
      { key: 'raw', label: '原文', value: trimmed },
    ];

    // 4. 返回默认评分为 3 的结果
    return {
      category: category,
      title: title,
      tags: [category, 'fallback'],
      difficulty: 3,
      importance: 3,
      fields: fallbackFields,
    };
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
   * 检查三类括号 {} () [] 是否配对，缺的自动补，多的自动删
   *
   * 设计要点：
   *   - 分别维护 curly / paren / square 三个独立深度计数器
   *   - 多余的闭合括号直接丢弃（不补对应的开括号，因为无法确定该补在哪里）
   *   - 缺失的闭合括号统一在文本末尾补全
   *   - 三类括号互不干扰（如 [{]} 视为合法，因为每类各自配对）
   *
   * @param text - 输入文本
   * @returns 检查结果 + 修正后的文本
   */
  checkBracePairing(text: string): BracePairingResult {
    const errors: string[] = [];
    // 三类括号：{} () []
    let curlyDepth: number = 0;
    let parenDepth: number = 0;
    let squareDepth: number = 0;
    let result: string = '';

    const openCurly: string = '{';
    const closeCurly: string = '}';
    const openParen: string = '(';
    const closeParen: string = ')';
    const openSquare: string = '[';
    const closeSquare: string = ']';

    for (let i: number = 0; i < text.length; i++) {
      const ch: string = text[i];
      if (ch === openCurly) {
        curlyDepth = curlyDepth + 1;
        result = result + ch;
      } else if (ch === closeCurly) {
        curlyDepth = curlyDepth - 1;
        if (curlyDepth < 0) {
          errors.push('位置 ' + String(i) + ': 多余的 }（已自动移除）');
          curlyDepth = 0;
        } else {
          result = result + ch;
        }
      } else if (ch === openParen) {
        parenDepth = parenDepth + 1;
        result = result + ch;
      } else if (ch === closeParen) {
        parenDepth = parenDepth - 1;
        if (parenDepth < 0) {
          errors.push('位置 ' + String(i) + ': 多余的 )（已自动移除）');
          parenDepth = 0;
        } else {
          result = result + ch;
        }
      } else if (ch === openSquare) {
        squareDepth = squareDepth + 1;
        result = result + ch;
      } else if (ch === closeSquare) {
        squareDepth = squareDepth - 1;
        if (squareDepth < 0) {
          errors.push('位置 ' + String(i) + ': 多余的 ]（已自动移除）');
          squareDepth = 0;
        } else {
          result = result + ch;
        }
      } else {
        result = result + ch;
      }
    }

    // 补全缺失的闭合括号
    if (curlyDepth > 0) {
      errors.push('缺少 ' + String(curlyDepth) + ' 个 }（已在末尾自动补充）');
      for (let j: number = 0; j < curlyDepth; j++) {
        result = result + closeCurly;
      }
    }
    if (parenDepth > 0) {
      errors.push('缺少 ' + String(parenDepth) + ' 个 )（已在末尾自动补充）');
      for (let j: number = 0; j < parenDepth; j++) {
        result = result + closeParen;
      }
    }
    if (squareDepth > 0) {
      errors.push('缺少 ' + String(squareDepth) + ' 个 ]（已在末尾自动补充）');
      for (let j: number = 0; j < squareDepth; j++) {
        result = result + closeSquare;
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
    // P1 优化: 用正则精准匹配分母位置的 /0，避免误报 \sqrt{0} 等安全表达式
    // fracZeroPattern  匹配 \frac{x}{0} 中花括号内的 /0
    // divZeroPattern   匹配 (x/0) 或 [x/0] 中括号内的 /0
    // 注意：LaTeX 中的 /0 如出现在 \sqrt{0}、/0.5 等位置则不会触发
    const fracZeroPattern: RegExp = /\{\s*\/\s*0\s*\}/;
    const divZeroPattern: RegExp = /[({]\s*\/\s*0\s*[)}]/;
    if (fracZeroPattern.test(text) || divZeroPattern.test(text)) {
      issues.push('检测到分母位置的 /0 表达式，可能存在除零风险');
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

  /**
   * 批量处理：按空行分割多段文本，逐段 structure（初赛限定最多 3 段）
   *
   * @param ocrText - 可能包含多段知识的文本
   * @returns KnowledgeUnitExt 数组
   */
  async structureBatch(ocrText: string): Promise<KnowledgeUnitExt[]> {
    // 阶段 1: 将文本按空行拆分为多个独立段落
    //   - 逐行扫描，空行作为段落分隔符
    //   - 连续多空行视为一个分隔符（不会产生空段落）
    //   - 每个段落内的换行保留原样
    const rawSegments: string[] = ocrText.split('\n');
    const merged: string[] = [];
    let current: string = '';
    for (let s: number = 0; s < rawSegments.length; s++) {
      const line: string = rawSegments[s].trim();
      if (line.length === 0) {
        // 遇到空行：提交当前累积的段落，重置缓冲区
        if (current.length > 0) {
          merged.push(current);
          current = '';
        }
      } else {
        // 非空行：追加到当前段落
        if (current.length > 0) {
          current = current + '\n';
        }
        current = current + line;
      }
    }
    // 提交最后一个段落（如果文本不以空行结尾）
    if (current.length > 0) {
      merged.push(current);
    }

    // 阶段 2: 逐段调用 structure() 独立处理
    const results: KnowledgeUnitExt[] = [];
    for (let i: number = 0; i < merged.length; i++) {
      const seg: string = merged[i];
      // 初赛限定最多 3 段，避免 AI 并发调用耗时过长导致演示卡顿
      if (results.length >= 3) {
        break;
      }
      const unit: KnowledgeUnitExt = await this.structure(seg);
      results.push(unit);
    }
    return results;
  }
}
