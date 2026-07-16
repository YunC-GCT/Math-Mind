// ============================================================================
//  services/ApiClient.ets — HTTP 客户端
//  ----------------------------------------------------------------------------
//  职责: 统一 HTTP 请求封装，自动 JWT 认证 + 401 自动刷新重试。
//  接口:
//    request<T>(method, path, options?): Promise<ApiResponse<T>>
//      - method: 'GET' | 'POST' | 'PUT' | 'DELETE'
//      - path: 相对路径, 如 '/agents/dispatch'
//      - options.body / options.headers / options.timeout
//    自动注入 JWT (Authorization: Bearer <token>)
//    401 时尝试一次 token 刷新后重试
//  验证方式: curl 调用 /health 端点返回 200
//  ============================================================================

import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { ApiResponse, ApiError } from 'common';

const PREF_STORE = 'auth_config';
const KEY_JWT = 'jwt_token';
const KEY_REFRESH = 'refresh_token';

// 请求选项
interface RequestOptions {
  body?: Object;
  headers?: Record<string, string>;
  timeout?: number;
}

export class ApiClient {
  private baseUrl: string = '';

  constructor(baseUrl?: string) { this.baseUrl = baseUrl ?? ''; }

  // 通用请求
  async request<T>(method: string, path: string, opts?: RequestOptions): Promise<ApiResponse<T>> {
    const url: string = this.baseUrl + path;
    const timeout: number = opts?.timeout ?? 10000;

    // 读 JWT
    const jwt: string = await this.loadJwt();
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (jwt.length > 0) { headers['Authorization'] = 'Bearer ' + jwt; }
    // 合并自定义 headers
    if (opts?.headers) {
      const custom: Record<string, string> = opts.headers;
      const keys: string[] = Object.keys(custom);
      for (const key of keys) { headers[key] = custom[key]; }
    }

    // 首次请求
    let resp: http.HttpResponse = await this.doHttp(method, url, headers, opts?.body, timeout);

    // 401 → 尝试刷新 token 后重试一次
    if (resp.responseCode === 401) {
      const refreshed: boolean = await this.refreshToken();
      if (refreshed) {
        const newJwt: string = await this.loadJwt();
        headers['Authorization'] = 'Bearer ' + newJwt;
        resp = await this.doHttp(method, url, headers, opts?.body, timeout);
      }
    }

    return this.parseResponse<T>(resp);
  }

  // 内部 HTTP 请求
  private async doHttp(
    method: string, url: string, headers: Record<string, string>,
    body: Object | undefined, timeout: number,
  ): Promise<http.HttpResponse> {
    const httpReq = http.createHttp();
    try {
      const resp: http.HttpResponse = await httpReq.request(url, {
        method: this.toMethod(method), header: headers,
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: timeout, readTimeout: timeout,
      });
      httpReq.destroy();
      return resp;
    } catch (e) {
      httpReq.destroy();
      throw { code: -1, message: 'Network error: ' + JSON.stringify(e), retryable: true } as ApiError;
    }
  }

  // 解析响应
  private parseResponse<T>(resp: http.HttpResponse): ApiResponse<T> {
    const code: number = resp.responseCode;
    if (code >= 200 && code < 300) {
      try {
        const raw: string = resp.result as string;
        return JSON.parse(raw) as ApiResponse<T>;
      } catch (e) {
        return { code: -2, message: 'Parse error: ' + JSON.stringify(e), success: false } as ApiResponse<T>;
      }
    }
    return { code: code, message: 'HTTP ' + code, success: false } as ApiResponse<T>;
  }

  // ===== JWT 持久化 =====

  private async loadJwt(): Promise<string> {
    try {
      const ctx = getContext();
      const store: preferences.Preferences = await preferences.getPreferences(ctx, PREF_STORE);
      return await store.get(KEY_JWT, '') as string;
    } catch (e) { return ''; }
  }

  private async refreshToken(): Promise<boolean> {
    try {
      const ctx = getContext();
      const store: preferences.Preferences = await preferences.getPreferences(ctx, PREF_STORE);
      const refresh: string = await store.get(KEY_REFRESH, '') as string;
      if (refresh.length === 0) { return false; }
      // MVP: refresh token 未实现 HTTP 调用 AuthService
      // 未实现前不能返回 true，否则调用方会误判 token 已刷新成功。
      return false;
    } catch (e) { return false; }
  }

  private toMethod(m: string): http.RequestMethod {
    if (m === 'POST') { return http.RequestMethod.POST; }
    if (m === 'PUT') { return http.RequestMethod.PUT; }
    if (m === 'DELETE') { return http.RequestMethod.DELETE; }
    return http.RequestMethod.GET;
  }
}
