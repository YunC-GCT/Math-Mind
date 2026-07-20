import type { ChatMessage } from './LlmTypes';

export const JSON_ONLY_RULES: string =
  'Return one strict JSON object only. Do not wrap it in markdown fences. Do not add explanations.';

export const LATEX_GENERATION_RULES: string =
  'LaTeX formatting rules: ' +
    '1. Inline short formulas must use $...$, for example $x$ or $n \\neq -1$. ' +
    '2. Standalone complex formulas must use $$...$$ and contain the complete expression. ' +
    '3. Do not output bare LaTeX command lines such as \\int ... or \\frac ... without delimiters. ' +
    '4. Do not nest $...$ inside $$...$$. ' +
    '5. Put formula conditions inside the same math environment, for example \\quad (n \\neq -1). ' +
    '6. If a formula is incomplete or uncertain, keep the original text instead of inventing missing math.';

export function buildGuardRetryMessage(label: string, issues: string[]): ChatMessage {
  return {
    role: 'user',
    content: 'The previous ' + label + ' output failed local validation. ' +
      'Regenerate the answer as a single strict JSON object only. Fix these issues:\n- ' +
      issues.join('\n- '),
  };
}
