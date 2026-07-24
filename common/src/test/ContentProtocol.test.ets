/**
 * ContentProtocol.test.ets — MM-MD-v1 协议纯逻辑测试
 *
 * 路径: common/src/test/ContentProtocol.test.ets
 * 职责: 覆盖公式边界归一化、风险降级、代码隔离与环境校验
 * 依赖: Hypium, common/ContentProtocol
 *
 * 数据流:
 *   fixture -> ContentProtocol -> ContentValidationResult assertion
 *
 * ArkTS 1.1 strict 适配:
 *   - 使用显式结果类型，不使用 any/unknown
 */

import { describe, it, expect } from '@ohos/hypium';
import { ContentProtocol, LatexRiskNormalizer } from '../main/ets/Index';
import type { ContentValidationResult, LatexRiskResult } from '../main/ets/Index';

export default function contentProtocolTest(): void {
  describe('ContentProtocol.MM_MD_v1', () => {
    it('keeps_short_inline_formula_in_paragraph', 0, () => {
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown('当 $a>0$ 时开口向上。');
      expect(result.fallbackRequired).assertFalse();
      expect(result.normalizedText).assertEqual('当 $a>0$ 时开口向上。');
    });

    it('expands_display_formula_to_independent_fences', 0, () => {
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown('由 $$a^2+b^2=c^2$$ 可知结论。');
      expect(result.fallbackRequired).assertFalse();
      expect(result.normalizedText).assertContain('\n$$\n');
      expect(result.normalizedText).assertContain('a^2+b^2=c^2');
      expect(result.fixes.indexOf('split_display_from_text') >= 0).assertTrue();
    });

    it('unwraps_numbered_list_display_formula_fences', 0, () => {
      const source: string = '1. 由柯西中值定理可得\n'
        + '2. $$\n'
        + '3. \\frac{f(x)-f(a)}{g(x)-g(a)}=\\frac{f^{\\prime}(\\xi)}{g^{\\prime}(\\xi)}\n'
        + '4. $$\n'
        + '5. 即得到结论。';
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(source);
      expect(result.fallbackRequired).assertFalse();
      expect(result.normalizedText.indexOf('2. $$')).assertEqual(-1);
      expect(result.normalizedText.indexOf('4. $$')).assertEqual(-1);
      expect(result.normalizedText).assertContain('$$\n\\frac{f(x)-f(a)}{g(x)-g(a)}=\\frac{f^{\\prime}(\\xi)}{g^{\\prime}(\\xi)}\n$$');
      expect(result.fixes.indexOf('remove_list_marker_from_display_block') >= 0).assertTrue();
    });

    it('falls_back_on_unclosed_inline_formula', 0, () => {
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown('当 $a>0 时开口向上。');
      expect(result.fallbackRequired).assertTrue();
      expect(result.issues.indexOf('unclosed_inline_delimiter') >= 0).assertTrue();
    });

    it('falls_back_on_unclosed_display_formula', 0, () => {
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown('$$\n\\frac{1}{2}');
      expect(result.fallbackRequired).assertTrue();
      expect(result.issues.indexOf('unclosed_display_delimiter') >= 0).assertTrue();
    });

    it('does_not_parse_formula_inside_code_block', 0, () => {
      const source: string = '```tex\n\\frac{1}{2\n```';
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(source);
      expect(result.fallbackRequired).assertFalse();
      expect(result.normalizedText).assertEqual(source);
    });

    it('falls_back_on_unsupported_latex_command', 0, () => {
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown('$\\newcommand{\\x}{1}$');
      expect(result.fallbackRequired).assertTrue();
      expect(result.issues.length > 0).assertTrue();
    });

    it('keeps_normalized_differential_and_arrow_commands', 0, () => {
      const source: string = '$$\n\\int x\\,dx = y \\leftarrow z\n$$';
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(source);
      expect(result.fallbackRequired).assertFalse();
      expect(result.normalizedText).assertEqual(source);
    });

    it('falls_back_on_raw_html_inside_formula', 0, () => {
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown('$x<script>alert(1)</script>$');
      expect(result.fallbackRequired).assertTrue();
      expect(result.issues.indexOf('raw_html_not_supported') >= 0).assertTrue();
    });

    it('falls_back_on_mismatched_latex_environment', 0, () => {
      const source: string = '$$\n\\begin{cases}x&x>0\\end{matrix}\n$$';
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(source);
      expect(result.fallbackRequired).assertTrue();
      expect(result.issues.length > 0).assertTrue();
    });

    it('falls_back_on_json_escape_control_character', 0, () => {
      const brokenFrac: string = '$' + String.fromCharCode(12) + 'rac{1}{2}$';
      const result: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(brokenFrac);
      expect(result.fallbackRequired).assertTrue();
      expect(result.issues.indexOf('unsupported_control_character') >= 0).assertTrue();
    });

    it('keeps_real_normal_distribution_reply_renderable', 0, () => {
      const source: string = '# 正态分布\n\n'
        + '**概率密度函数**\n\n'
        + '$$\n'
        + 'f(x)=\\frac{1}{\\sigma\\sqrt{2\\pi}}'
        + '\\exp\\left(-\\frac{(x-\\mu)^2}{2\\sigma^2}\\right)\n'
        + '$$\n\n'
        + '约 68% 的数据落在 $[\\mu-\\sigma,\\mu+\\sigma]$ 内。\n\n'
        + '分布函数可写为 $\\Phi(x)=\\frac{1}{2}'
        + '\\left[1+\\operatorname{erf}\\left(\\frac{x-\\mu}{\\sigma\\sqrt{2}}\\right)\\right]$。';
      const protocolResult: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(source);
      const latexResult: LatexRiskResult = new LatexRiskNormalizer().normalize(protocolResult.normalizedText);
      expect(protocolResult.fallbackRequired).assertFalse();
      expect(latexResult.renderMode).assertEqual('katex');
      expect(latexResult.riskLevel).assertEqual('none');
      expect(latexResult.normalizedText).assertEqual(source);
    });
  });
}
