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
      const result = normalizer.normalize('```tex\n\\int x dx\n```');
      expect(result.normalizedText).assertContain('\\int x dx');
    });
  });
}
