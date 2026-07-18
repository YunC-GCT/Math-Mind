/**
 * KnowledgeModel.test.ets — pure logic tests for KnowledgeModel.
 * structure() is not covered here because it needs LLM configuration.
 */

import { describe, it, expect } from '@ohos/hypium';
import { KnowledgeModel } from '../main/ets/agents/KnowledgeModel';
import { MvpTruthCheckResult } from '../main/ets/models/TruthCheckResult';

function createModel(): KnowledgeModel {
  return new KnowledgeModel();
}

export default function knowledgeModelTest(): void {
  describe('KnowledgeModel.pure_logic_test', () => {
    it('buildPrompt_contains_all_categories', 0, () => {
      const km: KnowledgeModel = createModel();
      const prompt: string = km.buildPrompt('test');
      expect(prompt).assertContain('category');
      expect(prompt).assertContain('definition');
      expect(prompt).assertContain('statement');
      expect(prompt).assertContain('expression');
      expect(prompt).assertContain('proposition');
      expect(prompt).assertContain('problem');
    });

    it('buildPrompt_contains_json_requirements', 0, () => {
      const km: KnowledgeModel = createModel();
      const prompt: string = km.buildPrompt('test');
      expect(prompt).assertContain('difficulty');
      expect(prompt).assertContain('importance');
      expect(prompt).assertContain('JSON');
    });

    it('checkBracePairing_valid_latex_passes', 0, () => {
      const km: KnowledgeModel = createModel();
      const r = km.checkBracePairing('\\frac{1}{2}');
      expect(r.valid).assertTrue();
    });

    it('checkBracePairing_missing_brace_is_patched', 0, () => {
      const km: KnowledgeModel = createModel();
      const r = km.checkBracePairing('\\frac{1}{2');
      expect(r.correctedText).assertEqual('\\frac{1}{2}');
    });

    it('checkBracePairing_extra_brace_is_removed', 0, () => {
      const km: KnowledgeModel = createModel();
      const r = km.checkBracePairing('\\frac{1}{2}} extra');
      expect(r.correctedText).assertEqual('\\frac{1}{2} extra');
    });

    it('checkDivisionByZero_normal_text_passes', 0, () => {
      const km: KnowledgeModel = createModel();
      const r = km.checkDivisionByZero('a/b=c');
      expect(r.hasIssue).assertFalse();
    });

    it('checkDivisionByZero_detects_slash_zero', 0, () => {
      const km: KnowledgeModel = createModel();
      const r = km.checkDivisionByZero('1/0');
      expect(r.hasIssue).assertTrue();
    });

    it('checkEquation_normal_equation_passes', 0, () => {
      const km: KnowledgeModel = createModel();
      const r = km.checkEquation('a+b=c');
      expect(r.hasIssue).assertFalse();
    });

    it('checkEquation_detects_contradiction', 0, () => {
      const km: KnowledgeModel = createModel();
      const r = km.checkEquation('1=0');
      expect(r.hasIssue).assertTrue();
    });

    it('truthCheck_empty_text_fails', 0, () => {
      const km: KnowledgeModel = createModel();
      const r: MvpTruthCheckResult = km.truthCheck('');
      expect(r.truthFlag).assertFalse();
    });

    it('truthCheck_returns_four_details', 0, () => {
      const km: KnowledgeModel = createModel();
      const r: MvpTruthCheckResult = km.truthCheck('a+b=c');
      expect(r.details.length).assertEqual(4);
    });
  });
}