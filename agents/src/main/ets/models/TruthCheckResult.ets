/**
 * TruthCheckResult.ets — 真值检验结果类型定义
 *
 * 对应 KnowledgeModel 步骤 4 的输出。
 * 对 OCR 文本做 5 项数学真值检验:
 *   1. 括号配对检查
 *   2. 除零检测
 *   3. 恒等式/矛盾等式检测（简化版）
 *   4. LaTeX 语法检查
 *   5. 自动修正建议
 */

export interface MvpTruthCheckResult {
  /** 是否通过全部真值检验（true = 可信任） */
  readonly truthFlag: boolean;
  /** 各检验项的详细结果列表 */
  readonly details: MvpTruthCheckItem[];
  /** 自动修正后的文本（有修正时填值，无修正为 undefined） */
  readonly correctedText?: string;
}

export interface MvpTruthCheckItem {
  /** 检验项名称: bracketPair / divisionByZero / equationCheck / latexSyntax */
  readonly checkName: string;
  /** 该项是否通过 */
  readonly passed: boolean;
  /** 问题描述（通过时为空数组） */
  readonly issues: string[];
}
