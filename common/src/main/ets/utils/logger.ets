// MathMind - 统一日志工具
// 封装 hilog,统一 TAG,按级别输出
// 创建: Z (W1 块 2 - 2026-07-04)

import hilog from '@ohos.hilog';

const APP_TAG = 'MathMind';
const DOMAIN = 0x0001;

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

export class Logger {
  private tag: string;

  constructor(tag: string) {
    this.tag = tag;
  }

  debug(msg: string, ...args: Object[]): void {
    hilog.debug(DOMAIN, APP_TAG, `[${this.tag}] ${this.format(msg, args)}`);
  }

  info(msg: string, ...args: Object[]): void {
    hilog.info(DOMAIN, APP_TAG, `[${this.tag}] ${this.format(msg, args)}`);
  }

  warn(msg: string, ...args: Object[]): void {
    hilog.warn(DOMAIN, APP_TAG, `[${this.tag}] ${this.format(msg, args)}`);
  }

  error(msg: string, ...args: Object[]): void {
    hilog.error(DOMAIN, APP_TAG, `[${this.tag}] ${this.format(msg, args)}`);
  }

  private format(msg: string, args: Object[]): string {
    if (args.length === 0) {
      return msg;
    }
    const parts: string[] = [msg];
    args.forEach((arg: Object, index: number): void => {
      parts.push(`arg${index}=${JSON.stringify(arg)}`);
    });
    return parts.join(' | ');
  }
}

// 全局默认 logger(无 tag)
export const defaultLog = new Logger('default');

// 模块级 logger 工厂
export function getLogger(tag: string): Logger {
  return new Logger(tag);
}
