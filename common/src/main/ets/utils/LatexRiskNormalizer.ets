export type LatexRiskLevel = 'none' | 'fixable' | 'fallback';
export type LatexRenderMode = 'native' | 'katex' | 'plainFallback';
export type LatexSegmentKind = 'text' | 'inlineMath' | 'displayMath' | 'fallbackText';

export interface RenderSegment {
  kind: LatexSegmentKind;
  source: string;
  normalized: string;
  safeToRender: boolean;
}

export interface LatexRiskResult {
  rawText: string;
  normalizedText: string;
  riskLevel: LatexRiskLevel;
  issues: string[];
  fixes: string[];
  renderMode: LatexRenderMode;
  segments: RenderSegment[];
}

export class LatexRiskNormalizer {
  normalize(rawText: string): LatexRiskResult {
    const raw: string = rawText;
    const issues: string[] = [];
    const fixes: string[] = [];
    const normalizedLines: string[] = [];
    const lines: string[] = raw.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
    let inCode: boolean = false;

    for (const line of lines) {
      const trimmed: string = line.trim();
      if (trimmed.indexOf('```') === 0) {
        inCode = !inCode;
        normalizedLines.push(line);
        continue;
      }
      if (inCode) {
        normalizedLines.push(line);
        continue;
      }
      normalizedLines.push(this.normalizeLine(line, issues, fixes));
    }

    const normalized: string = normalizedLines.join('\n').trim();
    this.detectFallbackRisk(normalized, issues);
    const hasFormula: boolean = this.hasFormulaSignal(normalized);
    const fallback: boolean = this.hasIssue(issues, 'unclosed_brace')
      || this.hasIssue(issues, 'unclosed_display_delimiter')
      || this.hasIssue(issues, 'unknown_command');
    const riskLevel: LatexRiskLevel = fallback ? 'fallback' : (fixes.length > 0 ? 'fixable' : 'none');
    const renderMode: LatexRenderMode = fallback ? 'plainFallback' : (hasFormula ? 'katex' : 'native');
    return {
      rawText: raw,
      normalizedText: normalized,
      riskLevel: riskLevel,
      issues: this.unique(issues),
      fixes: this.unique(fixes),
      renderMode: renderMode,
      segments: this.buildSegments(raw, normalized, renderMode),
    };
  }

  private normalizeLine(line: string, issues: string[], fixes: string[]): string {
    let result: string = line;
    const trimmed: string = line.trim();
    if (trimmed.length === 0) {
      return line;
    }
    if (this.isDisplayWrapped(trimmed)) {
      const inner: string = trimmed.substring(2, trimmed.length - 2).trim();
      const cleaned: string = this.removeNestedDollars(inner, issues, fixes);
      const dxFixed: string = this.normalizeDifferentialDx(cleaned, issues, fixes);
      return '$$' + dxFixed + '$$';
    }
    if (this.looksLikeBareDisplayFormula(trimmed)) {
      issues.push('bare_display_formula');
      fixes.push('wrap_display_delimiter');
      const cleaned: string = this.normalizeDifferentialDx(
        this.removeNestedDollars(trimmed, issues, fixes),
        issues,
        fixes,
      );
      return '$$' + cleaned + '$$';
    }
    result = this.wrapBareShortSymbols(result, issues, fixes);
    return result;
  }

  private isDisplayWrapped(text: string): boolean {
    return text.indexOf('$$') === 0 && text.lastIndexOf('$$') === text.length - 2 && text.length > 4;
  }

  private looksLikeBareDisplayFormula(text: string): boolean {
    if (text.indexOf('$$') >= 0 || text.indexOf('$') === 0) {
      return false;
    }
    const startsWithCommand: boolean = text.indexOf('\\int') === 0
      || text.indexOf('\\sum') === 0
      || text.indexOf('\\lim') === 0
      || text.indexOf('\\frac') === 0
      || text.indexOf('\\sqrt') === 0
      || text.indexOf('\\begin') === 0;
    if (startsWithCommand) {
      return true;
    }
    return text.indexOf('=') >= 0 && (
      text.indexOf('\\frac') >= 0 ||
      text.indexOf('\\sqrt') >= 0 ||
      text.indexOf('\\int') >= 0 ||
      text.indexOf('\\sum') >= 0 ||
      text.indexOf('\\lim') >= 0 ||
      text.indexOf('\\begin') >= 0
    );
  }

  private removeNestedDollars(text: string, issues: string[], fixes: string[]): string {
    if (text.indexOf('$') < 0) {
      return text;
    }
    issues.push('nested_dollar_in_display');
    fixes.push('remove_nested_dollar');
    return text.split('$').join('');
  }

  private normalizeDifferentialDx(text: string, issues: string[], fixes: string[]): string {
    let result: string = text;
    const beforeComma: string = result;
    result = result.replace(/,\s*d([a-zA-Z])/g, '\\,d$1');
    if (result !== beforeComma) {
      issues.push('loose_differential');
      fixes.push('normalize_differential_dx');
    }
    const beforeSpace: string = result;
    result = result.replace(/([^\\,])\s+d([xyztruv])(\s|$)/g, '$1\\,d$2$3');
    if (result !== beforeSpace) {
      issues.push('loose_differential');
      fixes.push('normalize_differential_dx');
    }
    return result;
  }

  private wrapBareShortSymbols(text: string, issues: string[], fixes: string[]): string {
    const commands: string[] = ['\\mu', '\\sigma', '\\theta', '\\alpha', '\\beta'];
    let result: string = text;
    for (const command of commands) {
      if (result.indexOf(command) >= 0 && result.indexOf('$' + command + '$') < 0) {
        result = result.split(command).join('$' + command + '$');
        issues.push('bare_inline_symbol');
        fixes.push('wrap_inline_symbol');
      }
    }
    return result;
  }

  private detectFallbackRisk(text: string, issues: string[]): void {
    const displayCount: number = this.countOccurrences(text, '$$');
    if (displayCount % 2 !== 0) {
      issues.push('unclosed_display_delimiter');
    }
    let braceDepth: number = 0;
    let idx: number = 0;
    while (idx < text.length) {
      const ch: string = text[idx];
      if (ch === '{') {
        braceDepth += 1;
      } else if (ch === '}') {
        braceDepth -= 1;
        if (braceDepth < 0) {
          issues.push('unclosed_brace');
          braceDepth = 0;
        }
      }
      idx += 1;
    }
    if (braceDepth !== 0) {
      issues.push('unclosed_brace');
    }
    if (text.indexOf('\\unknown') >= 0) {
      issues.push('unknown_command');
    }
  }

  private hasFormulaSignal(text: string): boolean {
    return text.indexOf('$') >= 0
      || text.indexOf('\\frac') >= 0
      || text.indexOf('\\sqrt') >= 0
      || text.indexOf('\\int') >= 0
      || text.indexOf('\\sum') >= 0
      || text.indexOf('\\lim') >= 0
      || text.indexOf('\\begin') >= 0;
  }

  private buildSegments(raw: string, normalized: string, renderMode: LatexRenderMode): RenderSegment[] {
    const safe: boolean = renderMode !== 'plainFallback';
    const kind: LatexSegmentKind = renderMode === 'katex'
      ? 'displayMath'
      : (renderMode === 'plainFallback' ? 'fallbackText' : 'text');
    return [{
      kind: kind,
      source: raw,
      normalized: normalized,
      safeToRender: safe,
    }];
  }

  private countOccurrences(text: string, needle: string): number {
    let count: number = 0;
    let pos: number = text.indexOf(needle);
    while (pos >= 0) {
      count += 1;
      pos = text.indexOf(needle, pos + needle.length);
    }
    return count;
  }

  private hasIssue(issues: string[], issue: string): boolean {
    return issues.indexOf(issue) >= 0;
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
