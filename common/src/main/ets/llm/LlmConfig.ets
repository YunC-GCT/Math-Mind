// MathMind - LLM 配置管理(单例 + preferences 持久化)
// 位置: common/src/main/ets/llm/LlmConfig.ets
// 责任: Z (Mavis)
// 创建: 2026-07-14 — 主 Agent 业务 LLM 调用基础设施
//
// 用法:
//   1) App 启动时(EntryAbility.onCreate 或 onWindowStageCreate)调一次:
//        await LlmConfig.getInstance().init(this.context)
//   2) UI 输入 API key 后:
//        await LlmConfig.getInstance().setApiKey(userInput)
//   3) 任何 agent 调 LLM 前:
//        const client = new LlmClient()
//        const text = await client.call(messages)  // 内部读 LlmConfig
//
// 存储: HarmonyOS preferences(单 key-value)
//   - store name: 'llm_config'
//   - key 'api_key': 用户输入的 LLM API key
//   - MVP: endpoint / model / temperature / maxTokens / timeoutMs 写死,后续可改 runtime 配置
//
// ArkTS 1.1 严格语法:
//   - 无 any / unknown
//   - 严格类型(无 Record<string, T> 断言)
//   - singleton 实例,private constructor

import { preferences } from '@kit.ArkData';
import { LlmConfigInitResult, LlmError } from './LlmTypes';

const STORE_NAME = 'llm_config';
const KEY_API_KEY = 'api_key';

export class LlmConfig {
  // ===== 单例 =====
  private static instance: LlmConfig | null = null;

  // ===== 内部状态 =====
  private store: preferences.Preferences | null = null;
  private inited: boolean = false;

  // ===== MVP 默认值(后续可改 runtime 配置)=====
  private static readonly DEFAULT_ENDPOINT: string = 'https://api.siliconflow.cn/v1/chat/completions';
  private static readonly DEFAULT_MODEL: string = 'deepseek-ai/DeepSeek-V3';
  private static readonly DEFAULT_TEMPERATURE: number = 0.1;
  private static readonly DEFAULT_MAX_TOKENS: number = 256;
  private static readonly DEFAULT_TIMEOUT_MS: number = 5000;

  // ===== 单例入口 =====
  private constructor() {}

  public static getInstance(): LlmConfig {
    if (LlmConfig.instance === null) {
      LlmConfig.instance = new LlmConfig();
    }
    return LlmConfig.instance;
  }

  // ===== 初始化(必须 app 启动时调一次)=====
  public async init(context: Context): Promise<LlmConfigInitResult> {
    if (this.inited && this.store !== null) {
      return { ok: true, message: 'LlmConfig already initialized' };
    }
    try {
      const storeRef: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
      this.store = storeRef;
      this.inited = true;
      return { ok: true, message: 'LlmConfig initialized' };
    } catch (e) {
      const msg: string = `LlmConfig init failed: ${JSON.stringify(e)}`;
      return { ok: false, message: msg };
    }
  }

  // ===== API key 读写 =====
  public async setApiKey(key: string): Promise<void> {
    this.requireInited();
    const trimmed: string = key.trim();
    if (trimmed.length === 0) {
      throw new LlmError('API key cannot be empty', 'NOT_INITIALIZED');
    }
    const storeRef: preferences.Preferences = this.store as preferences.Preferences;
    await storeRef.put(KEY_API_KEY, trimmed);
    await storeRef.flush();
  }

  public async getApiKey(): Promise<string | null> {
    this.requireInited();
    const storeRef: preferences.Preferences = this.store as preferences.Preferences;
    const v: string = await storeRef.get(KEY_API_KEY, '') as string;
    if (v === '') {
      return null;
    }
    return v;
  }

  public async isConfigured(): Promise<boolean> {
    const k: string | null = await this.getApiKey();
    return k !== null && k.length > 0;
  }

  public async clearApiKey(): Promise<void> {
    this.requireInited();
    const storeRef: preferences.Preferences = this.store as preferences.Preferences;
    await storeRef.delete(KEY_API_KEY);
    await storeRef.flush();
  }

  // ===== 静态配置 getter(MVP 写死)=====
  public getEndpoint(): string {
    return LlmConfig.DEFAULT_ENDPOINT;
  }

  public getModel(): string {
    return LlmConfig.DEFAULT_MODEL;
  }

  public getTemperature(): number {
    return LlmConfig.DEFAULT_TEMPERATURE;
  }

  public getMaxTokens(): number {
    return LlmConfig.DEFAULT_MAX_TOKENS;
  }

  public getTimeoutMs(): number {
    return LlmConfig.DEFAULT_TIMEOUT_MS;
  }

  // ===== 内部 =====
  private requireInited(): void {
    if (!this.inited || this.store === null) {
      throw new LlmError(
        'LlmConfig not initialized. Call LlmConfig.getInstance().init(context) at app startup.',
        'NOT_INITIALIZED',
      );
    }
  }
}
