import { describe, it, expect } from '@ohos/hypium';
import { LatexRiskNormalizer } from '../main/ets/Index';

export default function latexRiskNormalizerTest(): void {
  describe('LatexRiskNormalizer.pure_logic_test', () => {
    it('wraps_bare_display_formula', 0, () => {
      const normalizer: LatexRiskNormalizer = new LatexRiskNormalizer();
      const result = normalizer.normalize('\\int x^n, dx = \\frac{x^{n+1}}{n+1} + C \\quad ($n \\neq -1$)');
      expect(result.riskLevel).assertEqual('fixable');
      expect(result.normalizedText).assertContain('$$');
      expect(result.normalizedText).assertContain('\\,dx');
      expect(result.normalizedText).assertContain('n \\neq -1');
    });

    it('falls_back_on_unclosed_brace', 0, () => {
      const normalizer: LatexRiskNormalizer = new LatexRiskNormalizer();
      const result = normalizer.normalize('$$\\frac{x+1$$');
      expect(result.riskLevel).assertEqual('fallback');
      expect(result.renderMode).assertEqual('plainFallback');
    });

    it('keeps_code_block_intact', 0, () => {
      const normalizer: LatexRiskNormalizer = new LatexRiskNormalizer();
      const source: string = '```tex\n\\frac{1}{2\n```';
      const result = normalizer.normalize(source);
      expect(result.normalizedText).assertEqual(source);
      expect(result.renderMode).assertEqual('native');
    });

    it('does_not_nest_display_fences', 0, () => {
      const normalizer: LatexRiskNormalizer = new LatexRiskNormalizer();
      const source: string = '$$\n\\int x\\,dx = \\frac{1}{2}\n$$';
      const result = normalizer.normalize(source);
      expect(result.normalizedText).assertEqual(source);
      expect(result.riskLevel).assertEqual('none');
    });

    it('does_not_wrap_symbols_inside_inline_math', 0, () => {
      const normalizer: LatexRiskNormalizer = new LatexRiskNormalizer();
      const source: string = '约 68% 在 $[\\mu-\\sigma,\\mu+\\sigma]$ 内';
      const result = normalizer.normalize(source);
      expect(result.normalizedText).assertEqual(source);
      expect(result.renderMode).assertEqual('katex');
      expect(result.riskLevel).assertEqual('none');
    });

    it('wraps_legacy_bare_symbol_outside_math', 0, () => {
      const normalizer: LatexRiskNormalizer = new LatexRiskNormalizer();
      const result = normalizer.normalize('均值是 \\mu');
      expect(result.normalizedText).assertContain('$\\mu$');
      expect(result.riskLevel).assertEqual('fixable');
    });
  });
}
