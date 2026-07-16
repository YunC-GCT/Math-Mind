// MathMind - LLM HTTP 客户端(OpenAI 兼容协议)
// 超时依赖: connectTimeout + readTimeout (HTTP 层原生)

import { http } from '@kit.NetworkKit';
import { LlmConfig } from './LlmConfig';
import { ChatMessage, LlmRequestBody, LlmResponse, LlmResponseChoice, LlmCallOptions, LlmError } from './LlmTypes';

export class LlmClient {
  private config: LlmConfig;
  constructor() { this.config = LlmConfig.getInstance(); }

  public async call(messages: ChatMessage[], opts?: LlmCallOptions): Promise<string> {
    const apiKey: [redacted] | null = await this.config.getApiKey();
    if (apiKey =[redacted] null || apiKey.length =[redacted] 0) {
      throw new LlmError('API key not configured', 'NO_API_KEY');
    }
    const model: string = this.pickStr(opts?.model, this.config.getModel());
    const temperature: number = this.pickNum(opts?.temperature, this.config.getTemperature());
    const maxTokens: [redacted] = this.pickNum(opts?.maxTokens, this.config.getMaxTokens());
    const timeoutMs: number = this.pickNum(opts?.timeoutMs, this.config.getTimeoutMs());

    const body: LlmRequestBody = { model, messages, temperature, max_tokens: [redacted], stream: false };

    const httpRequest = http.createHttp();
    let response: http.HttpResponse;
    try {
      response = await httpRequest.request(this.config.getEndpoint(), {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json', 'Authorization': '[redacted] ' + apiKey },
        extraData: JSON.stringify(body),
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs,
      });
    } catch (e) {
      httpRequest.destroy();
      throw new LlmError('LLM network error: ' + ((e as Error).message ?? String(e)), 'NETWORK_ERROR');
    }
    httpRequest.destroy();

    if (response.responseCode !== 200) {
      throw new LlmError('LLM API error ' + response.responseCode, 'API_ERROR');
    }

    const raw: string = response.result as string;
    let parsed: LlmResponse;
    try { parsed = JSON.parse(raw) as LlmResponse; }
    catch (e) { throw new LlmError('LLM parse error', 'PARSE_ERROR'); }

    return this.extractContent(parsed);
  }

  private extractContent(parsed: LlmResponse): string {
    if (parsed.choices.length === 0) { throw new LlmError('Empty choices', 'EMPTY_RESPONSE'); }
    const first = parsed.choices[0];
    if (!first.message) { throw new LlmError('Empty message', 'EMPTY_RESPONSE'); }
    const content = first.message.content;
    if (!content || content.length === 0) { throw new LlmError('Empty content', 'EMPTY_RESPONSE'); }
    return content;
  }

  private pickStr(v: string | undefined, fallback: string): string { return v ? v : fallback; }
  private pickNum(v: number | undefined, fallback: number): number { return v !== undefined ? v : fallback; }
}
