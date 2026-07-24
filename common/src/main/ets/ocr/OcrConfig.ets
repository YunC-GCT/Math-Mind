// MindTrace - OCR 服务端点配置(单例 + preferences 持久化)
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
const KEY_MODE: string = 'mode';

// 默认值 — 用户未配置时使用
// 注意: 真机部署到 HarmonyOS 设备时, 127.0.0.1 不可达, 需在 AI 设置页改成局域网 IP
const DEFAULT_ENDPOINT: string = 'http://127.0.0.1:8000/api/v1/ocr/recognize';
const DEFAULT_ENABLED: boolean = true;
const DEFAULT_MODE: string = 'text';
const OCR_RECOGNIZE_PATH: string = '/api/v1/ocr/recognize';
const OCR_API_PREFIX: string = '/api/v1';
const FORMULA_HEALTH_PATH: string = '/api/v1/formula/health';
const DOCS_PATH: string = '/docs';

export class OcrConfig {
  private static instance: OcrConfig | null = null;
  private store: preferences.Preferences | null = null;
  private inited: boolean = false;

  // 运行时缓存
  private cachedEndpoint: string = DEFAULT_ENDPOINT;
  private cachedEnabled: boolean = DEFAULT_ENABLED;
  private cachedMode: string = DEFAULT_MODE;

  private constructor() {}

  public static getInstance(): OcrConfig {
    if (OcrConfig.instance === null) {
      OcrConfig.instance = new OcrConfig();
    }
    return OcrConfig.instance;
  }

  public static normalizeEndpointInput(value: string): string {
    let endpoint: string = value.trim().replace(/\\/g, '/');
    if (endpoint.length === 0) {
      return DEFAULT_ENDPOINT;
    }

    const queryIndex: number = endpoint.indexOf('?');
    const hashIndex: number = endpoint.indexOf('#');
    let cutIndex: number = -1;
    if (queryIndex >= 0 && hashIndex >= 0) {
      cutIndex = Math.min(queryIndex, hashIndex);
    } else if (queryIndex >= 0) {
      cutIndex = queryIndex;
    } else if (hashIndex >= 0) {
      cutIndex = hashIndex;
    }
    if (cutIndex >= 0) {
      endpoint = endpoint.substring(0, cutIndex);
    }

    if (!endpoint.startsWith('http://') && !endpoint.startsWith('https://')) {
      endpoint = 'http://' + endpoint;
    }

    while (endpoint.endsWith('/') && endpoint.length > 'http://'.length) {
      endpoint = endpoint.substring(0, endpoint.length - 1);
    }

    const lower: string = endpoint.toLowerCase();
    if (lower.endsWith(OCR_RECOGNIZE_PATH)) {
      return OcrConfig.ensureDefaultPort(endpoint);
    }
    if (lower.endsWith(FORMULA_HEALTH_PATH)) {
      return OcrConfig.ensureDefaultPort(
        endpoint.substring(0, endpoint.length - FORMULA_HEALTH_PATH.length) + OCR_RECOGNIZE_PATH,
      );
    }
    if (lower.endsWith(DOCS_PATH)) {
      endpoint = endpoint.substring(0, endpoint.length - DOCS_PATH.length);
    } else if (lower.endsWith(OCR_API_PREFIX + '/ocr')) {
      return OcrConfig.ensureDefaultPort(endpoint + '/recognize');
    } else if (lower.endsWith(OCR_API_PREFIX)) {
      return OcrConfig.ensureDefaultPort(endpoint + '/ocr/recognize');
    }

    return OcrConfig.ensureDefaultPort(endpoint) + OCR_RECOGNIZE_PATH;
  }

  public static normalizeModeInput(value: string): string {
    const mode: string = value.trim().toLowerCase();
    if (mode === 'formula' || mode === 'auto') {
      return mode;
    }
    return DEFAULT_MODE;
  }

  private static hostPart(endpoint: string): string {
    let start: number = 0;
    const schemeIndex: number = endpoint.indexOf('://');
    if (schemeIndex >= 0) {
      start = schemeIndex + 3;
    }
    const slashIndex: number = endpoint.indexOf('/', start);
    if (slashIndex >= 0) {
      return endpoint.substring(start, slashIndex);
    }
    return endpoint.substring(start);
  }

  private static shouldAppendDefaultPort(host: string): boolean {
    if (host.length === 0 || host.indexOf(':') >= 0) {
      return false;
    }
    if (host === 'localhost') {
      return true;
    }
    return /^\d{1,3}(\.\d{1,3}){3}$/.test(host);
  }

  private static ensureDefaultPort(endpoint: string): string {
    const host: string = OcrConfig.hostPart(endpoint);
    if (!OcrConfig.shouldAppendDefaultPort(host)) {
      return endpoint;
    }

    let start: number = 0;
    const schemeIndex: number = endpoint.indexOf('://');
    if (schemeIndex >= 0) {
      start = schemeIndex + 3;
    }
    const slashIndex: number = endpoint.indexOf('/', start);
    if (slashIndex < 0) {
      return endpoint + ':8000';
    }
    return endpoint.substring(0, slashIndex) + ':8000' + endpoint.substring(slashIndex);
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
      if (ep.length > 0) { this.cachedEndpoint = OcrConfig.normalizeEndpointInput(ep); }
      const en: boolean = await this.store.get(KEY_ENABLED, true) as boolean;
      this.cachedEnabled = en;
      const mode: string = await this.store.get(KEY_MODE, DEFAULT_MODE) as string;
      this.cachedMode = OcrConfig.normalizeModeInput(mode);
      this.inited = true;
    } catch (e) {
      // init 失败用默认, 不抛错 (OCR 是非关键路径, 失败走纯文本 prompt 兜底)
      this.cachedEndpoint = DEFAULT_ENDPOINT;
      this.cachedEnabled = DEFAULT_ENABLED;
      this.cachedMode = DEFAULT_MODE;
    }
  }

  // ===== Endpoint =====
  public getEndpoint(): string { return this.cachedEndpoint; }

  public async setEndpoint(v: string): Promise<void> {
    this.cachedEndpoint = OcrConfig.normalizeEndpointInput(v);
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

  // ===== Mode =====
  public getMode(): string { return this.cachedMode; }

  public async setMode(v: string): Promise<void> {
    this.cachedMode = OcrConfig.normalizeModeInput(v);
    if (this.store !== null) {
      await this.store.put(KEY_MODE, this.cachedMode);
      await this.store.flush();
    }
  }

  // ===== 恢复默认 =====
  public async resetDefaults(): Promise<void> {
    this.cachedEndpoint = DEFAULT_ENDPOINT;
    this.cachedEnabled = DEFAULT_ENABLED;
    this.cachedMode = DEFAULT_MODE;
    if (this.store !== null) {
      await this.store.put(KEY_ENDPOINT, DEFAULT_ENDPOINT);
      await this.store.put(KEY_ENABLED, DEFAULT_ENABLED);
      await this.store.put(KEY_MODE, DEFAULT_MODE);
      await this.store.flush();
    }
  }
}
