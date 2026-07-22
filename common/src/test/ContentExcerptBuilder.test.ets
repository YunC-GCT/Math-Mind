/**
 * ContentExcerptBuilder.test.ets - protocol-safe note excerpt regression tests
 *
 * Path: common/src/test/ContentExcerptBuilder.test.ets
 * Responsibility: Verify compact previews never cut formula delimiters.
 * Dependencies: Hypium, ContentExcerptBuilder, ContentProtocol
 *
 * ArkTS 1.1 strict adaptation:
 *   - Uses explicit result types and no any/unknown values.
 */

import { describe, it, expect } from '@ohos/hypium';
import { ContentExcerptBuilder, ContentProtocol } from '../main/ets/Index';
import type { ContentValidationResult } from '../main/ets/Index';

export default function contentExcerptBuilderTest(): void {
  describe('ContentExcerptBuilder.note_preview', () => {
    it('replaces_long_inline_formula_instead_of_cutting_it', 0, () => {
      const source: string = '正态分布的概率密度函数为 '
        + '$f(x)=\\frac{1}{\\sigma\\sqrt{2\\pi}}e^{-\\frac{(x-\\mu)^2}{2\\sigma^2}}$，'
        + '并且关于均值对称。';
      const preview: string = new ContentExcerptBuilder().buildListPreview(source, 46);
      const validation: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(preview);
      expect(preview).assertContain('相应公式');
      expect(preview.indexOf('\\frac') < 0).assertTrue();
      expect(validation.fallbackRequired).assertFalse();
    });

    it('keeps_complete_short_inline_formula', 0, () => {
      const source: string = '当 $a>0$ 时，抛物线开口向上。';
      const preview: string = new ContentExcerptBuilder().buildListPreview(source, 46);
      expect(preview).assertEqual(source);
      expect(new ContentProtocol().normalizeNoteMarkdown(preview).fallbackRequired).assertFalse();
    });

    it('keeps_short_display_formula_renderable', 0, () => {
      const source: string = '$$\na+b=c\n$$';
      const preview: string = new ContentExcerptBuilder().buildListPreview(source, 46);
      expect(preview).assertEqual(source);
      expect(new ContentProtocol().normalizeNoteMarkdown(preview).fallbackRequired).assertFalse();
    });

    it('collapses_oversized_display_formula', 0, () => {
      const source: string = '$$\nf(x)=\\frac{1}{\\sigma\\sqrt{2\\pi}}'
        + '\\exp\\left(-\\frac{(x-\\mu)^2}{2\\sigma^2}\\right)\n$$';
      const preview: string = new ContentExcerptBuilder().buildListPreview(source, 46);
      expect(preview).assertEqual('核心公式');
    });

    it('builds_short_plain_summary_without_broken_math', 0, () => {
      const source: string = '若随机变量的密度函数为 '
        + '$f(x)=\\frac{1}{\\sigma\\sqrt{2\\pi}}e^{-\\frac{(x-\\mu)^2}{2\\sigma^2}}$，'
        + '则称其服从正态分布。\n$$\nP(a<X<b)=\\int_a^b f(x)\\,dx\n$$';
      const summary: string = new ContentExcerptBuilder().buildPlainSummary(source, 80);
      const validation: ContentValidationResult = new ContentProtocol().normalizeNoteMarkdown(summary);
      expect(summary).assertContain('相应公式');
      expect(summary).assertContain('正态分布');
      expect(summary.indexOf('$') < 0).assertTrue();
      expect(summary.length <= 109).assertTrue();
      expect(validation.fallbackRequired).assertFalse();
    });

    it('is_idempotent_for_already_compact_preview', 0, () => {
      const builder: ContentExcerptBuilder = new ContentExcerptBuilder();
      const first: string = builder.buildListPreview('当 $a>0$ 时，抛物线开口向上。', 46);
      const second: string = builder.buildListPreview(first, 46);
      expect(second).assertEqual(first);
    });
  });
}
