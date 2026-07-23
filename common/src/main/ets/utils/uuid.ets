// MindTrace - UUID 生成
// 优先使用系统 util,失败时降级到时间戳 + 随机
// 创建: Z (W1 块 2 - 2026-07-04)

import { util } from '@kit.ArkTS';

// 缓存随机辅助
function rand(): string {
  return Math.floor(Math.random() * 0x100000000).toString(16).padStart(8, '0');
}

export function uuid(): string {
  // 优先用系统 util(更标准的 RFC 4122 v4)
  try {
    const gen = util.generateRandomUUID(false);
    if (typeof gen === 'string' && gen.length > 0) {
      return gen;
    }
  } catch (e) {
    // 降级路径
  }
  // 降级: 时间戳 + 随机
  return `${Date.now().toString(16)}-${rand()}-${rand()}-${rand()}`;
}

// 短 ID(12 字符,适合卡片显示)
export function shortId(): string {
  return uuid().replace(/-/g, '').substring(0, 12);
}