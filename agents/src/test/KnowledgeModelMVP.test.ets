/**
 * KnowledgeModelMVP.test.ets — agents 模块本地单元测试
 *
 * 测试范围：纯逻辑方法（不需要后端、不需要模拟器）
 * 覆盖方法：buildPrompt / truthCheck / checkBracePairing /
 *          checkDivisionByZero / checkEquation / checkLatexInternal
 *
 * 注意：
 *   callAi() 和 structure() 需要后端，不在纯逻辑测试范围内。
 *   buildPrompt 只测试 prompt 字符串的完整性。
 */

import { describe, it, expect } from '@ohos/hypium';
import { KnowledgeModelMVP } from '../main/ets/agents/KnowledgeModelMVP';
import { MvpTruthCheckResult } from '../main/ets/models/TruthCheckResult';
import { KnowledgeUnitExt } from '../main/ets/models/KnowledgeUnitExt';
import { NoteDaoInterface } from '../main/ets/models/NoteDaoInterface';

// ── Mock NoteDao ──

class MockNoteDao implements NoteDaoInterface {
  async insert(unit: KnowledgeUnitExt): Promise<number> {
    return 42;
  }
}

// ── 辅助 ──

function createModel(): KnowledgeModelMVP {
  return new KnowledgeModelMVP(new MockNoteDao());
}

// ── 测试套件 ──

export default function knowledgeModelTest(): void {
  describe('KnowledgeModelMVP.pure_logic_test', () => {

    // ─── 组 A：buildPrompt ───

    it('buildPrompt_包含5个最小类', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const prompt: string = km.buildPrompt('测试文本');
      expect(prompt).assertContain('概念');
      expect(prompt).assertContain('定理');
      expect(prompt).assertContain('公式');
      expect(prompt).assertContain('证明题');
      expect(prompt).assertContain('计算题');
    });

    it('buildPrompt_包含各类字段定义', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const prompt: string = km.buildPrompt('测试文本');
      expect(prompt).assertContain('definition');
      expect(prompt).assertContain('statement');
      expect(prompt).assertContain('expression');
      expect(prompt).assertContain('proposition');
      expect(prompt).assertContain('problem');
    });

    it('buildPrompt_包含结构化和评分要求', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const prompt: string = km.buildPrompt('测试文本');
      expect(prompt).assertContain('difficulty');
      expect(prompt).assertContain('importance');
      expect(prompt).assertContain('JSON');
    });

    // ─── 组 B：checkBracePairing ───

    it('checkBracePairing_正确括号通过', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkBracePairing('\\frac{1}{2}');
      expect(r.valid).assertTrue();
    });

    it('checkBracePairing_缺少括号自动补', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkBracePairing('\\frac{1}{2');
      expect(r.correctedText).assertEqual('\\frac{1}{2}');
    });

    it('checkBracePairing_多余括号自动移', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkBracePairing('\\frac{1}{2}} extra');
      expect(r.correctedText).assertEqual('\\frac{1}{2} extra');
    });

    // ─── 组 C：checkDivisionByZero ───

    it('checkDivisionByZero_正常文本无警告', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkDivisionByZero('a除以b等于c');
      expect(r.hasIssue).assertFalse();
    });

    it('checkDivisionByZero_检测到除以0', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkDivisionByZero('1除以0结果为无穷大');
      expect(r.hasIssue).assertTrue();
    });

    it('checkDivisionByZero_检测到分母为零', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkDivisionByZero('分母为零的情况需要讨论');
      expect(r.hasIssue).assertTrue();
    });

    // ─── 组 D：checkEquation ───

    it('checkEquation_正常等式无警告', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkEquation('a+b=c');
      expect(r.hasIssue).assertFalse();
    });

    it('checkEquation_检测到1=0矛盾', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkEquation('结论是1=0，这是错误的');
      expect(r.hasIssue).assertTrue();
    });

    it('checkEquation_检测到不等号', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r = km.checkEquation('x ≠ y');
      expect(r.hasIssue).assertTrue();
    });

    // ─── 组 E：truthCheck 集成 ───

    it('truthCheck_正常文本通过', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r: MvpTruthCheckResult = km.truthCheck('勾股定理：直角三角形两直角边的平方和等于斜边的平方。');
      expect(r.truthFlag).assertTrue();
    });

    it('truthCheck_多余括号不通过', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r: MvpTruthCheckResult = km.truthCheck('公式 {{1+2}');
      expect(r.truthFlag).assertFalse();
    });

    it('truthCheck_空文本不通过', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r: MvpTruthCheckResult = km.truthCheck('');
      expect(r.truthFlag).assertFalse();
    });

    it('truthCheck_返回4项检验细节', 0, () => {
      const km: KnowledgeModelMVP = createModel();
      const r: MvpTruthCheckResult = km.truthCheck('勾股定理。');
      expect(r.details.length).assertEqual(4);
    });
  });
}

