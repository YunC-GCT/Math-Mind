/**
 * MathMind 设计 Token — 严格对照 styles.css :root + app.js tc()/sc()
 * 全量 #AARRGGBB hex；半透明由 rgba() 换算
 */

// ========== 主色板 11 个 ==========
export const MINT         = '#FF5BE3B0';   // --mint
export const MINT_DARK    = '#FF1F8F65';   // --mint-dark
export const MINT_LIGHT   = '#245BE3B0';   // rgba(91,227,176,0.14)
export const MINT_GLOW    = '#6B5BE3B0';   // rgba(91,227,176,0.42)
export const MINT_BORDER  = '#475BE3B0';   // rgba(91,227,176,0.28)
export const PURPLE       = '#FF9775FA';   // --purple
export const PURPLE_DARK  = '#FF7C5CE0';   // --purple-dark
export const PURPLE_LIGHT = '#249775FA';   // rgba(151,117,250,0.14)
export const PINK         = '#FFFF6B9D';   // --pink
export const AMBER        = '#FFF0C674';   // --amber
export const BG_DARK      = '#FF0A0C10';   // --bg

// ========== 扩展色 ==========
export const BG_CARD     = '#FF10131A';   // --bg-2

// ========== 学科色 3 个 ==========
export const SUBJECT_COLORS: Record<string, string> = {
  '数学分析': PINK,
  '高等代数': PURPLE,
  '空间解析几何': AMBER,
  '解析几何': AMBER,
};

// ========== 类型色 3 个 ==========
export const TYPE_COLORS: Record<string, string> = {
  '概念': MINT,
  '计算': PURPLE,
  '证明': AMBER,
};

// ========== 文字色 4 个 ==========
export const TEXT   = '#FFFFFFFF';   // 主文字 白
export const TEXT_2 = '#FFB0B3C1';   // 次要文字 浅灰
export const TEXT_3 = '#FF6B7280';   // 三级文字 中灰
export const TEXT_4 = '#FF4B5563';   // 四级文字 暗灰

// ========== 边框色 ==========
export const BORDER = '#1AFFFFFF';   // rgba(255,255,255,0.10)

// ========== 间距 6 个 (vp) ==========
export const S_1: number = 4;
export const S_2: number = 8;
export const S_3: number = 12;
export const S_4: number = 16;
export const S_5: number = 20;
export const S_6: number = 24;

// ========== 圆角 6 个 (vp) ==========
export const R_SM: number   = 6;
export const R_MD: number   = 8;
export const R_LG: number   = 12;
export const R_XL: number   = 16;
export const R_2XL: number  = 24;
export const R_FULL: number = 9999;

// ========== 字号 8 个 (fp) ==========
export const F_XS: number   = 11;
export const F_SM: number   = 12;
export const F_BASE: number = 14;
export const F_MD: number   = 16;
export const F_LG: number   = 18;
export const F_XL: number   = 20;
export const F_2XL: number  = 24;
export const F_3XL: number  = 30;

// ========== Pura 90 屏幕尺寸 (vp) ==========
export const SCREEN_W: number = 377;
export const SCREEN_H: number = 816;
