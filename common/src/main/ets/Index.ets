// MathMind common HSP - public API 入口
// W1 块 2 完成 - 共享类型 + 工具层

// ==================== 占位常量(W0 验证保留)====================
export const COMMON_TAG = 'Hello from common v1!';
export const COMMON_VERSION = 'v0.0.1';

// ==================== 共享类型 ====================
export * from './models/CommonTypes';

// ==================== 工具层 ====================
export * from './utils/logger';
export * from './utils/uuid';
export * from './utils/timeWindow';
export * from './utils/confidenceSort';