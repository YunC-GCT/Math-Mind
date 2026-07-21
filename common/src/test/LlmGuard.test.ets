import { describe, it, expect } from '@ohos/hypium';
import { LlmGuard } from '../main/ets/Index';
import type { LlmCaller, LlmGuardValidationResult, ChatMessage } from '../main/ets/Index';

class FakeCaller implements LlmCaller {
  public calls: ChatMessage[][] = [];
  private replies: string[];
  private index: number = 0;

  constructor(replies: string[]) {
    this.replies = replies;
  }

  async call(messages: ChatMessage[]): Promise<string> {
    this.calls.push(messages.slice(0));
    const reply: string = this.replies[this.index] ?? this.replies[this.replies.length - 1];
    this.index += 1;
    return reply;
  }
}

export default function llmGuardTest(): void {
  describe('LlmGuard.pure_logic_test', () => {
    it('retries_after_validation_failure', 0, async () => {
      const fake: FakeCaller = new FakeCaller([
        '{"intent":"wrong"}',
        '{"intent":"chat"}',
      ]);
      const guard: LlmGuard = new LlmGuard(fake);
      const result = await guard.callJsonWithRetry(
        [{ role: 'system', content: 'test' }, { role: 'user', content: 'hello' }],
        { label: 'intent' },
        (json: Record<string, Object>): LlmGuardValidationResult => {
          const intent: Object | undefined = json['intent'];
          if (typeof intent === 'string' && (intent === 'chat' || intent === 'note_generation')) {
            return { ok: true, issues: [] };
          }
          return { ok: false, issues: ['intent must be chat or note_generation'] };
        },
      );
      expect(result.attempts).assertEqual(2);
      expect(fake.calls.length).assertEqual(2);
      expect(fake.calls[1].length > fake.calls[0].length).assertTrue();
      expect(result.json['intent']).assertEqual('chat');
    });

    it('validateJsonText_reports_missing_object', 0, () => {
      const guard: LlmGuard = new LlmGuard();
      const result = guard.validateJsonText(
        'plain text',
        (_json: Record<string, Object>): LlmGuardValidationResult => ({ ok: true, issues: [] }),
      );
      expect(result.issues.length > 0).assertTrue();
    });
  });
}
