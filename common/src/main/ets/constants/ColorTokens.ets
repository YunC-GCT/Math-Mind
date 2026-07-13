// MathMind - 配色 / 尺寸 / 字号 设计常量
// 来源: C:\Users\YunCeH\Desktop\仓库\MathMind-MVP\styles.css + 配色系统.md
// 用途: 所有 UI 文件统一引用,避免硬编码颜色/尺寸
// 创建: 2026-07-13

// ==================== 主色板 ====================
// 主色调: 成功/确认/已掌握
export const MINT: string = '#5BE3B0';
export const MINT_DARK: string = '#1F8F65';
export const MINT_LIGHT: string = '#245BE3B0';   // rgba(91,227,176,0.14)
export const MINT_GLOW: string = '#6B5BE3B0';    // rgba(91,227,176,0.42)
export const MINT_BORDER: string = '#475BE3B0';  // rgba(91,227,176,0.28)

// 次色调: AI/分析
export const PURPLE: string = '#9775FA';
export const PURPLE_DARK: string = '#7C5CE0';
export const PURPLE_LIGHT: string = '#249775FA'; // rgba(151,117,250,0.14)
export const PURPLE_GLOW: string = '#6B9775FA';  // rgba(151,117,250,0.42)

// 强调色
export const PINK: string = '#FF6B9D';
export const PINK_DARK: string = '#E03E76';

// 警告/中置信度
export const AMBER: string = '#F0C674';
export const AMBER_DARK: string = '#D49B2B';

// 错误/低置信度/删除
export const RED: string = '#FF6B6B';
export const GREEN: string = '#22C55E';
export const BLUE: string = '#3B82F6';
export const CYAN: string = '#22D3EE';
export const ORANGE: string = '#FB923C';

// ==================== 学科色 (3 种) ====================
export const SUBJECT_COLORS: Record<string, string> = {
  '高等代数': '#9775FA',
  '数学分析': '#FF6B9D',
  '解析几何': '#FB923C'
};

export const SUBJECT_DEFAULT: string = '#A8A8B0';

// ==================== 类型色 (3 种) ====================
export const TYPE_COLORS: Record<string, string> = {
  '概念': '#22D3EE',
  '计算': '#F0C674',
  '证明': '#5BE3B0',
  '笔记': '#5BE3B0'
};

export const TYPE_DEFAULT: string = '#A8A8B0';

// ==================== 置信度色 ====================
export const CONFIDENCE_HI: string = '#5BE3B0';   // ≥ 0.8
export const CONFIDENCE_MD: string = '#F0C674';   // 0.5-0.8
export const CONFIDENCE_LO: string = '#FF6B6B';   // < 0.5

// ==================== 文字色 ====================
export const TEXT: string = '#F4EFE5';
export const TEXT_2: string = '#D4CFC4';
export const TEXT_3: string = '#A8A8B0';
export const TEXT_4: string = '#6B6B75';

// ==================== 背景色 (暗色主题) ====================
export const BG: string = '#0A0C10';
export const BG_2: string = '#10131A';
export const BG_3: string = '#161A22';
export const BG_4: string = '#1D222D';

// ==================== 表面色 (半透明, hex #AARRGGBB) ====================
export const SURFACE: string = '#08FFFFFF';   // rgba(255,255,255,0.03)
export const SURFACE_2: string = '#0DFFFFFF'; // rgba(255,255,255,0.05)
export const SURFACE_3: string = '#14FFFFFF'; // rgba(255,255,255,0.08)
export const BORDER: string = '#12FFFFFF';    // rgba(255,255,255,0.07)
export const BORDER_2: string = '#1FFFFFFF';  // rgba(255,255,255,0.12)

// ==================== 圆角 (vp) ====================
export const R_SM: number = 8;
export const R: number = 14;
export const R_MD: number = 18;
export const R_LG: number = 22;
export const R_XL: number = 28;
export const R_FULL: number = 9999;

// ==================== 间距 (vp) ====================
export const S_1: number = 4;
export const S_2: number = 8;
export const S_3: number = 12;
export const S_4: number = 16;
export const S_5: number = 20;
export const S_6: number = 24;

// ==================== 字号 (fp) ====================
export const T_XS: number = 10;
export const T_SM: number = 12;
export const T_BASE: number = 14;
export const T_MD: number = 15;
export const T_LG: number = 16;
export const T_XL: number = 18;
export const T_2XL: number = 22;
export const T_3XL: number = 28;

// ==================== 屏幕尺寸 (vp, 目标机型 HUAWEI Pura 90) ====================
// Pura 90 真实规格(来自模拟器面板 2026-07-13):
//   屏幕大小:   6.8"
//   分辨率:     1320 × 2856 px
//   像素密度:   560 dpi
//   HarmonyOS:  6.1.1 (API 24)
//   CPU/ABI:    x86
//   RAM:        4096 MB
//   UUID:       cc2a953d-ab49-4e93-9b37-525560d9686c
//   部署路径:   C:\Users\YunCeH\AppData\Local\Huawei\Emulator\deployed\Pura 90
// vp 换算: vp = px / (dpi/160) = 1320/3.5 = 377 vp 宽, 2856/3.5 = 816 vp 高
// 所有布局用 vp/% 自适应,此处 SCREEN_W/H 仅作参考
export const SCREEN_W: number = 377;
export const SCREEN_H: number = 816;
export const STATUS_BAR_H: number = 48;
export const HEADER_H: number = 54;
export const TABBAR_H: number = 74;
