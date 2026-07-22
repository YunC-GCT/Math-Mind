/**
 * ContentProtocol.ets — MM-MD-v1 内容协议归一化与校验
 *
 * 路径: common/src/main/ets/render/ContentProtocol.ets
 * 职责: 统一 AI、Markdown、LaTeX 与 ArkUI 之间的公式边界和失败兜底判定
 * 依赖: 无
 *
 * 数据流:
 *   AI/OCR/数据库正文 -> ContentProtocol -> MarkdownParser/MathTextRenderer
 *
 * ArkTS 1.1 strict 适配:
 *   - 全部对象使用显式类型
 *   - 遍历使用 for...of / while
 */

export type ContentProtocolRisk = 'none' | 'fixable' | 'fallback';

export interface ContentValidationResult {
  ok: boolean;
  normalizedText: string;
  issues: string[];
  fixes: string[];
  riskLevel: ContentProtocolRisk;
  fallbackRequired: boolean;
}

interface ProtocolValidationState {
  issues: string[];
  fallbackRequired: boolean;
}

export class ContentProtocol {
  normalizeNoteMarkdown(rawText: string): ContentValidationResult {
    const issues: string[] = [];
    const fixes: string[] = [];
    const lineNormalized: string = rawText.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    const rawHasControlCharacter: boolean = this.hasUnsupportedControlCharacter(lineNormalized);
    if (rawHasControlCharacter) {
      issues.push('unsupported_control_character');
    }
    if (lineNormalized !== rawText) {
      issues.push('non_lf_line_ending');
      fixes.push('normalize_line_ending');
    }
    const normalizedText: string = this.canonicalizeBoundaries(lineNormalized, issues, fixes).trim();
    const validation: ProtocolValidationState = this.validateCanonicalText(normalizedText);
    for (const issue of validation.issues) {
      issues.push(issue);
    }
    const uniqueIssues: string[] = this.unique(issues);
    const uniqueFixes: string[] = this.unique(fixes);
    const fallbackRequired: boolean = rawHasControlCharacter || validation.fallbackRequired;
    const riskLevel: ContentProtocolRisk = fallbackRequired
      ? 'fallback'
      : (uniqueFixes.length > 0 ? 'fixable' : 'none');
    return {
      ok: uniqueIssues.length === 0,
      normalizedText: normalizedText,
      issues: uniqueIssues,
      fixes: uniqueFixes,
      riskLevel: riskLevel,
      fallbackRequired: fallbackRequired,
    };
  }

  normalizeDisplayFormula(rawText: string): ContentValidationResult {
    const normalized: string = rawText.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim();
    if (normalized.length === 0) {
      return this.resultForEmptyDisplay();
    }
    if (this.hasDisplayDelimiter(normalized)) {
      return this.normalizeNoteMarkdown(normalized);
    }
    return this.normalizeNoteMarkdown('$$\n' + normalized + '\n$$');
  }

  validateNoteMarkdown(rawText: string): ContentValidationResult {
    return this.normalizeNoteMarkdown(rawText);
  }

  hasFormulaSyntax(text: string): boolean {
    return this.hasUnescapedDollar(text)
      || text.indexOf('\\(') >= 0
      || text.indexOf('\\[') >= 0
      || this.containsMathCommand(text);
  }

  private canonicalizeBoundaries(rawText: string, issues: string[], fixes: string[]): string {
    const output: string[] = [];
    const lines: string[] = rawText.split('\n');
    let inCode: boolean = false;
    let inDisplay: boolean = false;
    for (const rawLine of lines) {
      const trimmed: string = rawLine.trim();
      if (trimmed.indexOf('```') === 0) {
        inCode = !inCode;
        output.push(rawLine);
        continue;
      }
      if (inCode) {
        output.push(rawLine);
        continue;
      }
      if (inDisplay) {
        if (trimmed === '$$' || trimmed === '\\]') {
          output.push('$$');
          if (trimmed === '\\]') {
            issues.push('compat_display_delimiter');
            fixes.push('normalize_display_delimiter');
          }
          inDisplay = false;
        } else {
          output.push(this.normalizeFormulaBody(rawLine, issues, fixes));
        }
        continue;
      }
      if (trimmed === '$$' || trimmed === '\\[') {
        output.push('$$');
        if (trimmed === '\\[') {
          issues.push('compat_display_delimiter');
          fixes.push('normalize_display_delimiter');
        }
        inDisplay = true;
        continue;
      }
      if (this.appendStandaloneDisplay(output, rawLine, issues, fixes)) {
        continue;
      }
      const inlineNormalized: string = this.normalizeInlineParentheses(rawLine, issues, fixes);
      if (this.appendEmbeddedDisplay(output, inlineNormalized, issues, fixes)) {
        continue;
      }
      if (this.looksLikeBareDisplayFormula(inlineNormalized.trim())) {
        issues.push('bare_display_formula');
        fixes.push('wrap_display_delimiter');
        output.push('$$');
        output.push(this.normalizeFormulaBody(inlineNormalized.trim(), issues, fixes));
        output.push('$$');
        continue;
      }
      output.push(this.normalizeInlineFormulaBodies(inlineNormalized, issues, fixes));
    }
    return output.join('\n');
  }

  private appendStandaloneDisplay(
    output: string[],
    line: string,
    issues: string[],
    fixes: string[],
  ): boolean {
    const trimmed: string = line.trim();
    if (trimmed.startsWith('$$') && trimmed.endsWith('$$') && trimmed.length > 4) {
      output.push('$$');
      output.push(this.normalizeFormulaBody(trimmed.substring(2, trimmed.length - 2), issues, fixes));
      output.push('$$');
      issues.push('inline_display_fence');
      fixes.push('expand_display_fence');
      return true;
    }
    if (trimmed.startsWith('\\[') && trimmed.endsWith('\\]') && trimmed.length > 4) {
      output.push('$$');
      output.push(this.normalizeFormulaBody(trimmed.substring(2, trimmed.length - 2), issues, fixes));
      output.push('$$');
      issues.push('compat_display_delimiter');
      fixes.push('normalize_display_delimiter');
      return true;
    }
    return false;
  }

  private appendEmbeddedDisplay(
    output: string[],
    line: string,
    issues: string[],
    fixes: string[],
  ): boolean {
    const openIndex: number = line.indexOf('$$');
    if (openIndex < 0) {
      return false;
    }
    const closeIndex: number = line.indexOf('$$', openIndex + 2);
    if (closeIndex < 0) {
      return false;
    }
    const prefix: string = line.substring(0, openIndex).trim();
    const formula: string = line.substring(openIndex + 2, closeIndex).trim();
    const suffix: string = line.substring(closeIndex + 2).trim();
    if (prefix.length > 0) {
      output.push(prefix);
      output.push('');
    }
    output.push('$$');
    output.push(this.normalizeFormulaBody(formula, issues, fixes));
    output.push('$$');
    if (suffix.length > 0) {
      output.push('');
      output.push(suffix);
    }
    issues.push('display_formula_inside_text');
    fixes.push('split_display_from_text');
    return true;
  }

  private normalizeInlineParentheses(line: string, issues: string[], fixes: string[]): string {
    let result: string = line;
    let openIndex: number = result.indexOf('\\(');
    while (openIndex >= 0) {
      const closeIndex: number = result.indexOf('\\)', openIndex + 2);
      if (closeIndex < 0) {
        break;
      }
      result = result.substring(0, openIndex) + '$'
        + result.substring(openIndex + 2, closeIndex) + '$'
        + result.substring(closeIndex + 2);
      issues.push('compat_inline_delimiter');
      fixes.push('normalize_inline_delimiter');
      openIndex = result.indexOf('\\(', openIndex + 1);
    }
    return result;
  }

  private normalizeInlineFormulaBodies(line: string, issues: string[], fixes: string[]): string {
    let output: string = '';
    let cursor: number = 0;
    let openIndex: number = this.nextUnescapedDollar(line, cursor);
    while (openIndex >= 0) {
      const closeIndex: number = this.nextUnescapedDollar(line, openIndex + 1);
      if (closeIndex < 0) {
        break;
      }
      output += line.substring(cursor, openIndex + 1);
      output += this.normalizeFormulaBody(line.substring(openIndex + 1, closeIndex), issues, fixes);
      output += '$';
      cursor = closeIndex + 1;
      openIndex = this.nextUnescapedDollar(line, cursor);
    }
    return output.length > 0 ? output + line.substring(cursor) : line;
  }

  private normalizeFormulaBody(rawBody: string, issues: string[], fixes: string[]): string {
    let result: string = rawBody.trim();
    if (result.indexOf('$') >= 0) {
      result = result.split('$').join('');
      issues.push('nested_dollar_in_display');
      fixes.push('remove_nested_dollar');
    }
    result = this.replaceKnownTypo(result, '\\fract{', '\\frac{', issues, fixes);
    result = this.replaceKnownTypo(result, '\\sqt{', '\\sqrt{', issues, fixes);
    result = this.replaceKnownTypo(result, '\\begin{align*}', '\\begin{aligned}', issues, fixes);
    result = this.replaceKnownTypo(result, '\\end{align*}', '\\end{aligned}', issues, fixes);
    result = this.replaceKnownTypo(result, '\\begin{align}', '\\begin{aligned}', issues, fixes);
    result = this.replaceKnownTypo(result, '\\end{align}', '\\end{aligned}', issues, fixes);
    const beforeDifferential: string = result;
    result = result.replace(/(^|[^\\]),\s*d([a-zA-Z])/g, '$1\\,d$2');
    if (result !== beforeDifferential) {
      issues.push('loose_differential');
      fixes.push('normalize_differential');
    }
    return result;
  }

  private replaceKnownTypo(
    text: string,
    target: string,
    replacement: string,
    issues: string[],
    fixes: string[],
  ): string {
    if (text.indexOf(target) < 0) {
      return text;
    }
    issues.push('known_latex_typo');
    fixes.push('replace_' + target.substring(1));
    return text.split(target).join(replacement);
  }

  private validateCanonicalText(text: string): ProtocolValidationState {
    const issues: string[] = [];
    const lines: string[] = text.split('\n');
    const formulaLines: string[] = [];
    let inCode: boolean = false;
    let inDisplay: boolean = false;
    let fallbackRequired: boolean = false;
    if (this.hasUnsupportedControlCharacter(text)) {
      issues.push('unsupported_control_character');
      fallbackRequired = true;
    }
    for (const rawLine of lines) {
      const trimmed: string = rawLine.trim();
      if (trimmed.indexOf('```') === 0) {
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        continue;
      }
      if (trimmed === '$$') {
        if (inDisplay) {
          if (formulaLines.join('\n').trim().length === 0) {
            issues.push('empty_display_formula');
            fallbackRequired = true;
          } else if (this.validateFormulaBody(formulaLines.join('\n'), issues)) {
            fallbackRequired = true;
          }
          formulaLines.splice(0, formulaLines.length);
        }
        inDisplay = !inDisplay;
        continue;
      }
      if (inDisplay) {
        formulaLines.push(rawLine);
        continue;
      }
      if (rawLine.indexOf('$$') >= 0 || rawLine.indexOf('\\[') >= 0 || rawLine.indexOf('\\]') >= 0) {
        issues.push('display_delimiter_not_independent');
        fallbackRequired = true;
      }
      if (trimmed.indexOf('#') === 0 && this.hasFormulaSyntax(trimmed)) {
        issues.push('formula_in_heading');
      }
      if (this.looksLikeRawHtml(trimmed)) {
        issues.push('raw_html_not_supported');
        fallbackRequired = true;
      }
      if (this.looksLikeTableDelimiter(trimmed)) {
        issues.push('markdown_table_not_supported');
      }
      if (this.validateInlineFormulas(rawLine, issues)) {
        fallbackRequired = true;
      }
    }
    if (inCode) {
      issues.push('unclosed_code_fence');
    }
    if (inDisplay) {
      issues.push('unclosed_display_delimiter');
      fallbackRequired = true;
    }
    return {
      issues: this.unique(issues),
      fallbackRequired: fallbackRequired,
    };
  }

  private validateInlineFormulas(line: string, issues: string[]): boolean {
    let fallbackRequired: boolean = false;
    let cursor: number = 0;
    let openIndex: number = this.nextUnescapedDollar(line, cursor);
    while (openIndex >= 0) {
      const closeIndex: number = this.nextUnescapedDollar(line, openIndex + 1);
      if (closeIndex < 0) {
        issues.push('unclosed_inline_delimiter');
        return true;
      }
      const body: string = line.substring(openIndex + 1, closeIndex);
      if (body.trim().length === 0) {
        issues.push('empty_inline_formula');
        fallbackRequired = true;
      } else if (this.validateFormulaBody(body, issues)) {
        fallbackRequired = true;
      }
      cursor = closeIndex + 1;
      openIndex = this.nextUnescapedDollar(line, cursor);
    }
    if (line.indexOf('\\(') >= 0 || line.indexOf('\\)') >= 0) {
      issues.push('unclosed_compat_inline_delimiter');
      fallbackRequired = true;
    }
    return fallbackRequired;
  }

  private validateFormulaBody(body: string, issues: string[]): boolean {
    let fallbackRequired: boolean = false;
    if (this.looksLikeRawHtml(body)) {
      issues.push('raw_html_not_supported');
      fallbackRequired = true;
    }
    let braceDepth: number = 0;
    let index: number = 0;
    while (index < body.length) {
      const char: string = body.charAt(index);
      if (char === '{' && !this.isEscapedAt(body, index)) {
        braceDepth += 1;
      } else if (char === '}' && !this.isEscapedAt(body, index)) {
        braceDepth -= 1;
        if (braceDepth < 0) {
          issues.push('unbalanced_formula_brace');
          fallbackRequired = true;
          braceDepth = 0;
        }
      }
      index += 1;
    }
    if (braceDepth !== 0) {
      issues.push('unbalanced_formula_brace');
      fallbackRequired = true;
    }
    const leftCount: number = this.countLatexCommand(body, '\\left');
    const rightCount: number = this.countLatexCommand(body, '\\right');
    if (leftCount !== rightCount) {
      issues.push('unbalanced_left_right');
      fallbackRequired = true;
    }
    if (this.validateLatexEnvironments(body, issues)) {
      fallbackRequired = true;
    }
    const unsupported: string[] = [
      '\\newcommand', '\\renewcommand', '\\def', '\\gdef', '\\require',
      '\\includegraphics', '\\htmlClass', '\\htmlId', '\\htmlStyle', '\\href',
    ];
    for (const command of unsupported) {
      if (body.indexOf(command) >= 0) {
        issues.push('unsupported_latex_command:' + command);
        fallbackRequired = true;
      }
    }
    return fallbackRequired;
  }

  private looksLikeBareDisplayFormula(text: string): boolean {
    if (text.length === 0 || text.indexOf('$') >= 0) {
      return false;
    }
    const startsWithCommand: boolean = text.indexOf('\\int') === 0
      || text.indexOf('\\sum') === 0
      || text.indexOf('\\lim') === 0
      || text.indexOf('\\prod') === 0
      || text.indexOf('\\frac') === 0
      || text.indexOf('\\sqrt') === 0
      || text.indexOf('\\begin') === 0;
    if (startsWithCommand) {
      return true;
    }
    return text.indexOf('=') >= 0 && this.containsMathCommand(text);
  }

  private containsMathCommand(text: string): boolean {
    const commands: string[] = [
      '\\frac', '\\sqrt', '\\sum', '\\int', '\\lim', '\\prod', '\\begin',
      '\\alpha', '\\beta', '\\theta', '\\lambda', '\\mu', '\\sigma', '\\pi',
    ];
    for (const command of commands) {
      if (text.indexOf(command) >= 0) {
        return true;
      }
    }
    return false;
  }

  private hasDisplayDelimiter(text: string): boolean {
    return text.indexOf('$$') >= 0 || text.indexOf('\\[') >= 0 || text.indexOf('\\]') >= 0;
  }

  private hasUnescapedDollar(text: string): boolean {
    return this.nextUnescapedDollar(text, 0) >= 0;
  }

  private nextUnescapedDollar(text: string, start: number): number {
    let index: number = text.indexOf('$', start);
    while (index >= 0) {
      if (!this.isEscapedAt(text, index)) {
        return index;
      }
      index = text.indexOf('$', index + 1);
    }
    return -1;
  }

  private isEscapedAt(text: string, index: number): boolean {
    let slashCount: number = 0;
    let slashIndex: number = index - 1;
    while (slashIndex >= 0 && text.charAt(slashIndex) === '\\') {
      slashCount += 1;
      slashIndex -= 1;
    }
    return slashCount % 2 !== 0;
  }

  private countLatexCommand(text: string, command: string): number {
    let count: number = 0;
    let position: number = text.indexOf(command);
    while (position >= 0) {
      const nextIndex: number = position + command.length;
      const nextChar: string = nextIndex < text.length ? text.charAt(nextIndex) : '';
      const isLetter: boolean = nextChar >= 'a' && nextChar <= 'z'
        || nextChar >= 'A' && nextChar <= 'Z';
      if (!isLetter) {
        count += 1;
      }
      position = text.indexOf(command, nextIndex);
    }
    return count;
  }

  private validateLatexEnvironments(body: string, issues: string[]): boolean {
    const stack: string[] = [];
    const supported: string[] = [
      'aligned', 'alignedat', 'array', 'matrix', 'pmatrix', 'bmatrix',
      'Bmatrix', 'vmatrix', 'Vmatrix', 'cases', 'gathered',
    ];
    let invalid: boolean = false;
    let cursor: number = 0;
    while (cursor < body.length) {
      const beginIndex: number = body.indexOf('\\begin{', cursor);
      const endIndex: number = body.indexOf('\\end{', cursor);
      if (beginIndex < 0 && endIndex < 0) {
        break;
      }
      const isBegin: boolean = beginIndex >= 0 && (endIndex < 0 || beginIndex < endIndex);
      const markerIndex: number = isBegin ? beginIndex : endIndex;
      const nameStart: number = markerIndex + (isBegin ? 7 : 5);
      const nameEnd: number = body.indexOf('}', nameStart);
      if (nameEnd < 0) {
        issues.push('unbalanced_latex_environment');
        return true;
      }
      const environment: string = body.substring(nameStart, nameEnd);
      if (isBegin) {
        stack.push(environment);
        if (supported.indexOf(environment) < 0) {
          issues.push('unsupported_latex_environment:' + environment);
          invalid = true;
        }
      } else if (stack.length === 0) {
        issues.push('unbalanced_latex_environment');
        invalid = true;
      } else {
        const expected: string = stack.pop() ?? '';
        if (expected !== environment) {
          issues.push('mismatched_latex_environment:' + expected + ':' + environment);
          invalid = true;
        }
      }
      cursor = nameEnd + 1;
    }
    if (stack.length > 0) {
      issues.push('unbalanced_latex_environment');
      invalid = true;
    }
    return invalid;
  }

  private looksLikeRawHtml(text: string): boolean {
    return text.indexOf('<!--') >= 0 || /<\/?[a-zA-Z][^>]*>/.test(text);
  }

  private looksLikeTableDelimiter(text: string): boolean {
    return text.indexOf('|') >= 0 && text.indexOf('---') >= 0;
  }

  private hasUnsupportedControlCharacter(text: string): boolean {
    let index: number = 0;
    while (index < text.length) {
      const code: number = text.charCodeAt(index);
      if (code < 32 && code !== 10) {
        return true;
      }
      index += 1;
    }
    return false;
  }

  private resultForEmptyDisplay(): ContentValidationResult {
    return {
      ok: false,
      normalizedText: '',
      issues: ['empty_display_formula'],
      fixes: [],
      riskLevel: 'fallback',
      fallbackRequired: true,
    };
  }

  private unique(values: string[]): string[] {
    const result: string[] = [];
    for (const value of values) {
      if (result.indexOf(value) < 0) {
        result.push(value);
      }
    }
    return result;
  }
}
