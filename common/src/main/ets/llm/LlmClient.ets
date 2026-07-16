// MathMind - LLM HTTP 客户端(OpenAI 兼容协议)
// 位置: common/src/main/ets/llm/LlmClient.ets
// 责任: Z (Mavis)
// 创建: 2026-07-14 — 主 Agent 业务 LLM 调用基础设施
//
// 用法:
//   const client = new LlmClient();
//   const text: string = await client.call([
//     { role: 'system', content: '...' },
//     { role: 'user', content: '...' },
//   ]);
//
// 设计:
//   - 端点 / model / temperature / max_tokens / timeout 全部从 LlmConfig 单例读
//   - 单次调用可用 opts 覆盖默认
//   - 错误统一抛 LlmError(kind: NO_API_KEY / NETWORK_ERROR / API_ERROR / PARSE_ERROR / EMPTY_RESPONSE)
//   - 双重超时: connectTimeout/readTimeout + Promise.race 兜底

import { http } from '@kit.NetworkKit';
import { LlmConfig } from './LlmConfig';
import {
  ChatMessage, LlmRequestBody, LlmResponse, LlmResponseChoice, LlmCallOptions, LlmError,
} from './LlmTypes';

export class LlmClient {
  private config: LlmConfig;

  constructor() { this.config = LlmConfig.getInstance(); }

  // 主入口:发 chat completion 请求,返回首条 message.content 字符串
  public async call(messages: ChatMessage[], opts?: LlmCallOptions): Promise<string> {
    // 1. 校验 API key
    const apiKey: string | null = await this.config.getApiKey();
    if (apiKey === null || apiKey.length === 0) {
      throw new LlmError('API key not configured. Set it in Settings first.', 'NO_API_KEY');
    }

    // 2. 构造请求体(opts 优先,默认从 LlmConfig)
    const model: string = this.pickStr(opts?.model, this.config.getModel());
    const temperature: number = this.pickNum(opts?.temperature, this.config.getTemperature());
    const maxTokens: number = this.pickNum(opts?.maxTokens, this.config.getMaxTokens());
    const timeoutMs: number = this.pickNum(opts?.timeoutMs, this.config.getTimeoutMs());

    const body: LlmRequestBody = {
      model: model,
      messages: messages,
      temperature: temperature,
      max_tokens: maxTokens,
      stream: false,
    };

    // 3. 发 HTTP POST（双重超时: connectTimeout/readTimeout + Promise.race 兜底）
    const httpRequest = http.createHttp();
    let response: http.HttpResponse;
    try {
      const httpCall = httpRequest.request(this.config.getEndpoint(), {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + apiKey,
        },
        extraData: JSON.stringify(body),
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs,
      });
      // Promise.race 兜底: 即使底层超时不生效, JS 层面也能超时
      const timeoutPromise = new Promise<http.HttpResponse>((_resolve, reject) => {
        setTimeout((): void => { reject(new Error('LLM timeout after ' + timeoutMs + 'ms')) }, timeoutMs + 3000)
      });
      response = await Promise.race([httpCall, timeoutPromise]) as http.HttpResponse;
    } catch (e) {
      httpRequest.destroy();
      throw new LlmError('LLM network error: ' + ((e as Error).message ?? String(e)), 'NETWORK_ERROR');
    }
    httpRequest.destroy();

    // 4. 状态码校验
    if (response.responseCode !== 200) {
      const errBody: string = (response.result as string) ?? '';
      throw new LlmError('LLM API error ' + response.responseCode + ': ' + errBody, 'API_ERROR');
    }

    // 5. 解析 JSON
    const raw: string = response.result as string;
    let parsed: LlmResponse;
    try { parsed = JSON.parse(raw) as LlmResponse; }
    catch (e) { throw new LlmError('LLM response parse error: ' + ((e as Error).message ?? String(e)), 'PARSE_ERROR'); }

    // 6. 提取 content
    return this.extractContent(parsed);
  }

  private extractContent(parsed: LlmResponse): string {
    if (parsed.choices.length === 0) { throw new LlmError('LLM returned empty choices', 'EMPTY_RESPONSE'); }
    const first: LlmResponseChoice = parsed.choices[0];
    if (first.message === undefined || first.message === null) { throw new LlmError('LLM returned empty message', 'EMPTY_RESPONSE'); }
    const content: string = first.message.content;
    if (content === undefined || content === null || content.length === 0) { throw new LlmError('LLM returned empty content', 'EMPTY_RESPONSE'); }
    return content;
  }

  private pickStr(v: string | undefined, fallback: string): string {
    if (v === undefined || v === null || v.length === 0) { return fallback; }
    return v;
  }

  private pickNum(v: number | undefined, fallback: number): number {
    if (v === undefined || v === null) { return fallback; }
    return v;
  }
}
