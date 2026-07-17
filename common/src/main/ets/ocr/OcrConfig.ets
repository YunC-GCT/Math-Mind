// MathMind - OCR 服务端点配置(单例 + preferences 持久化)
// 创建: 2026-07-17 (P0 修复: OcrTool 端点从硬编码 localhost 改为可配置)
//
// 设计: 跟 LlmConfig 一致的单例 + preferences 模式
//   - getInstance() 单例
//   - init(context) 加载 preferences
//   - getEndpoint() / setEndpoint() 运行时读写
//   - resetDefaults() 恢复默认
//
// 默认值: 本地开发用 127.0.0.1:8000, 真机部署改 IP (类似 LLM)

import { preferences } from '@kit.ArkData';

const STORE_NAME: string = 'ocr_config';
const KEY_ENDPOINT: string = 'endpoint';
const KEY_ENABLED: string = 'enabled';

// 默认值 — 用户未配置时使用
// 注意: 真机部署到 HarmonyOS 设备时, 127.0.0.1 不可达, 需在 AI 设置页改成局域网 IP
const DEFAULT_ENDPOINT: string = 'http://127.0.0.1:8000/api/v1/ocr/recognize';
const DEFAULT_ENABLED: boolean = true;

export class OcrConfig {
  private static instance: OcrConfig | null = null;
  private store: preferences.Preferences | null = null;
  private inited: boolean = false;

  // 运行时缓存
  private cachedEndpoint: string = DEFAULT_ENDPOINT;
  private cachedEnabled: boolean = DEFAULT_ENABLED;

  private constructor() {}

  public static getInstance(): OcrConfig {
    if (OcrConfig.instance === null) {
      OcrConfig.instance = new OcrConfig();
    }
    return OcrConfig.instance;
  }

  // ===== 初始化 =====
  public async init(context: Context): Promise<void> {
    if (this.inited && this.store !== null) {
      return;
    }
    try {
      this.store = await preferences.getPreferences(context, STORE_NAME);
      // 加载持久化值(无则用默认)
      const ep: string = await this.store.get(KEY_ENDPOINT, '') as string;
      if (ep.length > 0) { this.cachedEndpoint = ep; }
      const en: boolean = await this.store.get(KEY_ENABLED, true) as boolean;
      this.cachedEnabled = en;
      this.inited = true;
    } catch (e) {
      // init 失败用默认, 不抛错 (OCR 是非关键路径, 失败走纯文本 prompt 兜底)
      this.cachedEndpoint = DEFAULT_ENDPOINT;
      this.cachedEnabled = DEFAULT_ENABLED;
    }
  }

  // ===== Endpoint =====
  public getEndpoint(): string { return this.cachedEndpoint; }

  public async setEndpoint(v: string): Promise<void> {
    const t: string = v.trim();
    this.cachedEndpoint = t.length > 0 ? t : DEFAULT_ENDPOINT;
    if (this.store !== null) {
      await this.store.put(KEY_ENDPOINT, this.cachedEndpoint);
      await this.store.flush();
    }
  }

  // ===== Enabled =====
  public isEnabled(): boolean { return this.cachedEnabled; }

  public async setEnabled(v: boolean): Promise<void> {
    this.cachedEnabled = v;
    if (this.store !== null) {
      await this.store.put(KEY_ENABLED, this.cachedEnabled);
      await this.store.flush();
    }
  }

  // ===== 恢复默认 =====
  public async resetDefaults(): Promise<void> {
    this.cachedEndpoint = DEFAULT_ENDPOINT;
    this.cachedEnabled = DEFAULT_ENABLED;
    if (this.store !== null) {
      await this.store.put(KEY_ENDPOINT, DEFAULT_ENDPOINT);
      await this.store.put(KEY_ENABLED, DEFAULT_ENABLED);
      await this.store.flush();
    }
  }
}
